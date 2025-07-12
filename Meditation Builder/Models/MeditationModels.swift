//
//  MeditationModels.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import Foundation
import SwiftUI
import Dragula

// MARK: - Block Content Type
enum BlockContentType: String, Codable, CaseIterable {
    case bell = "bell"
    case audio = "audio"
    case video = "video"
    case ambient = "ambient"
    
    var displayName: String {
        switch self {
        case .bell: return String(localized: "content.type.bell")
        case .audio: return String(localized: "content.type.audio")
        case .video: return String(localized: "content.type.video")
        case .ambient: return String(localized: "content.type.ambient")
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .bell: return LocalizedStringKey("content.type.bell")
        case .audio: return LocalizedStringKey("content.type.audio")
        case .video: return LocalizedStringKey("content.type.video")
        case .ambient: return LocalizedStringKey("content.type.ambient")
        }
    }
    
    var icon: String {
        switch self {
        case .bell: return "bell.fill"
        case .audio: return "waveform"
        case .video: return "video.fill"
        case .ambient: return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Media Resource
struct MediaResource: Identifiable, Codable, Equatable {
    var id: UUID
    var type: BlockContentType
    var name: String            // "Guided Chant", "Rain Loop", etc.
    var fileName: String        // local or bundle asset name
    var url: URL?               // future remote URL
    
    init(id: UUID = UUID(), type: BlockContentType, name: String, fileName: String, url: URL? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.fileName = fileName
        self.url = url
    }
}

// MARK: - Bell Sound
enum BellSound: String, CaseIterable, Equatable, Codable {
    case silent = "silent"
    case softBell = "soft_bell"
    case tibetanBowl = "tibetan_bowl"
    case digitalChime = "digital_chime"
    
    var displayName: String {
        switch self {
        case .silent: return String(localized: "bell.silent")
        case .softBell: return String(localized: "bell.soft")
        case .tibetanBowl: return String(localized: "bell.tibetan")
        case .digitalChime: return String(localized: "bell.digital")
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .silent: return LocalizedStringKey("bell.silent")
        case .softBell: return LocalizedStringKey("bell.soft")
        case .tibetanBowl: return LocalizedStringKey("bell.tibetan")
        case .digitalChime: return LocalizedStringKey("bell.digital")
        }
    }
    
    var icon: String {
        switch self {
        case .silent: return "bell.slash.fill"
        case .softBell: return "bell.fill"
        case .tibetanBowl: return "circle.grid.cross"
        case .digitalChime: return "waveform"
        }
    }
    
    static var `default`: BellSound {
        return .silent
    }
}

// MARK: - Meditation Block
struct MeditationBlock: Identifiable, Equatable, Codable, DragulaItem {
    let id: UUID
    var name: String
    var durationInMinutes: Int
    var type: BlockType
    var blockStartBell: BellSound
    var media: [MediaResource]  // ← empty for MVP, uplevel later
    
    init(id: UUID = UUID(), name: String, durationInMinutes: Int, type: BlockType, blockStartBell: BellSound = .default, media: [MediaResource] = []) {
        self.id = id
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.type = type
        self.blockStartBell = blockStartBell
        self.media = media
    }
    
    enum BlockType: String, CaseIterable, Codable {
        case silence = "silence"
        case breathwork = "breathwork"
        case chanting = "chanting"
        case visualization = "visualization"
        case bodyScan = "body_scan"
        case walking = "walking"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .silence: return String(localized: "block.type.silence")
            case .breathwork: return String(localized: "block.type.breathwork")
            case .chanting: return String(localized: "block.type.chanting")
            case .visualization: return String(localized: "block.type.visualization")
            case .bodyScan: return String(localized: "block.type.body_scan")
            case .walking: return String(localized: "block.type.walking")
            case .custom: return String(localized: "block.type.custom")
            }
        }
        
        var titleKey: LocalizedStringKey {
            switch self {
            case .silence: return LocalizedStringKey("block.type.silence")
            case .breathwork: return LocalizedStringKey("block.type.breathwork")
            case .chanting: return LocalizedStringKey("block.type.chanting")
            case .visualization: return LocalizedStringKey("block.type.visualization")
            case .bodyScan: return LocalizedStringKey("block.type.body_scan")
            case .walking: return LocalizedStringKey("block.type.walking")
            case .custom: return LocalizedStringKey("block.type.custom")
            }
        }
        
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

// MARK: - Routine
struct Routine: Equatable, Codable {
    var name: String
    var blocks: [MeditationBlock]
    var openingBell: BellSound
    var closingBell: BellSound
    var media: [MediaResource]  // ← empty for MVP, uplevel later
    
    init(name: String, blocks: [MeditationBlock], openingBell: BellSound = .softBell, closingBell: BellSound = .softBell, media: [MediaResource] = []) {
        self.name = name
        self.blocks = blocks
        self.openingBell = openingBell
        self.closingBell = closingBell
        self.media = media
    }
    
    static func == (lhs: Routine, rhs: Routine) -> Bool {
        lhs.name == rhs.name &&
        lhs.blocks == rhs.blocks && 
        lhs.openingBell == rhs.openingBell && 
        lhs.closingBell == rhs.closingBell &&
        lhs.media == rhs.media
    }
}

// MARK: - Saved Routine
struct SavedRoutine: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var routine: Routine
    var createdAt: Date
    var lastModified: Date
    var version: Int
    var playCount: Int
    var lastPlayed: Date?
    
    init(
        id: UUID = UUID(), 
        name: String, 
        routine: Routine, 
        createdAt: Date = Date(), 
        lastModified: Date = Date(),
        version: Int = 1,
        playCount: Int = 0,
        lastPlayed: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.routine = routine
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.version = version
        self.playCount = playCount
        self.lastPlayed = lastPlayed
    }
    
    // Helper method to increment play count
    mutating func recordPlay() {
        self.playCount += 1
        self.lastPlayed = Date()
        self.lastModified = Date()
    }
    
    static func == (lhs: SavedRoutine, rhs: SavedRoutine) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.routine == rhs.routine &&
        lhs.createdAt == rhs.createdAt &&
        lhs.lastModified == rhs.lastModified &&
        lhs.version == rhs.version &&
        lhs.playCount == rhs.playCount &&
        lhs.lastPlayed == rhs.lastPlayed
    }
}

// MARK: - Sample Media Resources (for future use)
extension MediaResource {
    static let sampleBellSounds: [MediaResource] = [
        MediaResource(type: .bell, name: "Tibetan Bowl", fileName: "tibetan_bowl.mp3"),
        MediaResource(type: .bell, name: "Soft Bell", fileName: "soft_bell.mp3"),
        MediaResource(type: .bell, name: "Digital Chime", fileName: "digital_chime.mp3")
    ]
    
