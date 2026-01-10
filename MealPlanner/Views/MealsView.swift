//
//  MealsView.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//

import SwiftUI
import PhotosUI

struct MealsView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""
    @State private var selectedCourse: MealCourse? = nil
    
    var filtered: [Meal] {
        var result = store.meals
        
        if !search.isEmpty {
            result = result.filter { $0.name.localizedCaseInsensitiveContains(search) }
        }
        
        if let course = selectedCourse {
            result = result.filter { $0.course == course }
        }
        
        return result
    }
    
    var body: some View {
        ZStack {
            Color.clear
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text("Your Meals")
                                    .font(AppFont.header(38, weight: .bold))
                                    .foregroundStyle(.textPrimary)
                                
                                Text("\(store.meals.count) recipes")
                                    .font(AppFont.mono(14, weight: .medium))
                                    .foregroundStyle(.textSecondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                MealFormSheet.present(meal: nil, store: store)
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 56, height: 56)
                                    .background {
                                        Circle()
                                            .fill(Color.brandPrimary)
                                            .shadow(color: .brandPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
                                    }
                            }
                            .buttonStyle(BouncyButtonStyle())
                        }
                        
                        // Search bar
                        HStack(spacing: Spacing.md) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.textSecondary)
                            
                            TextField("Search meals...", text: $search)
                                .font(AppFont.body(16, weight: .medium))
                                .foregroundStyle(.textPrimary)
                        }
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background {
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Course filter
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.sm) {
                                FilterChip(title: "All", isSelected: selectedCourse == nil) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCourse = nil
                                    }
                                }
                                
                                ForEach(MealCourse.allCases) { course in
                                    FilterChip(
                                        title: "\(course.emoji) \(course.rawValue.capitalized)",
                                        isSelected: selectedCourse == course,
                                        color: course.accentColor
                                    ) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCourse = course
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    
                    // Meals grid
                    if filtered.isEmpty {
                        EmptyMealsView()
                            .padding(.top, Spacing.xxl)
                    } else {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: Spacing.md),
                            GridItem(.flexible(), spacing: Spacing.md)
                        ], spacing: Spacing.md) {
                            ForEach(filtered) { meal in
                                MealCard(meal: meal)
                            }
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .brandPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.caption(14, weight: .semibold))
                .foregroundStyle(isSelected ? .white : color)
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.sm)
                .background {
                    Capsule()
                        .fill(isSelected ? color : color.opacity(0.12))
                }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Meal Card
struct MealCard: View {
    @EnvironmentObject private var store: AppStore
    let meal: Meal
    @State private var showingActions = false
    
    var body: some View {
        Button {
            MealFormSheet.present(meal: meal, store: store)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    MealThumbnail(meal: meal)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                    
                    if meal.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(Spacing.sm)
                            .background {
                                Circle()
                                    .fill(.ultraThinMaterial)
                            }
                            .padding(Spacing.sm)
                    }
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(meal.name)
                        .font(AppFont.body(16, weight: .bold))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text("\(meal.calories)")
                            .font(AppFont.mono(20, weight: .bold))
                            .foregroundStyle(meal.course.accentColor)
                        
                        Text("kcal")
                            .font(AppFont.caption(11, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                    
                    Text(meal.course.rawValue.capitalized)
                        .font(AppFont.caption(12, weight: .medium))
                        .foregroundStyle(.textSecondary)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(meal.course.accentColor.opacity(0.15))
                        }
                }
                .padding(Spacing.md)
            }
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
            }
        }
        .buttonStyle(BouncyButtonStyle())
        .contextMenu {
            Button {
                Task {
                    var updated = meal
                    updated.isFavorite.toggle()
                    await store.updateMeal(updated)
                }
            } label: {
                Label(meal.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                      systemImage: meal.isFavorite ? "heart.slash" : "heart")
            }
            
            Button(role: .destructive) {
                Task {
                    if let idx = store.meals.firstIndex(of: meal) {
                        await store.deleteMeal(at: IndexSet(integer: idx))
                    }
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Meal Thumbnail
struct MealThumbnail: View {
    @EnvironmentObject private var store: AppStore
    let meal: Meal
    
    var body: some View {
        GeometryReader { geometry in
            if let file = meal.imageFilename,
               let image = UIImage(contentsOfFile: store.imageURL(for: file).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            } else {
                ZStack {
                    meal.course.accentColor.opacity(0.2)
                    
                    VStack(spacing: Spacing.sm) {
                        Text(meal.course.emoji)
                            .font(.system(size: 40))
                        
                        Image(systemName: "photo")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(meal.course.accentColor)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
    }
}

// MARK: - Empty State
struct EmptyMealsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            ZStack {
                Circle()
                    .fill(Color.brandPrimary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(.brandPrimary)
            }
            
            VStack(spacing: Spacing.xs) {
                Text("No meals yet")
                    .font(AppFont.header(24, weight: .bold))
                    .foregroundStyle(.textPrimary)
                
                Text("Tap the + button to add your first meal")
                    .font(AppFont.body(15, weight: .regular))
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xl)
    }
}
