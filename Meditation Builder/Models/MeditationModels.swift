//
//  MeditationModels.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import Foundation
import Dragula

// MARK: - Meditation Block
struct MeditationBlock: Identifiable, Equatable, DragulaItem {
    let id: UUID
    var name: String
    var durationInMinutes: Int
    var type: BlockType
    
    enum BlockType: String, CaseIterable {
        case silence = "Silence"
        case breathwork = "Breathwork"
        case chanting = "Chanting"
        case visualization = "Visualization"
        case bodyScan = "Body Scan"
        case walking = "Walking"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .silence: return "bell.fill"
            case .breathwork: return "leaf.fill"
            case .chanting: return "om.symbol"
            case .visualization: return "eye.fill"
            case .bodyScan: return "figure.mind.and.body"
            case .walking: return "figure.walk"
            case .custom: return "sparkles"
            }
        }
        
        var defaultDuration: Int {
            switch self {
            case .silence: return 5
            case .breathwork: return 3
            case .chanting: return 4
            case .visualization: return 6
            case .bodyScan: return 8
            case .walking: return 10
            case .custom: return 5
            }
        }
    }
}

// MARK: - Transition Bell
struct TransitionBell: Equatable {
    var soundName: String
    var displayName: String {
        switch soundName {
        case "None": return "None"
        case "Soft Bell": return "Soft Bell"
        case "Tibetan Bowl": return "Tibetan Bowl"
        case "Digital Chime": return "Digital Chime"
        default: return soundName
        }
    }
}

// MARK: - Routine
struct Routine: Equatable {
    var blocks: [MeditationBlock]
    var transitionBells: [TransitionBell?] // size = blocks.count - 1
    
    static func == (lhs: Routine, rhs: Routine) -> Bool {
        lhs.blocks == rhs.blocks && lhs.transitionBells == rhs.transitionBells
    }
}

// MARK: - Saved Routine
struct SavedRoutine: Identifiable, Equatable {
    let id: UUID
    var name: String
    var routine: Routine
    var createdAt: Date
    var lastModified: Date
    
    init(id: UUID = UUID(), name: String, routine: Routine, createdAt: Date = Date(), lastModified: Date = Date()) {
        self.id = id
        self.name = name
        self.routine = routine
        self.createdAt = createdAt
        self.lastModified = lastModified
    }
    
    static func == (lhs: SavedRoutine, rhs: SavedRoutine) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.routine == rhs.routine &&
        lhs.createdAt == rhs.createdAt &&
        lhs.lastModified == rhs.lastModified
    }
}

// MARK: - IdentifiableInt for sheet index
struct IdentifiableInt: Identifiable {
    var id: Int { value }
    let value: Int
} 
