import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay = Date().startOfDay

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                WeekStrip(selected: $selectedDay)
                PlanEditor(day: selectedDay)
            }
            .padding(.horizontal)
            .navigationTitle("Plan")
        }
    }
}

private struct WeekStrip: View {
    @Binding var selected: Date
    var body: some View {
        let days = (-3...3).map { Date().addingDays($0).startOfDay }
        HStack(spacing: 8) {
            ForEach(days, id: \.self) { day in
                let isSel = Calendar.current.isDate(day, inSameDayAs: selected)
                Button {
                    selected = day
                } label: {
                    VStack {
                        Text(day.formatted(.dateTime.weekday(.abbreviated)))
                            .font(.caption2).foregroundStyle(.secondary)
                        Text(day.formatted(.dateTime.day()))
                            .font(.headline)
                    }
                    .frame(width: 48, height: 56)
                    .background(isSel ? Color.accentColor.opacity(0.2) : .thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}

private struct PlanEditor: View {
    @EnvironmentObject private var store: AppStore
    let day: Date

    @State private var plan: DayPlan = DayPlan(date: Date().startOfDay)

    var body: some View {
        Form {
            CourseRow(title: "Breakfast", selection: $plan.breakfast, options: store.suggestedMeals(for: .breakfast))
            CourseRow(title: "Lunch",     selection: $plan.lunch,     options: store.suggestedMeals(for: .lunch))
            CourseRow(title: "Dinner",    selection: $plan.dinner,    options: store.suggestedMeals(for: .dinner))
            CourseRow(title: "Snack",     selection: $plan.snack,     options: store.suggestedMeals(for: .snack))
        }
        .scrollContentBackground(.hidden)
        .background(.clear)
        .onAppear { plan = store.plan(for: day) }
        .onChange(of: day) { _, new in plan = store.plan(for: new) }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button {
                    Task { await store.savePlan(plan) }
                } label: {
                    Label("Save Plan", systemImage: "checkmark.circle.fill")
                }
            }
        }
    }

    private struct CourseRow: View {
        @EnvironmentObject private var store: AppStore
        var title: String
        @Binding var selection: UUID?
        var options: [Meal]

        var body: some View {
            Picker(title, selection: $selection) {
                Text("None").tag(UUID?.none)
                ForEach(options) { m in
                    Text(m.name + " • \(m.calories)kcal").tag(UUID?.some(m.id))
                }
            }
        }
    }
}
