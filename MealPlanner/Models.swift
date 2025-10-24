//
//  MealCourse.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import Foundation

// MARK: - Domain Models

enum MealCourse: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snack
    var id: String { rawValue }
}

enum Flavor: String, Codable, CaseIterable, Identifiable {
    case sweet, salty, sour, bitter, umami, spicy, savory
    var id: String { rawValue }
}

enum Allergy: String, Codable, CaseIterable, Identifiable {
    case nuts, dairy, gluten, eggs, shellfish, soy, fish, sesame
    var id: String { rawValue }
}

struct Meal: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var calories: Int
    var course: MealCourse
    var flavors: [Flavor]
    var allergies: [Allergy]
    var bestCookedWith: String
    var bestServedAs: String
    /// Local filename in Documents/images (jpeg). Optional if using SF Symbol fallback.
    var imageFilename: String?
    var isFavorite: Bool = false
}

struct UserProfile: Codable {
    enum Sex: String, Codable, CaseIterable, Identifiable { case male, female; var id: String { rawValue } }
    enum Activity: String, Codable, CaseIterable, Identifiable {
        case sedentary, light, moderate, active, veryActive
        var id: String { rawValue }
        var multiplier: Double {
            switch self {
            case .sedentary:   return 1.2
            case .light:       return 1.375
            case .moderate:    return 1.55
            case .active:      return 1.725
            case .veryActive:  return 1.9
            }
        }
    }

    var age: Int = 25
    var sex: Sex = .male
    var heightCm: Double = 170
    var weightKg: Double = 65
    var activity: Activity = .moderate

    var preferredFlavors: Set<Flavor> = []
    var dislikedMealIDs: Set<UUID> = []
    var allergies: Set<Allergy> = []

    // Mifflin–St Jeor BMR (kcal/day)
    var bmr: Double {
        // Men: 10W + 6.25H - 5A + 5
        // Women: 10W + 6.25H - 5A - 161
        let w = weightKg, h = heightCm, a = Double(age)
        switch sex {
        case .male:   return 10*w + 6.25*h - 5*a + 5
        case .female: return 10*w + 6.25*h - 5*a - 161
        }
    }

    var tdee: Double { bmr * activity.multiplier }
}

struct DayPlan: Identifiable, Codable, Equatable {
    var id = UUID()
    var date: Date // normalized to day (midnight)
    var breakfast: UUID?
    var lunch: UUID?
    var dinner: UUID?
    var snack: UUID?
}
