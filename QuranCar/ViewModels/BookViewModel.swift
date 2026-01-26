//
//  BookViewModel.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import Foundation
import Combine

class BookViewModel: ObservableObject {
    static let shared = BookViewModel()

    private let defaults = UserDefaults.standard

    private enum UserDefaultsKeys {
        static let selectedChapterId = "selectedChapterId"
        static let selectedVerseNumber = "selectedVerseNumber"
        static let numberOfVerses = "numberOfVerses"
        static let selectedReciterId = "selectedReciterId"
    }

    @Published var selectedChapter: ChapterEntity? {
        willSet {
            Logger.debug("BookViewModel: About to set selectedChapter to: \(newValue?.nameSimple ?? "None")")
            Logger.debug("BookViewModel: Called from: \(Thread.callStackSymbols[1])")
        }
        didSet {
            Logger.debug("BookViewModel: selectedChapter changed to: \(selectedChapter?.nameSimple ?? "None")")
            // Add persistence
            if let chapterId = selectedChapter?.id {
                defaults.set(chapterId, forKey: UserDefaultsKeys.selectedChapterId)
            }
        }
    }
    @Published var currentVerses: [VerseEntity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var chapters: [ChapterEntity] = []
    @Published var reciters: [ReciterEntity] = []
    @Published var selectedReciter: ReciterEntity? {
        didSet {
            if let reciterId = selectedReciter?.id {
                defaults.set(reciterId, forKey: UserDefaultsKeys.selectedReciterId)
            }
        }
    }
    @Published var currentAudioFiles: [AudioFileEntity] = []
    @Published var isPlaying = false
    @Published var currentVerseNumber: Int = 1 {
        didSet {
            defaults.set(currentVerseNumber, forKey: UserDefaultsKeys.selectedVerseNumber)
        }
    }
    @Published var selectedVerseText: String = "1. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"
    @Published var numberOfVerses: Int = 3 {
        didSet {
            defaults.set(numberOfVerses, forKey: UserDefaultsKeys.numberOfVerses)
        }
    }
    @Published var isPreparingAudio = false  // Add new state for audio preparation

    private let apiService: QuranAPIService
    private let dataStore: QuranDataStore
    private let audioManager = AudioManager()
    private var cancellables = Set<AnyCancellable>()

    init(apiService: QuranAPIService = QuranAPIService(
        clientId: TokenManager.shared.getClientId() ?? "NOT_FOUND",
        authToken: TokenManager.shared.getAccessToken() ?? "NOT_FOUND"
    )) {
        self.apiService = apiService
        self.dataStore = QuranDataStore.shared

        // Add notification observer
        NotificationCenter.default
            .publisher(for: .audioPlaybackCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Logger.debug("BookViewModel: Received playback completed notification")
                self?.isPlaying = false
            }
            .store(in: &cancellables)

        Logger.debug("BookViewModel: Initialized with apiService: \(apiService) and dataStore: \(dataStore)")
        Logger.debug("BookViewModel: Client ID: \(TokenManager.shared.getClientId() ?? "NOT_FOUND")")
        Logger.debug("BookViewModel: Access Token: \(TokenManager.shared.getAccessToken() ?? "NOT_FOUND")")
        Logger.debug("BookViewModel: called from \(Thread.callStackSymbols[1])")

        // Load initial data
        Task {
            await loadQuranData()
        }

        restoreSavedState()
    }

    var audioLoadingProgress: Double {
        audioManager.downloadProgress
    }

    var currentVerseIndex: Int {
        audioManager.currentVerseIndex
    }

    func loadQuranData() async {
        Logger.debug("BookViewModel: Starting loadQuranData")
        Logger.debug("BookViewModel: Current chapter: \(selectedChapter?.nameSimple ?? "None")")

        // Prevent multiple simultaneous loading operations
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Ensure we have a valid token
            await QuranAuthManager.shared.refreshTokenIfNeeded()

            // Load data sequentially
            await loadChapters()
            if let chapter = selectedChapter {
                await loadVersesByChapter(Int(chapter.id))
            }
            await loadReciters()
            if selectedReciter != nil {
                await loadAudioFiles()
            }
        } catch {
            // Suppress socket idle errors from being shown to users
            if !error.isSocketIdleError() {
                self.error = error
            }
        }

        isLoading = false

        Logger.debug("BookViewModel: Finished loadQuranData")
        Logger.debug("BookViewModel: Verses loaded: \(currentVerses.count)")
    }

