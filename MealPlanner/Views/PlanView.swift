//
//  PlanView.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//

import SwiftUI
import Foundation

struct PlanView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedDay = Date().startOfDay

    var body: some View {
        ZStack {
            Color.clear
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Meal Plan")
                            .font(AppFont.header(38, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        
                        Text("Plan your week ahead")
                            .font(AppFont.body(15, weight: .regular))
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    
                    // Week Strip
                    WeekStrip(selected: $selectedDay)
                        .padding(.horizontal, Spacing.lg)
                    
                    // Plan Editor
                    PlanEditor(day: selectedDay)
                        .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

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
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = day
                        }
                    } label: {
                        VStack(spacing: Spacing.xs) {
                            Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                .font(AppFont.caption(11, weight: .semibold))
                                .foregroundStyle(isSel ? .white : .textSecondary)
                            
                            Text(day.formatted(.dateTime.day()))
                                .font(AppFont.mono(20, weight: .bold))
                                .foregroundStyle(isSel ? .white : .textPrimary)
                            
                            if isToday {
                                Circle()
                                    .fill(isSel ? .white : Color.brandPrimary)
                                    .frame(width: 4, height: 4)
                            }
                        }
                        .frame(width: 60, height: 72)
                        .background {
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(isSel ? Color.brandPrimary : Color.white)
                                .shadow(color: .black.opacity(isSel ? 0.15 : 0.04), radius: isSel ? 12 : 4, x: 0, y: isSel ? 6 : 2)
                        }
                    }
                    .buttonStyle(BouncyButtonStyle())
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
        VStack(spacing: Spacing.md) {
            // Date header
            HStack {
                Text(day.formatted(date: .complete, time: .omitted))
                    .font(AppFont.body(16, weight: .semibold))
                    .foregroundStyle(.textPrimary)
                
                Spacer()
                
                if totalCalories > 0 {
                    HStack(spacing: 4) {
                        Text("\(totalCalories)")
                            .font(AppFont.mono(18, weight: .bold))
                        Text("kcal")
                            .font(AppFont.caption(12, weight: .medium))
                    }
                    .foregroundStyle(.textSecondary)
                }
            }
            .padding(.horizontal, Spacing.md)
            
            // Course pickers
            VStack(spacing: Spacing.sm) {
                CourseRow(course: .breakfast, selection: $plan.breakfast, options: store.suggestedMeals(for: .breakfast))
                CourseRow(course: .lunch, selection: $plan.lunch, options: store.suggestedMeals(for: .lunch))
                CourseRow(course: .dinner, selection: $plan.dinner, options: store.suggestedMeals(for: .dinner))
                CourseRow(course: .snack, selection: $plan.snack, options: store.suggestedMeals(for: .snack))
            }
            
            // Save button
            Button {
                Task { await store.savePlan(plan) }
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save Plan")
                        .font(AppFont.body(16, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(Color.brandPrimary)
                        .shadow(color: .brandPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                }
            }
            .buttonStyle(BouncyButtonStyle())
            .padding(.top, Spacing.sm)
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .onAppear { plan = store.plan(for: day) }
        .onChange(of: day) { _, new in plan = store.plan(for: new) }
    }
    
    private var totalCalories: Int {
        let ids = [plan.breakfast, plan.lunch, plan.dinner, plan.snack].compactMap { $0 }
        return store.meals.filter { ids.contains($0.id) }.reduce(0) { $0 + $1.calories }
    }

    private struct CourseRow: View {
        @EnvironmentObject private var store: AppStore
        let course: MealCourse
        @Binding var selection: UUID?
        var options: [Meal]
        
        @State private var isExpanded = false

        var body: some View {
            VStack(spacing: 0) {
                // Course header
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(course.emoji)
                            .font(.system(size: 24))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.rawValue.capitalized)
                                .font(AppFont.body(16, weight: .semibold))
                                .foregroundStyle(.textPrimary)
                            
                            if let mealID = selection, let meal = store.meals.first(where: { $0.id == mealID }) {
                                Text("\(meal.name) • \(meal.calories) kcal")
                                    .font(AppFont.caption(13, weight: .medium))
                                    .foregroundStyle(.textSecondary)
                            } else {
                                Text("Not planned")
                                    .font(AppFont.caption(13, weight: .medium))
                                    .foregroundStyle(.textTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.textSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                    .padding(Spacing.md)
                    .background {
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .fill(course.accentColor.opacity(0.1))
                    }
                }
                .buttonStyle(BouncyButtonStyle())
                
                // Meal options
                if isExpanded {
                    VStack(spacing: 0) {
                        ForEach(options.prefix(5)) { meal in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selection = meal.id
                                    isExpanded = false
                                }
                            } label: {
                                HStack {
                                    Text(meal.name)
                                        .font(AppFont.body(15, weight: .medium))
                                        .foregroundStyle(.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text("\(meal.calories)")
                                        .font(AppFont.mono(14, weight: .semibold))
                                        .foregroundStyle(course.accentColor)
                                    
                                    Text("kcal")
                                        .font(AppFont.caption(11, weight: .medium))
                                        .foregroundStyle(.textSecondary)
                                }
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(BouncyButtonStyle())
                            
                            if meal.id != options.prefix(5).last?.id {
                                Divider()
                                    .padding(.leading, Spacing.md)
                            }
                        }
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selection = nil
                                isExpanded = false
                            }
                        } label: {
                            HStack {
                                Text("Clear selection")
                                    .font(AppFont.body(15, weight: .medium))
                                    .foregroundStyle(.brandPrimary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                    .background {
                        RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                            .fill(.white)
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}
