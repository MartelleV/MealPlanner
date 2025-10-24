//
//  Persistence.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 11/9/25.
//

import CoreData
import os

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<3 {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()
        }
        do { try viewContext.save() } catch {
            let nsError = error as NSError
            Logger(subsystem: "com.example.mealplanner", category: "coredata")
                .error("Preview CoreData save failed: \(nsError.localizedDescription, privacy: .public)")
        }
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "MealPlanner")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                Logger(subsystem: "com.example.mealplanner", category: "coredata")
                    .fault("CoreData load failed: \(error.localizedDescription, privacy: .public) \(error.userInfo, privacy: .private)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
