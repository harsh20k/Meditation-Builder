//
//  RoutineDataManager.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

     // In RoutineDataManager.swift
     /// ⚠️ CRITICAL: DO NOT CREATE NEW MODEL CONTAINERS
     /// This is the single source of truth for data persistence
     /// Creating new containers will cause data loss
     /// 
     /// Always use:
     /// @Environment(\.modelContext) or
     /// RoutineDataManager.shared

   /// ModelContainer Safety Guidelines:
   /// 1. NEVER create new ModelContainer instances at runtime
   /// 2. ALWAYS use @Environment(\.modelContext)
   /// 3. ALWAYS use RoutineDataManager.shared
   /// 4. Container creation is restricted to app initialization
   ///
   /// ⚠️ Violation will cause:
   /// - Data truncation
   /// - Schema conflicts
   /// - Permanent data loss

import Foundation
import SwiftData
import SwiftUI
import Observation
import os.log

@MainActor
@Observable
class RoutineDataManager {
    // MARK: - Singleton
    static let shared = RoutineDataManager()
    
    private var context: ModelContext?
    
    // MARK: - Debug Configuration
    #if DEBUG
    private let isDebugMode = false
    #endif
    
    private init() {}
    
    func configure(with context: ModelContext) {
        self.context = context
    }
    
    private var safeContext: ModelContext {
        guard let context = context else {
            fatalError("RoutineDataManager not configured with ModelContext")
        }
        return context
    }
    
    // MARK: - CRUD Operations
    
