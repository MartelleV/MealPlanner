//
//  RootView.swift
//  MealPlanner
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()
            GrainTexture()
            
            TabView(selection: $selectedTab) {
                MealsView().tag(0)
                PlanView().tag(1)
                ProfileView().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack {
                Spacer()
                FloatingNavBar(selectedTab: $selectedTab)
            }
        }
        .overlay(alignment: .top) {
            if let banner = store.banner {
                BannerView(banner: banner)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .task { await store.loadAll() }
    }
}

// MARK: - Floating Nav Bar

struct FloatingNavBar: View {
    @Binding var selectedTab: Int
    @Namespace private var animation
    
    var body: some View {
        HStack(spacing: Spacing.xs) {
            NavBarItem(
                icon: "fork.knife",
                label: "Meals",
                isSelected: selectedTab == 0,
                namespace: animation
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 0
                }
            }
            
            NavBarItem(
                icon: "calendar",
                label: "Plan",
                isSelected: selectedTab == 1,
                namespace: animation
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 1
                }
            }
            
            NavBarItem(
                icon: "person",
                label: "Profile",
                isSelected: selectedTab == 2,
                namespace: animation
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedTab = 2
                }
            }
        }
        .padding(Spacing.xs)
        .background {
            Capsule()
                .fill(.white)
                .overlay { Capsule().stroke(Color.border, lineWidth: 0.5) }
                .shadow(color: .black.opacity(0.08), radius: 24, x: 0, y: 10)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.bottom, Spacing.md)
    }
}

struct NavBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var namespace: Namespace.ID
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                
                if isSelected {
                    Text(label)
                        .font(AppFont.body(15, weight: .semibold))
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
            }
            .foregroundStyle(isSelected ? .white : .textSecondary)
            .padding(.horizontal, isSelected ? Spacing.lg : Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color.brandPrimary)
                        .matchedGeometryEffect(id: "navBg", in: namespace)
                }
            }
        }
        .buttonStyle(BouncyButtonStyle())
    }
}

// MARK: - Banner

struct ModernBannerView: View {
    var banner: Banner
    var body: some View { BannerView(banner: banner) }
}
