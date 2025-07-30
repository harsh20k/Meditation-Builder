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
    static let backgroundColor = Color(red: 20/255, green: 22/255, blue: 20/255) // #141518
    static let cardColor = Color(red: 15/255, green: 17/255, blue: 17/255) // #
	static let cardColorLight = Color(red: 25/255, green: 27/255, blue: 27/255) // Lighter than background
	static let blockColor = Color(red: 39/255, green: 76/255, blue: 119/255) // #274c77

//	static let cardColor = Color(red: 30/255, green: 32/255, blue: 32/255) // #
	static let searchBar = Color(red: 35/255, green: 37/255, blue: 40/255) //232528
	static let tabBar = Color(red: 35/255, green: 36/255, blue: 39/255) //232427
	static let offWhiteText = Color(red: 200/255, green: 200/255, blue: 200/255) //232427


//	static let accentColor = Color(red: 221/255, green: 97/255, blue: 27/255) // #dd611b (orange)
	static let accentColor = Color(red: 77/255, green: 181/255, blue: 172/255) // #4DB6AC (Teal)
	static let accentCompColor = Color(red: 246/255, green: 239/255, blue: 166/255) // #f6efa6 (yellowgold)
    static let lightGrey = Color(red: 119/255, green: 119/255, blue: 129/255) // #777781
    
    // MARK: - Typography
//    struct Typography {
//        static let titleFont = Font.system(size: 32, weight: .bold, design: .rounded)
//		static let headlineFontLarge = Font.system(size: 28, weight: .bold, design: .rounded)
//        static let headlineFont = Font.system(size: 17, weight: .bold, design: .rounded)
//        static let bodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
//        static let buttonFont = Font.system(size: 20, weight: .bold, design: .rounded)
//        static let captionFont = Font.system(size: 19, weight: .semibold, design: .rounded)
//    }
	
	struct Typography {
			// Big, bold serif for main titles
		static let titleFont          = Font.system(size: 25, weight: .light,   design: .serif)
		
			// Medium-weight serif for large headlines
		static let headlineFontLarge  = Font.system(size: 18, weight: .medium, design: .serif)
		
			// Regular serif for section headers
		static let headlineFont       = Font.system(size: 15, weight: .light, design: .serif)
		
			// Clean, readable sans-serif for body text
		static let bodyFont           = Font.system(size: 16, weight: .regular, design: .serif)
		
			// Slightly smaller, semibold sans-serif for tappable buttons
		static let buttonFont         = Font.system(size: 16, weight: .semibold, design: .serif)
		
			// Light, compact sans-serif for captions & metadata
		static let captionFont        = Font.system(size: 14, weight: .light,   design: .serif)
	}
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let extraLarge: CGFloat = 24
		static let xxLarge: CGFloat = 28
        static let section: CGFloat = 32
		static let titleRoom: CGFloat = 50
        static let cardGrid: CGFloat = 8
        static let cardInternal: CGFloat = 8
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 12
        static let medium: CGFloat = 14
        static let large: CGFloat = 16
        static let button: CGFloat = 24
		static let extraLarge: CGFloat = 32
		static let blockCard: CGFloat = 40
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
    
    // MARK: - Button Styles
    struct ButtonStyles {
        /// Primary button style - used for main actions like play, save, etc.
        static let primary = ButtonStyle(
            backgroundColor: accentColor,
            foregroundColor: offWhiteText,
            font: Typography.buttonFont,
            cornerRadius: CornerRadius.button,
            padding: Spacing.medium
        )
        
        /// Secondary button style - used for secondary actions like edit
        static let secondary = ButtonStyle(
            backgroundColor: accentColor.opacity(0.8),
            foregroundColor: offWhiteText,
            font: Typography.buttonFont,
            cornerRadius: CornerRadius.button,
            padding: Spacing.medium
        )
        
        /// Destructive button style - used for delete actions
        static let destructive = ButtonStyle(
            backgroundColor: Color.red.opacity(0.1),
            foregroundColor: Color.red.opacity(0.8),
            font: Typography.buttonFont,
            cornerRadius: CornerRadius.button,
            padding: Spacing.medium
        )
        
        /// Disabled button style - used when button is not interactive
        static let disabled = ButtonStyle(
            backgroundColor: lightGrey.opacity(0.3),
            foregroundColor: lightGrey.opacity(0.6),
            font: Typography.buttonFont,
            cornerRadius: CornerRadius.button,
            padding: Spacing.medium
        )
        
        /// Card button style - used for category cards with icons and text
        static let card = ButtonStyle(
            backgroundColor: cardColorLight,
            foregroundColor: offWhiteText,
            font: .system(size: 12, weight: .light, design: .serif),
            cornerRadius: CornerRadius.small,
            padding: Spacing.cardInternal
        )
    }
}

// MARK: - Button Style Structure
struct ButtonStyle {
    let backgroundColor: Color
    let foregroundColor: Color
    let font: Font
    let cornerRadius: CGFloat
    let padding: CGFloat
}

