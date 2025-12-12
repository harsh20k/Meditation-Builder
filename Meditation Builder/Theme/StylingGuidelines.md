# Meditation Builder - Styling Guidelines

## Overview

This document outlines the design system and styling guidelines for the Meditation Builder app. All components, layouts, and spacing should follow these guidelines to ensure consistency, maintainability, and a professional user experience.

## 8-Point Grid System

### Core Principle
All spacing, sizing, and layout measurements should be multiples of 8 points to create a consistent visual rhythm and maintain design harmony across the app.

### Grid Units
- **Base Unit**: 8 points (1x grid unit)
- **Small**: 8 points (1x grid unit)
- **Medium**: 16 points (2x grid unit)
- **Large**: 24 points (3x grid unit)
- **Extra Large**: 32 points (4x grid unit)
- **XX Large**: 40 points (5x grid unit)
- **Section**: 48 points (6x grid unit)
- **Title Room**: 56 points (7x grid unit)

### Usage Guidelines
- **Small (8pt)**: Tight spacing, internal elements, icon spacing
- **Medium (16pt)**: Standard padding, component spacing, section gaps
- **Large (24pt)**: Section breaks, major spacing, card spacing
- **Extra Large (32pt)**: Page-level spacing, major sections
- **Section (48pt)**: Page headers, major content breaks
- **Title Room (56pt)**: Hero sections, prominent headers

## Spacing Hierarchy

### Component-Level Spacing
```swift
// Internal component spacing
VStack(spacing: AppTheme.Spacing.small) // 8pt
HStack(spacing: AppTheme.Spacing.small) // 8pt

// Component padding
.padding(AppTheme.Spacing.medium) // 16pt
.padding(.horizontal, AppTheme.Spacing.medium) // 16pt
.padding(.vertical, AppTheme.Spacing.small) // 8pt
```

### Section-Level Spacing
```swift
// Section containers
VStack(spacing: AppTheme.Spacing.medium) // 16pt
.padding(.bottom, AppTheme.Spacing.large) // 24pt

// Section headers
.padding(.top, AppTheme.Spacing.section) // 48pt
.padding(.bottom, AppTheme.Spacing.large) // 24pt
```

### Page-Level Spacing
```swift
// Main content areas
.padding(.horizontal, AppTheme.Spacing.medium) // 16pt
.padding(.bottom, AppTheme.Spacing.extraLarge) // 32pt

// Floating elements
.padding(.bottom, AppTheme.Spacing.extraLarge) // 32pt
```

## Typography System

### Font Hierarchy
- **Title Font**: 25pt, light weight, serif design
- **Headline Font Large**: 18pt, medium weight, serif design
- **Headline Font**: 15pt, light weight, serif design
- **Body Font**: 16pt, regular weight, serif design
- **Button Font**: 16pt, semibold weight, serif design
- **Caption Font**: 14pt, light weight, serif design

### Usage Guidelines
- **Title Font**: Main page titles, prominent headings
- **Headline Font**: Section headers, card titles
- **Body Font**: Main content, readable text
- **Caption Font**: Metadata, secondary information
- **Button Font**: Interactive elements, call-to-action text

## Color System