    func loadChapters() async {
        isLoading = true
        error = nil

        do {
            // Try to fetch from local storage first
            Logger.debug("BookViewModel: Fetching chapters from local storage")
            let localChapters = try await dataStore.fetchChapters()

            if localChapters.isEmpty {
                // If no local data, fetch from API
                let apiChapters = try await apiService.fetchChapters()
                Logger.debug("BookViewModel: Fetched \(apiChapters.count) chapters from API")
                try await dataStore.saveChapters(apiChapters)
                self.chapters = try await dataStore.fetchChapters()
                Logger.debug("BookViewModel: Fetched \(self.chapters.count) chapters from local storage")
            } else {
                self.chapters = localChapters
                Logger.debug("BookViewModel: Fetched \(self.chapters.count) chapters from local storage")
            }

            // Set first chapter (Al-Fatiha) as default if none selected
            if selectedChapter == nil {
                selectedChapter = chapters.first { Int(truncating: $0.id as NSNumber) == 1 } ?? chapters.first
                // Load verses for the default chapter
                if let selectedChapter = selectedChapter {
                    await loadVersesByChapter(Int(selectedChapter.id))
                }
            }
        } catch {
            // Suppress socket idle errors from being shown to users
            if !error.isSocketIdleError() {
                self.error = error
            }
        }

        isLoading = false
    }

    func loadVersesByChapter(_ chapterId: Int) async {
        isLoading = true
        error = nil

        do {
            // Try to fetch from local storage first
            let localVerses = try await dataStore.fetchVersesByChapter(chapterId)

            if localVerses.isEmpty {
                // If no local data, fetch both verse data and Uthmani text from API
                async let apiVerses = apiService.fetchVersesByChapter(chapterId)
                async let uthmaniVerses = apiService.fetchUthmaniVerses(chapterNumber: chapterId)

                let (verses, uthmaniTexts) = try await (apiVerses, uthmaniVerses)

                // Create a dictionary for quick lookup of Uthmani text by verse key
                let uthmaniDict = Dictionary(uniqueKeysWithValues:
                    uthmaniTexts.map { ($0.verseKey, $0.textUthmani) }
                )

                // Update verses with Uthmani text
                let versesWithUthmani = verses.map { verse -> Verse in
                    // Create a new Verse instance with the updated Uthmani text
                    if let uthmaniText = uthmaniDict[verse.verseKey] {
                        return Verse(
                            id: verse.id,
                            verseNumber: verse.verseNumber,
                            verseKey: verse.verseKey,
                            hizbNumber: verse.hizbNumber,
                            rubElHizbNumber: verse.rubElHizbNumber,
                            rukuNumber: verse.rukuNumber,
                            manzilNumber: verse.manzilNumber,
                            sajdahNumber: verse.sajdahNumber,
                            pageNumber: verse.pageNumber,
                            juzNumber: verse.juzNumber,
                            textUthmani: uthmaniText
                        )
                    }
                    return verse
                }

                try await dataStore.saveVerses(versesWithUthmani, forChapter: chapterId)
                self.currentVerses = try await dataStore.fetchVersesByChapter(chapterId)
            } else {
                // Use local data
                self.currentVerses = localVerses
            }
        } catch {
            // Suppress socket idle errors from being shown to users
            if !error.isSocketIdleError() {
                self.error = error
            }
        }

        isLoading = false
    }


    func loadReciters() async {
        isLoading = true
        error = nil

        do {
            // Try to fetch from local storage first
            let localReciters = try await dataStore.fetchReciters()

            if localReciters.isEmpty {
                // If no local data, fetch from API
                let apiReciters = try await apiService.fetchReciters()
                try await dataStore.saveReciters(apiReciters)
                // Fetch again from local storage to get managed objects
                self.reciters = try await dataStore.fetchReciters()
                // Set first reciter as default if none selected
                if selectedReciter == nil {
                    selectedReciter = reciters.first
                }
            } else {
                // Use local data
                self.reciters = localReciters
                if selectedReciter == nil {
                    selectedReciter = reciters.first
                }
            }
        } catch {
            // Suppress socket idle errors from being shown to users
            if !error.isSocketIdleError() {
                self.error = error
            }
        }

        isLoading = false
    }

    func loadAudioFiles() async {
        guard let chapterId = selectedChapter?.id,
              let reciterId = selectedReciter?.id else { return }

        isLoading = true
        error = nil

        do {
            // Try to fetch from local storage first
            let localAudioFiles = try await dataStore.fetchAudioFiles(
                chapterId: Int(chapterId),
                reciterId: Int(reciterId)
            )

            if localAudioFiles.isEmpty {
                // If no local data, fetch from API
                let apiAudioFiles = try await apiService.fetchVerseAudio(
                    recitationId: Int(reciterId),
                    chapterNumber: Int(chapterId)
                )
                try await dataStore.saveAudioFiles(
                    apiAudioFiles,
                    chapterId: Int(chapterId),
                    reciterId: Int(reciterId)
                )
                // Fetch again from local storage to get managed objects
                self.currentAudioFiles = try await dataStore.fetchAudioFiles(
                    chapterId: Int(chapterId),
                    reciterId: Int(reciterId)
                )
            } else {
                // Use local data
                self.currentAudioFiles = localAudioFiles
            }
        } catch {
            // Suppress socket idle errors from being shown to users
            if !error.isSocketIdleError() {
                self.error = error
            }
        }

        isLoading = false
    }

