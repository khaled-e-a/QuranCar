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
        setupNotificationObservers()
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

        Logger.debug("AudioManager: Found \(versesToPlay.count) verses to play in range \(startVerse) to \(endVerse)")
        Logger.debug("AudioManager: Verse keys to play: \(versesToPlay.map { $0.verseKey ?? "unknown" })")
        Logger.debug("AudioManager: URLs to download: \(versesToPlay.map { $0.url ?? "unknown" })")

        // Download files
        let urls = try await downloadAudioFiles(urls: versesToPlay.map { $0.url ?? "" })
        Logger.debug("AudioManager: Successfully downloaded \(urls.count) files")
        self.audioFiles = urls

        // Create player items
        self.playerItems = urls.map { AVPlayerItem(url: $0) }
        Logger.debug("AudioManager: Created \(playerItems.count) player items")

        // Create player with first item
        if let firstItem = playerItems.first {
            let player = AVPlayer(playerItem: firstItem)
            player.automaticallyWaitsToMinimizeStalling = false
            player.allowsExternalPlayback = true

            // Enable background playback
            try? AVAudioSession.sharedInstance().setActive(true)

            self.player = player
            setupPlayerObservers()
            Logger.debug("AudioManager: Player created with first item")
        } else {
            Logger.error("AudioManager: Error - No player items available")
        }

        isLoading = false
    }

    func startPlayback() {
        Logger.debug("AudioManager: Starting playback")
        Logger.debug("AudioManager: Current player item: \(String(describing: player?.currentItem))")
        Logger.debug("AudioManager: Total items in queue: \(playerItems.count)")
        isPlaying = true
        player?.play()
    }

    func stopPlayback() {
        Logger.debug("AudioManager: Stopping playback")
        isPlaying = false
        player?.pause()
    }

    private func downloadAudioFiles(urls: [String]) async throws -> [URL] {
        Logger.debug("AudioManager: Starting download of \(urls.count) files")
        var downloadedFiles: [URL] = []
        let fileManager = FileManager.default
        let cacheDirectory = try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        Logger.debug("AudioManager: Cache directory: \(cacheDirectory.path)")

        for (index, urlString) in urls.enumerated() {
            let formattedUrlString = urlString.contains("mirrors.quranicaudio") ? "https:\(urlString)" : "https://verses.quran.foundation/\(urlString)"
            Logger.debug("AudioManager: Processing URL [\(index + 1)/\(urls.count)]: \(formattedUrlString)")

            guard let url = URL(string: formattedUrlString) else {
                Logger.error("AudioManager: Invalid URL: \(formattedUrlString)")
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

            Logger.debug("AudioManager: Generated filename: \(fileName)")
            let fileURL = cacheDirectory.appendingPathComponent(fileName)

            if fileManager.fileExists(atPath: fileURL.path) {
                Logger.debug("AudioManager: File already cached: \(fileName)")
                downloadedFiles.append(fileURL)
                downloadProgress = Double(index + 1) / Double(urls.count)
                continue
            }

            Logger.debug("AudioManager: Downloading file: \(fileName)")
            do {
                let (downloadURL, _) = try await URLSession.shared.download(from: url)
                try fileManager.moveItem(at: downloadURL, to: fileURL)
                downloadedFiles.append(fileURL)
                Logger.debug("AudioManager: Successfully downloaded and cached: \(fileName)")
            } catch {
                Logger.error("AudioManager: Error downloading file \(fileName): \(error)")
                throw error
            }

            downloadProgress = Double(index + 1) / Double(urls.count)
        }

        Logger.debug("AudioManager: Completed downloads. Total files: \(downloadedFiles.count)")
        return downloadedFiles
    }

    private func setupAudioSession() {
        do {
            // Update audio session configuration
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.allowBluetooth, .defaultToSpeaker]
            )
            try AVAudioSession.sharedInstance().setActive(true)

            // Enable background audio
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)

            Logger.debug("AudioManager: Audio session setup successful")
        } catch {
            Logger.error("AudioManager: Failed to set up audio session: \(error)")
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
        Logger.debug("AudioManager: Setting up observers for \(playerItems.count) items")

        // Make sure we have a valid player
        guard let player = player else {
            Logger.error("AudioManager: No player available to setup observers")
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
                Logger.debug("AudioManager: Playback progress: \(Int(progress * 100))% of current item")
            }
        }

        // Print the queue for debugging
        Logger.debug("AudioManager: Audio queue:")
        for (index, item) in playerItems.enumerated() {
            if let urlAsset = item.asset as? AVURLAsset {
                Logger.debug("AudioManager: Item \(index): \(urlAsset.url.lastPathComponent)")
            }
        }
    }

    @objc private func playerItemDidFinish(_ notification: Notification) {
        guard let playerItem = notification.object as? AVPlayerItem,
              let currentIndex = playerItems.firstIndex(of: playerItem) else {
            Logger.error("AudioManager: Could not identify completed item")
            return
        }

        Logger.debug("AudioManager: Item \(currentIndex) finished playing")
        currentVerseIndex = currentIndex + 1

        if currentVerseIndex >= playerItems.count {
            Logger.debug("AudioManager: Reached end of playlist, resetting state")
            currentVerseIndex = 0
            isPlaying = false
            player?.pause()

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .audioPlaybackCompleted, object: nil)
            }
            return
        }

        Logger.debug("AudioManager: Playing next item at index: \(currentVerseIndex)")
        if let nextItem = playerItems[safe: currentVerseIndex] {
            player?.replaceCurrentItem(with: nextItem)
            player?.play()

            if let urlAsset = nextItem.asset as? AVURLAsset {
                Logger.debug("AudioManager: Now playing: \(urlAsset.url.lastPathComponent)")
            }
        }
    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Audio session interrupted (e.g., phone call)
            stopPlayback()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                // Interruption ended - resume playback
                startPlayback()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        switch reason {
        case .oldDeviceUnavailable:
            // Audio output was removed (e.g., headphones unplugged)
            stopPlayback()
        default:
            break
        }
    }

    deinit {
        cleanupCurrentPlayer()
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
