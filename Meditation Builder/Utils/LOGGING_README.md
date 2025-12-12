# Logging System Documentation

## Overview

The Meditation Builder app includes a comprehensive centralized logging system that provides:

- **Multiple log levels**: DEBUG, INFO, WARNING, ERROR, CRITICAL
- **File persistence**: Logs are automatically saved to daily log files
- **Automatic rotation**: Log files are rotated when they reach 5MB
- **Log management**: Built-in log viewer and cleanup functionality
- **Crashlytics integration**: Optional integration for crash reporting

## Architecture

### Core Components

1. **AppLogger** (`Utils/Logger.swift`): Main logging singleton
2. **LoggingSettingsView** (`Views/LoggingSettingsView.swift`): Settings UI
3. **LogViewerView**: Built-in log viewer
4. **Global logger instance**: `logger` for easy access

### Log Levels

- **DEBUG** 🔍: Detailed debugging information (only in debug builds)
- **INFO** ℹ️: General information about app operations
- **WARNING** ⚠️: Potential issues that don't prevent operation
- **ERROR** ❌: Errors that affect functionality
- **CRITICAL** 🚨: Critical errors that may cause app crashes

## Usage

### Basic Logging

```swift
import os.log

// Simple logging
logger.info("User tapped play button", category: "UserAction")
logger.error("Failed to save routine", category: "Data")

// With error objects
logger.error(someError, context: "Saving routine", category: "Data")

// Debug logging (only in debug builds)
logger.debug("Routine has \(blocks.count) blocks", category: "RoutineBuilder")
```

### Categories

Use categories to organize logs by functionality:

- `AppLifecycle`: App launch, background, foreground events
- `Navigation`: Tab changes, view transitions
- `UserAction`: Button taps, user interactions
- `Data`: Database operations, data persistence
- `RoutineBuilder`: Routine creation and editing
- `RoutineLibrary`: Routine management and playback
- `Settings`: User preference changes
- `System`: System-level events and errors

### File Management

Logs are automatically managed:

- **Location**: `Documents/Logs/meditation-builder-YYYY-MM-DD.log`
- **Rotation**: Files rotate when they reach 5MB
- **Retention**: Only 10 most recent log files are kept
- **Cleanup**: Automatic cleanup of old files

## Integration Points

### App Lifecycle

The logging system is integrated into:

- App launch and termination
- Scene phase changes (active/inactive/background)
- SwiftData container creation and errors
- Sample data initialization

### User Workflows

All major user actions are logged:

- Routine creation, editing, and deletion
- Block addition and modification
- Routine playback
- Settings changes
- Navigation between tabs

### Data Operations

Database operations are comprehensively logged:

- CRUD operations on routines
- Play count recording
- Sample data initialization
- Error handling and recovery

## Settings

Users can access logging settings via the Settings tab:

- **Enable/Disable Logging**: Toggle logging on/off
- **Log Level**: Set minimum log level to record
- **View Recent Logs**: Access built-in log viewer
- **Clear All Logs**: Remove all log files

## Debug vs Release

- **Debug builds**: All log levels are available and printed to console
- **Release builds**: DEBUG logs are automatically filtered out
- **File logging**: Works in both debug and release builds

## Crashlytics Integration

When Firebase Crashlytics is available:

```swift
// Send recent logs to Crashlytics for post-mortem analysis
logger.sendToCrashlytics()
```

This automatically includes recent log entries in crash reports.

## Best Practices

1. **Use appropriate log levels**: Don't use ERROR for normal operations
2. **Include context**: Provide meaningful category and context information
3. **Avoid sensitive data**: Never log passwords, tokens, or personal information
4. **Use categories**: Organize logs by functionality for easier debugging
5. **Include relevant data**: Log relevant IDs, counts, and state information

## Example Log Output

```
ℹ️ [2025-01-09 14:30:15.123] [INFO] [AppLifecycle] [Meditation_BuilderApp.swift:25] handleScenePhaseChange(): App became active
ℹ️ [2025-01-09 14:30:20.456] [INFO] [Navigation] [MainTabView.swift:45] onChange(): Tab changed to: library
ℹ️ [2025-01-09 14:30:25.789] [INFO] [RoutineLibrary] [RoutineLibraryView.swift:155] recordPlay(): Starting routine playback: Morning Meditation
🔍 [2025-01-09 14:30:25.790] [DEBUG] [RoutineLibrary] [RoutineLibraryView.swift:165] logRoutineBlocks(): Playing routine 'Morning Meditation'
```

## Troubleshooting

### Common Issues

1. **Logs not appearing**: Check if logging is enabled in settings
2. **Missing debug logs**: Ensure running in debug build
3. **Large log files**: Check for excessive logging in loops
4. **Permission errors**: Ensure app has file system access

### Performance Considerations

- Logging is asynchronous and doesn't block the UI
- File operations are performed on background queues
- Log rotation happens automatically without user intervention
- Debug logs are automatically filtered in release builds 