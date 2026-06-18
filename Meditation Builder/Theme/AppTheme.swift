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
    static let lightGrey = Color(red: 160/255, green: 160/255, blue: 168/255) // #A0A0A8 — WCAG AA compliant on dark bg
    
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
		// Semantic fonts with Dynamic Type scaling + serif character
		// Using .custom with size preserves the design; Dynamic Type is respected via the semantic base

		// Title: equivalent to iOS .title2 but with serif design
		static let titleFont          = Font.system(.title2, design: .serif).weight(.light)

		// Large headline: equivalent to .headline but slightly larger
		static let headlineFontLarge  = Font.system(.headline, design: .serif).weight(.medium)

		// Section header
		static let headlineFont       = Font.system(.subheadline, design: .serif).weight(.light)

		// Body copy
		static let bodyFont           = Font.system(.body, design: .serif)

		// Tappable buttons
		static let buttonFont         = Font.system(.body, design: .serif).weight(.semibold)

		// Captions and metadata
		static let captionFont        = Font.system(.caption, design: .serif).weight(.light)
	}
    
    // MARK: - Spacing
    struct Spacing {
        static let small: CGFloat = 8      // 1x grid unit
        static let medium: CGFloat = 16    // 2x grid unit
        static let large: CGFloat = 24     // 3x grid unit
        static let extraLarge: CGFloat = 32 // 4x grid unit
        static let xxLarge: CGFloat = 40   // 5x grid unit
        static let section: CGFloat = 48   // 6x grid unit
        static let titleRoom: CGFloat = 56 // 7x grid unit
        static let cardGrid: CGFloat = 8   // 1x grid unit
        static let cardInternal: CGFloat = 8 // 1x grid unit
        /// Space above the floating tab bar for overlays (FAB, etc.)
        static let tabBarClearance: CGFloat = 92
        /// FAB sits above the native liquid glass tab bar
        static let fabTabBarClearance: CGFloat = 104
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
        
        /// Toggle button style - used for pin/unpin, favorite, and other toggle actions
        static let toggle = ButtonStyle(
            backgroundColor: cardColor,
            foregroundColor: lightGrey,
            font: Typography.captionFont,
            cornerRadius: CornerRadius.medium,
            padding: Spacing.medium
        )
        
        /// Toggle button style (active state) - used when toggle is active
        static let toggleActive = ButtonStyle(
            backgroundColor: accentColor.opacity(0.1),
            foregroundColor: accentColor,
            font: Typography.captionFont,
            cornerRadius: CornerRadius.medium,
            padding: Spacing.medium
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

// MARK: - Toggle Style Button
struct ToggleStyleButton: View {
    let icon: String
    let activeIcon: String
    let title: String
    let activeTitle: String
    let isActive: Bool
    let action: () -> Void
    
    init(
        icon: String,
        activeIcon: String,
        title: String,
        activeTitle: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.activeIcon = activeIcon
        self.title = title
        self.activeTitle = activeTitle
        self.isActive = isActive
        self.action = action
    }
    
    var body: some View {
        BaseCardStyleButton(isEnabled: true, action: action) {
            VStack(spacing: AppTheme.Spacing.small) {
                // Icon with animation
                Image(systemName: isActive ? activeIcon : icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isActive ? AppTheme.accentColor : AppTheme.lightGrey)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .conditionalAnimation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)

                // Title with animation
                Text(isActive ? activeTitle : title)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(isActive ? AppTheme.accentColor : AppTheme.lightGrey)
                    .conditionalAnimation(.easeInOut(duration: 0.2), value: isActive)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(isActive ? AppTheme.ButtonStyles.toggleActive.backgroundColor : AppTheme.ButtonStyles.toggle.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(isActive ? AppTheme.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

// MARK: - Base Card Style Button
struct BaseCardStyleButton<Content: View>: View {
    let isEnabled: Bool
    let action: () -> Void
    let content: Content
    
    @State private var isPressed: Bool = false
    
    init(
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
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

// MARK: - Card Style Button
struct CardStyleButton: View {
    let icon: String
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
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
        BaseCardStyleButton(isEnabled: isEnabled, action: action) {
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
        }
    }
}

// MARK: - Reduce Motion Helper
extension View {
    /// Wraps `withAnimation` calls so they respect Reduce Motion.
    /// Pass `.none` as the reduced alternative or omit it to get no animation when Reduce Motion is on.
    @ViewBuilder
    func conditionalAnimation<V: Equatable>(_ animation: Animation, reducedAnimation: Animation? = nil, value: V) -> some View {
        self.modifier(ReduceMotionAnimationModifier(animation: animation, reducedAnimation: reducedAnimation, value: value))
    }
}

private struct ReduceMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation
    let reducedAnimation: Animation?
    let value: V

    func body(content: Content) -> some View {
        if reduceMotion {
            content.animation(reducedAnimation, value: value)
        } else {
            content.animation(animation, value: value)
        }
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
    
    /// Create a base card style button with custom content
    static func baseCardButton<Content: View>(
        isEnabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> BaseCardStyleButton<Content> {
        BaseCardStyleButton(
            isEnabled: isEnabled,
            action: action,
            content: content
        )
    }
    
    /// Create a toggle style button for pin/unpin, favorite, and other toggle actions
    static func toggleButton(
        icon: String,
        activeIcon: String,
        title: String,
        activeTitle: String,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> ToggleStyleButton {
        ToggleStyleButton(
            icon: icon,
            activeIcon: activeIcon,
            title: title,
            activeTitle: activeTitle,
            isActive: isActive,
            action: action
        )
    }
    
    /// Create a customizable separator line
    static func separator(
        color: Color = lightGrey.opacity(0.01),
        height: CGFloat = 1,
        horizontalPadding: CGFloat = 0,
        verticalPadding: CGFloat = Spacing.medium
    ) -> some View {
        Rectangle()
            .fill(color)
            .frame(height: height)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
    }
    
    /// Create a responsive floating action button
    static func floatingActionButton(
        icon: String,
        backgroundColor: Color = tabBar,
        foregroundColor: Color = lightGrey,
        size: CGFloat = 44,
        action: @escaping () -> Void
    ) -> FloatingActionButton {
        FloatingActionButton(
            icon: icon,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            size: size,
            action: action
        )
    }
}

// MARK: - Floating Action Button
struct FloatingActionButton: View {
    let icon: String
    let backgroundColor: Color
    let foregroundColor: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        if #available(iOS 26.0, *) {
            Button(action: performAction) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: size, height: size)
            }
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .tint(AppTheme.accentColor)
        } else {
            Button(action: performAction) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: size, height: size)
                    .background {
                        Circle()
                            .fill(AppTheme.accentColor)
                            .shadow(color: AppTheme.accentColor.opacity(0.45), radius: 6, y: 2)
                    }
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func performAction() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .soft)
        impactFeedback.impactOccurred()
        action()
    }
} 
