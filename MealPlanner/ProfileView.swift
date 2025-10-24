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
                    ToggleGroup(title: "Preferred flavors", all: Flavor.allCases, selection: $store.profile.preferredFlavors)
                    ToggleGroup(title: "Allergies", all: Allergy.allCases, selection: $store.profile.allergies)
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

private struct ToggleGroup<T: CaseIterable & Identifiable & Hashable, LabelView: View>: View where T.AllCases: RandomAccessCollection {
    let title: String
    let all: T.AllCases
    @Binding var selection: Set<T>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
            WrapLayout {
                ForEach(all, id: \.self) { t in
                    let on = selection.contains(t)
                    Button {
                        if on { selection.remove(t) } else { selection.insert(t) }
                    } label: {
                        Text(t.id.description.capitalized)
                            .padding(.horizontal, 12).padding(.vertical, 8)
                            .background(on ? Color.accentColor.opacity(0.2) : .thinMaterial, in: Capsule())
                    }
                }
            }
        }
    }
}
