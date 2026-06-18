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
