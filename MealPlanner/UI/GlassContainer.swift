//
//  GlassContainer.swift
//  MealPlanner
//

import SwiftUI

struct GlassContainer: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            Color.surfaceBase.ignoresSafeArea()
            GrainTexture()
            content
        }
    }
}

extension View {
    func glassContainer() -> some View { modifier(GlassContainer()) }
}

struct BannerView: View {
    var banner: Banner
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            Circle()
                .fill(iconColor.opacity(0.15))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
            
            Text(banner.text)
                .font(AppFont.body(15, weight: .medium))
                .foregroundStyle(.textPrimary)
            
            Spacer()
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
                .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }

    private var icon: String {
        switch banner.kind {
        case .success: return "checkmark"
        case .info:    return "info"
        case .error:   return "exclamationmark"
        }
    }
    
    private var iconColor: Color {
        switch banner.kind {
        case .success: return .brandAccent
        case .info:    return .brandPrimary
        case .error:   return .brandSecondary
        }
    }
}
