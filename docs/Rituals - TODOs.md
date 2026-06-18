---
dg-publish: true
---


### List of things to change


- [x] Change Tab Bar, not floating.
	- [x] tab bar should be visible in RitualPageview/ global tab bar
- [x] Ritual page navigation -> stack navigation

- [x] 8 point grid sturcture. (library view/ritualpage)

- [x] Pinned ritual look.
- [ ] d
- [ ] New Routine in navigation maybe...cha
	- [ ] Responsive floating button.
	- [ ] routine name editable indication. 
	- [ ] routine name editing save button should be fixed. 
- [ ] d

- [ ] d
- [ ] Icon selector - look 
- [x] timer view different states not required. 
      We have now SYSTEM ROUTINES!!!
- [x] Now just build scrollview to scroll through the routines. 

- [x] Remove Linked mentions from obsidian.
- [ ] Data backup plan (Session Data is precious)

- [x] UI builderviewcard time belo icon 3 m

- [x] RoutineBuilder - not sheet but navigation. 





1. ~~**Block-Repeat Support**~~  
2. ~~**Read-Only Ritual Preview**~~  
3. ~~**Pinned Rituals (Favorites)**~~  
4. **UI Polish & Micro-Interactions**  
   - Snap-to-center carousel for pinned rituals  
   - Ease-in/out animations on previews, beads indicator, expand/collapse  
   - Final alignment to your 8-pt grid and rounded-corner design language  


> [!success] MVP
> 1. **Routine Creation & Editing**
>   - Create, name and delete “Rituals” (routines)  
>   - Add, remove and reorder blocks via drag-and-drop  
 >  - Set block duration and repeat count (×N)  
 >  - Choose a transition bell for each block  
>2. **Ritual Preview**  
>   - Read-only vertical timeline of any Ritual  
>   - Displays block icons, names, durations, repeat counts and bell markers  
>   - ▶️ Play button placeholder  
>3. **Standalone Timer Launcher**  
 >  - Pick a Ritual from your library  
  > - Swap opening and closing bell sounds on the fly  
   >- Launch the full player flow with a single “Play Session” tap  
>4. **Player & Audio Engine**  
 >  - Runs through each block (including repeats) with accurate timing  
  > - AVAudioEngine-driven bell scheduling (opening, transition, closing)  
  > - “Beads” progress indicator visualizing block and in-block progress  
  > - Pause/resume and clean session finish controls  
>5. **Session Logging & History**  
 >  - Record start, pause, resume and finish events for each session  
  > - Persist detailed block-by-block performance data  
  > - “Recent Sessions” list showing date, duration and completion rate  
 >  - Session Details view with per-block actual vs planned times 
>6. **Pinned Rituals**  
 >  - Star (pin) your favorite Rituals in the Library  
 >  - Snap-to-center carousel (or top-of-list) display of pinned items  
>7. **Persistence & UX Polish**  
 >  - SwiftData-backed save/load for all Rituals and Sessions  
 >  - Consistent 8-pt grid, rounded-corner design language  
 >  - Subtle ease-in/out and spring animations on carousels, buttons and transitions  
