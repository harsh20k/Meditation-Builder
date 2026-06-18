---
dg-publish: true
---


# ✅ Day 5 – 1-Hour Sprint Checklist (Sunday, 13 July 2025)

### 🎯 Objective: Lay groundwork for Timer View & Engine, plus tackle one persistence bug

- [ ] 🔲 **Wireframe Timer View** (20 min)  
  - Sketch core playback screen:  
    - Current block name + icon  
    - Large countdown timer  
    - Transition-bell indicator  
    - Pause/Stop controls  
    - “Next block” preview

- [ ] 📝 **Draft Timer-Engine Pseudocode** (20 min)  
  - Outline sequence:  
    1. Play `openingBell`  
    2. For each block → play `blockStartBell` → wait `duration`  
    3. Play `closingBell`  
  - Note edge cases: pause/resume, backgrounding, app quit

- [ ] 🐞 **Triage Persistence Bug** (20 min)  
  - Reproduce most pressing save/load issue in debugger  
  - Add a quick test or breakpoint  
  - Fix the root cause so routine data is reliably persisted and loaded

## Timer View Sketch

![[IMG_0131 2.jpg]]

![[Pasted image 20250714102149.jpg]]