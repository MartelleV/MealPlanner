//
//  RootView.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Hero gradient background
            Color.heroGradient
                .ignoresSafeArea()
            
            // Grain texture overlay
            GrainTexture()
            
            // Main content
            TabView(selection: $selectedTab) {
                MealsView()
                    .tag(0)
                
                PlanView()
                    .tag(1)
                
                ProfileView()
                    .tag(2)
            }
            .tint(.brandPrimary)
            
            // Custom tab bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
            }
        }
        .overlay(alignment: .top) {
            if let banner = store.banner {
                ModernBannerView(banner: banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .task {
            await store.loadAll()
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(icon: "fork.knife", title: "Meals", isSelected: selectedTab == 0) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            TabButton(icon: "calendar", title: "Plan", isSelected: selectedTab == 1) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
            
            TabButton(icon: "person.circle", title: "Profile", isSelected: selectedTab == 2) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    selectedTab = 2
                }
            }
        }
        .padding(.vertical, Spacing.sm)
        .padding(.horizontal, Spacing.xs)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        }
    }
}

struct TabButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Spacing.xs) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .symbolRenderingMode(.hierarchical)
                
                Text(title)
                    .font(AppFont.caption(10, weight: isSelected ? .semibold : .medium))
            }
            .foregroundStyle(isSelected ? Color.brandPrimary : Color.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.sm)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: CornerRadius.sm, style: .continuous)
                        .fill(Color.brandPrimary.opacity(0.12))
                        .matchedGeometryEffect(id: "tab", in: namespace)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }
    
    @Namespace private var namespace
}

// MARK: - Modern Banner
struct ModernBannerView: View {
    var banner: Banner
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(iconColor)
            
            Text(banner.text)
                .font(AppFont.body(15, weight: .semibold))
                .foregroundStyle(.textPrimary)
            
            Spacer()
        }
        .padding(.vertical, Spacing.md)
        .padding(.horizontal, Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: CornerRadius.md, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }
    
    private var icon: String {
        switch banner.kind {
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
    
    private var iconColor: Color {
        switch banner.kind {
        case .success: return .green
        case .info: return .brandSecondary
        case .error: return .brandPrimary
        }
    }
}
