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
        ZStack {
            Color.clear
            
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Your Profile")
                            .font(AppFont.header(38, weight: .bold))
                            .foregroundStyle(.textPrimary)
                        
                        Text("Personalize your meal planning")
                            .font(AppFont.body(15, weight: .regular))
                            .foregroundStyle(.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.xl)
                    
                    // Daily Needs Card - Prominent
                    DailyNeedsCard()
                    
                    // Physical Attributes
                    PhysicalAttributesCard()
                    
                    // Diet Preferences
                    DietPreferencesCard()
                    
                    // Save Button
                    Button {
                        Task { await store.saveProfile() }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Save Profile")
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
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.bottom, 100)
            }
        }
    }
}

// MARK: - Daily Needs Card
private struct DailyNeedsCard: View {
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Title
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandPrimary)
                
                Text("Daily Energy Needs")
                    .font(AppFont.body(18, weight: .bold))
                    .foregroundStyle(.textPrimary)
                
                Spacer()
            }
            
            // Metrics
            HStack(spacing: Spacing.xl) {
                // BMR
                VStack(spacing: Spacing.xs) {
                    Text("BMR")
                        .font(AppFont.caption(12, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(store.profile.bmr))")
                            .font(AppFont.mono(32, weight: .bold))
                            .foregroundStyle(Color.brandSecondary)
                        
                        Text("kcal")
                            .font(AppFont.caption(14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(Color.brandSecondary.opacity(0.1))
                }
                
                // TDEE
                VStack(spacing: Spacing.xs) {
                    Text("TDEE")
                        .font(AppFont.caption(12, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Int(store.profile.tdee))")
                            .font(AppFont.mono(32, weight: .bold))
                            .foregroundStyle(Color.brandPrimary)
                        
                        Text("kcal")
                            .font(AppFont.caption(14, weight: .medium))
                            .foregroundStyle(.textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
                .background {
                    RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                        .fill(Color.brandPrimary.opacity(0.1))
                }
            }
            
            // Info text
            Text("Based on Mifflin–St Jeor equation and your activity level")
                .font(AppFont.caption(12, weight: .medium))
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Physical Attributes Card
private struct PhysicalAttributesCard: View {
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Title
            HStack {
                Image(systemName: "figure.arms.open")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandSecondary)
                
                Text("Physical Attributes")
                    .font(AppFont.body(18, weight: .bold))
                    .foregroundStyle(.textPrimary)
                
                Spacer()
            }
            
            // Sex picker
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Sex")
                    .font(AppFont.caption(13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                HStack(spacing: Spacing.sm) {
                    ForEach(UserProfile.Sex.allCases) { sex in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                store.profile.sex = sex
                            }
                        } label: {
                            Text(sex.rawValue.capitalized)
                                .font(AppFont.body(15, weight: .semibold))
                                .foregroundStyle(store.profile.sex == sex ? .white : .textPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Spacing.sm)
                                .background {
                                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                        .fill(store.profile.sex == sex ? Color.brandSecondary : Color.brandSecondary.opacity(0.1))
                                }
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
            
            // Age
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Age")
                        .font(AppFont.caption(13, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                    
                    Spacer()
                    
                    Text("\(store.profile.age) years")
                        .font(AppFont.mono(16, weight: .bold))
                        .foregroundStyle(.textPrimary)
                }
                
                Slider(value: Binding(
                    get: { Double(store.profile.age) },
                    set: { store.profile.age = Int($0) }
                ), in: 12...100, step: 1)
                .tint(Color.brandSecondary)
            }
            
            // Height
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Height")
                        .font(AppFont.caption(13, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                    
                    Spacer()
                    
                    Text("\(Int(store.profile.heightCm)) cm")
                        .font(AppFont.mono(16, weight: .bold))
                        .foregroundStyle(.textPrimary)
                }
                
                Slider(value: $store.profile.heightCm, in: 120...220, step: 1)
                    .tint(Color.brandSecondary)
            }
            
            // Weight
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack {
                    Text("Weight")
                        .font(AppFont.caption(13, weight: .semibold))
                        .foregroundStyle(.textSecondary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", store.profile.weightKg))
                        .font(AppFont.mono(16, weight: .bold))
                        .foregroundStyle(.textPrimary)
                }
                
                Slider(value: $store.profile.weightKg, in: 30...180, step: 0.5)
                    .tint(Color.brandSecondary)
            }
            
            // Activity
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Activity Level")
                    .font(AppFont.caption(13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                VStack(spacing: Spacing.xs) {
                    ForEach(UserProfile.Activity.allCases) { activity in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                store.profile.activity = activity
                            }
                        } label: {
                            HStack {
                                Text(activity.rawValue.capitalized)
                                    .font(AppFont.body(15, weight: .medium))
                                    .foregroundStyle(store.profile.activity == activity ? Color.brandSecondary : .textPrimary)
                                
                                Spacer()
                                
                                if store.profile.activity == activity {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brandSecondary)
                                }
                            }
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background {
                                RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                                    .fill(store.profile.activity == activity ? Color.brandSecondary.opacity(0.1) : Color.clear)
                            }
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, Spacing.lg)
    }
}

// MARK: - Diet Preferences Card
private struct DietPreferencesCard: View {
    @EnvironmentObject private var store: AppStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Title
            HStack {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color.brandAccent)
                
                Text("Diet Preferences")
                    .font(AppFont.body(18, weight: .bold))
                    .foregroundStyle(.textPrimary)
                
                Spacer()
            }
            
            // Preferred Flavors
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Preferred Flavors")
                    .font(AppFont.caption(13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                FlowRows(spacing: Spacing.xs) {
                    ForEach(Flavor.allCases) { flavor in
                        let isSelected = store.profile.preferredFlavors.contains(flavor)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    store.profile.preferredFlavors.remove(flavor)
                                } else {
                                    store.profile.preferredFlavors.insert(flavor)
                                }
                            }
                        } label: {
                            Text(flavor.rawValue.capitalized)
                                .font(AppFont.caption(13, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : Color.brandAccent)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background {
                                    Capsule()
                                        .fill(isSelected ? Color.brandAccent : Color.brandAccent.opacity(0.15))
                                }
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
            
            // Allergies
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Allergies & Restrictions")
                    .font(AppFont.caption(13, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                
                FlowRows(spacing: Spacing.xs) {
                    ForEach(Allergy.allCases) { allergy in
                        let isSelected = store.profile.allergies.contains(allergy)
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if isSelected {
                                    store.profile.allergies.remove(allergy)
                                } else {
                                    store.profile.allergies.insert(allergy)
                                }
                            }
                        } label: {
                            Text(allergy.rawValue.capitalized)
                                .font(AppFont.caption(13, weight: .semibold))
                                .foregroundStyle(isSelected ? .white : Color.brandPrimary)
                                .padding(.horizontal, Spacing.md)
                                .padding(.vertical, Spacing.xs)
                                .background {
                                    Capsule()
                                        .fill(isSelected ? Color.brandPrimary : Color.brandPrimary.opacity(0.15))
                                }
                        }
                        .buttonStyle(BouncyButtonStyle())
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
        .padding(.horizontal, Spacing.lg)
    }
}