    static let sampleAmbientSounds: [MediaResource] = [
        MediaResource(type: .ambient, name: "Rain Loop", fileName: "rain_loop.mp3"),
        MediaResource(type: .ambient, name: "Ocean Waves", fileName: "ocean_waves.mp3"),
        MediaResource(type: .ambient, name: "Forest Birds", fileName: "forest_birds.mp3"),
        MediaResource(type: .ambient, name: "White Noise", fileName: "white_noise.mp3")
    ]
    
    static let sampleGuidedAudio: [MediaResource] = [
        MediaResource(type: .audio, name: "Breathing Guide", fileName: "breathing_guide.mp3"),
        MediaResource(type: .audio, name: "Body Scan", fileName: "body_scan.mp3"),
        MediaResource(type: .audio, name: "Loving Kindness", fileName: "loving_kindness.mp3")
    ]
}

// MARK: - IdentifiableInt for sheet index
struct IdentifiableInt: Identifiable {
    var id: Int { value }
    let value: Int
}

// MARK: - Legacy Support (for migration)
@available(*, deprecated, message: "Use BellSound instead")
struct TransitionBell: Equatable {
    var soundName: String
    var displayName: String {
        switch soundName {
        case "None": return "Silent"
        case "Soft Bell": return "Soft Bell"
        case "Tibetan Bowl": return "Tibetan Bowl"
        case "Digital Chime": return "Digital Chime"
        default: return soundName
        }
    }
    
    // Helper to convert to new BellSound
    var bellSound: BellSound {
        switch soundName {
        case "None": return .silent
        case "Soft Bell": return .softBell
        case "Tibetan Bowl": return .tibetanBowl
        case "Digital Chime": return .digitalChime
        default: return .silent
        }
    }
} 
