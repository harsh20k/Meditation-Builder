---
name: UI Audit Meditation App
overview: Comprehensive UI audit of the Meditation Builder iOS app covering design system consistency, Apple HIG compliance (iOS 18), accessibility, visual hierarchy, navigation patterns, and psychological principles for a calming meditation experience.
todos:
  - id: restyle-history
    content: "P0: Restyle SessionHistoryView to match dark theme (AppTheme.backgroundColor, custom header, themed cards)"
    status: completed
  - id: tab-labels
    content: "P0: Add text labels below icons in CustomTabBar"
    status: completed
  - id: accessibility
    content: "P0: Add accessibilityLabel/Hint/Value to all interactive elements across every view"
    status: completed
  - id: contrast
    content: "P0: Lighten AppTheme.lightGrey for WCAG AA compliance"
    status: completed
  - id: deprecated-nav
    content: "P1: Replace NavigationView with NavigationStack, .navigationBarItems with .toolbar"
    status: completed
  - id: hardcoded-white
    content: "P1: Replace all .foregroundColor(.white) with AppTheme.offWhiteText"
    status: completed
  - id: typography
    content: "P1: Standardize all inline .font() calls to use AppTheme.Typography"
    status: completed
  - id: tab-safe-area
    content: "P1: Fix tab bar safe area handling with safeAreaInset"
    status: completed
  - id: fab-visibility
    content: "P1: Change FAB to use accent color background"
    status: completed
  - id: accent-catalog
    content: "P1: Define teal in AccentColor.colorset"
    status: completed
  - id: dynamic-type
    content: "P2: Add Dynamic Type support via semantic text styles"
    status: completed
  - id: reduce-motion
    content: "P2: Respect accessibilityReduceMotion environment value"
    status: completed
  - id: breathing-room
    content: "P2: Increase spacing, padding, card sizes for calmer feel"
    status: completed
  - id: empty-state
    content: "P2: Add breathing animation to LibraryEmptyStateView"
    status: completed
  - id: player-richness
    content: "P2: Add subtle ambient visuals to RoutinePlayerView (mesh gradient, breathing light)"
    status: completed
  - id: haptics
    content: "P2: Expand haptics using .sensoryFeedback to timer, tabs, toggles, block transitions"
    status: completed
  - id: modern-effects
    content: "P2: Add scrollTransition, MeshGradient, symbolEffect(.breathe) where appropriate"
    status: completed
  - id: localization-gaps
    content: "P1: Replace remaining hardcoded English strings with localization keys"
    status: completed
isProject: false
---

# UI Audit: Meditation Builder

---

## 1. Design System Inconsistencies

### 1A. SessionHistoryView is completely unstyled

[`SessionHistoryView.swift`](Meditation Builder/Views/SessionHistoryView.swift) is the **only** tab that uses default system styling (`NavigationView`, `.navigationTitle`, `Color(.systemBackground)`, `RoundedBorderTextFieldStyle()`, `PlainListStyle()`). Every other tab uses the custom dark theme from `AppTheme`. This creates a jarring white screen when switching to the History tab.

**Fix:** Restyle SessionHistoryView to use `AppTheme.backgroundColor`, custom header pattern (matching Library/Sounds/Settings), and themed cards instead of system List rows. Replace `NavigationView` (deprecated) with the `NavigationStack` already used in `MainTabView`.

### 1B. Deprecated API usage: `NavigationView` and `.navigationBarItems`

Files still using deprecated APIs:
- [`SessionHistoryView.swift`](Meditation Builder/Views/SessionHistoryView.swift) -- `NavigationView`, `.navigationBarItems`
- [`AddBlockView.swift`](Meditation Builder/Views/AddBlockView.swift), [`EditBlockView.swift`](Meditation Builder/Views/EditBlockView.swift), [`BellPickerView.swift`](Meditation Builder/Views/BellPickerView.swift), [`IconPickerView.swift`](Meditation Builder/Views/IconPickerView.swift) -- `.navigationBarItems` or `.toolbar` with legacy patterns
- [`SessionStatisticsView.swift`](Meditation Builder/Views/SessionStatisticsView.swift), [`LoggingSettingsView.swift`](Meditation Builder/Views/Playground/LoggingSettingsView.swift) -- `NavigationView`

