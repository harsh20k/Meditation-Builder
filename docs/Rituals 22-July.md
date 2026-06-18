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
# ✅ Day 15 (updated) – Tuesday, 22 July 2025

### 🎯 Today’s Focus: Critical MVP Screens & Block-Repeat Support

- [ ] 🕹️ **Standalone Timer View**  
  - Design & implement a “Quick Timer” screen that lets the user:  
    - Pick a routine from a picker or carousel  
    - Swap opening/closing bells on-the-fly  
    - Hit Play to launch the same timer UI you already have  
  - Reuse your existing `RoutinePlayerView` components where possible.

- [ ] 👁️ **Routine Preview Screen**  
  - Build a read-only version of your RoutineBuilder (no edit handles) that:  
    - Renders the vertical block stack with icons, names, durations  
    - Shows repeat counts (see below) and transition-bell markers  
    - Has a ▶ Play button at the bottom  

- [ ] 🔁 **Block Repeat Count**  
  - Extend your `RoutineBlock`/`SavedRoutine` model to include `repeatCount: Int` (default = 1)  
  - Update the builder UI so each block has a “×N” selector (stepper or text + “+”/“–”)  
  - In your playback logic, loop each block N times before moving on  

- [ ] 🔄 **Wire New Features into MVP Flow**  
  - Add a “Quick Timer” tab or modal entry point in your tab bar  
  - Link the Routine Preview from both the Library and the Builder screens  
  - Verify end-to-end: build routine → preview → play → bells → record → review

---

# 📅 Updated High-Level MVP Timeline

| Week | Dates          | Goals                                                                                              | Status         |
| ---- | -------------- | -------------------------------------------------------------------------------------------------- | -------------- |
| 1    | 30 Jun– 6 Jul  | RoutineBuilder UI, drag-drop, custom block types, tab bar                                          | ✅ Complete     |
| 2    | 7 Jul– 13 Jul  | Persistence (SwiftData), Timer UI, Deferred session logging                                        | ✅ Complete     |
| 3    | 14 Jul– 20 Jul | Completion screen, Session logging edge cases, AudioEngine & BellScheduler                         | 🔄 In progress |
| 4    | 21 Jul– 27 Jul | **Standalone Timer** & **Preview** screens; **Block-Repeat**; UI polish; Session Details & Sharing | ⏳ This week    |
| 5    | 28 Jul– 3 Aug  | Onboarding flow, basic analytics/dashboard, localization prep, TestFlight                          | Pending        |
| 6    | 4 Aug– 10 Aug  | Beta feedback iteration, performance tuning, App Store submission prep                             | Pending        |

By focusing this week on the two new screens and block-repeat support, you’ll lock in all of your core flows and be ready to layer on onboarding, analytics, and polish in Weeks 5–6.