//
//  RoutineDataManager.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
class RoutineDataManager: ObservableObject {
    private var context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    // MARK: - CRUD Operations
    
    /// Save a new routine
    func saveRoutine(_ routine: Routine, name: String? = nil) throws {
        var routineToSave = routine
        if let name = name {
            routineToSave.name = name
        }
        
        let savedRoutine = SavedRoutine(
            routine: routineToSave
        )
        
        context.insert(savedRoutine)
        try context.save()
    }
    
    /// Update an existing routine
    func updateRoutine(_ savedRoutine: SavedRoutine, with routine: Routine) throws {
        savedRoutine.updateFromRoutine(routine)
        savedRoutine.version += 1
        
        try context.save()
    }
    
    /// Delete a routine
    func deleteRoutine(_ savedRoutine: SavedRoutine) throws {
        context.delete(savedRoutine)
        try context.save()
    }
    
    /// Record a play for a routine
    func recordPlay(for savedRoutine: SavedRoutine) throws {
        savedRoutine.recordPlay()
        try context.save()
    }
    
    /// Duplicate a routine
    func duplicateRoutine(_ savedRoutine: SavedRoutine) throws {
        var duplicatedRoutine = savedRoutine.getRoutine()
        duplicatedRoutine.name = "\(savedRoutine.routineName) Copy"
        
        let savedDuplicatedRoutine = SavedRoutine(
            routine: duplicatedRoutine
        )
        
        context.insert(savedDuplicatedRoutine)
        try context.save()
    }
    
    // MARK: - Sample Data
    
    /// Add sample routines for first-time users
    func addSampleRoutines() throws {
        let sampleRoutines = Self.createSampleRoutines()
        
        for routine in sampleRoutines {
            context.insert(routine)
        }
        
        try context.save()
    }
    
    /// Check if sample data should be added (first launch)
    func shouldAddSampleData() -> Bool {
        let descriptor = FetchDescriptor<SavedRoutine>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        return count == 0
    }
    
    /// Initialize sample data if needed
    func initializeSampleDataIfNeeded() throws {
        if shouldAddSampleData() {
            try addSampleRoutines()
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