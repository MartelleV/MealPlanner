//
//  ProfileView.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            Form {
                Section("Physical attributes") {
                    Picker("Sex", selection: $store.profile.sex) {
                        ForEach(UserProfile.Sex.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                    Stepper("Age: \(store.profile.age)", value: $store.profile.age, in: 12...100)
                    HStack {
                        Text("Height")
                        Spacer()
                        Text("\(Int(store.profile.heightCm)) cm").foregroundStyle(.secondary)
                    }
                    Slider(value: $store.profile.heightCm, in: 120...220, step: 1)

                    HStack {
                        Text("Weight")
                        Spacer()
                        Text("\(String(format: "%.1f", store.profile.weightKg)) kg").foregroundStyle(.secondary)
                    }
                    Slider(value: $store.profile.weightKg, in: 30...180, step: 0.5)

                    Picker("Activity", selection: $store.profile.activity) {
                        ForEach(UserProfile.Activity.allCases) { Text($0.rawValue.capitalized).tag($0) }
                    }
                }

                Section("Diet preferences") {
                    ChoiceChips(
                        title: "Preferred flavors",
                        options: Array(Flavor.allCases),
                        selection: $store.profile.preferredFlavors,
                        labelText: { $0.rawValue.capitalized }
                    )
                    ChoiceChips(
                        title: "Allergies",
                        options: Array(Allergy.allCases),
                        selection: $store.profile.allergies,
                        labelText: { $0.rawValue.capitalized }
                    )
                }

                Section("Daily needs") {
                    LabeledContent("BMR") { Text("\(Int(store.profile.bmr)) kcal/day") }
                    LabeledContent("TDEE") { Text("\(Int(store.profile.tdee)) kcal/day") }
                    Text("We use the Mifflin–St Jeor equations and an activity multiplier to estimate daily energy needs.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await store.saveProfile() }
                    } label: { Text("Save") }
                }
            }
        }
    }
}

private struct ChoiceChips<T: Identifiable & Hashable>: View {
    let title: String
    let options: [T]
    @Binding var selection: Set<T>
    var labelText: (T) -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            FlowRows(spacing: 8) {
                ForEach(options, id: \.id) { option in
                    let isOn = selection.contains(option)
                    Button {
                        if isOn { selection.remove(option) } else { selection.insert(option) }
                    } label: {
                        Text(labelText(option))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background {
                                // type-erased ShapeStyle so Color/Material can be mixed in a ternary
                                Capsule().fill(isOn
                                               ? AnyShapeStyle(Color.accentColor.opacity(0.2))
                                               : AnyShapeStyle(.thinMaterial))
                            }
                    }
                }
            }
        }
    }
}

