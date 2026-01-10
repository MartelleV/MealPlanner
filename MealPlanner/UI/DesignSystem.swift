//
//  DesignSystem.swift
//  MealPlanner
//
//  Created by Zayne Verlyn on 10/1/26.
//

import SwiftUI

// MARK: - Design System

enum AppFont {
    /// Header fonts - Bold, impactful serif
    static func header(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    /// Body fonts - Clean sans-serif
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
    
    /// Mono fonts - For numbers and data
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    /// Caption fonts - Small, refined
    static func caption(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Color Extensions

extension ShapeStyle where Self == Color {
    // Brand Colors - Bold & Vibrant
    static var brandPrimary: Color { Color(red: 1.0, green: 0.29, blue: 0.35) }      // Coral Red
    static var brandSecondary: Color { Color(red: 0.2, green: 0.58, blue: 0.92) }    // Vivid Blue
    static var brandAccent: Color { Color(red: 0.98, green: 0.75, blue: 0.18) }      // Golden Yellow
    
    // Text Colors
    static var textPrimary: Color { Color(red: 0.11, green: 0.11, blue: 0.12) }      // Near black
    static var textSecondary: Color { Color(red: 0.47, green: 0.47, blue: 0.49) }    // Medium gray
    static var textTertiary: Color { Color(red: 0.68, green: 0.68, blue: 0.70) }     // Light gray
    
    // Surface Colors
    static var surfaceBase: Color { Color(red: 0.98, green: 0.97, blue: 0.96) }      // Warm white
    static var surfaceElevated: Color { Color.white }
}

extension Color {
    // Hero Gradient Background
    static let heroGradient = LinearGradient(
        colors: [
            Color(red: 0.96, green: 0.94, blue: 0.92),  // Warm beige
            Color(red: 0.92, green: 0.90, blue: 0.88),  // Slightly darker
            Color(red: 0.94, green: 0.92, blue: 0.90)   // Soft variation
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing System

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius System

enum CornerRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

// MARK: - Bouncy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Grain Texture Overlay

struct GrainTexture: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.02),
                        Color.black.opacity(0.01),
                        Color.black.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .blendMode(.overlay)
    }
}

// MARK: - 3D Card Style

struct CardStyle: ViewModifier {
    var isPressed: Bool = false
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
