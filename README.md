# Meditation Builder

A comprehensive SwiftUI app for building, managing, and playing custom meditation routines with beautiful animations and progress tracking.

## 🎯 Overview

Meditation Builder is a full-featured meditation app that allows users to create custom meditation routines, save them to a library, and play them with an immersive timer experience. The app features elegant animations, progress tracking, and a clean, modern interface designed for focus and tranquility.

## 🏗️ Project Structure

The app follows a clean, modular architecture with proper separation of concerns:

### 📁 Models
- **`MeditationModels.swift`** - Core data models:
  - `RoutineBlock` - Individual meditation blocks with types, duration, and icons
  - `BellType` - Transition sounds between blocks
  - `Routine` - Complete meditation routine structure
  - `SavedRoutine` - Persisted routine with metadata
  - `RoutineSession` - Session tracking and statistics

- **`RoutineDataManager.swift`** - Data persistence and management:
  - Core Data integration for routine storage
  - Session recording and statistics
  - Routine CRUD operations

### 🎨 Theme
- **`AppTheme.swift`** - Centralized theme management:
  - Colors (background, cards, accent, text)
  - Typography (fonts for different text styles)
  - Spacing constants and corner radius values
  - Shadow and opacity settings

### 👁️ Views

#### Main Navigation
- **`MainTabView.swift`** - Primary navigation with tab bar
- **`ContentView.swift`** - Root view coordinator

#### Core Features
- **`RoutineBuilderView.swift`** - Interface for building meditation routines
- **`RoutineLibraryView.swift`** - Browse, manage, and play saved routines
- **`RoutinePlayerView.swift`** - Immersive timer experience with progress tracking

#### Component Views
- **`TimelineBlockCard.swift`** - Individual meditation block display
- **`BlockProgressIndicator.swift`** - Animated progress indicator with traveling balls
- **`CustomTabBar.swift`** - Bottom navigation bar

#### Modal Views
- **`AddBlockView.swift`** - Add new meditation blocks
- **`EditBlockView.swift`** - Edit existing blocks
- **`BellPickerView.swift`** - Select transition bells
- **`IconPickerView.swift`** - Choose block icons

#### Development & Debugging
- **`AnimationPlaygroundView.swift`** - Animation testing and experimentation
- **`FinalAnimationFile.swift`** - Reference animation implementations
- **`LoggingSettingsView.swift`** - Debug logging configuration

### 🛠️ Utils
- **`Logger.swift`** - Comprehensive logging system with categories
- **`LOGGING_README.md`** - Logging system documentation

### 🌐 Localization
- **`Localizable.strings`** - String resources
- **`L10n.swift`** - Localization helper

## ✨ Features

### 🧘‍♀️ Meditation Block Types
- **Silence** - Quiet meditation periods
- **Breathwork** - Breathing exercises
- **Chanting** - Vocal meditation
- **Visualization** - Guided imagery
- **Body Scan** - Progressive relaxation
- **Walking** - Walking meditation
- **Custom** - User-defined blocks

### 🔔 Transition Bells
- **None** - No transition sound
- **Soft Bell** - Gentle bell sound
- **Tibetan Bowl** - Traditional bowl sound
- **Digital Chime** - Modern chime sound

### 🎮 Core Functionality
- ✅ **Routine Builder** - Create custom meditation routines
- ✅ **Drag & Drop** - Reorder blocks with smooth animations
- ✅ **Routine Library** - Save, load, and manage routines
- ✅ **Immersive Player** - Full-screen timer with progress tracking
- ✅ **Progress Animation** - Beautiful traveling ball animations
- ✅ **Session Tracking** - Record and view meditation sessions
- ✅ **Pause/Resume** - Flexible timer controls
- ✅ **Background Handling** - Automatic pause when app backgrounds

### 🎨 Animation System
- **Traveling Ball Animation** - Balls move from bottom to top as blocks complete
- **Progress Dots** - 5 dots that fill progressively during block progress
- **Spring Animations** - Smooth, natural motion with configurable bounce
- **Matched Geometry** - Seamless transitions between states
- **Timeline Integration** - Real-time progress updates

### 📊 Data Management
- **Core Data Integration** - Persistent storage for routines and sessions
- **Session Statistics** - Track meditation habits and progress
- **Routine Metadata** - Creation dates, play counts, and favorites

## 🎯 User Experience

### Routine Builder
- Intuitive drag-and-drop interface
- Real-time duration calculations
- Visual block timeline
- Custom block creation
- Bell selection for transitions

### Routine Library
- Grid layout for saved routines
- Search and filtering capabilities
- Quick play functionality
- Routine management (edit, delete, duplicate)
- Session history and statistics

### Meditation Player
- **Full-Screen Experience** - Distraction-free meditation environment
- **Progress Visualization** - Animated progress indicator with traveling balls
- **Timer Display** - Large, easy-to-read countdown
- **Block Transitions** - Smooth progression between meditation blocks
- **Pause Controls** - Easy pause/resume with session management
- **Background Handling** - Automatic pause when leaving the app

## 🎨 Design System

### Colors
- **Background**: Pure black (#000000) for OLED displays
- **Cards**: Dark gray (#2A2E37)
- **Accent**: Orange (#FF7A00)
- **Text**: White and light gray
- **Progress**: White with opacity variations

### Typography
- **Timer**: 72pt bold monospaced
- **Title**: 32pt bold rounded
- **Headline**: 17pt bold rounded
- **Body**: 15pt regular rounded
- **Button**: 20pt bold rounded
- **Caption**: 19pt semibold rounded

### Animations
- **Spring Duration**: 0.8s with 0.4 bounce
- **Progress Updates**: 0.2s ease-in-out
- **Ball Travel**: 0.8s spring animation
- **Dot Filling**: 0.2s ease-in-out

## 🏗️ Architecture Benefits

1. **Maintainability** - Each component has a single responsibility
2. **Reusability** - Components can be easily reused across the app
3. **Testability** - Individual components can be tested in isolation
4. **Scalability** - Easy to add new features and components
5. **Consistency** - Centralized theme ensures consistent styling
6. **Performance** - Efficient animations and state management
7. **User Experience** - Smooth, responsive interface with beautiful animations

## 🔧 Technical Features

### State Management
- **SwiftUI State** - Reactive UI updates
- **Core Data** - Persistent data storage
- **TimelineView** - Efficient timer updates
- **Matched Geometry** - Smooth transitions

### Animation System
- **Spring Animations** - Natural, physics-based motion
- **Progress Tracking** - Real-time visual feedback
- **Transition Effects** - Seamless state changes
- **Performance Optimized** - Efficient rendering and updates

### Logging & Debugging
- **Category-based Logging** - Organized debug output
- **Configurable Levels** - Adjustable verbosity
- **Performance Monitoring** - Track app performance
- **Error Handling** - Comprehensive error logging

## 🚀 Future Enhancements

- **Audio Integration** - Background sounds and guided meditations
- **Cloud Sync** - iCloud integration for cross-device sync
- **Social Features** - Share routines with friends
- **Advanced Analytics** - Detailed meditation insights
- **Accessibility** - VoiceOver and accessibility improvements
- **Watch Integration** - Apple Watch companion app
- **Custom Themes** - User-selectable color schemes
- **Export/Import** - Routine sharing and backup

## 📱 Platform Support

- **iOS 17.0+** - Modern iOS features and design
- **iPhone & iPad** - Universal app with adaptive layouts
- **Dark Mode** - Optimized for OLED displays
- **Accessibility** - VoiceOver and accessibility support

---

*Meditation Builder - Transform your meditation practice with custom routines and beautiful animations.* 