**Fix:** Replace `NavigationView` with `NavigationStack`. Replace `.navigationBarItems` with `.toolbar { ToolbarItem(...) }`.

### 1C. Hardcoded `.white` color throughout

Multiple views use `foregroundColor(.white)` instead of `AppTheme.offWhiteText`. This bypasses the theme system and will break if light mode support is ever added. Found in:
- `MainTabView.swift` (PlaceholderView)
- `RoutineLibraryView.swift` (empty state)
- `SettingsView.swift` (header)
- `RitualPageView.swift`
- `RoutinePlayerView.swift`

**Fix:** Replace all `.white` text references with `AppTheme.offWhiteText`.

### 1D. Typography inconsistencies

The `AppTheme.Typography` defines a complete serif type scale, but several views bypass it:
- `SessionHistoryView` uses `.caption`, `.headline` -- system defaults
- `PlaceholderView` uses `.system(size: 24, weight: .bold, design: .rounded)` -- rounded, not serif
- `RoutineCard` action buttons use `.system(size: 16, weight: .semibold, design: .rounded)`
- `LibraryEmptyStateView` uses `.system(size: 20, weight: .semibold, design: .rounded)`

**Fix:** Audit every inline `.font(...)` call. Replace with `AppTheme.Typography.*` or add new named levels (e.g., `subtitleFont`, `overlineFont`) to the theme.

---

## 2. Navigation and Tab Bar Issues

### 2A. Custom tab bar has no labels

The tab bar shows only icons with no text labels. Apple HIG strongly recommends always showing labels for tab bars -- icons alone force users to guess. The `TabSelection.title` property exists but is never displayed.

**Fix:** Add the title text below each icon in `CustomTabBar`. Use a small `VStack(spacing: 2)` of icon + label. Match SF Symbols + label pattern from native `TabView`.

### 2B. Tab bar lacks safe area handling

`CustomTabBar` uses `.ignoresSafeArea(edges: .bottom)` but has a fixed height of 48pt. On devices with a home indicator (iPhone with Dynamic Island), the bottom safe area is ~34pt. The tab bar content should sit above the safe area, with the background extending into it.

**Fix:** Extend the background `.fill` into the safe area but keep interactive content above it. Use `safeAreaInset(edge: .bottom)` on the content instead of manually calculating padding offsets with `calculateBottomPadding`.

### 2C. No tab-switching animation

Tab content changes instantly (`switch selectedTab`). There is no cross-fade or matched geometry transition between tabs.

**Fix:** Add `.transition(.opacity)` to the `Group` content block with `animation(.easeInOut(duration: 0.2), value: selectedTab)`.

### 2D. Double navigation header

`RoutineLibraryView` displays the title "Ritual Library" in a custom header, but `SessionHistoryView` uses `.navigationTitle` which renders a system large title. When wrapped in the shared `NavigationStack` from `MainTabView`, `SessionHistoryView` shows a redundant navigation bar.

**Fix:** All tabs should use the same custom header pattern (icon + title left-aligned) and disable the system navigation bar via `.navigationBarHidden(true)`.

---

## 3. Accessibility (Critical Gap)

### 3A. Zero accessibility modifiers

There are **zero** uses of `accessibilityLabel`, `accessibilityHint`, `accessibilityValue`, or `accessibilityIdentifier` in the entire codebase. VoiceOver users cannot meaningfully use this app.

**Priority fixes:**
- Every `Button` and interactive control needs an `accessibilityLabel`
- Tab bar items need labels (partially solved by adding text labels per 2A)
- Slider controls (volume sliders in `AmbientSoundMixerView`) need `accessibilityValue`
- Cards with tap gestures need `.accessibilityAddTraits(.isButton)`
- Timer display needs `accessibilityLabel` with spoken time format
- Context menus (ellipsis buttons) need `accessibilityLabel("More options")`

