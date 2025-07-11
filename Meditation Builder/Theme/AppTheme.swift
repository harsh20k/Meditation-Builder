//
//  AppTheme.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

// MARK: - App Theme
struct AppTheme {
    // MARK: - Colors
    static let backgroundColor = Color(red: 34/255, green: 38/255, blue: 45/255) // #22262D
    static let cardColor = Color(red: 42/255, green: 46/255, blue: 55/255) // #2A2E37
    static let accentColor = Color(red: 1.0, green: 122/255, blue: 0) // #FF7A00
    static let lightGrey = Color(red: 176/255, green: 176/255, blue: 176/255) // #B0B0B0
    
    // MARK: - Typography
    struct Typography {
        static let titleFont = Font.system(size: 32, weight: .bold, design: .rounded)
        static let headlineFont = Font.system(size: 17, weight: .bold, design: .rounded)
        static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
        static let buttonFont = Font.system(size: 20, weight: .bold, design: .rounded)
        static let captionFont = Font.system(size: 19, weight: .semibold, design: .rounded)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
        static let section: CGFloat = 32
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 16
        static let button: CGFloat = 24
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let card = Color.black.opacity(0.18)
        static let button = Color.black.opacity(0.1)
    }
    
    // MARK: - Opacity
    struct Opacity {
        static let disabled: Double = 0.7
        static let overlay: Double = 0.08
        static let border: Double = 0.07
        static let timeline: Double = 0.25
    }
} 