//
//  RoutineDataManager.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import Foundation
import SwiftData
import SwiftUI
import os.log

@MainActor
class RoutineDataManager: ObservableObject {
    private var context: ModelContext
	
	// MARK: - Debug Configuration
	
	#if DEBUG
	private let isDebugMode = true // Set to true for 5-second blocks, false for normal duration
	#else
	private let isDebugMode = false
	#endif
    
    init(context: ModelContext) {
        self.context = context
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
        
        context.insert(savedRoutine)
        try context.save()
        
        logger.info("Routine saved successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    
    /// Update an existing routine
    func updateRoutine(_ savedRoutine: SavedRoutine, with routine: Routine) throws {
        logger.info("Updating routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.updateFromRoutine(routine)
        savedRoutine.version += 1
        
        try context.save()
        
        logger.info("Routine updated successfully: \(savedRoutine.routineName) (version: \(savedRoutine.version))", category: "Routine")
    }
    
    /// Delete a routine (soft delete - preserves session data)
    func deleteRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Soft deleting routine: \(savedRoutine.routineName)", category: "Routine")
        
        // Soft delete - mark as deleted but keep in database
        savedRoutine.isDeleted = true
        savedRoutine.deletedAt = Date()
        
        try context.save()
        
        logger.info("Routine soft deleted successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    
    /// Permanently delete a routine and all its sessions (use with caution)
    func permanentlyDeleteRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Permanently deleting routine: \(savedRoutine.routineName)", category: "Routine")
        
        // First, delete all sessions for this routine
        let sessions = try fetchSessions(for: savedRoutine.id)
        for session in sessions {
            context.delete(session)
        }
        
        // Then delete the routine itself
        context.delete(savedRoutine)
        try context.save()
        
        logger.info("Routine permanently deleted successfully: \(savedRoutine.routineName) (\(sessions.count) sessions removed)", category: "Routine")
    }
    
    /// Restore a soft-deleted routine
    func restoreRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Restoring soft-deleted routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.isDeleted = false
        savedRoutine.deletedAt = nil
        
        try context.save()
        
        logger.info("Routine restored successfully: \(savedRoutine.routineName)", category: "Routine")
    }
    

    
    /// Record a play for a routine
    func recordPlay(for savedRoutine: SavedRoutine) throws {
        logger.info("Recording play for routine: \(savedRoutine.routineName)", category: "Routine")
        
        savedRoutine.recordPlay()
        try context.save()
        
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
        
        context.insert(savedDuplicatedRoutine)
        try context.save()
        
        logger.info("Routine duplicated successfully: \(savedDuplicatedRoutine.routineName)", category: "Routine")
    }
    
    // MARK: - Session Management
    
    /// Create a new meditation session (DEPRECATED - use event-based approach instead)
    @available(*, deprecated, message: "Use event-based SessionRecord approach instead")
    func createSession(for routine: SavedRoutine, startTime: Date = Date()) -> MeditationSession {
        logger.warning("Using deprecated createSession - consider switching to event-based approach", category: "Session")
        
        // Validate that the routine is not soft-deleted
        guard !routine.isDeleted else {
            logger.error("Cannot create session for soft-deleted routine: \(routine.routineName)", category: "Session")
            fatalError("Attempted to create session for soft-deleted routine")
        }
        
        let routineData = routine.getRoutine()
        let totalPlannedDuration = routineData.blocks.reduce(0) { $0 + $1.durationInMinutes }
        
        let session = MeditationSession(
            routineId: routine.id,
            routineName: routine.routineName,
            routineIcon: routine.routineIcon,
            sessionStartTime: startTime,
            totalPlannedDurationInMinutes: totalPlannedDuration,
            totalBlocksCount: routineData.blocks.count
        )
        
        // Pre-create block records for all blocks
        for (index, block) in routineData.blocks.enumerated() {
            let blockRecord = SessionBlockRecord(
                blockId: block.id,
                blockName: block.name,
                blockType: block.type,
                plannedDurationInMinutes: block.durationInMinutes,
                orderIndex: index,
                startTime: startTime // Will be updated when block actually starts
            )
            session.addBlockRecord(blockRecord)
        }
        
        context.insert(session)
        
        // Console logging for session creation
        print("🧘‍♀️ LEGACY SESSION CREATED")
        print("   Routine: \(routine.routineName)")
        print("   Session ID: \(session.id)")
        print("   Start Time: \(startTime)")
        print("   Planned Duration: \(totalPlannedDuration) minutes")
        print("   Total Blocks: \(routineData.blocks.count)")
        
        // Verify session was inserted
        do {
            try context.save()
            logger.info("Legacy session created and saved successfully: \(session.id)", category: "Session")
        } catch {
            logger.error("Failed to save legacy session: \(error)", category: "Session")
        }
        
        return session
    }
    
    /// Update block record when block starts (DEPRECATED - use event-based approach instead)
    @available(*, deprecated, message: "Use event-based SessionRecord approach instead")
    func startBlock(_ blockId: UUID, in session: MeditationSession, startTime: Date) async throws {
        logger.warning("Using deprecated startBlock - consider switching to event-based approach", category: "Session")
        
        if let record = session.blockRecords.first(where: { $0.blockId == blockId }) {
            record.startTime = startTime
            try context.save()
            logger.debug("Legacy block start time updated", category: "Session")
        }
    }
    
    /// Update block record when block ends (DEPRECATED - use event-based approach instead)
    @available(*, deprecated, message: "Use event-based SessionRecord approach instead")
    func endBlock(_ blockId: UUID, in session: MeditationSession, endTime: Date, wasSkipped: Bool = false, actualDuration: Int? = nil) async throws {
        logger.warning("Using deprecated endBlock - consider switching to event-based approach", category: "Session")
        
        if let record = session.blockRecords.first(where: { $0.blockId == blockId }) {
            let finalDuration: Int
            if wasSkipped {
                finalDuration = 0
            } else if let providedDuration = actualDuration {
                finalDuration = providedDuration
            } else {
                finalDuration = Int(endTime.timeIntervalSince(record.startTime))
            }
            
            session.updateBlockRecord(blockId, actualDuration: finalDuration, wasSkipped: wasSkipped, endTime: endTime)
            try context.save()
            logger.debug("Legacy block end time and duration updated: \(finalDuration)s", category: "Session")
        }
    } 
    
    /// Complete and save a meditation session (legacy method - still used for existing sessions)
    func completeSession(_ session: MeditationSession, endTime: Date, wasDiscarded: Bool = false, actualMeditationTime: Int? = nil) async throws {
        logger.info("Completing session \(session.id) (discarded: \(wasDiscarded))", category: "Session")
        
        session.completeSession(endTime: endTime, wasDiscarded: wasDiscarded, actualMeditationTime: actualMeditationTime)
        
        if !wasDiscarded {
            // Also record the play for the routine
            if let routine = try? fetchRoutine(by: session.routineId) {
                routine.recordPlay()
            }
        }
        
        try context.save()
        
        // Console logging for session completion
        let status = wasDiscarded ? "DISCARDED" : "COMPLETED"
        let durationFormatted = session.sessionDurationFormatted
        let completionRate = session.completionRatePercentage
        let overshootInfo = session.hasOvershoot ? " (Overshoot: \(session.overshootTimeFormatted))" : ""
        
        print("🏁 SESSION \(status)")
        print("   Routine: \(session.routineName)")
        print("   Duration: \(durationFormatted)")
        print("   Completion: \(session.completedBlocksCount)/\(session.totalBlocksCount) blocks (\(completionRate)%)")
        print("   End Time: \(endTime)\(overshootInfo)")
        
        // Log block summary with detailed timing
        print("   Block Summary:")
        for record in session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let blockStatus: String
            if record.wasSkipped {
                blockStatus = "SKIPPED"
            } else if record.endTime == nil {
                blockStatus = "NOT_STARTED"
            } else {
                // Use the same completion criteria as in MeditationSession
                let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10) // 10 seconds or 10% of planned, whichever is smaller
                if record.actualDurationInSeconds >= minimumDurationForCompletion {
                    blockStatus = "COMPLETED"
                } else if record.actualDurationInSeconds > 0 {
                    blockStatus = "STARTED_ONLY"
                } else {
                    blockStatus = "INTERRUPTED"
                }
            }
            
            let blockDuration = String(format: "%d:%02d", record.actualDurationInSeconds / 60, record.actualDurationInSeconds % 60)
            let plannedDuration = String(format: "%d:%02d", record.plannedDurationInMinutes, 0)
            
            print("     \(record.orderIndex + 1). \(record.blockName)")
            print("        Type: \(record.blockType.displayName)")
            print("        Planned: \(plannedDuration) | Actual: \(blockDuration)")
            print("        Status: \(blockStatus)")
            
            // Only show timing information for blocks that actually ran (not skipped and have meaningful timing)
            if !record.wasSkipped && record.endTime != nil {
                let startTimeFormatted = String(format: "%d:%02d", Int(record.startTime.timeIntervalSince(session.sessionStartTime)) / 60, Int(record.startTime.timeIntervalSince(session.sessionStartTime)) % 60)
                let endTimeFormatted = String(format: "%d:%02d", Int(record.endTime!.timeIntervalSince(session.sessionStartTime)) / 60, Int(record.endTime!.timeIntervalSince(session.sessionStartTime)) % 60)
                print("        Start: +\(startTimeFormatted) | End: +\(endTimeFormatted)")
                
                // Verify timing consistency - log if there's a mismatch
                let calculatedDuration = Int(record.endTime!.timeIntervalSince(record.startTime))
                if abs(calculatedDuration - record.actualDurationInSeconds) > 1 {
                    print("        ⚠️  Timing inconsistency: Raw duration \(calculatedDuration)s vs Actual \(record.actualDurationInSeconds)s")
                }
            }
        }
        
        logger.info("Session completed successfully: \(session.sessionDurationFormatted)", category: "Session")
    }
    