### 3B. No Dynamic Type support

All fonts use fixed `size:` values. None use `.font(.title)` or `.font(.body)` which respect the user's Dynamic Type setting. The entire typography system is hardcoded.

**Fix:** Replace the static `AppTheme.Typography` with semantic text styles using `Font.system(.body, design: .serif)` or at minimum apply `.dynamicTypeSize(.large ... .accessibility3)` range to allow scaling. Consider using `@ScaledMetric` for spacing values.

### 3C. No Reduce Motion support

Animations are always on. Users with vestibular disorders who enable "Reduce Motion" in iOS settings will still see all scale effects, spring animations, and transitions.

**Fix:** Check `@Environment(\.accessibilityReduceMotion)` and conditionally disable or simplify animations.

### 3D. Insufficient color contrast

- `AppTheme.lightGrey` (#777781) on `backgroundColor` (#141614) = contrast ratio ~3.6:1. WCAG AA requires 4.5:1 for normal text.
- Caption text at `size: 14, weight: .light` with this grey on dark background is especially hard to read.

**Fix:** Lighten `lightGrey` to at least #9A9AA0 for body text, or #B0B0B8 for caption/secondary text.

---

## 4. Visual Design and Serenity

### 4A. Breathing room and visual weight

The current design is dense. Cards in the library grid have `minHeight: 120` with `spacing: 8` (small). For a meditation app, generous whitespace communicates calm.

**Fix:**
- Increase grid spacing from 8pt to 16pt
- Increase card internal padding from 16pt to 20pt
- Add more top padding to scroll content for a spacious header area
- Consider reducing the 2-column grid to single-column cards on smaller devices (iPhone SE)

### 4B. No onboarding or empty state delight

The `LibraryEmptyStateView` is functional but uninspiring -- a circle with a plus icon and text. For a meditation app, this is the user's first impression.

**Fix:** Add a gentle breathing animation (pulsing circle or expanding rings), a warm welcome message ("Begin your practice"), and possibly a single-tap "Create your first ritual" prominent CTA. Use `AppTheme.accentColor` as a subtle radial gradient behind the icon.

### 4C. Player view lacks visual richness

`RoutinePlayerView` is a pure black screen with a white timer and minimal controls. During an active meditation session (potentially 20-60 minutes), this is what users stare at.

**Fix:**
- Add a subtle animated gradient or particle effect (breathing light) behind the timer
- Use the routine's icon as a large, very faint watermark
- Consider a "dimming" mode where the screen progressively darkens during meditation
- Add a subtle pulse animation synced to a breathing rhythm guide

### 4D. Floating action button blends with tab bar

The FAB uses `AppTheme.tabBar` color and grey icon -- it's nearly invisible against the tab bar sitting directly below it.

**Fix:** Use `AppTheme.accentColor` (teal) as the FAB background with white icon. This follows Material Design and Apple HIG patterns for primary actions. Alternatively, use a translucent blur material.

### 4E. Accent color not set in asset catalog

`AccentColor.colorset` is empty (no color defined). The teal accent is only defined in code via `AppTheme.accentColor`. This means system tinting (alerts, toggles, links) won't match the app's teal.

**Fix:** Define the teal color (#4DB6AC) in `AccentColor.colorset` for both light and dark appearances.

### 4F. Settings appearance picker is disconnected

`SettingsView` stores `@AppStorage("colorScheme")` and `@AppStorage("accentColorHex")` but neither value is read by `Meditation_BuilderApp`, `ContentView`, or any parent view. The picker UI exists but changing it does nothing.

**Fix:** In `Meditation_BuilderApp` (or `ContentView`), read `@AppStorage("colorScheme")` and apply `.preferredColorScheme(...)` to the root `WindowGroup`. For the accent color, apply `.tint(Color(hex: accentColorHex))`.

### 4G. Player controls use Unicode text instead of SF Symbols

`PlayerControlsView` renders play/pause as `Text("▶")` / `Text("❙❙")` instead of `Image(systemName: "play.fill")` / `Image(systemName: "pause.fill")`. This breaks VoiceOver (reads "black right-pointing triangle") and doesn't match the rest of the app.

**Fix:** Replace with SF Symbol images.

### 4H. AuditoriumEngine lives in Views/Components/

`AuditoriumManager.swift` (which declares `AuditoriumEngine`) is a pure audio engine with no SwiftUI -- it belongs in `Models/` alongside `AmbientSoundEngine`.

**Fix:** Move to `Models/AuditoriumEngine.swift`.

---

## 5. Haptic Feedback

### 5A. Haptics only on custom buttons

Haptic feedback is implemented in `AppTheme`'s button components (`UIImpactFeedbackGenerator(.light)`) but nowhere else. Key moments that should have feedback:
- Timer start/pause/resume/complete
- Block transitions during meditation
- Tab switching
- Swipe actions (delete, edit)
- Toggle switches (favorite, sound enable)

**Fix:** Use the iOS 17+ `.sensoryFeedback` modifier instead of `UIImpactFeedbackGenerator` for cleaner code. Apply `.sensoryFeedback(.impact(flexibility: .soft), trigger:)` for interactions and `.sensoryFeedback(.success, trigger:)` for completions.

---

## 6. Modern iOS 18 Patterns Not Used

### 6A. No `@Entry` macro for environment values

`RoutineDataManager` is injected via a custom `EnvironmentKey`. iOS 18 introduces `@Entry` for cleaner environment values.

### 6B. No `.scrollTransition` or `.visualEffect`

The library card grid and sound mixer list could benefit from `scrollTransition` for subtle parallax/fade effects as items enter the viewport. This adds perceived polish with minimal code.

### 6C. No mesh gradient or variable blur

iOS 18's `MeshGradient` is perfect for meditation app backgrounds -- organic, flowing, serene. A very subtle mesh gradient behind the timer or library header would elevate the design significantly.

### 6D. No symbol effects

SF Symbols 5 (iOS 17+) supports `.symbolEffect(.breathe)`, `.symbolEffect(.pulse)`, and `.symbolEffect(.variableColor)`. The tab bar icons, routine icons, and player controls would benefit from these -- especially `.breathe` for a meditation app.

---

## 7. Localization Gaps

Several strings are hardcoded in English rather than using localization keys:
- `"Sounds"` in `TabSelection` (`.music` case)
- `"History"` in `TabSelection` (`.history` case)
- `"Settings"` header in `SettingsView`
- `"Master Volume"`, `"Appearance"`, `"Color Scheme"`, etc. in `SettingsView`
- `"System Routine"` in `CompactRoutineCard`

**Fix:** Replace with `String(localized:)` or `LocalizedStringKey` calls matching the pattern already used for Library/Timer tabs.

---

## Summary: Priority Matrix

**P0 -- Fixes that impact usability:**
- 1A: Restyle SessionHistoryView to match app theme
- 2A: Add tab bar labels
- 3A: Add accessibility labels to all interactive elements
- 3D: Fix contrast ratios

**P1 -- Design consistency and polish:**
- 1B: Replace deprecated NavigationView/navigationBarItems
- 1C: Replace hardcoded `.white` with theme colors
- 1D: Standardize typography
- 2B: Fix tab bar safe area
- 4D: Make FAB visible with accent color
- 4E: Set accent color in asset catalog

**P2 -- Delight and modern patterns:**
- 3B: Dynamic Type support
- 3C: Reduce Motion support
- 4A: More breathing room
- 4B: Animated empty state
- 4C: Richer player view
- 5A: Expand haptic coverage
- 6B-6D: ScrollTransition, MeshGradient, SymbolEffects