    func togglePlayback(selectedVerse: String, numberOfVerses: Int) async throws {
        Logger.debug("BookViewModel: Toggle playback called")
        Logger.debug("BookViewModel: Selected verse: \(selectedVerse)")
        Logger.debug("BookViewModel: Number of verses: \(numberOfVerses)")

        if audioManager.isPlaying {
            Logger.debug("BookViewModel: Stopping playback")
            audioManager.stopPlayback()
            isPlaying = false
        } else {
            // Set preparing state at start
            isPreparingAudio = true

            // Use defer to ensure we clear the preparing state
            defer {
                isPreparingAudio = false
                Logger.debug("BookViewModel: Audio preparation completed")
            }

            do {
                let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
                let endVerseNumber = currentVerseNumber + numberOfVerses - 1
                Logger.debug("BookViewModel: Playing verses from \(currentVerseNumber) to \(endVerseNumber)")

                // Prepare audio if needed
                Logger.debug("BookViewModel: Preparing audio files")
                try await audioManager.prepareAudio(
                    audioFiles: currentAudioFiles,
                    startVerse: currentVerseNumber,
                    endVerse: endVerseNumber
                )

                Logger.debug("BookViewModel: Starting playback")
                audioManager.startPlayback()
                isPlaying = true
            } catch {
                Logger.debug("BookViewModel: Error during playback: \(error)")
                throw error
            }
        }
    }

    public func handlePreviousVerse() async {
        guard let currentVerse = currentVerses.first(where: { $0.verseNumber == currentVerseNumber }),
              currentVerseNumber > 1 else { return }

        let previousVerseNumber = currentVerseNumber - 1
        if let previousVerse = currentVerses.first(where: { $0.verseNumber == previousVerseNumber }) {
            currentVerseNumber = previousVerseNumber
            // Stop current playback if any
            if isPlaying {
                audioManager.stopPlayback()
                isPlaying = false
            }

            // Start new playback
            if let text = previousVerse.textUthmani {
                do {
                    try await togglePlayback(
                        selectedVerse: "\(previousVerseNumber). \(text)",
                        numberOfVerses: 1
                    )
                } catch {
                    // Suppress socket idle errors from being shown to users
                    if !error.isSocketIdleError() {
                        self.error = error
                    }
                    Logger.debug("Error during previous verse playback: \(error)")
                }
            }
        }
    }

    public func handleNextVerse() async {
        guard let chapter = selectedChapter,
              currentVerseNumber < chapter.versesCount else { return }

        let nextVerseNumber = currentVerseNumber + 1
        if let nextVerse = currentVerses.first(where: { $0.verseNumber == nextVerseNumber }) {
            currentVerseNumber = nextVerseNumber
            // Stop current playback if any
            if isPlaying {
                audioManager.stopPlayback()
                isPlaying = false
            }

            // Start new playback
            if let text = nextVerse.textUthmani {
                do {
                    try await togglePlayback(
                        selectedVerse: "\(nextVerseNumber). \(text)",
                        numberOfVerses: 1
                    )
                } catch {
                    // Suppress socket idle errors from being shown to users
                    if !error.isSocketIdleError() {
                        self.error = error
                    }
                    Logger.debug("Error during next verse playback: \(error)")
                }
            }
        }
    }

    private func restoreSavedState() {
        // Restore number of verses first as it's simple
        numberOfVerses = defaults.integer(forKey: UserDefaultsKeys.numberOfVerses)
        if numberOfVerses == 0 { // If no saved value
            numberOfVerses = 3 // Default value
        }

        // Restore current verse number
        currentVerseNumber = defaults.integer(forKey: UserDefaultsKeys.selectedVerseNumber)
        if currentVerseNumber == 0 { // If no saved value
            currentVerseNumber = 1 // Default value
        }

        // Load saved chapter and reciter IDs
        let savedChapterId = defaults.integer(forKey: UserDefaultsKeys.selectedChapterId)
        let savedReciterId = defaults.integer(forKey: UserDefaultsKeys.selectedReciterId)

        // We need to load the data first before we can restore the selections
        Task {
            do {
                // Load chapters and reciters
                try await loadChaptersAndReciters()

                // Restore chapter selection
                if savedChapterId > 0 {
                    selectedChapter = chapters.first(where: { $0.id == savedChapterId })
                }

                // Restore reciter selection
                if savedReciterId > 0 {
                    selectedReciter = reciters.first(where: { $0.id == savedReciterId })
                }

                // Load Quran data after restoring selections
                await loadQuranData()

                // Update verse text after data is loaded
                if let verse = currentVerses.first(where: { $0.verseNumber == currentVerseNumber }),
                   let text = verse.textUthmani {
                    selectedVerseText = "\(verse.verseNumber). \(text)"
                }
            } catch {
                Logger.error("Error restoring saved state: \(error)")
                // Suppress socket idle errors from being shown to users
                if !error.isSocketIdleError() {
                    self.error = error
                }
            }
        }
    }

    private func loadChaptersAndReciters() async throws {
        // Load chapters
        await loadChapters()

        // Load reciters
        await loadReciters()

        // Check for any errors that occurred during loading
        if let error = self.error {
            throw error
        }
    }
}
