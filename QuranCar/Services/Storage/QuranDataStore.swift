//
//  QuranDataStore.swift
//  QuranCar
//
//  Created by Khaled Ahmed on 2025-02-04.
//

import CoreData
import Foundation

class QuranDataStore {
    static let shared = QuranDataStore()

    private let container: NSPersistentContainer

    private init() {
        container = NSPersistentContainer(name: "QuranModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("Error loading Core Data: \(error)")
            }
        }
    }

    // MARK: - Chapters

    func saveChapters(_ chapters: [Chapter]) async throws {
        let context = container.newBackgroundContext()

        try await context.perform {
            // Clear existing chapters
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = ChapterEntity.fetchRequest()
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)

            // Save new chapters
            for chapter in chapters {
                let entity = ChapterEntity(context: context)
                entity.id = Int32(chapter.id)
                entity.nameSimple = chapter.nameSimple
                entity.nameArabic = chapter.nameArabic
                entity.versesCount = Int32(chapter.versesCount)
                entity.revelationPlace = chapter.revelationPlace
            }

            try context.save()
        }
    }

    func fetchChapters() async throws -> [ChapterEntity] {
        let context = container.viewContext
        let request = ChapterEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]

        return try context.fetch(request)
    }

    func fetchVersesByChapter(_ chapterId: Int) async throws -> [VerseEntity] {
        let context = container.viewContext
        let request = VerseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "chapter.id == %d", chapterId)
        request.sortDescriptors = [NSSortDescriptor(key: "verseNumber", ascending: true)]

        return try context.fetch(request)
    }

    func saveVerses(_ verses: [Verse], forChapter chapterId: Int) async throws {
        let context = container.viewContext

        // Fetch the chapter
        let chapterRequest = ChapterEntity.fetchRequest()
        chapterRequest.predicate = NSPredicate(format: "id == %d", chapterId)
        guard let chapter = try context.fetch(chapterRequest).first else {
            throw NSError(domain: "QuranDataStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Chapter not found"])
        }

        // Delete existing verses for this chapter
        let deleteRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VerseEntity")
        deleteRequest.predicate = NSPredicate(format: "chapter.id == %d", chapterId)
        let deleteResult = NSBatchDeleteRequest(fetchRequest: deleteRequest)
        try context.execute(deleteResult)

        // Create new verse entities
        for verse in verses {
            let verseEntity = VerseEntity(context: context)
            verseEntity.id = Int32(verse.id)
            verseEntity.verseNumber = Int32(verse.verseNumber)
            verseEntity.verseKey = verse.verseKey
            verseEntity.hizbNumber = Int32(verse.hizbNumber)
            verseEntity.rubElHizbNumber = Int32(verse.rubElHizbNumber)
            verseEntity.rukuNumber = Int32(verse.rukuNumber)
            verseEntity.manzilNumber = Int32(verse.manzilNumber)
            if let sajdahNumber = verse.sajdahNumber {
                verseEntity.sajdahNumber = Int32(sajdahNumber)
            }
            verseEntity.pageNumber = Int32(verse.pageNumber)
            verseEntity.juzNumber = Int32(verse.juzNumber)
            verseEntity.textUthmani = verse.textUthmani
            verseEntity.chapter = chapter
        }

        try context.save()
    }
}