    /// Save a new routine
    func saveRoutine(_ routine: Routine, name: String? = nil) throws {
        logger.info("Saving routine: \(routine.name)", category: "Routine")
        
        var routineToSave = routine
        if let name = name {
            routineToSave.name = name
            logger.debug("Routine name overridden to: \(name)", category: "Routine")
        }
        
        let savedRoutine = SavedRoutine(
            routine: routineToSave
        )
        
        safeContext.insert(savedRoutine)
        try safeContext.save()
        
        logger.info("Routine saved successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    
    /// Update an existing routine
    func updateRoutine(_ savedRoutine: SavedRoutine, with routine: Routine) throws {
        logger.info("Updating routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.updateFromRoutine(routine)
        savedRoutine.version += 1
        
        try safeContext.save()
        
        logger.info("Routine updated successfully: \(savedRoutine.routineName) (version: \(savedRoutine.version))", category: "Routine")
    }
    
    // MARK: - Favorite Management
    
    /// Set a routine as favorite
    func setRoutineFavorite(_ routine: SavedRoutine) throws {
        logger.info("Setting routine as favorite: \(routine.routineName)", category: "Routine")
        
        routine.isFavorite = true
        try safeContext.save()
        
        logger.info("Routine marked as favorite successfully", category: "Routine")
    }
    
    /// Unset a routine's favorite status
    func unsetRoutineFavorite(_ routine: SavedRoutine) throws {
        logger.info("Unsetting routine favorite: \(routine.routineName)", category: "Routine")
        
        routine.isFavorite = false
        try safeContext.save()
        
        logger.info("Routine favorite status removed successfully", category: "Routine")
    }
    
    /// Set a meditation block as favorite
    func setBlockFavorite(_ block: MeditationBlock) throws {
        logger.info("Setting block as favorite: \(block.name)", category: "Block")
        
        block.isFavorite = true
        try safeContext.save()
        
        logger.info("Block marked as favorite successfully", category: "Block")
    }
    
    /// Unset a meditation block's favorite status
    func unsetBlockFavorite(_ block: MeditationBlock) throws {
        logger.info("Unsetting block favorite: \(block.name)", category: "Block")
        
        block.isFavorite = false
        try safeContext.save()
        
        logger.info("Block favorite status removed successfully", category: "Block")
    }
    
    /// Delete a routine (soft delete - preserves session data)
    func deleteRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Soft deleting routine: \(savedRoutine.routineName)", category: "Routine")
        
        // Clear favorite status when soft deleting
        savedRoutine.isFavorite = false
        
        // Soft delete - mark as deleted but keep in database
        savedRoutine.isDeleted = true
        savedRoutine.deletedAt = Date()
        
        try safeContext.save()
        
        logger.info("Routine soft deleted successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    
    /// Permanently delete a routine and all its sessions (use with caution)
    func permanentlyDeleteRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Permanently deleting routine: \(savedRoutine.routineName)", category: "Routine")
        
        // First, delete all sessions for this routine
        let sessions = try fetchSessions(for: savedRoutine.id)
        for session in sessions {
            safeContext.delete(session)
        }
        
        // Then delete the routine itself
        safeContext.delete(savedRoutine)
        try safeContext.save()
        
        logger.info("Routine permanently deleted successfully: \(savedRoutine.routineName) (\(sessions.count) sessions removed)", category: "Routine")
    }
    
    /// Restore a soft-deleted routine
    func restoreRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Restoring soft-deleted routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.isDeleted = false
        savedRoutine.deletedAt = nil
        
        try safeContext.save()
        
        logger.info("Routine restored successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    

    
    /// Record a play for a routine
    func recordPlay(for savedRoutine: SavedRoutine) throws {
        logger.info("Recording play for routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.recordPlay()
        try safeContext.save()
        
        logger.info("Play recorded for routine: \(savedRoutine.routineName) (total plays: \(savedRoutine.playCount))", category: "Routine")
    }
    
    /// Duplicate a routine
    func duplicateRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Duplicating routine: \(savedRoutine.routineName)", category: "Routine")
        
        var duplicatedRoutine = savedRoutine.getRoutine()
        duplicatedRoutine.name = "\(savedRoutine.routineName) Copy"
        
        let savedDuplicatedRoutine = SavedRoutine(
            routine: duplicatedRoutine
        )
        // Ensure favorite status is not copied
        savedDuplicatedRoutine.isFavorite = false
        
        safeContext.insert(savedDuplicatedRoutine)
        try safeContext.save()
        
        logger.info("Routine duplicated successfully: \(savedDuplicatedRoutine.routineName)", category: "Routine")
    }
    
    // MARK: - Session Management

    /// Complete and save a meditation session using the event-based approach
    func completeSession(using sessionRecord: SessionRecord, routine: SavedRoutine, wasDiscarded: Bool = false) async throws {
        logger.info("Completing session using events \(sessionRecord.id) (discarded: \(wasDiscarded))", category: "Session")
        
        // First, persist the SessionRecord
        safeContext.insert(sessionRecord)
        try safeContext.save()
        
        // Get routine data and validate
        let routineData = routine.getRoutine()
        guard let startTime = sessionRecord.startTime,
              let finishTime = sessionRecord.finishTime else {
            throw NSError(domain: "SessionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid session events - missing start or finish time"])
        }
        
        // Calculate actual meditation time from events
        let actualMeditationTime = sessionRecord.calculateActualMeditationTime()
        
        // Create the main session record
        let session = MeditationSession(
            routineId: routine.id,
            routineName: routine.routineName,
            routineIcon: routine.routineIcon,
            sessionStartTime: startTime,
            sessionEndTime: finishTime,
            totalPlannedDurationInMinutes: routineData.blocks.reduce(0) { $0 + $1.durationInMinutes },
            totalActualDurationInSeconds: Int(actualMeditationTime),
            wasCompleted: !wasDiscarded,
            wasDiscarded: wasDiscarded,
            totalBlocksCount: routineData.blocks.count,
            actualMeditationTimeInSeconds: Int(actualMeditationTime)
        )
        
        // Reconstruct detailed block logs from events
        let blockRecords = reconstructBlockLogs(
            from: sessionRecord.events,
            routineBlocks: routineData.blocks,
            sessionStartTime: startTime,
            finishTime: finishTime
        )
        
        // Add block records to session
        for record in blockRecords {
            session.addBlockRecord(record)
        }
        
        // Calculate completion metrics
        session.completedBlocksCount = blockRecords.filter { record in
            guard !record.wasSkipped && record.endTime != nil else { return false }
            let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10)
            #if DEBUG
            if isDebugMode { return record.actualDurationInSeconds >= 5 }
            #endif
            return record.actualDurationInSeconds >= minimumDurationForCompletion
        }.count
        
        // Calculate overshoot time
        let plannedDurationInSeconds = session.totalPlannedDurationInMinutes * 60
        session.overshootTimeInSeconds = max(0, Int(actualMeditationTime) - plannedDurationInSeconds)
        
        // Insert session into context
        safeContext.insert(session)
        
        // Record play for the routine if not discarded
        if !wasDiscarded {
            routine.recordPlay()
        }
        
        try safeContext.save()

        let status = wasDiscarded ? "DISCARDED" : "COMPLETED"
        logger.info("Session \(status): \(session.routineName) | \(session.sessionDurationFormatted) | \(session.completedBlocksCount)/\(session.totalBlocksCount) blocks | events: \(sessionRecord.events.count)", category: "Session")
    }
    
    /// Reconstruct detailed block logs from session events
    private func reconstructBlockLogs(
        from events: [SessionEvent],
        routineBlocks: [RoutineBlock],
        sessionStartTime: Date,
        finishTime: Date
    ) -> [SessionBlockRecord] {
        var blockRecords: [SessionBlockRecord] = []
        var virtualClock = sessionStartTime
        let pauseIntervals = getPauseIntervalsFromEvents(events)

        logger.debug("Reconstructing block logs: start=\(sessionStartTime) finish=\(finishTime) pauses=\(pauseIntervals.count)", category: "Session")

        for (index, block) in routineBlocks.enumerated() {
            #if DEBUG
            let blockDurationSeconds = isDebugMode ? TimeInterval(5) : TimeInterval(block.durationInMinutes * 60)
            #else
            let blockDurationSeconds = TimeInterval(block.durationInMinutes * 60)
            #endif
            
            // Calculate when this block should start (virtual clock time)
            let blockStartTime = virtualClock
            
            // Calculate when this block should end (without pauses)
            let blockScheduledEndTime = blockStartTime.addingTimeInterval(blockDurationSeconds)
            
            // Check if session finished before this block completed
            let sessionFinishedDuringBlock = finishTime < blockScheduledEndTime
            
            // Calculate actual end time considering session finish
            let blockActualEndTime = sessionFinishedDuringBlock ? finishTime : blockScheduledEndTime
            
            // Calculate actual duration excluding paused time during this block
            let blockActualDuration = calculateActualBlockDuration(
                blockStart: blockStartTime,
                blockEnd: blockActualEndTime,
                pauseIntervals: pauseIntervals
            )
            
            // Determine if block was skipped (finished before it could meaningfully start)
            let wasSkipped = sessionFinishedDuringBlock && blockActualDuration < 1.0 // Less than 1 second means skipped
            
            let blockRecord = SessionBlockRecord(
                blockId: block.id,
                blockName: block.name,
                blockType: block.type,
                plannedDurationInMinutes: block.durationInMinutes,
                actualDurationInSeconds: Int(blockActualDuration),
                wasSkipped: wasSkipped,
                orderIndex: index,
                startTime: blockStartTime,
                endTime: wasSkipped ? nil : blockActualEndTime
            )
            
            blockRecords.append(blockRecord)
            logger.debug("Block \(index + 1) '\(block.name)': \(wasSkipped ? "SKIPPED" : String(format: "%.1fs", blockActualDuration))", category: "Session")

            virtualClock = blockScheduledEndTime

            if sessionFinishedDuringBlock {
                for remainingIndex in (index + 1)..<routineBlocks.count {
                    let remainingBlock = routineBlocks[remainingIndex]
                    let skippedRecord = SessionBlockRecord(
                        blockId: remainingBlock.id,
                        blockName: remainingBlock.name,
                        blockType: remainingBlock.type,
                        plannedDurationInMinutes: remainingBlock.durationInMinutes,
                        actualDurationInSeconds: 0,
                        wasSkipped: true,
                        orderIndex: remainingIndex,
                        startTime: virtualClock
                    )
                    blockRecords.append(skippedRecord)
                    virtualClock = virtualClock.addingTimeInterval(TimeInterval(remainingBlock.durationInMinutes * 60))
                }
                break
            }
        }
        
        return blockRecords
    }
    
    /// Extract pause intervals from events for easier processing
    private func getPauseIntervalsFromEvents(_ events: [SessionEvent]) -> [(pause: Date, resume: Date?)] {
        var intervals: [(pause: Date, resume: Date?)] = []
        var currentPause: Date?
        
        for event in events {
            switch event {
            case .pause(let pauseTime):
                currentPause = pauseTime
            case .resume(let resumeTime):
                if let pause = currentPause {
                    intervals.append((pause: pause, resume: resumeTime))
                    currentPause = nil
                }
            case .finish:
                if let pause = currentPause {
                    intervals.append((pause: pause, resume: nil))
                    currentPause = nil
                }
            case .start:
                break
            }
        }
        
        return intervals
    }
    
    /// Calculate actual block duration excluding paused time
    private func calculateActualBlockDuration(
        blockStart: Date,
        blockEnd: Date,
        pauseIntervals: [(pause: Date, resume: Date?)]
    ) -> TimeInterval {
        var totalDuration = blockEnd.timeIntervalSince(blockStart)
        
        // Subtract any paused time that overlaps with this block
        for interval in pauseIntervals {
            let pauseStart = interval.pause
            let pauseEnd = interval.resume ?? blockEnd // Use block end if pause never resumed
            
            // Check if pause interval overlaps with block timeframe
            let overlapStart = max(blockStart, pauseStart)
            let overlapEnd = min(blockEnd, pauseEnd)
            
            if overlapStart < overlapEnd {
                let pausedTimeInBlock = overlapEnd.timeIntervalSince(overlapStart)
                totalDuration -= pausedTimeInBlock
            }
        }
        
        return max(0, totalDuration) // Ensure non-negative
    }
    
    /// Fetch all sessions for a specific routine
    func fetchSessions(for routineId: UUID) throws -> [MeditationSession] {
        let descriptor = FetchDescriptor<MeditationSession>(
            predicate: #Predicate<MeditationSession> { session in
                session.routineId == routineId
            },
            sortBy: [SortDescriptor(\.sessionStartTime, order: .reverse)]
        )
        
        return try safeContext.fetch(descriptor)
    }
    
    /// Fetch all sessions (for history view)
    func fetchAllSessions() throws -> [MeditationSession] {
        let descriptor = FetchDescriptor<MeditationSession>(
            sortBy: [SortDescriptor(\.sessionStartTime, order: .reverse)]
        )
        
        return try safeContext.fetch(descriptor)
    }
    
    /// Fetch sessions within a date range
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [MeditationSession] {
        let descriptor = FetchDescriptor<MeditationSession>(
            predicate: #Predicate<MeditationSession> { session in
                session.sessionStartTime >= startDate && session.sessionStartTime <= endDate
            },
            sortBy: [SortDescriptor(\.sessionStartTime, order: .reverse)]
        )
        
        return try safeContext.fetch(descriptor)
    }
    
