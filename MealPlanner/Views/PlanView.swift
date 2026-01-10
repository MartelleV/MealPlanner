//
//  PlanView.swift
//  MealPlanner
//

import SwiftUI

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay = Date().startOfDay

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Plan")
                        .font(AppFont.display(42))
                        .foregroundStyle(.textPrimary)
                    
                    Text("Organize your week")
                        .font(AppFont.body(15))
                        .foregroundStyle(.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
                
                // Week Strip
                WeekStrip(selected: $selectedDay)
                
                // Plan Editor
                PlanEditor(day: selectedDay)
                    .padding(.horizontal, Spacing.lg)
            }
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Week Strip

private struct WeekStrip: View {
    @Binding var selected: Date
    
    var body: some View {
        let days = (-3...3).map { Date().addingDays($0).startOfDay }
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(days, id: \.self) { day in
                    let isSel = Calendar.current.isDate(day, inSameDayAs: selected)
                    let isToday = Calendar.current.isDateInToday(day)
                    
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selected = day }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                                .font(AppFont.caption(11, weight: .medium))
                                .foregroundStyle(isSel ? .white.opacity(0.8) : .textTertiary)
                                .tracking(0.5)
                            
                            Text(day.formatted(.dateTime.day()))
                                .font(AppFont.mono(20, weight: .semibold))
                                .foregroundStyle(isSel ? .white : .textPrimary)
                            
                            Circle()
                                .fill(isToday ? (isSel ? .white : .brandPrimary) : .clear)
                                .frame(width: 5, height: 5)
                        }
                        .frame(width: 54, height: 76)
                        .background {
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(isSel ? Color.brandPrimary : .white)
                                .overlay {
                                    if !isSel {
                                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                            .stroke(Color.border, lineWidth: 0.5)
                                    }
                                }
                        }
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

// MARK: - Plan Editor

private struct PlanEditor: View {
    @EnvironmentObject private var store: AppStore
    let day: Date
    @State private var plan: DayPlan = DayPlan(date: Date().startOfDay)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(day.formatted(date: .abbreviated, time: .omitted))
                    .font(AppFont.body(14, weight: .medium))
                    .foregroundStyle(.textSecondary)
                
                Spacer()
                
                if totalCalories > 0 {
                    HStack(spacing: 4) {
                        Text("\(totalCalories)")
                            .font(AppFont.mono(16, weight: .semibold))
                            .foregroundStyle(.brandPrimary)
                        Text("kcal")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.textTertiary)
                    }
                }
            }
            .padding(Spacing.md)
            
            ThinDivider()
            
            // Courses
            VStack(spacing: 0) {
                CourseRow(course: .breakfast, selection: $plan.breakfast, options: store.suggestedMeals(for: .breakfast))
                ThinDivider().padding(.leading, Spacing.lg)
                CourseRow(course: .lunch, selection: $plan.lunch, options: store.suggestedMeals(for: .lunch))
                ThinDivider().padding(.leading, Spacing.lg)
                CourseRow(course: .dinner, selection: $plan.dinner, options: store.suggestedMeals(for: .dinner))
                ThinDivider().padding(.leading, Spacing.lg)
                CourseRow(course: .snack, selection: $plan.snack, options: store.suggestedMeals(for: .snack))
            }
            
            ThinDivider()
            
            // Save
            Button {
                Task { await store.savePlan(plan) }
            } label: {
                Text("Save Plan")
                    .font(AppFont.body(15, weight: .semibold))
                    .foregroundStyle(.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                        .stroke(Color.border, lineWidth: 0.5)
                }
        }
        .onAppear { plan = store.plan(for: day) }
        .onChange(of: day) { _, new in plan = store.plan(for: new) }
    }
    
    private var totalCalories: Int {
        let ids = [plan.breakfast, plan.lunch, plan.dinner, plan.snack].compactMap { $0 }
        return store.meals.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.calories }
    }
}

// MARK: - Course Row

private struct CourseRow: View {
    @EnvironmentObject private var store: AppStore
    let course: MealCourse
    @Binding var selection: UUID?
    var options: [Meal]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: Spacing.md) {
                    Text(course.emoji)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(course.rawValue.capitalized)
                            .font(AppFont.body(16, weight: .medium))
                            .foregroundStyle(.textPrimary)
                        
                        if let mealID = selection, let meal = store.meals.first(where: { $0.id == mealID }) {
                            Text(meal.name)
                                .font(AppFont.body(13))
                                .foregroundStyle(.textSecondary)
                        } else {
                            Text("Not set")
                                .font(AppFont.body(13))
                                .foregroundStyle(.textTertiary)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
            }
            .buttonStyle(BouncyButtonStyle())
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(options.prefix(4)) { meal in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = meal.id; isExpanded = false }
                        } label: {
                            HStack {
                                Text(meal.name)
                                    .font(AppFont.body(14))
                                    .foregroundStyle(.textPrimary)
                                Spacer()
                                Text("\(meal.calories)")
                                    .font(AppFont.mono(13))
                                    .foregroundStyle(.textTertiary)
                            }
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(selection == meal.id ? Color.surfaceBase : .clear)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    
                    if selection != nil {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = nil; isExpanded = false }
                        } label: {
                            Text("Clear")
                                .font(AppFont.body(14, weight: .medium))
                                .foregroundStyle(.brandSecondary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
                .background(Color.surfaceBase.opacity(0.5))
            }
        }
    }
}
