//
//  DesignSystem.swift
//  MealPlanner
//
//  Spacious, Snappy Design System
//

import SwiftUI

// MARK: - Typography (Native iOS - Larger)

enum AppFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .serif)
    }
    
    static func header(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    
    static func body(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }
    
    static func mono(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
    
    static func caption(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }
}

// MARK: - Colors

extension ShapeStyle where Self == Color {
    static var brandPrimary: Color { Color(red: 0.15, green: 0.15, blue: 0.2) }
    static var brandSecondary: Color { Color(red: 0.9, green: 0.35, blue: 0.3) }
    static var brandAccent: Color { Color(red: 0.2, green: 0.55, blue: 0.5) }
    
    static var textPrimary: Color { Color(red: 0.08, green: 0.08, blue: 0.1) }
    static var textSecondary: Color { Color(red: 0.45, green: 0.45, blue: 0.48) }
    static var textTertiary: Color { Color(red: 0.65, green: 0.65, blue: 0.68) }
    
    static var surfaceBase: Color { Color(red: 0.96, green: 0.96, blue: 0.965) }
    static var surfaceElevated: Color { .white }
    static var border: Color { Color(red: 0.88, green: 0.88, blue: 0.89) }
}

// MARK: - Spacing (More Generous)

enum Spacing {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 10
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 56
}

// MARK: - Corner Radius

enum CornerRadius {
    static let xs: CGFloat = 6
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Snappy Button Style

struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Card Style

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                    .fill(.white)
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.lg, style: .continuous)
                            .stroke(Color.border, lineWidth: 0.5)
                    }
            }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// MARK: - Grain Texture

struct GrainTexture: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for _ in 0..<Int(size.width * size.height / 100) {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                        with: .color(.black.opacity(Double.random(in: 0.008...0.02)))
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Divider

struct ThinDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.border)
            .frame(height: 0.5)
    }
}