    /// Delete a session
    func deleteSession(_ session: MeditationSession) throws {
        logger.info("Deleting session: \(session.id)", category: "Session")
        
        safeContext.delete(session)
        try safeContext.save()
        
        logger.info("Session deleted successfully", category: "Session")
    }
    
    /// Get session statistics
    func getSessionStatistics() async throws -> SessionStatistics {
        let allSessions = try fetchAllSessions()
        let completedSessions = allSessions.filter { !$0.wasDiscarded }
        
        let totalSessions = completedSessions.count
        let totalDuration = completedSessions.reduce(0) { $0 + $1.sessionDurationInSeconds }
        let averageDuration = totalSessions > 0 ? totalDuration / totalSessions : 0
        
        let fullyCompletedSessions = completedSessions.filter { $0.wasFullyCompleted }
        let completionRate = totalSessions > 0 ? Double(fullyCompletedSessions.count) / Double(totalSessions) : 0
        
        let totalOvershootTime = completedSessions.reduce(0) { $0 + $1.overshootTimeInSeconds }
        
        return SessionStatistics(
            totalSessions: totalSessions,
            totalDurationInSeconds: totalDuration,
            averageDurationInSeconds: averageDuration,
            completionRate: completionRate,
            totalOvershootTimeInSeconds: totalOvershootTime
        )
    }
    
