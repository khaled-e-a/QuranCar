import CarPlay
import SwiftUI
import Combine
import MediaPlayer

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
    private var currentVerse: String = ""
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
            print("CarPlay: Using shared BookViewModel instance: \(ObjectIdentifier(viewModel))")
        }

        // Load initial data
        Task {
            try? await bookViewModel?.loadQuranData()

            // Update local state from BookViewModel
            if let firstVerse = bookViewModel?.currentVerses.first,
               let text = firstVerse.textUthmani {
                currentVerse = "\(firstVerse.verseNumber). \(text)"
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
        print("CarPlay: Setting up root template")
        if let viewModel = bookViewModel {
            print("CarPlay: BookViewModel instance: \(ObjectIdentifier(viewModel))")
            print("CarPlay: Selected chapter: \(viewModel.selectedChapter?.nameSimple ?? "None")")
            print("CarPlay: Current verses count: \(viewModel.currentVerses.count)")
        }

        // Use memorize template directly as root
        rootTemplate = createMemorizeTemplate()
        interfaceController?.setRootTemplate(rootTemplate!, animated: true)
        print("CarPlay: Root template updated")
    }

    private func createMemorizeTemplate() -> CPListTemplate {
        // Get current state for display
        let surahDetailText = bookViewModel?.selectedChapter?.nameSimple ?? "Not Selected"
        let verseDetailText = currentVerse.isEmpty ? "Not Selected" : currentVerse
        let isPlaying = bookViewModel?.isPlaying ?? false
        let isPreparingAudio = bookViewModel?.isPreparingAudio ?? false
        let reciterName = bookViewModel?.selectedReciter?.translatedName ?? "Not Selected"

        print("CarPlay: Creating template - Playing: \(isPlaying), Preparing: \(isPreparingAudio)")

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
                            print("CarPlay: Stopping playback")
                            await self?.stopPlayback()
                        } else if !isPreparingAudio {
                            print("CarPlay: Starting playback")
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
                    print("CarPlay: Select Surah item tapped")
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
            }
        ])

        // Create template with single section
        let template = CPListTemplate(title: "Memorize", sections: [section])
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
        print("CarPlay: Showing surah selection")
        guard let viewModel = bookViewModel else {
            print("CarPlay: ERROR - No BookViewModel available")
            return
        }
        print("CarPlay: BookViewModel instance in showSurahSelection: \(ObjectIdentifier(viewModel))")
        print("CarPlay: Number of chapters available: \(viewModel.chapters.count)")

        let items = viewModel.chapters.map { chapter in
            print("CarPlay: Creating item for chapter: \(chapter.nameSimple)")
            return CPListItem(
                text: chapter.nameSimple,
                detailText: "Verses: \(chapter.versesCount)",
                image: UIImage(systemName: "book"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    print("CarPlay: Chapter selected: \(chapter.nameSimple)")
                    self?.handleChapterSelection(chapter)
                }
            }
        }

        print("CarPlay: Created \(items.count) chapter items")
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Surah", sections: [section])

        print("CarPlay: Pushing surah selection template")
        isShowingSubTemplate = true  // Set flag before pushing
        interfaceController?.pushTemplate(template, animated: true)
        print("CarPlay: Surah selection template pushed")
    }

    private func showVerseSelection() {
        print("CarPlay: Showing verse selection")
        guard let viewModel = bookViewModel else {
            print("CarPlay: ERROR - No BookViewModel available")
            return
        }
        print("CarPlay: Current verses count: \(viewModel.currentVerses.count)")

        // Only show verses if we have them
        if viewModel.currentVerses.isEmpty {
            print("CarPlay: No verses available")
            return
        }

        let items = viewModel.currentVerses.map { verse in
            print("CarPlay: Creating item for verse: \(verse.verseNumber)")
            return CPListItem(
                text: "\(verse.verseNumber). \(verse.textUthmani ?? "")",
                detailText: "",
                image: UIImage(systemName: "text.quote"),
                accessoryImage: nil,
                accessoryType: .none
            ).then { item in
                item.isEnabled = isEnabled
                item.handler = { [weak self] _, _ in
                    print("CarPlay: Verse selected: \(verse.verseNumber)")
                    self?.handleVerseSelection(verse)
                }
            }
        }

        print("CarPlay: Created \(items.count) verse items")
        let section = CPListSection(items: items)
        let template = CPListTemplate(title: "Starting Verse", sections: [section])

        print("CarPlay: Pushing verse selection template")
        isShowingSubTemplate = true
        interfaceController?.pushTemplate(template, animated: true)
        print("CarPlay: Verse selection template pushed")
    }

    private func showNumberOfVersesSelection() {
        guard let viewModel = bookViewModel else { return }

        // Calculate max verses remaining from current verse
        let currentVerseNumber = Int(currentVerse.split(separator: ".").first ?? "1") ?? 1
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

    // MARK: - Selection Handlers

    private func handleChapterSelection(_ chapter: ChapterEntity) {
        print("CarPlay: Starting chapter selection for: \(chapter.nameSimple)")
        print("CarPlay: Current BookViewModel instance: \(ObjectIdentifier(bookViewModel!))")
        print("CarPlay: Current UI state before update - detailText: \(bookViewModel?.selectedChapter?.nameSimple ?? "Not Selected")")

        Task {
            do {
                print("CarPlay: Setting selectedChapter")
                bookViewModel?.selectedChapter = chapter
                print("CarPlay: Selected chapter is now: \(bookViewModel?.selectedChapter?.nameSimple ?? "None")")

                print("CarPlay: Loading Quran data")
                try await bookViewModel?.loadQuranData()
                print("CarPlay: Quran data loaded")

                numberOfVerses = 3
                print("CarPlay: Set numberOfVerses to 3")

                if let firstVerse = bookViewModel?.currentVerses.first,
                   let text = firstVerse.textUthmani {
                    currentVerse = "\(firstVerse.verseNumber). \(text)"
                    print("CarPlay: Updated currentVerse to: \(currentVerse)")
                }

                await MainActor.run {
                    print("CarPlay: Updating UI")
                    updateNowPlayingInfo()
                    print("CarPlay: Updated now playing info")

                    // Only try to pop if we're showing a sub-template
                    if isShowingSubTemplate {
                        print("CarPlay: Popping sub-template")
                        interfaceController?.popTemplate(animated: true) { _, _ in
                            print("CarPlay: Sub-template popped")
                            self.isShowingSubTemplate = false
                            // Update root template after pop completes
                            self.setupRootTemplate()
                        }
                    } else {
                        print("CarPlay: No sub-template to pop, updating root directly")
                        setupRootTemplate()
                    }
                }
                print("CarPlay: Chapter selection complete")
            } catch {
                print("CarPlay: Error during chapter selection: \(error)")
            }
        }
    }

    private func handleVerseSelection(_ verse: VerseEntity) {
        print("CarPlay: Starting verse selection for verse \(verse.verseNumber)")

        if let text = verse.textUthmani {
            let verseText = "\(verse.verseNumber). \(text)"

            // Update both local and shared state
            currentVerse = verseText
            print("CarPlay: Set current verse to: \(currentVerse)")

            if let viewModel = bookViewModel {
                // Update shared state
                viewModel.currentVerseNumber = Int(verse.verseNumber)
                viewModel.selectedVerseText = verseText
                print("CarPlay: Updated shared verse text to: \(verseText)")

                // Update number of verses if needed
                let maxVerses = Int(viewModel.selectedChapter?.versesCount ?? 1)
                let remainingVerses = maxVerses - Int(verse.verseNumber) + 1
                if numberOfVerses > remainingVerses {
                    numberOfVerses = remainingVerses
                    print("CarPlay: Adjusted number of verses to: \(numberOfVerses)")
                }

                // Create new template with updated state
                let newMemorizeTemplate = createMemorizeTemplate()
                print("CarPlay: Created new templates with updated verse")

                // Pop and update root template
                if isShowingSubTemplate {
                    print("CarPlay: Popping verse selection template")
                    interfaceController?.popTemplate(animated: true) { _, _ in
                        print("CarPlay: Template popped, updating root")
                        self.isShowingSubTemplate = false
                        self.rootTemplate = newMemorizeTemplate
                        self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                        print("CarPlay: Root template updated with new verse")
                    }
                } else {
                    print("CarPlay: Directly updating root template")
                    rootTemplate = newMemorizeTemplate
                    interfaceController?.setRootTemplate(rootTemplate!, animated: true)
                }

                // Update now playing info
                updateNowPlayingInfo()
            }
        }
    }

    private func handleNumberSelection(_ number: Int) {
        print("CarPlay: Starting number selection: \(number)")

        // Update both local and shared state
        numberOfVerses = number
        print("CarPlay: Set number of verses to: \(number)")

        if let viewModel = bookViewModel {
            // Update shared state
            viewModel.numberOfVerses = number
            print("CarPlay: Updated shared number of verses to: \(number)")

            // Create new template with updated state
            let newMemorizeTemplate = createMemorizeTemplate()
            print("CarPlay: Created new templates with updated number")

            // Pop and update root template
            if isShowingSubTemplate {
                print("CarPlay: Popping number selection template")
                interfaceController?.popTemplate(animated: true) { _, _ in
                    print("CarPlay: Template popped, updating root")
                    self.isShowingSubTemplate = false
                    self.rootTemplate = newMemorizeTemplate
                    self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                    print("CarPlay: Root template updated with new number")
                }
            } else {
                print("CarPlay: Directly updating root template")
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
                print("Error loading reciter data: \(error)")
            }
        }
    }

    private func observePlaybackState() {
        // Existing playback observation
        bookViewModel?.$isPlaying
            .sink { [weak self] isPlaying in
                print("CarPlay: Playback state changed - isPlaying: \(isPlaying)")
                self?.updatePlaybackState(isPlaying: isPlaying)
            }
            .store(in: &cancellables)

        // Enhanced chapter observation
        bookViewModel?.$selectedChapter
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chapter in
                print("CarPlay: Chapter changed in BookViewModel to: \(chapter?.nameSimple ?? "None")")
                if let viewModel = self?.bookViewModel {
                    print("CarPlay: BookViewModel instance: \(ObjectIdentifier(viewModel))")
                }

                // Force a complete UI refresh when chapter changes
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    print("CarPlay: Refreshing UI for chapter change")

                    // Create new template with updated state
                    let newMemorizeTemplate = self.createMemorizeTemplate()
                    print("CarPlay: Created new template with chapter: \(chapter?.nameSimple ?? "None")")

                    // Just update the root template directly without popping
                    self.rootTemplate = newMemorizeTemplate
                    self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                    print("CarPlay: Set new root template for chapter change")
                }
            }
            .store(in: &cancellables)

        // Add observation for verses to update UI when they change
        bookViewModel?.$currentVerses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("CarPlay: Verses updated, refreshing UI")
                Task { @MainActor in
                    self?.setupRootTemplate()
                }
            }
            .store(in: &cancellables)

        // Add verse number observation
        bookViewModel?.$currentVerseNumber
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verseNumber in
                print("CarPlay: Verse number changed to: \(verseNumber)")
                guard let self = self,
                      let viewModel = self.bookViewModel,
                      let verse = viewModel.currentVerses.first(where: { $0.verseNumber == verseNumber }),
                      let text = verse.textUthmani else { return }

                self.currentVerse = "\(verseNumber). \(text)"
                print("CarPlay: Updated current verse to: \(self.currentVerse)")

                Task { @MainActor in
                    self.setupRootTemplate()
                    self.updateNowPlayingInfo()
                }
            }
            .store(in: &cancellables)

        // Update selected verse text observation
        bookViewModel?.$selectedVerseText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] verseText in
                print("CarPlay: Selected verse text changed to: \(verseText)")
                guard let self = self else { return }

                self.currentVerse = verseText
                print("CarPlay: Updated current verse to: \(verseText)")

                // Create new template with updated state
                let newMemorizeTemplate = self.createMemorizeTemplate()
                print("CarPlay: Created new templates with updated verse")

                // Update root template
                self.rootTemplate = newMemorizeTemplate
                self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                print("CarPlay: Root template updated with new verse")

                // Update now playing info
                self.updateNowPlayingInfo()
            }
            .store(in: &cancellables)

        // Add number of verses observation
        bookViewModel?.$numberOfVerses
            .receive(on: DispatchQueue.main)
            .sink { [weak self] number in
                print("CarPlay: Number of verses changed to: \(number)")
                guard let self = self else { return }

                self.numberOfVerses = number
                print("CarPlay: Updated local number of verses to: \(number)")

                // Create new template with updated state
                let newMemorizeTemplate = self.createMemorizeTemplate()
                print("CarPlay: Created new templates with updated number")

                // Update root template
                self.rootTemplate = newMemorizeTemplate
                self.interfaceController?.setRootTemplate(self.rootTemplate!, animated: true)
                print("CarPlay: Root template updated with new number")
            }
            .store(in: &cancellables)

        // Add observation for audio preparation state
        bookViewModel?.$isPreparingAudio
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isPreparing in
                print("CarPlay: Audio preparation state changed: \(isPreparing)")
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
        print("CarPlay: Updating now playing info")
        guard let viewModel = bookViewModel else {
            print("CarPlay: ERROR - No BookViewModel available for now playing info")
            return
        }

        // Update the now playing info using MPNowPlayingInfoCenter
        var nowPlayingInfo = [String: Any]()

        let title = viewModel.selectedChapter?.nameSimple ?? "Unknown Surah"
        let artist = viewModel.selectedReciter?.translatedName ?? "Unknown Reciter"
        let albumTitle = "Verse \(viewModel.currentVerseNumber)"

        print("CarPlay: Setting now playing info - Title: \(title), Artist: \(artist), Album: \(albumTitle)")

        nowPlayingInfo[MPMediaItemPropertyTitle] = title
        nowPlayingInfo[MPMediaItemPropertyArtist] = artist
        nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = albumTitle

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        print("CarPlay: Now playing info updated")
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
            do {
                try await playWithLooping(
                    verse: currentVerse,
                    numberOfVerses: numberOfVerses
                )
            } catch {
                print("CarPlay: Error during playback: \(error)")
            }

            // Update UI after attempt
            await updateRootTemplate()
        }
    }

    private func stopPlayback() async {
        print("CarPlay: Stopping playback and loop")
        isLooping = false
        currentPlaybackTask?.cancel()
        currentPlaybackTask = nil

        if let viewModel = bookViewModel {
            do {
                try await viewModel.togglePlayback(
                    selectedVerse: currentVerse,
                    numberOfVerses: numberOfVerses
                )

                // Update UI
                await updateRootTemplate()
                print("CarPlay: Updated UI to show start button")
            } catch {
                print("CarPlay: Error stopping playback: \(error)")
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
