---
dg-publish: true
---

# ✅ Day 13 – Saturday, 19 July 2025 (Light Weekend Focus)

### 🎯 Objective: Deepen your understanding of the Audio Engine & Timer Engine

- [ ] 📚 **Read Apple’s AVAudioEngine Guide**  
  - Skim the “Audio Playback” and “Scheduling” chapters in the *Audio Programming Guide*  
  - Note key concepts: hostTime, node connections, buffer vs file scheduling

- [ ] 📝 **Draft high-level sequence diagrams**  
  - **Audio Engine**: App start → configure AVAudioSession → attach/connect nodes → schedule files → play/pause/resume → stop  
  - **Timer Engine**: Play → compute endTimestamp → TimelineView ticks → onTick calculate remainingTime → block boundary detection → completion

- [ ] 💻 **Create two minimal Swift playgrounds**  
  - **Audio Playground**: Initialize AVAudioEngine + AVAudioPlayerNode, load one bell file, schedule it in 3 seconds, and verify playback  
  - **Timer Playground**: Use `TimelineView` to display a 30-second countdown driven purely by a `Date + TimeInterval` deadline

- [ ] ✍️ **Write a one-page spec**  
  - Compare and contrast the two engines: threading model, battery impact, lifecycle hooks, edge-case behaviors (background/foreground)  
  - Identify any gaps or questions you’ll need to address when coding Monday

> 🔄 These quick, focused exercises will give you the confidence to tackle implementation next week, without burning out your weekend. Enjoy!  

![[Pasted image 20250719203822-1.jpg]]

## Database Design

### Relationships

1. **SavedRoutine 1—* MeditationBlock**: One saved routine contains many blocks.
2. **MeditationBlock 1—* MediaResource**: Each block can have multiple media assets.
3. **SavedRoutine 1—* MediaResource**: Routines can also have routine-level media.
4. **MeditationSession 1—* SessionBlockRecord**: One session logs many block records.
5. **SessionRecord 1—* SessionEvent**: Deferred sessions store a sequence of events.
6. **Value-types (Routine, RoutineBlock, MediaInfo)** mirror the persistent models for in-memory editing.


![[mermaid-diagram-2025-07-19-125814-1.jpg]]

![[mermaid-diagram-2025-07-19-125338-1.jpg]]