    /// Get statistics about soft-deleted routines (for debugging)
    func getSoftDeleteStatistics() async throws -> (totalRoutines: Int, deletedRoutines: Int, activeRoutines: Int) {
        let allRoutines = try fetchAllRoutinesIncludingDeleted()
        let deletedRoutines = try fetchSoftDeletedRoutines()
        let activeRoutines = allRoutines.filter { !$0.isDeleted }
        
        return (
            totalRoutines: allRoutines.count,
            deletedRoutines: deletedRoutines.count,
            activeRoutines: activeRoutines.count
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchRoutine(by id: UUID) throws -> SavedRoutine? {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                routine.id == id && !routine.isDeleted
            }
        )
        
        return try safeContext.fetch(descriptor).first
    }
    
    /// Fetch all routines including soft-deleted ones (for admin/debug purposes)
    func fetchAllRoutinesIncludingDeleted() throws -> [SavedRoutine] {
        let descriptor = FetchDescriptor<SavedRoutine>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        
        return try safeContext.fetch(descriptor)
    }
    
    /// Fetch only soft-deleted routines (for admin/debug purposes)
    func fetchSoftDeletedRoutines() throws -> [SavedRoutine] {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                routine.isDeleted
            },
            sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
        )
        
        return try safeContext.fetch(descriptor)
    }
    
    // MARK: - Sample Data
    
    /// Add sample routines for first-time users
    func addSampleRoutines() throws {
        logger.info("Adding sample routines for first-time user", category: "Data")
        
        let sampleRoutines = Self.createSampleRoutines()
        
        for routine in sampleRoutines {
            safeContext.insert(routine)
            logger.debug("Added sample routine: \(routine.routineName)", category: "Data")
        }
        
        try safeContext.save()
        
        logger.info("Sample routines added successfully (\(sampleRoutines.count) routines)", category: "Data")
    }
    
    /// Check if sample data should be added (first launch)
    func shouldAddSampleData() -> Bool {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                !routine.isDeleted
            }
        )
        let count = (try? safeContext.fetchCount(descriptor)) ?? 0
        logger.debug("Current non-deleted routine count: \(count)", category: "Data")
        return count == 0
    }
    
    /// Initialize sample data if needed
    func initializeSampleDataIfNeeded() throws {
        if shouldAddSampleData() {
            logger.info("First-time user detected, adding sample data", category: "Data")
            try addSampleRoutines()
        } else {
            logger.debug("Sample data already exists, skipping initialization", category: "Data")
        }
        
        // Initialize system routine (ensures it exists for all users)
        try initializeSystemRoutineIfNeeded()
    }
    
    private static func createSampleRoutines() -> [SavedRoutine] {
        let morningMeditation = SavedRoutine(
            routine: Routine(
                name: "Morning Meditation",
                icon: "sunrise.fill",
                blocks: [
                    RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                    RoutineBlock(name: "Breathwork", durationInMinutes: 10, type: .breathwork, blockStartBell: .softBell),
                    RoutineBlock(name: "Visualization", durationInMinutes: 8, type: .visualization, blockStartBell: .tibetanBowl)
                ],
                openingBell: .softBell,
                closingBell: .tibetanBowl
            )
        )
        morningMeditation.playCount = 12
        morningMeditation.lastPlayed = Date().addingTimeInterval(-3600) // 1 hour ago
        
        let eveningWindDown = SavedRoutine(
            routine: Routine(
                name: "Evening Wind Down",
                icon: "moon.fill",
                blocks: [
                    RoutineBlock(name: "Body Scan", durationInMinutes: 15, type: .bodyScan, blockStartBell: .silent),
                    RoutineBlock(name: "Silence", durationInMinutes: 10, type: .silence, blockStartBell: .digitalChime)
                ],
                openingBell: .digitalChime,
                closingBell: .silent
            ),
            createdAt: Date().addingTimeInterval(-86400),
            lastModified: Date().addingTimeInterval(-3600)
        )
        eveningWindDown.playCount = 8
        eveningWindDown.lastPlayed = Date().addingTimeInterval(-7200) // 2 hours ago
        
        let quickFocus = SavedRoutine(
            routine: Routine(
                name: "Quick Focus",
                icon: "target",
                blocks: [
                    RoutineBlock(name: "Breathwork", durationInMinutes: 3, type: .breathwork, blockStartBell: .silent),
                    RoutineBlock(name: "Silence", durationInMinutes: 2, type: .silence, blockStartBell: .softBell)
                ],
                openingBell: .softBell,
                closingBell: .softBell
            ),
            createdAt: Date().addingTimeInterval(-172800),
            lastModified: Date().addingTimeInterval(-7200)
        )
        quickFocus.playCount = 25
        quickFocus.lastPlayed = Date().addingTimeInterval(-1800) // 30 minutes ago
        
        return [morningMeditation, eveningWindDown, quickFocus]
    }
    
    // MARK: - System Routine Management
    
    /// Initialize the system routine if it doesn't exist
    /// This method ensures there's always a special system routine available
    ///
    /// ⚠️ Should only be called ONCE at app launch, after SwiftData is initialized.
    func initializeSystemRoutineIfNeeded() throws {
        logger.info("Checking for system routine initialization", category: "SystemRoutine")
        
        // Check UserDefaults for existing system routine ID
        let userDefaults = UserDefaults.standard
        let systemRoutineIDKey = "SystemRoutineID"
        
        if let existingSystemRoutineID = userDefaults.string(forKey: systemRoutineIDKey),
           let uuid = UUID(uuidString: existingSystemRoutineID) {
            // Verify the system routine still exists in the database
            if let existingRoutine = try fetchRoutine(by: uuid) {
                logger.info("System routine already exists: \(existingRoutine.routineName)", category: "SystemRoutine")
                return
            } else {
                logger.warning("System routine ID found in UserDefaults but routine not found in database, will create new one", category: "SystemRoutine")
                // Remove invalid ID from UserDefaults
                userDefaults.removeObject(forKey: systemRoutineIDKey)
            }
        }
        
        // Create the system routine
        logger.info("Creating new system routine", category: "SystemRoutine")
        let systemRoutine = createSystemRoutine()
        
        // Insert into database
        safeContext.insert(systemRoutine)
        try safeContext.save()
        
        // Store the system routine ID in UserDefaults ONLY after successful save
        userDefaults.set(systemRoutine.id.uuidString, forKey: systemRoutineIDKey)
        
        logger.info("System routine created and stored successfully: \(systemRoutine.routineName) (ID: \(systemRoutine.id))", category: "SystemRoutine")
    }
    
    /// Create the system routine with predefined content
    private func createSystemRoutine() -> SavedRoutine {
        let systemRoutine = SavedRoutine(
            routine: Routine(
                name: "Pure Silence",
                icon: "bell.slash.fill",
                blocks: [
                    RoutineBlock(
                        name: "Silence",
                        durationInMinutes: 30,
                        type: .silence,
                        blockStartBell: .silent
                    )
                ],
                openingBell: .softBell,
                closingBell: .tibetanBowl,
                isSystemRoutine: true
            ),
            isSystemRoutine: true
        )
        
        return systemRoutine
    }
    
    /// Get the system routine if it exists
    func getSystemRoutine() -> SavedRoutine? {
        let userDefaults = UserDefaults.standard
        let systemRoutineIDKey = "SystemRoutineID"
        
        guard let systemRoutineIDString = userDefaults.string(forKey: systemRoutineIDKey),
              let systemRoutineID = UUID(uuidString: systemRoutineIDString) else {
            logger.warning("No system routine ID found in UserDefaults", category: "SystemRoutine")
            return nil
        }
        
        do {
            return try fetchRoutine(by: systemRoutineID)
        } catch {
            logger.error("Failed to fetch system routine: \(error)", category: "SystemRoutine")
            return nil
        }
    }
    
    /// Check if a routine is the system routine
    func isSystemRoutine(_ routine: SavedRoutine) -> Bool {
        return routine.isSystemRoutine
    }
    
    /// Permanently delete all system routines
    /// ⚠️ This action cannot be undone
    func deleteAllSystemRoutines() throws {
        logger.warning("Attempting to delete all system routines", category: "SystemRoutine")
        
        // Fetch all system routines
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                routine.isSystemRoutine == true
            }
        )
        
        let systemRoutines = try safeContext.fetch(descriptor)
        logger.info("Found \(systemRoutines.count) system routines to delete", category: "SystemRoutine")
        
        // Delete each system routine
        for routine in systemRoutines {
            try permanentlyDeleteRoutine(routine)
            logger.info("Deleted system routine: \(routine.routineName)", category: "SystemRoutine")
        }
        
        // Clear the system routine ID from UserDefaults
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: "SystemRoutineID")
        
        logger.info("Successfully deleted \(systemRoutines.count) system routines and cleared UserDefaults", category: "SystemRoutine")
    }
}

// MARK: - Environment Key
private struct RoutineDataManagerKey: EnvironmentKey {
    static let defaultValue = RoutineDataManager.shared
}

extension EnvironmentValues {
    var routineDataManager: RoutineDataManager {
        get { self[RoutineDataManagerKey.self] }
        set { self[RoutineDataManagerKey.self] = newValue }
    }
} 
