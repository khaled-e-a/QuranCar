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
}