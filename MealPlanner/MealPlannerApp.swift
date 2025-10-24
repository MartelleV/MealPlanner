//
//  MealPlannerApp.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 11/9/25.
//

import SwiftUI
import CoreData
import os

@main
struct MealPlannerApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(store)
                .task {
                    await store.bootstrap()
                }
        }
    }
}

/// Global app logger subsystem
let AppLog = Logger(subsystem: "com.example.mealplanner", category: "app")