// MARK: - Custom Button View Modifier
struct ThemedButtonModifier: ViewModifier {
    let style: ButtonStyle
    let isEnabled: Bool
    @State private var isPressed: Bool = false
    
    init(_ style: ButtonStyle, isEnabled: Bool = true) {
        self.style = style
        self.isEnabled = isEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .font(style.font)
            .foregroundColor(isEnabled ? style.foregroundColor : AppTheme.ButtonStyles.disabled.foregroundColor)
            .frame(maxWidth: .infinity)
            .padding(style.padding)
            .background(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(isEnabled ? style.backgroundColor : AppTheme.ButtonStyles.disabled.backgroundColor)
                    .opacity(isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: AppTheme.Shadows.button,
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onTapGesture {
                // Haptic feedback for iOS
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if isEnabled {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isPressed = true
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = false
                        }
                    }
            )
    }
}

// MARK: - Reactive Themed Button
struct ReactiveThemedButton<Content: View>: View {
    let style: ButtonStyle
    let isEnabled: Bool
    let action: () -> Void
    let content: Content
    
    @State private var isPressed: Bool = false
    
    init(
        style: ButtonStyle,
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
        self.content = content()
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Execute action
                action()
            }
        }) {
            content
                .font(style.font)
                .foregroundColor(isEnabled ? style.foregroundColor : AppTheme.ButtonStyles.disabled.foregroundColor)
                .frame(maxWidth: .infinity)
                .padding(style.padding)
                .background(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .fill(isEnabled ? style.backgroundColor : AppTheme.ButtonStyles.disabled.backgroundColor)
                        .opacity(isPressed ? 0.8 : 1.0)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .shadow(
                    color: AppTheme.Shadows.button,
                    radius: isPressed ? 2 : 4,
                    x: 0,
                    y: isPressed ? 1 : 2
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}

// MARK: - Card Style Button
struct CardStyleButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    init(
        icon: String,
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // Haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                
                // Execute action
                action()
            }
        }) {
            VStack(spacing: AppTheme.Spacing.cardInternal) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(isEnabled ? AppTheme.offWhiteText : AppTheme.lightGrey.opacity(0.5))
                    .frame(width: 28, height: 28)
                
                // Title
                Text(title)
                    .font(.system(size: 12, weight: .light, design: .serif))
                    .foregroundColor(isEnabled ? AppTheme.offWhiteText : AppTheme.lightGrey.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, minHeight: 70)
            .padding(AppTheme.Spacing.cardInternal)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(AppTheme.ButtonStyles.card.backgroundColor)
                    .opacity(isPressed ? 0.8 : 1.0)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(AppTheme.lightGrey.opacity(AppTheme.Opacity.border), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: AppTheme.Shadows.card,
                radius: isPressed ? 2 : 6,
                x: 0,
                y: isPressed ? 1 : 3
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            if isEnabled {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isPressed = pressing
                }
            }
        }, perform: {})
    }
}

// MARK: - View Extension for Easy Button Styling
extension View {
    /// Apply themed button styling
    func themedButton(_ style: ButtonStyle, isEnabled: Bool = true) -> some View {
        self.modifier(ThemedButtonModifier(style, isEnabled: isEnabled))
    }
    
    /// Apply primary button styling
    func primaryButton(isEnabled: Bool = true) -> some View {
        self.themedButton(AppTheme.ButtonStyles.primary, isEnabled: isEnabled)
    }
    
    /// Apply secondary button styling
    func secondaryButton(isEnabled: Bool = true) -> some View {
        self.themedButton(AppTheme.ButtonStyles.secondary, isEnabled: isEnabled)
    }
    
    /// Apply destructive button styling
    func destructiveButton(isEnabled: Bool = true) -> some View {
        self.themedButton(AppTheme.ButtonStyles.destructive, isEnabled: isEnabled)
    }
    
    /// Apply card button styling
    func cardButton(isEnabled: Bool = true) -> some View {
        self.themedButton(AppTheme.ButtonStyles.card, isEnabled: isEnabled)
    }
}

// MARK: - Convenience Functions for Reactive Buttons
extension AppTheme {
    /// Create a reactive primary button
    static func primaryButton<Content: View>(
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> ReactiveThemedButton<Content> {
        ReactiveThemedButton(
            style: ButtonStyles.primary,
            isEnabled: isEnabled,
            action: action,
            content: content
        )
    }
    
    /// Create a reactive secondary button
    static func secondaryButton<Content: View>(
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> ReactiveThemedButton<Content> {
        ReactiveThemedButton(
            style: ButtonStyles.secondary,
            isEnabled: isEnabled,
            action: action,
            content: content
        )
    }
    
    /// Create a reactive destructive button
    static func destructiveButton<Content: View>(
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> ReactiveThemedButton<Content> {
        ReactiveThemedButton(
            style: ButtonStyles.destructive,
            isEnabled: isEnabled,
            action: action,
            content: content
        )
    }
    
    /// Create a card style button
    static func cardButton(
        icon: String,
        title: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> CardStyleButton {
        CardStyleButton(
            icon: icon,
            title: title,
            isEnabled: isEnabled,
            action: action
        )
    }
} 
