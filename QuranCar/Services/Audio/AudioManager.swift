import AVFoundation
import Foundation

class AudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var currentVerseIndex = 0
    @Published var downloadProgress: Double = 0

    private var player: AVPlayer?
    private var playerItems: [AVPlayerItem] = []
    private var audioFiles: [URL] = []
    private var startVerse: Int = 1
    private var endVerse: Int = 1
    private var timeObserver: Any?

    override init() {
        super.init()
        setupAudioSession()
    }

    func prepareAudio(audioFiles: [AudioFileEntity], startVerse: Int, endVerse: Int) async throws {
        // Clean up existing player and observers before creating new ones
        cleanupCurrentPlayer()

        isLoading = true
        self.startVerse = startVerse
        self.endVerse = endVerse

        // Get URLs for the verse range
        let versesToPlay = audioFiles.filter { file in
            if let verseNumber = Int(file.verseKey?.split(separator: ":").last ?? "0") {
                return verseNumber >= startVerse && verseNumber <= endVerse
            }
            return false
        }

        print("AudioManager: Found \(versesToPlay.count) verses to play in range \(startVerse) to \(endVerse)")
        print("AudioManager: Verse keys to play: \(versesToPlay.map { $0.verseKey ?? "unknown" })")
        print("AudioManager: URLs to download: \(versesToPlay.map { $0.url ?? "unknown" })")

        // Download files
        let urls = try await downloadAudioFiles(urls: versesToPlay.map { $0.url ?? "" })
        print("AudioManager: Successfully downloaded \(urls.count) files")
        self.audioFiles = urls

        // Create player items
        self.playerItems = urls.map { AVPlayerItem(url: $0) }
        print("AudioManager: Created \(playerItems.count) player items")

        // Create player with first item
        if let firstItem = playerItems.first {
            player = AVPlayer(playerItem: firstItem)
            setupPlayerObservers()
            print("AudioManager: Player created with first item")
        } else {
            print("AudioManager: Error - No player items available")
        }

        isLoading = false
    }

    func startPlayback() {
        print("AudioManager: Starting playback")
        print("AudioManager: Current player item: \(String(describing: player?.currentItem))")
        print("AudioManager: Total items in queue: \(playerItems.count)")
        isPlaying = true
        player?.play()
    }

    func stopPlayback() {
        print("AudioManager: Stopping playback")
        isPlaying = false
        player?.pause()
    }

    private func downloadAudioFiles(urls: [String]) async throws -> [URL] {
        print("AudioManager: Starting download of \(urls.count) files")
        var downloadedFiles: [URL] = []
        let fileManager = FileManager.default
        let cacheDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        print("AudioManager: Cache directory: \(cacheDirectory.path)")

        for (index, urlString) in urls.enumerated() {
            let formattedUrlString = urlString.contains("mirrors.quranicaudio") ? "https:\(urlString)" : "https://verses.quran.foundation/\(urlString)"
            print("AudioManager: Processing URL [\(index + 1)/\(urls.count)]: \(formattedUrlString)")

            guard let url = URL(string: formattedUrlString) else {
                print("AudioManager: Invalid URL: \(formattedUrlString)")
                continue
            }

            // Create filename from last 4 path components while preserving extension, if 4 components are not available, use the last 3
            let pathComponents = url.pathComponents.filter { $0 != "/" }
            let lastComponents = pathComponents.count >= 4 ? pathComponents.suffix(4) : pathComponents.suffix(3)
            let urlExtension = url.pathExtension

            // Join components without the last component's extension
            let fileNameWithoutExtension = lastComponents
                .dropLast()
                .joined(separator: "_")
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? UUID().uuidString

            // Add the last component and extension back
            let fileName = "\(fileNameWithoutExtension)_\(lastComponents.last?.components(separatedBy: ".").first ?? "").\(urlExtension)"

            print("AudioManager: Generated filename: \(fileName)")
            let fileURL = cacheDirectory.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: fileURL.path) {
                print("AudioManager: File already cached: \(fileName)")
                downloadedFiles.append(fileURL)
                downloadProgress = Double(index + 1) / Double(urls.count)
                continue
            }

            print("AudioManager: Downloading file: \(fileName)")
            do {
                let (downloadURL, _) = try await URLSession.shared.download(from: url)
                try fileManager.moveItem(at: downloadURL, to: fileURL)
                downloadedFiles.append(fileURL)
                print("AudioManager: Successfully downloaded and cached: \(fileName)")
            } catch {
                print("AudioManager: Error downloading file \(fileName): \(error)")
                throw error
            }

            downloadProgress = Double(index + 1) / Double(urls.count)
        }

        print("AudioManager: Completed downloads. Total files: \(downloadedFiles.count)")
        return downloadedFiles
    }

    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("AudioManager: Audio session setup successful")
        } catch {
            print("AudioManager: Failed to set up audio session: \(error)")
        }
    }

    private func cleanupCurrentPlayer() {
        // Remove time observer from current player
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        // Stop and clear current player
        player?.pause()
        player = nil

        // Clear items
        playerItems.removeAll()
        audioFiles.removeAll()
    }

    private func setupPlayerObservers() {
        print("AudioManager: Setting up observers for \(playerItems.count) items")

        // Make sure we have a valid player
        guard let player = player else {
            print("AudioManager: No player available to setup observers")
            return
        }

        // Remove existing observers without clearing the player
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
        NotificationCenter.default.removeObserver(self)

        // Observe ALL player items for completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )

        // Add periodic time observer to the current player
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            if let currentItem = self?.player?.currentItem,
               currentItem.duration.isValid && currentItem.duration != .indefinite,
               currentItem.duration.seconds > 0 {
                let progress = time.seconds / currentItem.duration.seconds
                print("AudioManager: Playback progress: \(Int(progress * 100))% of current item")
            }
        }

        // Print the queue for debugging
        print("AudioManager: Audio queue:")
        for (index, item) in playerItems.enumerated() {
            if let urlAsset = item.asset as? AVURLAsset {
                print("AudioManager: Item \(index): \(urlAsset.url.lastPathComponent)")
            }
        }
    }

    @objc private func playerItemDidFinish(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem,
              let currentIndex = playerItems.firstIndex(of: playerItem) else {
            print("AudioManager: Could not identify completed item")
            return
        }

        print("AudioManager: Item \(currentIndex) finished playing")
        currentVerseIndex = currentIndex + 1

        if currentVerseIndex >= playerItems.count {
            print("AudioManager: Reached end of playlist, resetting state")
            currentVerseIndex = 0
            isPlaying = false
            player?.pause()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioPlaybackCompleted, object: nil)
            }
            return
        }

        print("AudioManager: Playing next item at index: \(currentVerseIndex)")
        if let nextItem = playerItems[safe: currentVerseIndex] {
            player?.replaceCurrentItem(with: nextItem)
            player?.play()

            if let urlAsset = nextItem.asset as? AVURLAsset {
                print("AudioManager: Now playing: \(urlAsset.url.lastPathComponent)")
            }
        }
    }

    deinit {
        cleanupCurrentPlayer()
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// Add notification name
extension Notification.Name {
    static let audioPlaybackCompleted = Notification.Name("audioPlaybackCompleted")
}
