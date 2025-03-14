import CarPlay
import SwiftUI
import Combine
import MediaPlayer

class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var nowPlayingTemplate: CPNowPlayingTemplate?
    private var rootTemplate: CPTabBarTemplate?
    private var bookViewModel: BookViewModel?
    private var cancellables = Set<AnyCancellable>()

    // Add state for looping
    private var isLooping: Bool = true
    private var currentPlaybackTask: Task<Void, Never>?

    // Add state tracking
    private var currentVerse: String = ""
    private var numberOfVerses: Int = 3

    // MARK: - Required CPTemplateApplicationSceneDelegate Methods

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Initialize view model if needed
        if bookViewModel == nil {
            bookViewModel = BookViewModel()
        }

        // Setup templates
        setupNowPlayingTemplate()
        setupRootTemplate()

        // Set initial root template
        interfaceController.setRootTemplate(rootTemplate!, animated: true)

        // Setup state observation
        observePlaybackState()

        // Setup remote command center
        setupRemoteCommandCenter()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
        cancellables.removeAll()
    }

    // MARK: - Scene Lifecycle Methods

    func sceneDidBecomeActive(_ scene: CPTemplateApplicationScene) {
        // Handle scene becoming active
    }

    func sceneWillResignActive(_ scene: CPTemplateApplicationScene) {
        // Handle scene resigning active
    }

    func sceneDidEnterBackground(_ scene: CPTemplateApplicationScene) {
        // Handle scene entering background
    }

    func sceneWillEnterForeground(_ scene: CPTemplateApplicationScene) {
        // Handle scene entering foreground
    }

    private func setupNowPlayingTemplate() {
        nowPlayingTemplate = CPNowPlayingTemplate.shared

        // Add custom buttons for chunk navigation
        let previousButton = CPNowPlayingImageButton(
            image: UIImage(systemName: "backward.fill")!
        ) { [weak self] _ in
            self?.handlePreviousChunk()
        }

        let nextButton = CPNowPlayingImageButton(
            image: UIImage(systemName: "forward.fill")!
        ) { [weak self] _ in
            self?.handleNextChunk()
        }

        // Create a more button for additional options
        let moreButton = CPNowPlayingMoreButton { [weak self] _ in
            // Handle more options if needed
        }

        // Enable/disable buttons based on state
        previousButton.isEnabled = true
        nextButton.isEnabled = true

        // Update the template with all buttons
        nowPlayingTemplate?.updateNowPlayingButtons([
            previousButton,
            nextButton,
            moreButton
        ])
    }

    private func setupRootTemplate() {
        // Create templates for each tab
        let memorizeTemplate = createMemorizeTemplate()
        let settingsTemplate = createSettingsTemplate()

        rootTemplate = CPTabBarTemplate(templates: [memorizeTemplate, settingsTemplate])
    }

    private func createMemorizeTemplate() -> CPListTemplate {
        let section = CPListSection(items: [
            CPListItem(
                text: "Current Memorization",
                detailText: getCurrentMemorizationDetails(),
                image: UIImage(systemName: "book.fill")
            )
        ])

        return CPListTemplate(title: "Memorize", sections: [section])
    }

    private func createSettingsTemplate() -> CPListTemplate {
        let section = CPListSection(items: [
            CPListItem(
                text: "Number of Verses",
                detailText: "3", // Default value since numberOfVerses isn't directly accessible
                image: UIImage(systemName: "number")
            ),
            CPListItem(
                text: "Selected Reciter",
                detailText: bookViewModel?.selectedReciter?.translatedName ?? "Default",
                image: UIImage(systemName: "person.wave.2")
            )
        ])

        return CPListTemplate(title: "Settings", sections: [section])
    }

    private func getCurrentMemorizationDetails() -> String {
        guard let viewModel = bookViewModel else { return "Not configured" }
        return "\(viewModel.selectedChapter?.nameSimple ?? "No surah") - Verse \(viewModel.currentVerseNumber)"
    }

    private func observePlaybackState() {
        bookViewModel?.$isPlaying
            .sink { [weak self] isPlaying in
                self?.updatePlaybackState(isPlaying: isPlaying)
            }
            .store(in: &cancellables)
    }

    private func updatePlaybackState(isPlaying: Bool) {
        // Update CarPlay now playing interface
        if isPlaying {
            // Update playback state
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 1.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo

            // Update now playing info if needed
            updateNowPlayingInfo()
        } else {
            // Pause playback
            var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        }
    }

    private func updateNowPlayingInfo() {
        guard let viewModel = bookViewModel else { return }

        // Update the now playing info using MPNowPlayingInfoCenter
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = viewModel.selectedChapter?.nameSimple ?? "Unknown Surah"
        nowPlayingInfo[MPMediaItemPropertyArtist] = viewModel.selectedReciter?.translatedName ?? "Unknown Reciter"
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = "Verse \(viewModel.currentVerseNumber)"

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            print("CarPlay: Play command received")
            Task {
                await self?.startPlayback()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            print("CarPlay: Pause command received")
            Task {
                await self?.stopPlayback()
            }
            return .success
        }

        // Next Track command (for steering wheel next)
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            print("CarPlay: Next track command received")
            Task { @MainActor in
                self?.handleNextChunk()
            }
            return .success
        }

        // Previous Track command (for steering wheel previous)
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            print("CarPlay: Previous track command received")
            Task { @MainActor in
                self?.handlePreviousChunk()
            }
            return .success
        }

        // Enable the commands
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.isEnabled = true
    }

    private func startPlayback() async {
        guard let viewModel = bookViewModel else { return }

        // Cancel any existing playback
        currentPlaybackTask?.cancel()

        // Start new playback loop
        currentPlaybackTask = Task {
            await playWithLooping(
                verse: currentVerse,
                numberOfVerses: numberOfVerses
            )
        }
    }

    private func stopPlayback() async {
        // Stop the loop and playback
        isLooping = false
        currentPlaybackTask?.cancel()
        currentPlaybackTask = nil

        if let viewModel = bookViewModel {
            await viewModel.togglePlayback(
                selectedVerse: currentVerse,
                numberOfVerses: numberOfVerses
            )
        }
    }

    private func playWithLooping(verse: String, numberOfVerses: Int) async {
        // Force stop any current playback
        if let viewModel = bookViewModel, viewModel.isPlaying {
            await viewModel.togglePlayback(
                selectedVerse: verse,
                numberOfVerses: numberOfVerses
            )
        }

        isLooping = true

        while isLooping {
            if Task.isCancelled { return }

            // Start new playback
            if let viewModel = bookViewModel {
                await viewModel.togglePlayback(
                    selectedVerse: verse,
                    numberOfVerses: numberOfVerses
                )

                // Wait for playback to complete
                while viewModel.isPlaying && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(100))
                }

                if Task.isCancelled { return }

                // Half second pause between loops
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func handleNextChunk() {
        guard let viewModel = bookViewModel else { return }

        // Stop current playback if playing
        if viewModel.isPlaying {
            Task {
                await stopPlayback()
            }
        }

        let currentVerseNumber = Int(currentVerse.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)

        // Calculate next verse number
        let nextVerseNumber = min(currentVerseNumber + numberOfVerses, maxVerses)

        if let nextVerse = viewModel.currentVerses.first(where: { $0.verseNumber == nextVerseNumber }),
           let text = nextVerse.textUthmani {
            currentVerse = "\(nextVerseNumber). \(text)"

            // Start playback of new verse
            Task {
                await startPlayback()
            }

            // Update UI
            updateNowPlayingInfo()
        }
    }

    private func handlePreviousChunk() {
        guard let viewModel = bookViewModel else { return }

        // Stop current playback if playing
        if viewModel.isPlaying {
            Task {
                await stopPlayback()
            }
        }

        let currentVerseNumber = Int(currentVerse.split(separator: ".").first ?? "1") ?? 1

        // Calculate previous verse number
        let previousVerseNumber = max(currentVerseNumber - numberOfVerses, 1)

        if let previousVerse = viewModel.currentVerses.first(where: { $0.verseNumber == previousVerseNumber }),
           let text = previousVerse.textUthmani {
            currentVerse = "\(previousVerseNumber). \(text)"

            // Start playback of new verse
            Task {
                await startPlayback()
            }

            // Update UI
            updateNowPlayingInfo()
        }
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didSelect nowPlayingTemplate: CPNowPlayingTemplate
    ) {
        // Handle when now playing template is selected
        self.nowPlayingTemplate = nowPlayingTemplate
        updateNowPlayingInfo()
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        willDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        // Prepare for disconnect
        // Save any state if needed
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didFailToLoadInterfaceController error: Error
    ) {
        print("CarPlay failed to load: \(error.localizedDescription)")
    }
}