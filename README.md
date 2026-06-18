# Meditation Builder

A SwiftUI meditation app for iOS that lets you build, manage, and play custom meditation routines.

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16.4+ |
| iOS Deployment Target | 18.5 |
| Swift | 5 (Swift 6 concurrency patterns, `@Observable`) |

---

## Building

1. Open `Meditation Builder.xcodeproj` in Xcode.
2. Select your simulator or device (iPhone, iOS 18.5+).
3. Build and run (`⌘R`).

No additional configuration is required. There are no third-party dependencies — the project uses only Apple frameworks.

---

## Architecture

### Tech Stack

| Layer | Choice |
|-------|--------|
| UI | SwiftUI |
| Persistence | SwiftData (`VersionedSchema`, `SchemaMigrationPlan`) |
| State management | `@Observable` macro (Swift 6 patterns) |
| Audio | AVFoundation (`AVAudioEngine`, `AVAudioPlayerNode`) |
| Drag-and-drop | Native SwiftUI `draggable`/`dropDestination` |

### Key Patterns

- **Dual model approach:** Value types (`Routine`, `RoutineBlock`) for in-memory editing; SwiftData models (`SavedRoutine`, `MeditationBlock`) for persistence.
- **Event-based session tracking:** `SessionRecord` records `.start`, `.pause`, `.resume`, `.finish` events. `RoutineDataManager.completeSession(using:routine:)` reconstructs per-block logs from the event timeline.
- **Soft delete:** Routines are soft-deleted (`isDeleted`, `deletedAt`). Session history is preserved. Hard-delete is available via `permanentlyDeleteRoutine`.
- **Singleton data manager:** `RoutineDataManager.shared` is the only entry point to the `ModelContext`. Never create additional `ModelContainer` instances.
- **Background audio:** `AVAudioSession` is configured with `.playback` category. Both `AuditoriumEngine` (bells) and `AmbientSoundEngine` (ambient sounds) handle interruption and route-change notifications.

---

## Project Structure

```
Meditation Builder/
├── Meditation_BuilderApp.swift        # App entry, ModelContainer, SchemaVersioning
├── ContentView.swift
│
├── Models/
│   ├── RoutineModels.swift            # SavedRoutine, MeditationBlock, Routine, RoutineBlock, Theme
│   ├── SessionModels.swift            # MeditationSession, SessionBlockRecord, SessionRecord, RoutinePlayerViewModel
│   ├── ContentTypes.swift             # BellSound, MediaResource, BlockContentType
│   ├── RoutineDataManager.swift       # Singleton data manager (CRUD, session completion, statistics)
│   ├── AmbientSoundEngine.swift       # Multi-track ambient audio mixer
│   ├── NotificationManager.swift      # Daily reminder scheduling (UNUserNotificationCenter)
│   └── SchemaVersioning.swift         # SchemaV1, MeditationMigrationPlan
│
├── Views/
│   ├── MainTabView.swift              # Root tab container
│   ├── RoutineLibraryView.swift       # Library tab
│   ├── RitualPageView.swift           # Routine detail screen
│   ├── RoutineBuilderView.swift       # Create/edit routine
│   ├── RoutinePlayerView.swift        # Meditation player (timer, bells)
│   ├── RoutinePlayerSelectionView.swift
│   ├── SessionHistoryView.swift       # History tab
│   ├── SessionStatisticsView.swift    # Aggregate stats
│   ├── AmbientSoundMixerView.swift    # Sounds tab (ambient mixer)
│   ├── SettingsView.swift             # Settings tab
│   ├── AddBlockView.swift
│   ├── EditBlockView.swift
│   ├── BellPickerView.swift
│   ├── IconPickerView.swift
│   ├── Components/
│   │   ├── CustomTabBar.swift         # Tab bar + TabSelection enum
│   │   ├── AuditoriumManager.swift    # Bell engine (class: AuditoriumEngine)
│   │   └── ...
│   └── Playground/                    # DEBUG-only: AnimationPlayground, AudioTest, LoggingSettings
│
├── Theme/
│   └── AppTheme.swift                 # Colors, typography, spacing, corner radii
│
├── Utils/
│   └── Logger.swift                   # AppLogger (@Observable), global `logger` shorthand
│
└── Localization/
    ├── L10n.swift
    └── Localizable.strings

Audio/                                 # Bell MP3 assets (opening_bell, soft_bell, etc.)
```

---

## Tabs

| Tab | Icon | View | Description |
|-----|------|------|-------------|
| Library | `books.vertical.fill` | `RoutineLibraryView` | Browse, search, create, favorite routines |
| Sounds | `waveform` | `AmbientSoundMixerView` | Layered ambient sound mixer |
| Timer | `timer` | `RoutinePlayerView` | Start a meditation session |
| History | `clock.arrow.circlepath` | `SessionHistoryView` | Past sessions and statistics |
| Settings | `gearshape` | `SettingsView` | Appearance, notifications, data, about |

---

## Data Models (SwiftData)

All models are registered in `SchemaV1` inside `SchemaVersioning.swift`. When you change any model, bump to `SchemaV2` with an appropriate `MigrationStage`.

| Model | Purpose |
|-------|---------|
| `SavedRoutine` | Persisted routine (name, icon, blocks, play count) |
| `MeditationBlock` | Persisted block within a routine |
| `MediaResource` | Media attached to a block |
| `MeditationSession` | Completed session record |
| `SessionBlockRecord` | Per-block timing within a session |
| `Theme` | Optional theme tag for routines/blocks |

---

## Audio

Bell assets live in the top-level `Audio/` folder. The `AuditoriumEngine` preloads them at init. Ambient loops should be placed in `Audio/ambient/` as MP3 files named per `AmbientSound.catalog` in `AmbientSoundEngine.swift`.

---

## Documentation

| Doc | Description |
|-----|-------------|
| [docs/CUSTOMER_PROBLEM_ANALYSIS.md](docs/CUSTOMER_PROBLEM_ANALYSIS.md) | Customer definition, root cause analysis, and industry retention/engagement benchmarks |

---

## Logging

`AppLogger.shared` (accessible as `logger`) writes to:
- `os.log` (visible in Console.app)
- A rolling file in `Documents/Logs/` (max 5 MB, 10 files)

The **Developer** section inside Settings exposes the logger controls in debug builds.

---

## Adding a New SwiftData Schema Version

1. Duplicate the model type changes into a new `SchemaV2` enum in `SchemaVersioning.swift`.
2. Add a `MigrationStage` (`.lightweight` for additive changes, custom for transformations).
3. Append `SchemaV2` to `MeditationMigrationPlan.schemas`.
4. Update `SchemaV1.models` → `SchemaV2.models` in `Meditation_BuilderApp.swift`.
