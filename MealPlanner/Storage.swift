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
        await load([Meal].self, from: mealsURL) ?? seedMeals()
    }

    func saveMeals(_ meals: [Meal]) async {
        await save(meals, to: mealsURL)
    }

    func loadProfile() async -> UserProfile {
        await load(UserProfile.self, from: profileURL) ?? UserProfile()
    }

    func saveProfile(_ profile: UserProfile) async {
        await save(profile, to: profileURL)
    }

    func loadPlans() async -> [DayPlan] {
        await load([DayPlan].self, from: plansURL) ?? []
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
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(type, from: data)
        } catch {
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

// MARK: - URL conveniences (iOS 16+ added handy static URLs)
extension URL {
    static var documentsDirectory: URL {
        // Prefer URL.documentsDirectory when available; otherwise fall back.
        if #available(iOS 16.0, *) { return .documentsDirectory }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
