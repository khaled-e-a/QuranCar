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
    @Published var isLoading = false
    @Published var error: Error?

    private let apiService: QuranAPIService
    private let dataStore: QuranDataStore

    init(apiService: QuranAPIService = QuranAPIService(
        clientId: "YOUR_CLIENT_ID",
        authToken: "YOUR_AUTH_TOKEN"
    )) {
        self.apiService = apiService
        self.dataStore = QuranDataStore.shared
        print("BookViewModel: Initialized with apiService: \(apiService) and dataStore: \(dataStore)")
    }

    func selectFirstAyah() async {
        isLoading = true
        error = nil
        print("BookViewModel: selectFirstAyah called")
        do {
            // Try to fetch from local storage first
            let localChapters = try await dataStore.fetchChapters()
            print("BookViewModel: Local chapters fetched: \(localChapters.count)")
            if localChapters.isEmpty {
                // If no local data, fetch from API
                let chapters = try await apiService.fetchChapters()
                print("BookViewModel: Chapters fetched from API: \(chapters.count)")
                try await dataStore.saveChapters(chapters)
                // Fetch again from local storage to get managed objects
                let savedChapters = try await dataStore.fetchChapters()
                print("BookViewModel: Saved chapters fetched: \(savedChapters.count)")
                // Update UI
                await MainActor.run {
                    print("BookViewModel: Updating UI with saved chapters: \(savedChapters.count)")
                    self.selectedChapter = savedChapters.first
                }
            } else {
                // Use local data
                await MainActor.run {
                    print("BookViewModel: Updating UI with local chapters: \(localChapters.count)")
                    self.selectedChapter = localChapters.first
                }
            }
        } catch {
            await MainActor.run {
                print("BookViewModel: Error: \(error)")
                self.error = error
            }
        }

        await MainActor.run {
            print("BookViewModel: Setting isLoading to false")
            self.isLoading = false
        }
    }
}