# Meditation Builder

A SwiftUI app for building custom meditation routines with different types of meditation blocks and transition bells.

## Project Structure

The app has been refactored into a clean, modular architecture with proper separation of concerns:

### 📁 Models
- **`MeditationModels.swift`** - Contains all data models:
  - `MeditationBlock` - Represents individual meditation blocks with types, duration, and icons
  - `TransitionBell` - Represents transition sounds between blocks
  - `Routine` - Contains the complete meditation routine
  - `IdentifiableInt` - Helper for sheet presentation

### 🎨 Theme
- **`AppTheme.swift`** - Centralized theme management:
  - Colors (background, cards, accent, text)
  - Typography (fonts for different text styles)
  - Spacing constants
  - Corner radius values
  - Shadow and opacity settings

### 👁️ Views

#### Main Views
- **`RoutineBuilderView.swift`** - Main interface for building meditation routines
- **`ContentView.swift`** - Root view that presents the routine builder

#### Component Views
- **`TimelineBlockCard.swift`** - Individual meditation block display in timeline
- **`CustomTabBar.swift`** - Bottom navigation bar

#### Modal Views
- **`AddBlockView.swift`** - Interface for adding new meditation blocks
- **`EditBlockView.swift`** - Interface for editing existing blocks
- **`BellPickerView.swift`** - Interface for selecting transition bells

## Features

### Meditation Block Types
- **Silence** - Quiet meditation periods
- **Breathwork** - Breathing exercises
- **Chanting** - Vocal meditation
- **Visualization** - Guided imagery
- **Body Scan** - Progressive relaxation
- **Walking** - Walking meditation
- **Custom** - User-defined blocks

### Transition Bells
- **None** - No transition sound
- **Soft Bell** - Gentle bell sound
- **Tibetan Bowl** - Traditional bowl sound
- **Digital Chime** - Modern chime sound

### Key Functionality
- ✅ Add/remove meditation blocks
- ✅ Edit block names and durations
- ✅ Reorder blocks via drag and drop
- ✅ Select transition bells between blocks
- ✅ Calculate total routine duration
- ✅ Search through default block types
- ✅ Create custom meditation blocks

## Design System

The app uses a consistent design system defined in `AppTheme.swift`:

### Colors
- **Background**: Dark gray (#22262D)
- **Cards**: Slightly lighter gray (#2A2E37)
- **Accent**: Orange (#FF7A00)
- **Text**: White and light gray

### Typography
- **Title**: 32pt bold rounded
- **Headline**: 17pt bold rounded
- **Body**: 15pt regular rounded
- **Button**: 20pt bold rounded
- **Caption**: 19pt semibold rounded

### Spacing
- **Small**: 8pt
- **Medium**: 16pt
- **Large**: 20pt
- **Extra Large**: 24pt
- **Section**: 32pt

## Architecture Benefits

1. **Maintainability** - Each component has a single responsibility
2. **Reusability** - Components can be easily reused across the app
3. **Testability** - Individual components can be tested in isolation
4. **Scalability** - Easy to add new features and components
5. **Consistency** - Centralized theme ensures consistent styling
6. **Readability** - Clear file organization makes code easy to navigate

## Future Enhancements

- Save/load meditation routines
- Timer functionality for running routines
- Background music/sounds
- Progress tracking
- Sharing routines
- Cloud sync
- Accessibility improvements 