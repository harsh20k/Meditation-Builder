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
    
    // MARK: - Private Helper Methods
    
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