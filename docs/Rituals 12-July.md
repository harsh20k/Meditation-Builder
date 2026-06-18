---
dg-publish: true
---



```table-of-contents
```


# ✅ Day 4 – Light Weekend Tasks (Saturday, 12 July 2025)

### 1. Define & Create Sample Routine Presets  
- [ ] Draft 3–5 realistic routines (e.g. “Morning Calm – 15 min”, “Sleep Wind-Down – 10 min”)  
- [ ] For each, list block sequence, durations, and opening/closing bells  
- [ ] Add them as hard-coded data in your project for quick manual testing  ₹

### 2. Gather Bell Sound Metadata  
- [ ] Assemble a simple spreadsheet or JSON of all `BellSound` options:  
  - [ ] `soundName` (filename)  
  - [ ] `displayName`  
  - [ ] Approximate duration (e.g. 2 sec)  
- [ ] This will speed up wiring up real audio later  

### 3. Sketch or Wireframe the Timer View  
- [ ] On paper or in Figma/Notion, outline how the **Playback Screen** will look:  
  - [ ] Current block name + icon  
  - [ ] Countdown timer  
  - [ ] Bell feedback UI  
  - [ ] Pause/Stop controls  
- [ ] Keep it high-level; you’ll refer to it when you build the timer engine next week  

---

🔄 **Bonus (if you have 30 min):**  
- Tidy up your Xcode folder structure (group screens, models, assets)  
- Write a short **README** stub describing the app’s purpose and next steps  

Enjoy your weekend and recharge—by Monday you’ll be set to tackle Save/Load and the timer engine with fresh energy!
---

# 🧘‍♂️ Meditation Routine App – Data Model (v1.0)

## 🧩 1. MeditationBlock

Represents a single meditation segment (e.g., silence, chanting, breathwork).

```swift
struct MeditationBlock: Identifiable, Equatable {
    var id: UUID
    var name: String
    var durationInMinutes: Int
    var type: BlockType
}

enum BlockType: String, Codable, CaseIterable {
    case silence
    case breathwork
    case chanting
    case visualization
    case bodyScan
    case walking
    case custom
}
```

---

## 🔔 2. BellSound

Represents a bell/chime to be played.

```swift
struct BellSound: Equatable, Codable {
    var soundName: String     // identifier for audio file
    var displayName: String   // user-facing name (e.g., “Tibetan Bowl”)
}
```

---

## 🧱 3. RoutineBlock

Encapsulates a block with its start bell.

```swift
struct RoutineBlock: Identifiable, Equatable {
    var id: UUID
    var block: MeditationBlock
    var blockStartBell: BellSound  // plays BEFORE the block (ignored for first block)
}
```

---

## 🧘‍♀️ 4. Routine

Represents a full meditation routine.

```swift
struct Routine: Identifiable, Equatable {
    var id: UUID
    var name: String
    var openingBell: BellSound     // plays once at the beginning
    var closingBell: BellSound     // plays once at the end
    var blocks: [RoutineBlock]     // ordered sequence of blocks
}
```

---

## 💾 5. SavedRoutine

Wraps a routine with metadata for persistent storage.

```swift
struct SavedRoutine: Identifiable, Equatable {
    var id: UUID
    var routine: Routine
    var createdAt: Date
    var lastModified: Date
}
```

---

## 🛠 6. UI Helper Models

```swift
struct IdentifiableInt: Identifiable {
    let id = UUID()
    var value: Int
}
```

---

## 🔁 Playback Flow Summary

```text
1. Play openingBell
2. For each block in routine.blocks:
    - If NOT first block → play block.blockStartBell
    - Play MeditationBlock for duration
3. Play closingBell
```


---
# Bell sound assets

> [!Links] Title
> https://samplefocus.com/samples/large-bell-with-deep-hall-reverb
> https://samplefocus.com/users/atle-aamodt
> https://samplefocus.com/samples/bell-hit-rise-fall-long
