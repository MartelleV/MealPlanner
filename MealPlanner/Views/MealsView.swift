//
//  MealsView.swift
//  MealPlanner
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
        ScrollView(showsIndicators: false) {
            VStack(spacing: Spacing.xl) {
                // Header
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Meals")
                            .font(AppFont.display(42))
                            .foregroundStyle(.textPrimary)
                        
                        Text("\(store.meals.count) recipes")
                            .font(AppFont.body(15))
                            .foregroundStyle(.textTertiary)
                    }
                    
                    Spacer()
                    
                    Button {
                        MealFormSheet.present(meal: nil, store: store)
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(.brandPrimary))
                    }
                    .buttonStyle(BouncyButtonStyle())
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.top, Spacing.xl)
                
                // Search
                HStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(.textTertiary)
                    
                    TextField("Search meals", text: $search)
                        .font(AppFont.body(16))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.md)
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(.white)
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                                .stroke(Color.border, lineWidth: 0.5)
                        }
                }
                .padding(.horizontal, Spacing.lg)
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        FilterPill(title: "All", isSelected: selectedCourse == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCourse = nil }
                        }
                        
                        ForEach(MealCourse.allCases) { course in
                            FilterPill(
                                title: course.rawValue.capitalized,
                                isSelected: selectedCourse == course,
                                color: course.accentColor
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedCourse = course }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                
                // Grid
                if filtered.isEmpty {
                    EmptyMealsView()
                        .padding(.top, Spacing.xxxl)
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
            .padding(.bottom, 120)
        }
    }
}

// MARK: - Filter Pill

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var color: Color = .brandPrimary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.body(14, weight: .medium))
                .foregroundStyle(isSelected ? .white : .textSecondary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background {
                    Capsule()
                        .fill(isSelected ? color : Color.white)
                        .overlay {
                            if !isSelected {
                                Capsule().stroke(Color.border, lineWidth: 0.5)
                            }
                        }
                }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Meal Card

struct MealCard: View {
    @EnvironmentObject private var store: AppStore
    let meal: Meal
    
    var body: some View {
        Button {
            MealFormSheet.present(meal: meal, store: store)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topTrailing) {
                    MealThumbnail(meal: meal)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous))
                    
                    if meal.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.brandSecondary)
                            .padding(6)
                            .background(Circle().fill(.white))
                            .padding(Spacing.sm)
                    }
                }
                
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(meal.name)
                        .font(AppFont.body(15, weight: .semibold))
                        .foregroundStyle(.textPrimary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("\(meal.calories)")
                            .font(AppFont.mono(18, weight: .semibold))
                            .foregroundStyle(meal.course.accentColor)
                        
                        Text("kcal")
                            .font(AppFont.caption(12))
                            .foregroundStyle(.textTertiary)
                    }
                }
                .padding(Spacing.md)
            }
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .stroke(Color.border, lineWidth: 0.5)
                    }
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
                Label(meal.isFavorite ? "Unfavorite" : "Favorite", systemImage: meal.isFavorite ? "heart.slash" : "heart")
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
        GeometryReader { geo in
            if let file = meal.imageFilename,
               let image = UIImage(contentsOfFile: store.imageURL(for: file).path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            } else {
                ZStack {
                    meal.course.accentColor.opacity(0.1)
                    Text(meal.course.emoji)
                        .font(.system(size: 32))
                }
            }
        }
    }
}

// MARK: - Empty State

struct EmptyMealsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.textTertiary)
            
            VStack(spacing: Spacing.xs) {
                Text("No meals yet")
                    .font(AppFont.header(20))
                    .foregroundStyle(.textPrimary)
                
                Text("Tap + to add your first")
                    .font(AppFont.body(15))
                    .foregroundStyle(.textTertiary)
            }
        }
    }
}