    /// Complete and save a meditation session using deferred event-based approach
    func completeSession(using sessionRecord: SessionRecord, routine: SavedRoutine, wasDiscarded: Bool = false) async throws {
        logger.info("Completing session using events \(sessionRecord.id) (discarded: \(wasDiscarded))", category: "Session")
        
        // First, persist the SessionRecord
        context.insert(sessionRecord)
        try context.save()
        
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
			if isDebugMode {
				return record.actualDurationInSeconds >= 5
			} else {
				return record.actualDurationInSeconds >= minimumDurationForCompletion
			}
        }.count
        
        // Calculate overshoot time
        let plannedDurationInSeconds = session.totalPlannedDurationInMinutes * 60
        session.overshootTimeInSeconds = max(0, Int(actualMeditationTime) - plannedDurationInSeconds)
        
        // Insert session into context
        context.insert(session)
        
        // Record play for the routine if not discarded
        if !wasDiscarded {
            routine.recordPlay()
        }
        
        try context.save()
        
        // Console logging for session completion
        let status = wasDiscarded ? "DISCARDED" : "COMPLETED"
        let durationFormatted = session.sessionDurationFormatted
        let completionRate = session.completionRatePercentage
        let overshootInfo = session.hasOvershoot ? " (Overshoot: \(session.overshootTimeFormatted))" : ""
        
