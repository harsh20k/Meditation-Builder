//
//  SchemaVersioning.swift
//  Meditation Builder
//

import SwiftData

// MARK: - Schema V1 (baseline)

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
