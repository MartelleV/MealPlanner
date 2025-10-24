//
//  ContentView.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 11/9/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    var body: some View {
        RootView() // Kept for compatibility if previews rely on ContentView
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppStore.mock)
}