### Primary Colors
- **Background**: Dark gray (#141518)
- **Card Color**: Darker gray (#0F1111)
- **Card Color Light**: Lighter gray (#191B1B)
- **Off White Text**: Light gray (#C8C8C8)
- **Light Grey**: Medium gray (#777781)

### Accent Colors
- **Accent Color**: Teal (#4DB6AC)
- **Accent Complementary**: Yellow-gold (#F6EFA6)

### Usage Guidelines
- **Background**: Main app background
- **Card Color**: Card backgrounds, elevated surfaces
- **Off White Text**: Primary text, high contrast
- **Light Grey**: Secondary text, metadata
- **Accent Color**: Interactive elements, highlights
- **Accent Complementary**: Complementary highlights

## Component Guidelines

### Card Components
```swift
// Standard card styling
.background(AppTheme.cardColor)
.cornerRadius(AppTheme.CornerRadius.medium) // 14pt
.padding(AppTheme.Spacing.medium) // 16pt
```

### Button Components
```swift
// Button spacing
.padding(AppTheme.Spacing.medium) // 16pt
.cornerRadius(AppTheme.CornerRadius.button) // 24pt

// Button hierarchy
- Primary: Accent color background
- Secondary: Accent color with opacity
- Destructive: Red with opacity
- Disabled: Light grey with opacity
```

### Grid Layouts
```swift
// Standard grid spacing
LazyVGrid(columns: [
    GridItem(.flexible(), spacing: AppTheme.Spacing.small), // 8pt
    GridItem(.flexible(), spacing: AppTheme.Spacing.small)  // 8pt
], spacing: AppTheme.Spacing.small) // 8pt

// Horizontal carousels
LazyHStack(spacing: AppTheme.Spacing.small) // 8pt
.padding(.horizontal, AppTheme.Spacing.medium) // 16pt
```

## Layout Patterns

### Page Structure
```swift
ScrollView {
    VStack(spacing: AppTheme.Spacing.medium) { // 16pt
        // Header Section
        headerSection
        
        // Content Sections
        contentSection
        
        // Action Sections
        actionSection
    }
    .padding(.horizontal, AppTheme.Spacing.medium) // 16pt
    .padding(.bottom, AppTheme.Spacing.extraLarge) // 32pt
}
```

### Section Structure
```swift
VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) { // 16pt
    // Section Header
    Text("Section Title")
        .font(AppTheme.Typography.headlineFont)
        .foregroundColor(AppTheme.offWhiteText)
    
    // Section Content
    VStack(spacing: AppTheme.Spacing.small) { // 8pt
        // Content items
    }
}
```

### Card Structure
```swift
VStack(alignment: .leading, spacing: AppTheme.Spacing.small) { // 8pt
    // Card Header
    HStack {
        // Icon and title
        Spacer()
        // Action buttons
    }
    
    // Card Content
    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) { // 8pt
        // Content elements
    }
}
.padding(AppTheme.Spacing.medium) // 16pt
.background(AppTheme.cardColor)
.cornerRadius(AppTheme.CornerRadius.medium) // 14pt
```

## Animation Guidelines

### Duration Standards
- **Quick interactions**: 0.1-0.2 seconds
- **Standard transitions**: 0.2-0.3 seconds
- **Complex animations**: 0.3-0.5 seconds

### Animation Types
```swift
// Standard button press
.animation(.easeInOut(duration: 0.1), value: isPressed)

// State transitions
.animation(.easeInOut(duration: 0.2), value: isActive)

// Spring animations
.animation(.spring(response: 0.3, dampingFraction: 0.6), value: isActive)
```

## Accessibility Guidelines

### Touch Targets
- **Minimum size**: 44x44 points (5.5x grid units)
- **Recommended size**: 48x48 points (6x grid units)
- **Button spacing**: 8pt minimum between interactive elements

### Color Contrast
- **Primary text**: High contrast against background
- **Secondary text**: Sufficient contrast for readability
- **Interactive elements**: Clear visual feedback

### Typography
- **Minimum font size**: 14pt for body text
- **Line height**: 1.2-1.4 for optimal readability
- **Font weights**: Use system fonts for better accessibility

## Implementation Checklist

### Before Implementing New Components
- [ ] Follow 8-point grid system for all spacing
- [ ] Use standardized color palette
- [ ] Apply consistent typography hierarchy
- [ ] Include proper touch targets (44pt minimum)
- [ ] Add appropriate animations and feedback
- [ ] Test with different content lengths
- [ ] Ensure accessibility compliance

### Code Review Checklist
- [ ] All spacing values are grid-compliant
- [ ] Consistent use of AppTheme constants
- [ ] Proper component hierarchy
- [ ] Responsive layout considerations
- [ ] Animation performance optimization
- [ ] Accessibility features implemented

## Best Practices

### Do's
- ✅ Use AppTheme constants for all styling
- ✅ Follow 8-point grid system consistently
- ✅ Maintain visual hierarchy with typography
- ✅ Provide clear visual feedback for interactions
- ✅ Consider accessibility in all designs
- ✅ Test layouts with various content lengths

### Don'ts
- ❌ Use arbitrary spacing values
- ❌ Mix different spacing systems
- ❌ Ignore touch target minimums
- ❌ Use colors outside the defined palette
- ❌ Create inconsistent component patterns
- ❌ Overlook animation performance

## Maintenance

### Regular Reviews
- Monthly spacing audit across all views
- Quarterly typography consistency check
- Bi-annual accessibility compliance review
- Annual design system documentation update

### Update Process
1. Identify inconsistencies or improvements
2. Update AppTheme constants
3. Apply changes systematically across components
4. Test thoroughly across different devices
5. Update documentation
6. Share changes with the team

---

*This document should be updated whenever the design system evolves. All team members should follow these guidelines to maintain consistency across the Meditation Builder app.* 