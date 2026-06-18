---
dg-publish: true
---

# ✅ Day 2 Checklist – July 10, 2025

## 🎯 Objective
Polish and structure the UI so it looks and feels like a calm, elegant meditation app — with working reordering and a scalable visual pattern for transition bells.

---

## 🔧 Functional Goals
- [ ] Implement drag-and-drop reordering of blocks using `.onMove` or `.move(fromOffsets:toOffset:)`
- [ ] Keep block order updated in the view model

---

## 🎨 Design + UI Goals

### 🧩 Block UI (Routine Card)
- [ ] Use rounded card layout (`RoundedRectangle`, padding)
- [ ] Use SF Symbols for block type icons:
  - Silence → `bell.slash`
  - Breathwork → `wind`
  - Chanting → `om.symbol` (custom or use fallback icon like `waveform`)
- [ ] Use bold text for block title
- [ ] Use subtle subtext for duration (e.g., “5 min”)
- [ ] Right-side “Edit” button with SF Symbol `pencil`

### 🔁 Transition Bell UI
- [ ] Replace full-width “Tap to set transition bell” with compact layout:
  - Small bell icon (`bell.fill`)
  - Label or chevron (`chevron.right`)
  - Tappable to open bell selection modal

### ➕ Add Block
- [ ] Improve spacing and alignment in modal
- [ ] Organize blocks with icon + duration
- [ ] Split into two tabs: “Default Blocks” / “My Custom Blocks”
- [ ] Add Search Bar (placeholder OK for now)

### 🧾 Routine Summary
- [ ] Display total duration cleanly
- [ ] Make “Start Routine” button full-width and visually strong
- [ ] Add shadow or border to button for affordance

---

## 🧪 Interaction Polish
- [ ] Add swipe-to-delete (already done)
- [ ] Add haptic feedback (optional)
- [ ] Animate block addition (optional)

---

## 🌓 Visual Design Notes
- Dark mode styling (background: #111, card: `.ultraThinMaterial` or `.gray.opacity(0.1)`)
- Rounded corners: 16pt
- Padding between blocks: 12–16pt
- Button corner radius: 24pt
- Icons: SF Symbols or fallback

---

## 📱 Stretch Goals (Optional Today)
- [ ] Add transition bell preview sound
- [ ] Save/load named routine
- [ ] Start Routine preview screen (with timer)


## Current UI
![[Pasted image 20250710160225.jpg]][[Pasted image 20250710160525.jpg]]
## UI Research Again!!

![[Pasted image 20250710114130.jpg]]
![[9b990d0a9d22b62f589093ebc69d446b84224a34f576a6bba278d7e6a2d32d79.jpg]]
![[screenshot.jpg]]![[add block.jpg]]
![[ChatGPT Image Jul 10, 2025 at 05_36_56 PM.jpg]]![[ChatGPT Image Jul 10, 2025 at 04_34_23 PM-2.jpg]]![[ChatGPT Image Jul 10, 2025 at 04_34_23 PM.jpg]]![[d3ac37ae-3633-4f41-9e8a-e7eaa6f4a77b.jpg]]![[ChatGPT Image Jul 10, 2025 at 04_20_01 PM.jpg]]

## Current And Final UI (LOCKED)

![[Simulator Screenshot - iPhone 16 Pro - 2025-07-10 at 20.47.04.jpg]]![[Simulator Screenshot - iPhone 16 Pro - 2025-07-10 at 20.46.56.jpg]]![[Simulator Screenshot - iPhone 16 Pro - 2025-07-10 at 20.46.31.jpg]]![[Simulator Screenshot - iPhone 16 Pro - 2025-07-10 at 20.46.17.jpg]]