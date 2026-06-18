---
dg-publish: true
---

# ✅ Day 3 – Meditation App Dev (Friday, 11 July 2025)

### 🎯 Mission: Move from UI prototype → functional product

---

## 🔧 Critical Tasks

- [ ] **🧱 Implement block reordering**
  - [x] Use drag & drop (`.onMove` or gesture)
  - [x] Ensure data model updates correctly
  - [ ] ~~**Confirm transition bell order is preserved~~**

- [ ] ~~💾 Implement Save & Load logic~~
  - [ ] ~~Store routine data in UserDefaults or local file~~
  - [ ] ~~Include: block order, names, durations, transition bells~~
  - [ ] ~~Load routine on app launch~~

- [ ] ~~⏱️ Build first version of timer engine~~
  - [ ] ~~Sequentially execute each block for its duration~~
  - [ ] ~~Log or test transition bells between blocks~~
  - [ ] ~~Keep it simple (no animations or sounds yet)~~

---

## 🔄 End of Day Check
- [ ] Can I reorder and persist a full routine?
- [ ] Does the routine play through with correct timings?
- [ ] Is this the **first time my app actually “functions”?** 🎉

---

# 🧘‍♂️ Meditation App – App Flow Structure

## 🏠 Home: Routine Library (Main Tab)
- 📋 List of saved routines
    - 🪷 [Routine Name]
        - ⏱ Duration: X min
        - ▶️ Play Routine
        - ✏️ Edit Routine
- ➕ Create New Routine
- 🔍 (Optional) Search / Filter
- 🗓 (Optional Future) Schedule / Reminders

---

## ✏️ Routine Builder (Editor Screen)
> Accessed via "Edit" or "Create New"

- 🔳 Stack of meditation blocks (Silence, Chanting, etc.)
    - Drag to reorder
    - Tap to edit name/duration
    - Tap bell icon to set transition sound
- ➕ Add Block
- 💾 Save Routine
- ❌ Discard / Cancel / Duplicate

---

## ⏱ Routine Player (Timer View)
> Accessed via "Play" from Library

- 🪷 Display current block (Name + Icon)
- 🔔 Plays transition bells
- ⏳ Countdown timer
- 🛑 Pause / Stop buttons
- 🎵 (Optional Future) Sound / Voice overlay
- 📿 (Optional Future) Visual mantra animation

---

## ⚙️ Other Tabs (Navigation Bar)
- 🏠 Library (default)
- ⏱ Timer (center icon or shortcut)
- ✏️ Builder (optional direct access)
- 👤 Profile or Stats (optional)
- ⚙️ Settings

---

## 🗂 Routine Data Model (Simplified)
- ID
- Name
- Blocks: [ {name, type, duration, bell} ]
- CreatedAt / ModifiedAt