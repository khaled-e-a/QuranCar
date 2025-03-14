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

    @Published var selectedChapter: ChapterEntity? {
        willSet {
            print("BookViewModel: About to set selectedChapter to: \(newValue?.nameSimple ?? "None")")
            print("BookViewModel: Called from: \(Thread.callStackSymbols[1])")
        }
        didSet {
            print("BookViewModel: selectedChapter changed to: \(selectedChapter?.nameSimple ?? "None")")
        }
    }
    @Published var currentVerses: [VerseEntity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var chapters: [ChapterEntity] = []
    @Published var reciters: [ReciterEntity] = []
    @Published var selectedReciter: ReciterEntity?
    @Published var currentAudioFiles: [AudioFileEntity] = []
    @Published var isPlaying = false
    @Published var currentVerseNumber: Int = 1
    @Published var selectedVerseText: String = "1. بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ"

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
                print("BookViewModel: Received playback completed notification")
                self?.isPlaying = false
            }
            .store(in: &cancellables)

        print("BookViewModel: Initialized with apiService: \(apiService) and dataStore: \(dataStore)")
        print("BookViewModel: Client ID: \(TokenManager.shared.getClientId() ?? "NOT_FOUND")")
        print("BookViewModel: Access Token: \(TokenManager.shared.getAccessToken() ?? "NOT_FOUND")")
        print("BookViewModel: called from \(Thread.callStackSymbols[1])")

        // Load initial data
        Task {
            await loadQuranData()
        }
    }

    var audioLoadingProgress: Double {
        audioManager.downloadProgress
    }

    var currentVerseIndex: Int {
        audioManager.currentVerseIndex
    }

    func loadQuranData() async {
        print("BookViewModel: Starting loadQuranData")
        print("BookViewModel: Current chapter: \(selectedChapter?.nameSimple ?? "None")")

        // Prevent multiple simultaneous loading operations
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Ensure we have a valid token
            await QuranAuthManager.shared.refreshTokenIfNeeded()

            // Load data sequentially to avoid merge conflicts
            await loadChapters()
            // Only load verses after chapters are fully loaded
            if let chapter = selectedChapter {
                await loadVersesByChapter(Int(chapter.id))
            }
            // Load reciters after verses are done
            await loadReciters()
            // Finally load audio files
            if selectedReciter != nil {
                await loadAudioFiles()
            }
        } catch {
            self.error = error
        }

        isLoading = false

        print("BookViewModel: Finished loadQuranData")
        print("BookViewModel: Verses loaded: \(currentVerses.count)")
    }

    func loadChapters() async {
        isLoading = true
        error = nil

        do {
            // Try to fetch from local storage first
            print("BookViewModel: Fetching chapters from local storage")
            let localChapters = try await dataStore.fetchChapters()

            if localChapters.isEmpty {
                // If no local data, fetch from API
                let apiChapters = try await apiService.fetchChapters()
                print("BookViewModel: Fetched \(apiChapters.count) chapters from API")
                try await dataStore.saveChapters(apiChapters)
                // Fetch again from local storage to get managed objects
                self.chapters = try await dataStore.fetchChapters()
                print("BookViewModel: Fetched \(self.chapters.count) chapters from local storage")
            } else {
                // Use local data
                self.chapters = localChapters
                print("BookViewModel: Fetched \(self.chapters.count) chapters from local storage")
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
            self.error = error
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
            self.error = error
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
            self.error = error
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
            self.error = error
        }

        isLoading = false
    }

    func togglePlayback(selectedVerse: String, numberOfVerses: Int) async {
        print("BookViewModel: Toggle playback called")
        print("BookViewModel: Selected verse: \(selectedVerse)")
        print("BookViewModel: Number of verses: \(numberOfVerses)")
        print("BookViewModel: Current audio files available: \(currentAudioFiles.count)")

        if audioManager.isPlaying {
            print("BookViewModel: Stopping playback")
            audioManager.stopPlayback()
            isPlaying = false
        } else {
            do {
                let currentVerseNumber = Int(selectedVerse.split(separator: ".").first ?? "1") ?? 1
                let endVerseNumber = currentVerseNumber + numberOfVerses - 1
                print("BookViewModel: Playing verses from \(currentVerseNumber) to \(endVerseNumber)")

                // Prepare audio if not already prepared
                if !audioManager.isPlaying {
                    print("BookViewModel: Preparing audio files")
                    try await audioManager.prepareAudio(
                        audioFiles: currentAudioFiles,
                        startVerse: currentVerseNumber,
                        endVerse: endVerseNumber
                    )
                }

                print("BookViewModel: Starting playback")
                audioManager.startPlayback()
                isPlaying = true
            } catch {
                print("BookViewModel: Error during playback: \(error)")
                self.error = error
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
                await togglePlayback(
                    selectedVerse: "\(previousVerseNumber). \(text)",
                    numberOfVerses: 1
                )
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
                await togglePlayback(
                    selectedVerse: "\(nextVerseNumber). \(text)",
                    numberOfVerses: 1
                )
            }
        }
    }
}
