import Foundation
import Combine
import os
import CoreData
import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    static let mock: AppStore = {
        let s = AppStore()
        s.meals = [
            Meal(name: "Test Breakfast", calories: 300, course: .breakfast, flavors: [.sweet], allergies: [], bestCookedWith: "Milk", bestServedAs: "Bowl", imageFilename: nil, isFavorite: true)
        ]
        s.profile = UserProfile()
        s.plans = []
        return s
    }()

    // In-memory state
    @Published var meals: [Meal] = []
    @Published var profile = UserProfile()
    @Published var plans: [DayPlan] = []

    // UI
    @Published var banner: Banner?

    private let storage = Storage()
    private let log = Logger(subsystem: "com.example.mealplanner", category: "store")

    func bootstrap() async {
        await loadAll()
    }

    func loadAll() async {
        meals = await storage.loadMeals()
        profile = await storage.loadProfile()
        plans = await storage.loadPlans()
    }

    // MARK: - Meals

    func addMeal(_ meal: Meal) async {
        meals.append(meal)
        await storage.saveMeals(meals)
        showBanner(.success("Meal added"))
        logActivity("Added meal: \(meal.name)")
    }

    func updateMeal(_ meal: Meal) async {
        guard let idx = meals.firstIndex(where: { $0.id == meal.id }) else { return }
        meals[idx] = meal
        await storage.saveMeals(meals)
        showBanner(.success("Meal updated"))
    }

    func deleteMeal(at offsets: IndexSet) async {
        meals.remove(atOffsets: offsets)
        await storage.saveMeals(meals)
        showBanner(.info("Meal deleted"))
    }

    func saveImageData(_ data: Data) async -> String? {
        await storage.saveImage(data)
    }

    func imageURL(for filename: String) -> URL {
        storage.imageURL(for: filename)
    }

    // MARK: - Profile

    func saveProfile() async {
        await storage.saveProfile(profile)
        showBanner(.success("Profile saved"))
    }

    // MARK: - Planning

    func plan(for day: Date) -> DayPlan {
        let key = day.startOfDay
        return plans.first(where: { $0.date == key }) ?? DayPlan(date: key)
    }

    func savePlan(_ plan: DayPlan) async {
        if let idx = plans.firstIndex(where: { $0.id == plan.id }) {
            plans[idx] = plan
        } else if let idx = plans.firstIndex(where: { $0.date == plan.date }) {
            plans[idx] = plan
        } else {
            plans.append(plan)
        }
        await storage.savePlans(plans)
        showBanner(.success("Plan saved"))
        logActivity("Updated plan for \(plan.date.formatted(date: .abbreviated, time: .omitted))")
    }

    // MARK: - Suggestions

    func suggestedMeals(for course: MealCourse) -> [Meal] {
        let dailyCal = profile.tdee
        // naive per-meal target: breakfast 25%, lunch 35%, dinner 35%, snack 5%
        let target: Double = {
            switch course {
            case .breakfast: return dailyCal * 0.25
            case .lunch:     return dailyCal * 0.35
            case .dinner:    return dailyCal * 0.35
            case .snack:     return dailyCal * 0.05
            }
        }()
        let disliked = profile.dislikedMealIDs
        let allergyBlock = profile.allergies

        // Score meals: calorie proximity + preferred flavors + favorites
        return meals
            .filter { $0.course == course }
            .filter { disliked.contains($0.id) == false }
            .filter { allergyBlock.isDisjoint(with: Set($0.allergies)) }
            .sorted { a, b in
                score(a) > score(b)
            }

        func score(_ m: Meal) -> Double {
            let calScore = 1.0 - min(abs(Double(m.calories) - target) / max(target, 1), 1.0)
            let flavorScore = Double(m.flavors.filter { profile.preferredFlavors.contains($0) }.count) / Double(max(m.flavors.count, 1))
            let favBonus = m.isFavorite ? 0.15 : 0.0
            return calScore * 0.6 + flavorScore * 0.25 + favBonus
        }
    }

    // MARK: - Activity log using Core Data's Item (keeps your original schema alive)

    private func logActivity(_ message: String) {
        log.info("\(message, privacy: .public)")
        // Optional: Write a timestamped Item so your base Core Data model remains exercised.
        do {
            let ctx = PersistenceController.shared.container.viewContext
            let item = Item(context: ctx)
            item.timestamp = Date()
            try ctx.save()
        } catch {
            log.error("CoreData activity log save failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Banners

    func showBanner(_ banner: Banner) {
        withAnimation { self.banner = banner }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation { self.banner = nil }
        }
    }
}

// MARK: - Lightweight banner

struct Banner: Equatable {
    enum Kind { case success, info, error }
    var kind: Kind
    var text: String
    static func success(_ t: String) -> Banner { .init(kind: .success, text: t) }
    static func info(_ t: String) -> Banner { .init(kind: .info, text: t) }
    static func error(_ t: String) -> Banner { .init(kind: .error, text: t) }
}
