//
//  GlassContainer.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 24/10/25.
//


import SwiftUI

struct GlassContainer: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            // Subtle pastel gradient background
            LinearGradient(
                colors: [
                    Color(.systemTeal).opacity(0.10),
                    Color(.systemPink).opacity(0.10),
                    Color(.systemIndigo).opacity(0.10)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            content
                .background(
                    // Frosted glass layer
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 16, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .opacity(0) // invisible container so scrolling content isn't clipped
                )
        }
    }
}

extension View {
    func glassContainer() -> some View { modifier(GlassContainer()) }
}

struct BannerView: View {
    var banner: Banner
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
            Text(banner.text).font(.callout).bold()
            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.top, 12)
        .padding(.horizontal)
    }

    private var icon: String {
        switch banner.kind {
        case .success: return "checkmark.seal.fill"
        case .info:    return "info.circle.fill"
        case .error:   return "exclamationmark.triangle.fill"
        }
    }
}
