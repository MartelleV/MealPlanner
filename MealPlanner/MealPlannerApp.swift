//
//  MealPlannerApp.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 11/9/25.
//

import SwiftUI

@main
struct MealPlannerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