        print("🏁 DEFERRED SESSION \(status)")
        print("   Routine: \(session.routineName)")
        print("   Duration: \(durationFormatted)")
        print("   Completion: \(session.completedBlocksCount)/\(session.totalBlocksCount) blocks (\(completionRate)%)")
        print("   End Time: \(finishTime)\(overshootInfo)")
        print("   Events Processed: \(sessionRecord.events.count)")
        
        // Log block summary with reconstructed timing
        print("   Reconstructed Block Summary:")
        for record in session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let blockStatus: String
            if record.wasSkipped {
                blockStatus = "SKIPPED"
            } else if record.endTime == nil {
                blockStatus = "NOT_STARTED"
            } else {
                let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10)
                if record.actualDurationInSeconds >= minimumDurationForCompletion {
                    blockStatus = "COMPLETED"
                } else if record.actualDurationInSeconds > 0 {
                    blockStatus = "STARTED_ONLY"
                } else {
                    blockStatus = "INTERRUPTED"
                }
            }
            
            let blockDuration = String(format: "%d:%02d", record.actualDurationInSeconds / 60, record.actualDurationInSeconds % 60)
            let plannedDuration = String(format: "%d:%02d", record.plannedDurationInMinutes, 0)
            
            print("     \(record.orderIndex + 1). \(record.blockName)")
            print("        Type: \(record.blockType.displayName)")
            print("        Planned: \(plannedDuration) | Actual: \(blockDuration)")
            print("        Status: \(blockStatus)")
            
            if !record.wasSkipped && record.endTime != nil {
                let startTimeFormatted = String(format: "%d:%02d", Int(record.startTime.timeIntervalSince(startTime)) / 60, Int(record.startTime.timeIntervalSince(startTime)) % 60)
                let endTimeFormatted = String(format: "%d:%02d", Int(record.endTime!.timeIntervalSince(startTime)) / 60, Int(record.endTime!.timeIntervalSince(startTime)) % 60)
                print("        Start: +\(startTimeFormatted) | End: +\(endTimeFormatted)")
            }
        }
        
        logger.info("Deferred session completed successfully: \(session.sessionDurationFormatted)", category: "Session")
    }
    
    /// Reconstruct detailed block logs from session events
    private func reconstructBlockLogs(
        from events: [SessionEvent],
        routineBlocks: [RoutineBlock],
        sessionStartTime: Date,
        finishTime: Date
    ) -> [SessionBlockRecord] {
        var blockRecords: [SessionBlockRecord] = []
        
        // Virtual clock starts at session start time
        var virtualClock = sessionStartTime
        var isPaused = false
        var currentPauseStart: Date?
        
        // Get pause intervals for easier processing
        let pauseIntervals = getPauseIntervalsFromEvents(events)
        
        print("🔧 RECONSTRUCTING BLOCK LOGS")
        print("   Session Start: \(sessionStartTime)")
        print("   Session Finish: \(finishTime)")
        print("   Pause Intervals: \(pauseIntervals.count)")
        
        for pauseInterval in pauseIntervals {
            let pauseDuration = (pauseInterval.resume ?? finishTime).timeIntervalSince(pauseInterval.pause)
            print("     Pause: \(pauseInterval.pause) to \(pauseInterval.resume?.description ?? "end") (\(String(format: "%.1f", pauseDuration))s)")
        }
        
        for (index, block) in routineBlocks.enumerated() {
            var blockDurationSeconds = TimeInterval(block.durationInMinutes * 60)
			
			if isDebugMode {
				blockDurationSeconds = TimeInterval(5)
			} else {
				blockDurationSeconds = TimeInterval(block.durationInMinutes * 60)
			}
            
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
            
            print("   Block \(index + 1): \(block.name)")
            print("     Planned: \(block.durationInMinutes) min")
            print("     Virtual Start: \(blockStartTime)")
            print("     Virtual End: \(blockScheduledEndTime)")
            print("     Actual End: \(blockActualEndTime)")
            print("     Actual Duration: \(String(format: "%.1f", blockActualDuration))s")
            print("     Was Skipped: \(wasSkipped)")
            
            // Advance virtual clock by the full scheduled duration (even if session ended early)
            virtualClock = blockScheduledEndTime
            
            // If session ended during this block, no need to process remaining blocks
            if sessionFinishedDuringBlock {
                // Mark remaining blocks as skipped
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
                        startTime: virtualClock // Use virtual clock for skipped blocks
                    )
                    blockRecords.append(skippedRecord)
                    
                    print("   Block \(remainingIndex + 1): \(remainingBlock.name) - SKIPPED")
                    
                    // Still advance virtual clock for consistency
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
                
                print("     Pause Overlap: \(String(format: "%.1f", pausedTimeInBlock))s")
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
        
        return try context.fetch(descriptor)
    }
    
    /// Fetch all sessions (for history view)
    func fetchAllSessions() throws -> [MeditationSession] {
        let descriptor = FetchDescriptor<MeditationSession>(
            sortBy: [SortDescriptor(\.sessionStartTime, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Fetch sessions within a date range
    func fetchSessions(from startDate: Date, to endDate: Date) throws -> [MeditationSession] {
        let descriptor = FetchDescriptor<MeditationSession>(
            predicate: #Predicate<MeditationSession> { session in
                session.sessionStartTime >= startDate && session.sessionStartTime <= endDate
            },
            sortBy: [SortDescriptor(\.sessionStartTime, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Delete a session
    func deleteSession(_ session: MeditationSession) throws {
        logger.info("Deleting session: \(session.id)", category: "Session")
        
        context.delete(session)
        try context.save()
        
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
        
        return try context.fetch(descriptor).first
    }
    
    /// Fetch all routines including soft-deleted ones (for admin/debug purposes)
    func fetchAllRoutinesIncludingDeleted() throws -> [SavedRoutine] {
        let descriptor = FetchDescriptor<SavedRoutine>(
            sortBy: [SortDescriptor(\.lastModified, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    /// Fetch only soft-deleted routines (for admin/debug purposes)
    func fetchSoftDeletedRoutines() throws -> [SavedRoutine] {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                routine.isDeleted
            },
            sortBy: [SortDescriptor(\.deletedAt, order: .reverse)]
        )
        
        return try context.fetch(descriptor)
    }
    
    // MARK: - Sample Data
    
    /// Add sample routines for first-time users
    func addSampleRoutines() throws {
        logger.info("Adding sample routines for first-time user", category: "Data")
        
        let sampleRoutines = Self.createSampleRoutines()
        
        for routine in sampleRoutines {
            context.insert(routine)
            logger.debug("Added sample routine: \(routine.routineName)", category: "Data")
        }
        
        try context.save()
        
        logger.info("Sample routines added successfully (\(sampleRoutines.count) routines)", category: "Data")
    }
    
    /// Check if sample data should be added (first launch)
    func shouldAddSampleData() -> Bool {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                !routine.isDeleted
            }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
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
}

// MARK: - Environment Key
struct RoutineDataManagerKey: EnvironmentKey {
    static let defaultValue: RoutineDataManager? = nil
}

extension EnvironmentValues {
    var routineDataManager: RoutineDataManager? {
        get { self[RoutineDataManagerKey.self] }
        set { self[RoutineDataManagerKey.self] = newValue }
    }
} 