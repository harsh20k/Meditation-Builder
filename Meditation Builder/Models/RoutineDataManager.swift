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
    
    /// Delete a routine
    func deleteRoutine(_ savedRoutine: SavedRoutine) throws {
        logger.info("Deleting routine: \(savedRoutine.routineName)", category: "Routine")
        
        context.delete(savedRoutine)
        try context.save()
        
        logger.info("Routine deleted successfully: \(savedRoutine.routineName)", category: "Routine")
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
    
    /// Create a new meditation session
    func createSession(for routine: SavedRoutine, startTime: Date = Date()) -> MeditationSession {
        logger.info("Creating new session for routine: \(routine.routineName)", category: "Session")
        
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
        print("🧘‍♀️ SESSION CREATED")
        print("   Routine: \(routine.routineName)")
        print("   Session ID: \(session.id)")
        print("   Start Time: \(startTime)")
        print("   Planned Duration: \(totalPlannedDuration) minutes")
        print("   Total Blocks: \(routineData.blocks.count)")
        print("   Blocks:")
        for (index, block) in routineData.blocks.enumerated() {
            print("     \(index + 1). \(block.name) (\(block.durationInMinutes) min) - \(block.type.displayName)")
        }
        
        // Verify session was inserted
        do {
            try context.save()
            print("✅ Session saved to database successfully")
        } catch {
            print("❌ Failed to save session to database: \(error)")
        }
        
        logger.info("Session created: \(session.id)", category: "Session")
        return session
    }
    
    /// Update block record when block starts
    func startBlock(_ blockId: UUID, in session: MeditationSession, startTime: Date) async throws {
        logger.info("Starting block \(blockId) in session \(session.id)", category: "Session")
        
        if let record = session.blockRecords.first(where: { $0.blockId == blockId }) {
            record.startTime = startTime
            try context.save()
            
            // Console logging for block start
            print("▶️ BLOCK STARTED")
            print("   Session: \(session.routineName)")
            print("   Block: \(record.blockName)")
            print("   Type: \(record.blockType.displayName)")
            print("   Planned Duration: \(record.plannedDurationInMinutes) minutes")
            print("   Start Time: \(startTime)")
            
            logger.debug("Block start time updated", category: "Session")
        }
    }
    
    /// Update block record when block ends
    func endBlock(_ blockId: UUID, in session: MeditationSession, endTime: Date, wasSkipped: Bool = false) async throws {
        logger.info("Ending block \(blockId) in session \(session.id) (skipped: \(wasSkipped))", category: "Session")
        
        if let record = session.blockRecords.first(where: { $0.blockId == blockId }) {
            let actualDuration = Int(endTime.timeIntervalSince(record.startTime))
            session.updateBlockRecord(blockId, actualDuration: actualDuration, wasSkipped: wasSkipped, endTime: endTime)
            try context.save()
            
            // Console logging for block end
            let status = wasSkipped ? "SKIPPED" : "COMPLETED"
            let durationFormatted = String(format: "%d:%02d", actualDuration / 60, actualDuration % 60)
            let plannedFormatted = String(format: "%d:%02d", record.plannedDurationInMinutes, 0)
            
            print("⏹️ BLOCK \(status)")
            print("   Session: \(session.routineName)")
            print("   Block: \(record.blockName)")
            print("   Planned: \(plannedFormatted) | Actual: \(durationFormatted)")
            print("   End Time: \(endTime)")
            
            logger.debug("Block end time and duration updated: \(actualDuration)s", category: "Session")
        }
    }
    
    /// Complete and save a meditation session
    func completeSession(_ session: MeditationSession, endTime: Date, wasDiscarded: Bool = false) async throws {
        logger.info("Completing session \(session.id) (discarded: \(wasDiscarded))", category: "Session")
        
        session.completeSession(endTime: endTime, wasDiscarded: wasDiscarded)
        
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
        
        // Log block summary
        print("   Block Summary:")
        for record in session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let blockStatus = record.wasSkipped ? "SKIPPED" : "COMPLETED"
            let blockDuration = String(format: "%d:%02d", record.actualDurationInSeconds / 60, record.actualDurationInSeconds % 60)
            print("     \(record.orderIndex + 1). \(record.blockName): \(blockDuration) (\(blockStatus))")
        }
        
        logger.info("Session completed successfully: \(session.sessionDurationFormatted)", category: "Session")
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
    
    // MARK: - Private Helper Methods
    
    private func fetchRoutine(by id: UUID) throws -> SavedRoutine? {
        let descriptor = FetchDescriptor<SavedRoutine>(
            predicate: #Predicate<SavedRoutine> { routine in
                routine.id == id
            }
        )
        
        return try context.fetch(descriptor).first
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
        let descriptor = FetchDescriptor<SavedRoutine>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        logger.debug("Current routine count: \(count)", category: "Data")
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