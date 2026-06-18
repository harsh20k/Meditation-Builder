---
dg-publish: true
---

```table-of-contents
title: 
style: nestedList # TOC style (nestedList|nestedOrderedList|inlineFirstLevel)
minLevel: 0 # Include headings from the specified level
maxLevel: 0 # Include headings up to the specified level
include: 
exclude: 
includeLinks: true # Make headings clickable
hideWhenEmpty: false # Hide TOC if no headings are found
debugInConsole: false # Print debug info in Obsidian console
```
# ✅ Day 16 – Wednesday, 23 July 2025

### 🎯 Today’s Mini-Sprint: Standalone Timer Launcher

- [ ] 🏗️ **Build `StandaloneTimerView` UI**  
  - Routine picker (wheel or menu) bound to `SavedRoutine` list  
  - Opening/Closing bell pickers side-by-side  
  - “Play Session” button styled as your primary pill (disabled when no routine)

- [ ] 🛠️ **Implement `StandaloneTimerViewModel`**  
  - `@Published var selectedRoutine: SavedRoutine?`  
  - `@Published var openingBell: BellSound`, `closingBell: BellSound`  
  - `func play()` that makes a copy of the routine, injects the chosen bells, and sets a `@Published var isPlaying = false` to true

- [ ] 📲 **Wire Navigation into `RoutinePlayerView`**  
  - Present the player as a `.sheet` or via a `NavigationLink` when `isPlaying` toggles  
  - Pass the modified routine and `modelContext` into the existing `RoutinePlayerView` init

- [ ] 🧪 **Quick End-to-End Smoke Test**  
  - Launch the Standalone Timer, pick a routine + bells, tap Play  
  - Confirm the full RoutinePlayer flow starts with your selected bells  
  - Verify no compile/runtime errors and console logs fire as expected

- [ ] ✏️ **Note Next Steps**  
  - Sketch out the Preview screen for tomorrow  
  - Begin mapping how block-repeat will slot into both builder & player flows