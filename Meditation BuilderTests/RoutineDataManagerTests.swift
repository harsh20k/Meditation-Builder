//
//  RoutineDataManagerTests.swift
//  Meditation BuilderTests
//

import Testing
import Foundation
import SwiftData
@testable import Meditation_Builder

// MARK: - Helpers

private func makeInMemoryContainer() throws -> ModelContainer {
    let schema = Schema(SchemaV1.models)
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}

@Suite("RoutineDataManager")
@MainActor
struct RoutineDataManagerTests {

    // MARK: - CRUD

    @Test("saveRoutine persists and is fetchable")
    func saveRoutineRoundTrip() async throws {
        let container = try makeInMemoryContainer()
        let manager = RoutineDataManager()
        manager.configure(with: ModelContext(container))

        let routine = Routine(
            name: "Test",
            icon: "sun.max.fill",
            blocks: [RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent)]
        )
        try manager.saveRoutine(routine)

        let all = try manager.fetchAllRoutinesIncludingDeleted()
        #expect(all.count == 1)
        #expect(all.first?.routineName == "Test")
    }

    @Test("deleteRoutine soft-deletes the routine")
    func softDelete() async throws {
        let container = try makeInMemoryContainer()
        let manager = RoutineDataManager()
        manager.configure(with: ModelContext(container))

        let routine = Routine(name: "ToDelete", icon: "trash", blocks: [
            RoutineBlock(name: "Block", durationInMinutes: 1, type: .silence, blockStartBell: .silent)
        ])
        try manager.saveRoutine(routine)

        let saved = try manager.fetchAllRoutinesIncludingDeleted()
        try manager.deleteRoutine(saved[0])

        let deleted = try manager.fetchSoftDeletedRoutines()
        #expect(deleted.count == 1)
        #expect(deleted[0].isDeleted)
    }

    @Test("restoreRoutine un-deletes a soft-deleted routine")
    func restore() async throws {
        let container = try makeInMemoryContainer()
        let manager = RoutineDataManager()
        manager.configure(with: ModelContext(container))

        let routine = Routine(name: "ToRestore", icon: "arrow.clockwise", blocks: [
            RoutineBlock(name: "Block", durationInMinutes: 1, type: .silence, blockStartBell: .silent)
        ])
        try manager.saveRoutine(routine)
        let saved = try manager.fetchAllRoutinesIncludingDeleted()
        try manager.deleteRoutine(saved[0])
        try manager.restoreRoutine(saved[0])

        let deleted = try manager.fetchSoftDeletedRoutines()
        #expect(deleted.isEmpty)
    }

    // MARK: - Session Completion

    @Test("completeSession saves MeditationSession with correct block count")
    func completeSessionEventPath() async throws {
        let container = try makeInMemoryContainer()
        let manager = RoutineDataManager()
        manager.configure(with: ModelContext(container))

        let blocks: [RoutineBlock] = [
            RoutineBlock(name: "A", durationInMinutes: 1, type: .silence, blockStartBell: .silent),
            RoutineBlock(name: "B", durationInMinutes: 1, type: .breathwork, blockStartBell: .silent),
        ]
        let routine = Routine(name: "R", icon: "circle", blocks: blocks)
        try manager.saveRoutine(routine)
        let saved = try manager.fetchAllRoutinesIncludingDeleted()[0]

        let t0 = Date()
        let sessionRecord = SessionRecord(routineID: saved.id)
        sessionRecord.addEvent(.start(t0))
        sessionRecord.addEvent(.finish(t0.addingTimeInterval(120))) // 2 min = both blocks

        try await manager.completeSession(using: sessionRecord, routine: saved, wasDiscarded: false)

        let sessions = try manager.fetchSessions(for: saved.id)
        #expect(sessions.count == 1)
        #expect(sessions[0].totalBlocksCount == 2)
        #expect(!sessions[0].wasDiscarded)
    }

    // MARK: - Statistics

    @Test("getSessionStatistics returns correct totals")
    func sessionStatistics() async throws {
        let container = try makeInMemoryContainer()
        let manager = RoutineDataManager()
        manager.configure(with: ModelContext(container))

        let t0 = Date()
        let session = MeditationSession(
            routineId: UUID(),
            routineName: "Test",
            routineIcon: "circle",
            sessionStartTime: t0,
            sessionEndTime: t0.addingTimeInterval(300),
            totalPlannedDurationInMinutes: 5,
            totalActualDurationInSeconds: 300,
            wasCompleted: true,
            wasDiscarded: false,
            totalBlocksCount: 1,
            actualMeditationTimeInSeconds: 300
        )
        session.completedBlocksCount = 1
        ModelContext(container).insert(session)
        try ModelContext(container).save()

        let stats = try await manager.getSessionStatistics()
        #expect(stats.totalSessions == 1)
    }
}
