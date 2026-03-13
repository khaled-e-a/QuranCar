import CarPlay
import SwiftUI
import Combine
import MediaPlayer

@MainActor
class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    private var nowPlayingTemplate: CPNowPlayingTemplate?
    private var rootTemplate: CPTemplate?
    private var bookViewModel: BookViewModel?
    private var cancellables = Set<AnyCancellable>()

    // Disable enabling for selection in the current version
    private var isEnabled = false

    // Add state for looping
    private var isLooping: Bool = true
    private var currentPlaybackTask: Task<Void, Never>?

    // Add state tracking
    private var numberOfVerses: Int = 3

    // Add this property to track template state
    private var isShowingSubTemplate = false

    // MARK: - Required CPTemplateApplicationSceneDelegate Methods

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        self.interfaceController = interfaceController

        // Notify connection status
        NotificationCenter.default.post(
            name: .CPTemplateApplicationSceneDidConnect,
            object: nil
        )

        // Use shared instance
        bookViewModel = BookViewModel.shared
        if let viewModel = bookViewModel {
            Logger.debug("CarPlay: Using shared BookViewModel instance: \(ObjectIdentifier(viewModel))")
        }

        // Load initial data
        Task {
            try? await bookViewModel?.loadQuranData()

            // Update verse text to match saved verse number, not always first verse
            guard let viewModel = bookViewModel else { return }
            let savedVerseNumber = viewModel.currentVerseNumber
            
            if let verse = viewModel.currentVerses.first(where: { $0.verseNumber == savedVerseNumber }),
               let text = verse.textUthmani {
                viewModel.selectedVerseText = "\(verse.verseNumber). \(text)"
            } else if let firstVerse = viewModel.currentVerses.first,
                      let text = firstVerse.textUthmani {
                // Only fallback to first verse if saved verse not found
                viewModel.selectedVerseText = "\(firstVerse.verseNumber). \(text)"
                viewModel.currentVerseNumber = Int(firstVerse.verseNumber)
            }
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

        // Notify disconnection
        NotificationCenter.default.post(
            name: .CPTemplateApplicationSceneDidDisconnect,
            object: nil
        )
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
        Logger.debug("CarPlay: Setting up root template")
        if let viewModel = bookViewModel {
            Logger.debug("CarPlay: BookViewModel instance: \(ObjectIdentifier(viewModel))")
            Logger.debug("CarPlay: Selected chapter: \(viewModel.selectedChapter?.nameSimple ?? "None")")
            Logger.debug("CarPlay: Current verses count: \(viewModel.currentVerses.count)")
        }

        // Use memorize template directly as root
        rootTemplate = createMemorizeTemplate()
        interfaceController?.setRootTemplate(rootTemplate!, animated: true)
        Logger.debug("CarPlay: Root template updated")
    }

    private func createMemorizeTemplate() -> CPListTemplate {
        // Get current state for display
        let surahDetailText = bookViewModel?.selectedChapter?.nameSimple ?? "Not Selected"
        let verseDetailText = bookViewModel?.selectedVerseText ?? "Not Selected"
        let isPlaying = bookViewModel?.isPlaying ?? false
        let isPreparingAudio = bookViewModel?.isPreparingAudio ?? false
        let reciterName = bookViewModel?.selectedReciter?.translatedName ?? "Not Selected"

        Logger.debug("CarPlay: Creating template - Playing: \(isPlaying), Preparing: \(isPreparingAudio)")

        // Create a single section with all items
        let section = CPListSection(items: [
            // Playback control
            CPListItem(
                text: getPlayButtonText(isPlaying: isPlaying, isPreparing: isPreparingAudio),
                detailText: getPlayButtonDetail(isPlaying: isPlaying, isPreparing: isPreparingAudio),
                image: getPlayButtonImage(isPlaying: isPlaying, isPreparing: isPreparingAudio),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.handler = { [weak self] _, _ in
                    Task {
                        if isPlaying {
                            Logger.debug("CarPlay: Stopping playback")
                            await self?.stopPlayback()
                        } else if !isPreparingAudio {
                            Logger.debug("CarPlay: Starting playback")
                            await self?.startPlayback()
                        }
                    }
                }
                item.isEnabled = !isPreparingAudio
            },

            // Surah selection
            CPListItem(
                text: "Surah",
                detailText: surahDetailText,
                image: UIImage(systemName: "book.fill"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    Logger.debug("CarPlay: Select Surah item tapped")
                    self?.showSurahSelection()
                }
            },

            // Verse selection
            CPListItem(
                text: "Starting Verse",
                detailText: verseDetailText,
                image: UIImage(systemName: "text.quote"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    self?.showVerseSelection()
                }
            },

            // Number of verses
            CPListItem(
                text: "Number of Verses",
                detailText: "\(numberOfVerses)",
                image: UIImage(systemName: "number.circle"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    self?.showNumberOfVersesSelection()
                }
            },

            // Reciter selection
            CPListItem(
                text: "Reciter",
                detailText: reciterName,
                image: UIImage(systemName: "person.wave.2"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    self?.showReciterSelection()
                }
            },

            // Playback Speed
            CPListItem(
                text: "Playback Speed",
                detailText: String(format: "%.2fx", bookViewModel?.audioManager.playbackSpeed ?? 1.0),
                image: UIImage(systemName: "speedometer"),
                accessoryImage: !StoreManager.shared.isPremiumActive ? UIImage(systemName: "lock.fill") : nil,
                accessoryType: .none
            ).then { item in
                // Only enable speed selection if premium is active
                item.isEnabled = StoreManager.shared.isPremiumActive
                
                item.handler = { [weak self] _, _ in
                    self?.showPlaybackSpeedSelection()
                }
            }
        ])

        // Create template with single section
        let template = CPListTemplate(title: "Memorization Settings", sections: [section])
        return template
    }

    private func getPlayButtonText(isPlaying: Bool, isPreparing: Bool) -> String {
        if isPreparing {
            return "Preparing..."
        } else if isPlaying {
            return "Stop Memorizing"
        } else {
            return "Start Memorizing"
        }
    }

    private func getPlayButtonDetail(isPlaying: Bool, isPreparing: Bool) -> String {
        if isPreparing {
            return "Loading audio..."
        } else if isPlaying {
            return "Playing..."
        } else {
            return "Tap to Start"
        }
    }

    private func getPlayButtonImage(isPlaying: Bool, isPreparing: Bool) -> UIImage? {
        if isPreparing {
            return UIImage(systemName: "hourglass")
        } else if isPlaying {
            return UIImage(systemName: "stop.circle.fill")
        } else {
            return UIImage(systemName: "play.circle.fill")
        }
    }

    private func showSurahSelection() {
        Logger.debug("CarPlay: Showing surah selection")
        guard let viewModel = bookViewModel else {
            Logger.error("CarPlay: No BookViewModel available")
            return
        }
        Logger.debug("CarPlay: BookViewModel instance in showSurahSelection: \(ObjectIdentifier(viewModel))")
        Logger.debug("CarPlay: Number of chapters available: \(viewModel.chapters.count)")

        let items = viewModel.chapters.map { chapter in
            Logger.debug("CarPlay: Creating item for chapter: \(chapter.nameSimple)")
            return CPListItem(
                text: chapter.nameSimple,
                detailText: "Verses: \(chapter.versesCount)",
                image: UIImage(systemName: "book"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    Logger.debug("CarPlay: Chapter selected: \(chapter.nameSimple)")
                    self?.handleChapterSelection(chapter)
                }
            }
        }

        Logger.debug("CarPlay: Created \(items.count) chapter items")
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Surah", sections: [section])

        Logger.debug("CarPlay: Pushing surah selection template")
        isShowingSubTemplate = true
        interfaceController?.pushTemplate(template, animated: true)
        Logger.debug("CarPlay: Surah selection template pushed")
    }

    private func showVerseSelection() {
        Logger.debug("CarPlay: Showing verse selection")
        guard let viewModel = bookViewModel else {
            Logger.error("CarPlay: No BookViewModel available")
            return
        }
        Logger.debug("CarPlay: Current verses count: \(viewModel.currentVerses.count)")

        // Only show verses if we have them
        if viewModel.currentVerses.isEmpty {
            Logger.debug("CarPlay: No verses available")
            return
        }

        let items = viewModel.currentVerses.map { verse in
            Logger.debug("CarPlay: Creating item for verse: \(verse.verseNumber)")
            return CPListItem(
                text: "\(verse.verseNumber). \(verse.textUthmani ?? "")",
                detailText: "",
                image: UIImage(systemName: "text.quote"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    Logger.debug("CarPlay: Verse selected: \(verse.verseNumber)")
                    self?.handleVerseSelection(verse)
                }
            }
        }

        Logger.debug("CarPlay: Created \(items.count) verse items")
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Starting Verse", sections: [section])

        Logger.debug("CarPlay: Pushing verse selection template")
        isShowingSubTemplate = true
        interfaceController?.pushTemplate(template, animated: true)
        Logger.debug("CarPlay: Verse selection template pushed")
    }

    private func showNumberOfVersesSelection() {
        guard let viewModel = bookViewModel else { return }

        // Calculate max verses remaining from current verse
        let currentVerseNumber = Int(viewModel.selectedVerseText.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
        let remainingVerses = maxVerses - currentVerseNumber + 1

        // Create number options like in BookView
        let numbers = [1, 3, 5, 7, remainingVerses]
            .filter { $0 <= remainingVerses }
            .distinct()
            .sorted()

        let items = numbers.map { number in
            CPListItem(
                text: "\(number) Verse\(number > 1 ? "s" : "")",
                detailText: nil,
                image: UIImage(systemName: "\(number).circle"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    self?.handleNumberSelection(number)
                }
            }
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Number of Verses", sections: [section])

        interfaceController?.pushTemplate(template, animated: true)
    }

    private func showReciterSelection() {
        guard let viewModel = bookViewModel else { return }

        let items = viewModel.reciters.map { reciter in
            CPListItem(
                text: reciter.translatedName,
                detailText: reciter.style,
                image: UIImage(systemName: "person.wave.2"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    self?.handleReciterSelection(reciter)
                }
            }
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Reciter", sections: [section])

        interfaceController?.pushTemplate(template, animated: true)
    }

    private func showPlaybackSpeedSelection() {
        guard let audioManager = bookViewModel?.audioManager else { return }

        let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        let items = speeds.map { speed in
            CPListItem(
                text: String(format: "%.2fx", speed),
                detailText: nil,
                image: UIImage(systemName: "speedometer"),
                accessoryImage: speed == audioManager.playbackSpeed ? UIImage(systemName: "checkmark") : nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = true // Always enable speed selection
                item.handler = { [weak self] _, _ in
                    audioManager.setPlaybackSpeed(speed)
                    self?.interfaceController?.popTemplate(animated: true) { _, _ in
                        Task { @MainActor in
                            await self?.updateRootTemplate()
                        }
                    }
                }
            }
        }

        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Playback Speed", sections: [section])

        interfaceController?.pushTemplate(template, animated: true)
    }

    // MARK: - Selection Handlers

    private func handleChapterSelection(_ chapter: ChapterEntity) {
        Logger.debug("CarPlay: Starting chapter selection for: \(chapter.nameSimple)")
        Logger.debug("CarPlay: Current BookViewModel instance: \(ObjectIdentifier(bookViewModel!))")
        Logger.debug("CarPlay: Current UI state before update - detailText: \(bookViewModel?.selectedChapter?.nameSimple ?? "Not Selected")")

        Task {
            do {
                Logger.debug("CarPlay: Setting selectedChapter")
                bookViewModel?.selectedChapter = chapter
                Logger.debug("CarPlay: Selected chapter is now: \(bookViewModel?.selectedChapter?.nameSimple ?? "None")")

                Logger.debug("CarPlay: Loading Quran data")
                try await bookViewModel?.loadQuranData()
                Logger.debug("CarPlay: Quran data loaded")

                numberOfVerses = 3
                Logger.debug("CarPlay: Set numberOfVerses to 3")

                if let firstVerse = bookViewModel?.currentVerses.first,
                   let text = firstVerse.textUthmani {
                    bookViewModel?.selectedVerseText = "\(firstVerse.verseNumber). \(text)"
                    bookViewModel?.currentVerseNumber = Int(firstVerse.verseNumber)
                    Logger.debug("CarPlay: Updated currentVerse to: \(bookViewModel?.selectedVerseText ?? "")")
                }

                await MainActor.run {
                    Logger.debug("CarPlay: Updating UI")
                    updateNowPlayingInfo()
                    Logger.debug("CarPlay: Updated now playing info")

                    // Only try to pop if we're showing a sub-template
                    if isShowingSubTemplate {
                        Logger.debug("CarPlay: Popping sub-template")
                        interfaceController?.popTemplate(animated: true) { _, _ in
                            Logger.debug("CarPlay: Sub-template popped")
                            self.isShowingSubTemplate = false
                            // Update root template after pop completes
                            self.setupRootTemplate()
                        }
                    } else {
                        Logger.debug("CarPlay: No sub-template to pop, updating root directly")
                        setupRootTemplate()
                    }
                }
                Logger.debug("CarPlay: Chapter selection complete")
            } catch {
                Logger.error("CarPlay: Error during chapter selection: \(error)")
            }
        }
    }

    private func handleVerseSelection(_ verse: VerseEntity) {
        Logger.debug("CarPlay: Starting verse selection for verse \(verse.verseNumber)")

        if let text = verse.textUthmani {
            let verseText = "\(verse.verseNumber). \(text)"

            // Update shared state
            bookViewModel?.selectedVerseText = verseText
            bookViewModel?.currentVerseNumber = Int(verse.verseNumber)
            Logger.debug("CarPlay: Set current verse to: \(bookViewModel?.selectedVerseText ?? "")")

            // Update number of verses if needed
            let maxVerses = Int(bookViewModel?.selectedChapter?.versesCount ?? 1)
            let remainingVerses = maxVerses - Int(verse.verseNumber) + 1
            if numberOfVerses > remainingVerses {
                numberOfVerses = remainingVerses
                Logger.debug("CarPlay: Adjusted number of verses to: \(numberOfVerses)")
            }

            // Create new template with updated state
            let newMemorizeTemplate = createMemorizeTemplate()
            Logger.debug("CarPlay: Created new templates with updated verse")

            // Pop and update root template
            if isShowingSubTemplate {
                Logger.debug("CarPlay: Popping verse selection template")
                interfaceController?.popTemplate(animated: true) { _, _ in
                    Logger.debug("CarPlay: Template popped, updating root")
                    self.isShowingSubTemplate = false
                    self.rootTemplate = newMemorizeTemplate
                    self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                    Logger.debug("CarPlay: Root template updated with new verse")
                }
            } else {
                Logger.debug("CarPlay: Directly updating root template")
                rootTemplate = newMemorizeTemplate
                interfaceController?.setRootTemplate(rootTemplate!, animated: true)
            }

            // Update now playing info
            updateNowPlayingInfo()
        }
    }

    private func handleNumberSelection(_ number: Int) {
        Logger.debug("CarPlay: Starting number selection: \(number)")

        // Update both local and shared state
        numberOfVerses = number
        Logger.debug("CarPlay: Set number of verses to: \(number)")

        if let viewModel = bookViewModel {
            // Update shared state
            viewModel.numberOfVerses = number
            Logger.debug("CarPlay: Updated shared number of verses to: \(number)")

            // Create new template with updated state
            let newMemorizeTemplate = createMemorizeTemplate()
            Logger.debug("CarPlay: Created new templates with updated number")

            // Pop and update root template
            if isShowingSubTemplate {
                Logger.debug("CarPlay: Popping number selection template")
                interfaceController?.popTemplate(animated: true) { _, _ in
                    Logger.debug("CarPlay: Template popped, updating root")
                    self.isShowingSubTemplate = false
                    self.rootTemplate = newMemorizeTemplate
                    self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                    Logger.debug("CarPlay: Root template updated with new number")
                }
            } else {
                Logger.debug("CarPlay: Directly updating root template")
                rootTemplate = newMemorizeTemplate
                interfaceController?.setRootTemplate(rootTemplate!, animated: true)
            }
        }
    }

    private func handleReciterSelection(_ reciter: ReciterEntity) {
        bookViewModel?.selectedReciter = reciter

        Task {
            do {
                try await bookViewModel?.loadQuranData()

                // Pop back and refresh
                await MainActor.run {
                    interfaceController?.popTemplate(animated: true)
                    setupRootTemplate()
                }
            } catch {
                Logger.error("Error loading reciter data: \(error)")
            }
        }
    }

    private func observePlaybackState() {
        // Existing playback observation
        bookViewModel?.$isPlaying
            .sink { [weak self] isPlaying in
                Logger.debug("CarPlay: Playback state changed - isPlaying: \(isPlaying)")
                self?.updatePlaybackState(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        // Enhanced chapter observation
        bookViewModel?.$selectedChapter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chapter in
                Logger.debug("CarPlay: Chapter changed in BookViewModel to: \(chapter?.nameSimple ?? "None")")
                if let viewModel = self?.bookViewModel {
                    Logger.debug("CarPlay: BookViewModel instance: \(ObjectIdentifier(viewModel))")
                }

                // Force a complete UI refresh when chapter changes
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    Logger.debug("CarPlay: Refreshing UI for chapter change")

                    // Create new template with updated state
                    let newMemorizeTemplate = self.createMemorizeTemplate()
                    Logger.debug("CarPlay: Created new template with chapter: \(chapter?.nameSimple ?? "None")")

                    // Just update the root template directly without popping
                    self.rootTemplate = newMemorizeTemplate
                    self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                    Logger.debug("CarPlay: Set new root template for chapter change")
                }
            }
            .store(in: &cancellables)

        // Add observation for verses to update UI when they change
        bookViewModel?.$currentVerses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Logger.debug("CarPlay: Verses updated, refreshing UI")
                Task { @MainActor in
                    self?.setupRootTemplate()
                }
            }
            .store(in: &cancellables)

        // Simplify verse number observation to only update UI
        bookViewModel?.$currentVerseNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verseNumber in
                Logger.debug("CarPlay: Verse number changed to: \(verseNumber)")
                Task { @MainActor in
                    self?.setupRootTemplate()
                    self?.updateNowPlayingInfo()
                }
            }
            .store(in: &cancellables)

        // Keep selected verse text observation for UI updates
        bookViewModel?.$selectedVerseText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verseText in
                Logger.debug("CarPlay: Selected verse text changed to: \(verseText)")
                guard let self = self else { return }

                Logger.debug("CarPlay: Updated current verse to: \(verseText)")

                // Create new template with updated state
                let newMemorizeTemplate = self.createMemorizeTemplate()
                Logger.debug("CarPlay: Created new templates with updated verse")

                // Update root template
                self.rootTemplate = newMemorizeTemplate
                self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                Logger.debug("CarPlay: Root template updated with new verse")

                // Update now playing info
                self.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Add number of verses observation
        bookViewModel?.$numberOfVerses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] number in
                Logger.debug("CarPlay: Number of verses changed to: \(number)")
                guard let self = self else { return }

                self.numberOfVerses = number
                Logger.debug("CarPlay: Updated local number of verses to: \(number)")

                // Create new template with updated state
                let newMemorizeTemplate = self.createMemorizeTemplate()
                Logger.debug("CarPlay: Created new templates with updated number")

                // Update root template
                self.rootTemplate = newMemorizeTemplate
                self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                Logger.debug("CarPlay: Root template updated with new number")
            }
            .store(in: &cancellables)

        // Add observation for audio preparation state
        bookViewModel?.$isPreparingAudio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPreparing in
                Logger.debug("CarPlay: Audio preparation state changed: \(isPreparing)")
                Task { @MainActor in
                    await self?.updateRootTemplate()
                }
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
        Logger.debug("CarPlay: Updating now playing info")
        guard let viewModel = bookViewModel else {
            Logger.error("CarPlay: ERROR - No BookViewModel available for now playing info")
            return
        }

        // Update the now playing info using MPNowPlayingInfoCenter
        var nowPlayingInfo = [String: Any]()

        let title = viewModel.selectedChapter?.nameSimple ?? "Unknown Surah"
        let artist = viewModel.selectedReciter?.translatedName ?? "Unknown Reciter"
        let albumTitle = "Verse \(viewModel.currentVerseNumber)"

        Logger.debug("CarPlay: Setting now playing info - Title: \(title), Artist: \(artist), Album: \(albumTitle)")

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        Logger.debug("CarPlay: Now playing info updated")
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            Logger.debug("CarPlay: Play command received")
            Task {
                await self?.startPlayback()
            }
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            Logger.debug("CarPlay: Pause command received")
            Task {
                await self?.stopPlayback()
            }
            return .success
        }

        // Next Track command (for steering wheel next)
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            Logger.debug("CarPlay: Next track command received")
            Task { @MainActor in
                self?.handleNextChunk()
            }
            return .success
        }

        // Previous Track command (for steering wheel previous)
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            Logger.debug("CarPlay: Previous track command received")
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
            do {
                try await playWithLooping(
                    verse: viewModel.selectedVerseText,
                    numberOfVerses: numberOfVerses
                )
            } catch {
                Logger.error("CarPlay: Error during playback: \(error)")
            }

            // Update UI after attempt
            await updateRootTemplate()
        }
    }

    private func stopPlayback() async {
        Logger.debug("CarPlay: Stopping playback and loop")
        isLooping = false
        currentPlaybackTask?.cancel()
        currentPlaybackTask = nil

        if let viewModel = bookViewModel {
            do {
                try await viewModel.togglePlayback(
                    selectedVerse: viewModel.selectedVerseText,
                    numberOfVerses: numberOfVerses
                )

                // Update UI
                await updateRootTemplate()
                Logger.debug("CarPlay: Updated UI to show start button")
            } catch {
                Logger.error("CarPlay: Error stopping playback: \(error)")
            }
        }
    }

    private func playWithLooping(verse: String, numberOfVerses: Int) async throws {
        // Force stop any current playback
        if let viewModel = bookViewModel, viewModel.isPlaying {
            try await viewModel.togglePlayback(
                selectedVerse: verse,
                numberOfVerses: numberOfVerses
            )
        }

        isLooping = true

        while isLooping {
            if Task.isCancelled { return }

            // Start new playback
            if let viewModel = bookViewModel {
                try await viewModel.togglePlayback(
                    selectedVerse: verse,
                    numberOfVerses: numberOfVerses
                )

                // Wait for playback to complete
                while viewModel.isPlaying && !Task.isCancelled {
                    try await Task.sleep(for: .milliseconds(100))
                }

                if Task.isCancelled { return }

                // Half second pause between loops
                try await Task.sleep(for: .milliseconds(500))
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

        let currentVerseNumber = Int(viewModel.selectedVerseText.split(separator: ".").first ?? "1") ?? 1
        let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)

        // Calculate next verse number
        let nextVerseNumber = min(currentVerseNumber + numberOfVerses, maxVerses)

        if let nextVerse = viewModel.currentVerses.first(where: { $0.verseNumber == nextVerseNumber }),
           let text = nextVerse.textUthmani {
            // Update the shared state instead of local state
            viewModel.selectedVerseText = "\(nextVerseNumber). \(text)"
            viewModel.currentVerseNumber = nextVerseNumber

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

        let currentVerseNumber = Int(viewModel.selectedVerseText.split(separator: ".").first ?? "1") ?? 1

        // Calculate previous verse number
        let previousVerseNumber = max(currentVerseNumber - numberOfVerses, 1)

        if let previousVerse = viewModel.currentVerses.first(where: { $0.verseNumber == previousVerseNumber }),
           let text = previousVerse.textUthmani {
            // Update the shared state instead of local state
            viewModel.selectedVerseText = "\(previousVerseNumber). \(text)"
            viewModel.currentVerseNumber = previousVerseNumber

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
        Logger.error("CarPlay failed to load: \(error.localizedDescription)")
    }

    private func updateRootTemplate() async {
        rootTemplate = createMemorizeTemplate()
        try? await interfaceController?.setRootTemplate(rootTemplate!, animated: true)
    }
}

// Helper extension for array uniqueness
extension Sequence where Element: Hashable {
    func distinct() -> [Element] {
        Array(Set(self))
    }
}

extension CPListItem {
    func then(_ configure: (CPListItem) -> Void) -> CPListItem {
        configure(self)
        return self
    }
}
