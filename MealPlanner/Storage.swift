//
//  Storage.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import Foundation
import os

actor Storage {
    private let logger = Logger(subsystem: "com.example.mealplanner", category: "storage")

    private var mealsURL: URL { URL.documentsDirectory
        .appendingPathComponent("data", conformingTo: .directory)
        .appendingPathComponent("meals.json", conformingTo: .json)
    }

    private var profileURL: URL { URL.documentsDirectory
        .appendingPathComponent("data", conformingTo: .directory)
        .appendingPathComponent("profile.json", conformingTo: .json)
    }

    private var plansURL: URL { URL.documentsDirectory
        .appendingPathComponent("data", conformingTo: .directory)
        .appendingPathComponent("plans.json", conformingTo: .json)
    }

    private var imagesDir: URL { URL.documentsDirectory
        .appendingPathComponent("images", conformingTo: .directory)
    }

    init() {
        do {
            try FileManager.default.createDirectory(at: mealsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
        } catch {
            logger.error("Create folders failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Public IO

    func loadMeals() async -> [Meal] {
        if let meals: [Meal] = await load([Meal].self, from: mealsURL) {
            return meals
        } else {
            // First run: seed and persist to avoid repeated logs on next launch.
            let seeded = seedMeals()
            await save(seeded, to: mealsURL)
            return seeded
        }
    }

    func saveMeals(_ meals: [Meal]) async {
        await save(meals, to: mealsURL)
    }

    func loadProfile() async -> UserProfile {
        if let profile: UserProfile = await load(UserProfile.self, from: profileURL) {
            return profile
        } else {
            let profile = UserProfile()
            await save(profile, to: profileURL)
            return profile
        }
    }

    func saveProfile(_ profile: UserProfile) async {
        await save(profile, to: profileURL)
    }

    func loadPlans() async -> [DayPlan] {
        if let plans: [DayPlan] = await load([DayPlan].self, from: plansURL) {
            return plans
        } else {
            let plans: [DayPlan] = []
            await save(plans, to: plansURL)
            return plans
        }
    }

    func savePlans(_ plans: [DayPlan]) async {
        await save(plans, to: plansURL)
    }

    func saveImage(_ data: Data) async -> String? {
        let name = UUID().uuidString + ".jpg"
        let url = imagesDir.appendingPathComponent(name)
        do {
            try data.write(to: url, options: [.atomic])
            return name
        } catch {
            logger.error("Save image failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func imageURL(for filename: String) -> URL {
        imagesDir.appendingPathComponent(filename)
    }

    // MARK: - Helpers

    private func load<T: Decodable>(_ type: T.Type, from url: URL) async -> T? {
        // Treat "file not found" as a benign first-run case.
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
            // Only log real decoding/IO problems now.
            logger.warning("Load \(url.lastPathComponent, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    private func save<T: Encodable>(_ value: T, to url: URL) async {
        do {
            let enc = JSONEncoder()
            enc.outputFormatting = [.prettyPrinted, .sortedKeys]
            enc.dateEncodingStrategy = .iso8601
            let data = try enc.encode(value)
            try data.write(to: url, options: [.atomic])
        } catch {
            logger.error("Save \(url.lastPathComponent, privacy: .public) failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func seedMeals() -> [Meal] {
        [
            Meal(name: "Oatmeal & Berries", calories: 320, course: .breakfast,
                 flavors: [.sweet], allergies: [.gluten], bestCookedWith: "Oats, almond milk",
                 bestServedAs: "Warm bowl", imageFilename: nil, isFavorite: true),
            Meal(name: "Grilled Chicken Salad", calories: 450, course: .lunch,
                 flavors: [.savory, .umami], allergies: [], bestCookedWith: "Olive oil, lemon",
                 bestServedAs: "Fresh", imageFilename: nil),
            Meal(name: "Salmon & Quinoa", calories: 560, course: .dinner,
                 flavors: [.umami, .savory], allergies: [.fish, .sesame], bestCookedWith: "Pan-sear",
                 bestServedAs: "Plate", imageFilename: nil),
            Meal(name: "Greek Yogurt & Nuts", calories: 280, course: .snack,
                 flavors: [.sweet], allergies: [.dairy, .nuts], bestCookedWith: "Honey",
                 bestServedAs: "Cup", imageFilename: nil)
        ]
    }
}

// MARK: - URL conveniences (no recursion)
extension URL {
    /// App's Documents directory (resolves via FileManager to avoid shadowing/recursion).
    static var documentsDirectory: URL {
        // This works on all supported iOS versions and avoids calling itself.
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

extension Storage {
    /// Build the image URL without touching actor-isolated state.
    nonisolated static func imageURL(for filename: String) -> URL {
        URL.documentsDirectory
            .appendingPathComponent("images", conformingTo: .directory)
            .appendingPathComponent(filename)
    }
}
