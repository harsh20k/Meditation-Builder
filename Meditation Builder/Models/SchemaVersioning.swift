//
//  SchemaVersioning.swift
//  Meditation Builder
//

import SwiftData

// MARK: - Schema V1 (baseline)
// Adding optional fields to @Model classes (musicFileName, musicDisplayName on MeditationBlock)
// is handled automatically by SwiftData — no explicit versioned migration needed.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            SavedRoutine.self,
            MeditationBlock.self,
            MediaResource.self,
            MeditationSession.self,
            SessionBlockRecord.self,
            Theme.self
        ]
    }
}

// MARK: - Migration Plan

enum MeditationMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self] }
    static var stages: [MigrationStage] { [] }
}
