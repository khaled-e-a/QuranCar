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
        print("AudioManager: Preparing audio for verses \(startVerse) to \(endVerse)")
        print("AudioManager: Total available audio files: \(audioFiles.count)")

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
            // Format URL if it's from mirrors.quranicaudio
            let formattedUrlString = urlString.contains("mirrors.quranicaudio") ? "https:\(urlString)" : urlString
            print("AudioManager: Processing URL [\(index + 1)/\(urls.count)]: \(formattedUrlString)")

            guard let url = URL(string: formattedUrlString) else {
                print("AudioManager: Invalid URL: \(formattedUrlString)")
                continue
            }

            // Create a filesystem-safe filename from the entire URL
            let fileName = url.absoluteString
                .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)?
                .replacingOccurrences(of: ".", with: "_") ?? UUID().uuidString
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

    private func setupPlayerObservers() {
        // Remove existing observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        // Observe item completion
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }

    @objc private func playerItemDidFinish() {
        print("AudioManager: Item finished playing")
        currentVerseIndex += 1

        if currentVerseIndex >= audioFiles.count {
            print("AudioManager: Reached end of playlist, resetting state")
            currentVerseIndex = 0
            isPlaying = false  // Reset playing state
            player?.pause()    // Ensure player is paused

            // Post notification for playlist completion
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioPlaybackCompleted, object: nil)
            }
            return  // Don't automatically start over
        }

        print("AudioManager: Playing next item at index: \(currentVerseIndex)")
        if let nextItem = playerItems[safe: currentVerseIndex] {
            player?.replaceCurrentItem(with: nextItem)
            player?.play()
        }
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
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