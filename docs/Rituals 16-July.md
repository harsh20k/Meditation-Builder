---
dg-publish: true
---
# ✅ Day 10 – Next Steps (Wednesday, 15 July 2025)

- [ ] 🔄 **Replace auto-dismiss with Completion Screen**  
  - On routine end show a “Session Complete” overlay or summary view with:  
    - Total meditation time  
    - Buttons: “Done” (back to library), “Restart Routine”, “View Session Details”

- [ ] 📊 **Implement Session Logging**  
  - On Play → create a `MeditationSession` (start timestamp, routine ID)  
  - For each block start/end or skip → append/update a `BlockLog` (durations, timestamps, skipped flag)  
  - On completion/discard → set `endedAt`, calculate `totalDuration`, save session  

- [ ] 🔔 **Wire Up Real Bell Playback**  
  - Add actual bell audio files to the bundle (e.g. MP3/WAV)  
  - In your timer engine, trigger the appropriate sound for `openingBell`, each `blockStartBell`, and `closingBell`  
  - Test reliable playback between blocks and at start/end  