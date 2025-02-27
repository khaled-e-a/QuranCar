//
//  BookViewModel.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import Foundation
import Combine

class BookViewModel: ObservableObject {
    @Published var selectedChapter: ChapterEntity?
    @Published var currentVerses: [VerseEntity] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var chapters: [ChapterEntity] = []

    private let apiService: QuranAPIService
    private let dataStore: QuranDataStore

    init(apiService: QuranAPIService = QuranAPIService(
        clientId: TokenManager.shared.getClientId() ?? "NOT_FOUND",
        authToken: TokenManager.shared.getAccessToken() ?? "NOT_FOUND"
    )) {
        self.apiService = apiService
        self.dataStore = QuranDataStore.shared
        print("BookViewModel: Initialized with apiService: \(apiService) and dataStore: \(dataStore)")
        print("BookViewModel: Client ID: \(TokenManager.shared.getClientId() ?? "NOT_FOUND")")
        print("BookViewModel: Access Token: \(TokenManager.shared.getAccessToken() ?? "NOT_FOUND")")
        print("BookViewModel: called from \(Thread.callStackSymbols[1])")
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

    func loadVersesForSelectedChapter() async {
        guard let chapterId = selectedChapter?.id else { return }
        await loadVersesByChapter(Int(chapterId))
    }
}
