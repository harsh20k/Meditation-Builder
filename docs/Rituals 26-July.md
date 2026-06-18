---
dg-publish: true
---

# ✅ Day 19 – Saturday, 26 July 2025

### 🎯 Today’s Mini-Sprint: Timer Launcher

- [ ] **Finish Standalone Timer Launcher**  
  - Complete the routine picker UI and opening/closing bell pickers.  
  - Wire the Play button to present `RoutinePlayerView` with the selected routine + bells.  
  - Run an end-to-end smoke test to confirm the full play flow launches correctly.

---

### 🛠️ Optional (If You Have Extra Cycles)

- [ ] **Implement Block-Repeat in Builder**  
  - Add a `repeatCount: Int` property to your `RoutineBlock` (and persist it in `SavedRoutine`).  
  - In the RoutineBuilder list, display the current repeat (“×1”) and add a stepper (“–” / “+”) to adjust it.  
  - Ensure your drag-and-drop and playback logic honor the repeat count (i.e. block runs N times).

- [ ] **Kick-off Read-Only Routine Preview**  
  - Create a new SwiftUI view (`RoutinePreviewView`) that takes a `SavedRoutine` (or `Routine`) and renders:  
    - Vertical timeline of blocks (icon, name, duration, ×N)  
    - Transition-bell markers between blocks  
    - A ▶️ Play button at the bottom (stub for now)

- [ ] **Stub Share/Export**  
  - Add an “Export” button on your Library screen.  
  - Implement a basic JSON encoder for `Routine` and simply `print` it (or present a share-sheet placeholder).