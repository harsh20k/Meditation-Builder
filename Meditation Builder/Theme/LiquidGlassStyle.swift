//
//  LiquidGlassStyle.swift
//  Meditation Builder
//

import SwiftUI

// MARK: - Navigation Bar

extension View {
    @ViewBuilder
    func liquidGlassNavigationBar() -> some View {
        if #available(iOS 26.0, *) {
            self.toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
        }
    }
}

// MARK: - Sheet Presentation

enum LiquidGlassSheetSize {
    case compact
    case half

    var detents: Set<PresentationDetent> {
        switch self {
        case .compact: [.fraction(0.42)]
        case .half: [.fraction(0.55)]
        }
    }
}

extension View {
    func liquidGlassSheet(size: LiquidGlassSheetSize = .half) -> some View {
        modifier(LiquidGlassSheetModifier(size: size))
    }
}

private struct LiquidGlassSheetModifier: ViewModifier {
    let size: LiquidGlassSheetSize

    func body(content: Content) -> some View {
        content
            .presentationDetents(size.detents)
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground {
                LiquidGlassSheetBackground()
            }
    }
}

private struct LiquidGlassSheetBackground: View {
    var body: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.clear)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        } else {
            AppTheme.backgroundColor
        }
    }
}

// MARK: - Close Button

struct LiquidGlassCloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .accessibilityLabel("Close")
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.offWhiteText)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(AppTheme.cardColor))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }
}

// MARK: - Sheet Header

struct LiquidGlassSheetHeader: View {
    let title: LocalizedStringKey
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            LiquidGlassCloseButton(action: onClose)
            Text(title)
                .font(AppTheme.Typography.headlineFontLarge)
                .foregroundColor(AppTheme.offWhiteText)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppTheme.Spacing.medium)
        .padding(.top, AppTheme.Spacing.medium)
        .padding(.bottom, AppTheme.Spacing.small)
    }
}

// MARK: - Fallback Material

extension View {
    @ViewBuilder
    func liquidGlassFallback<S: Shape>(
        in shape: S,
        tint: Color = AppTheme.accentColor
    ) -> some View {
        background {
            shape
                .fill(.ultraThinMaterial)
                .overlay {
                    shape.stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.28), .white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
                }
                .overlay {
                    if tint != .clear {
                        shape.fill(tint.opacity(0.04))
                    }
                }
        }
    }
}
