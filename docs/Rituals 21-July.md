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
# ✅ Day 14 – Monday, 21 July 2025

### 🎯 Today’s Focus: Solidify Audio Engine & Deepen Timer Understanding

- [x] 📚 **Study AVAudioEngine Scheduling**  
  - Read Apple’s “Scheduling Playback” section in the Audio Programming Guide  
  - Note how hostTime, sampleRate, and buffer vs. file scheduling differ  

- [x] 💡 **Build Mini Audio Engine Prototype**  
  - Create a lightweight SwiftUI view that lets you pick one of your bell sounds and a delay (e.g. 5, 10, 15 s)  
  - Use `AVAudioEngine` + `AVAudioPlayerNode` to schedule and play that sound after the chosen delay  
  - Log engine hostTime vs. file scheduling time to confirm alignment  

- [x] ⏱ **Review & Sketch Timer Engine Flow**  
  - Map out in sequence form how your timer drives block transitions:  
    1. User taps “Play” → record start timestamp  
    2. Deadline calculation: current block end = now + blockDuration – pausedTime  
    3. SwiftUI timer (e.g. `TimelineView` or `Timer.publish`) ticks every second → updates remaining time  
    4. When remaining ≤ 0 → trigger bell + advance to next block, recalc deadline  
  - Identify any edge cases (background, app sleep, clock drift)

[Flowchart](https://kroki.io/mermaid/svg/eNptU81u2zAMvvcpeOlu7ZrtOGxDftombZKlbjJsEIJCsTlHqCMZkpx0iAf0QbaX65NUouTEw5aDEZIfP5IfqR-F2qVrri3MByfgfl32VeAOumWJXJslnJ19qpUMZg09ZqwDz8UG9ZLwPY-AfvD3K61R2l6h0scQpo-pVrnm5RpmBf-54ukjjJUqKQSQCY2pFUrCvBddfeIcMF-mEBKpIytcXsdguoyoAaEuWVVm3GIs7VMawCUBrvbCzHhlMPv8KwauaKrvaGq4ZqWPtQZqwlNVw3AvJA0z0yrXaAy8KewH6JxfNFTDI1Uz3ENruOGBasQ2aotzNcWntj4AI-ryZp-2tBvJDJ9CLassL8hpDv3fHIv2_3L5QrdMmERV1unWV5uyQIvwEayuoi4osxP6c3oKNHtG0howVhQFBDVhMYJVZUEqWPnaLp9LI_yaDCVfhxUFplsyxux-rXbw8vz73inlF9rUf3n-4whD-TFhJ_uFQQ2Wl8YnDJQk0FtvJEi3dLBp-wO0XBTGOaMKExrYJ9YwZW6oWPTB8C0261pCCxt5a_jyzxFHslDDbZJJvhW518EqiMQx6rsJSVOa5I45vfiES56jPk_jxE0zlREyTzBVOou93FFWwjJhNsIdVOBrFkKqCGlR8_Qo9uH9ULjbirSfzziJrkWHzXkJdPThAVuV5wWSw518A3tHMCdLtfkfrjmtxXvCuU18c_IH4FHvGpLmrF4BmFhc6A)

![[mermaid-diagram-2025-07-21-174123-1.jpg]]


- [x] 🛠 **Integrate Audio & Timer Engines**  
  - In your `RoutinePlayerView`, hook your new `AudioTester`/`BellScheduler` prototype into the real block loop  
  - Verify that each block transition fires exactly when the timer reaches zero  

- [x] 🔄 **End–of–Day Demo**  
  - Record a short screen capture or app run showing a 3-block routine with real bells at each transition  

---

# 📅 High-Level Timeline to MVP

| Week | Dates            | Goals                                                                                  | Status                     |
|------|------------------|----------------------------------------------------------------------------------------|----------------------------|
| 1    | 30 Jun – 6 Jul   | RoutineBuilder UI, drag-drop blocks, two themes, tab bar                               | ✅ Complete                |
| 2    | 7 Jul – 13 Jul   | Persistence (SwiftData), Timer UI, Deferred session logging                            | ✅ Complete                |
| 3    | 14 Jul – 20 Jul  | Completion screen, Session logging edge cases, Real bell scheduling via AVEngine       | 🔄 In progress (audio engine) |
| 4    | 21 Jul – 27 Jul  | Finalize Audio Engine & Timer Engine integration, Recent Sessions list, basic analytics| 🔄 Today’s focus           |
| 5    | 28 Jul – 3 Aug   | UI polish & animations, onboarding flow, multi-lingual prep, TestFlight beta setup     | Pending                    |
| 6    | 4 Aug – 10 Aug   | Beta feedback iteration, crash-safety, performance tuning, App Store submission prep   | Pending                    |

By the end of Week 4 (27 July), you’ll have a fully wired core loop (build → play with real bells → record → review). Weeks 5–6 cover polish, onboarding, and beta prep toward an early-August App Store release.  