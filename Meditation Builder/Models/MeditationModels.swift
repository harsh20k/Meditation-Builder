	//
	//  MeditationModels.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import Foundation
import SwiftUI
import SwiftData
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
@Model
final class MediaResource: Identifiable {
    var id: UUID
    var type: BlockContentType
    var name: String            // "Guided Chant", "Rain Loop", etc.
    var fileName: String        // local or bundle asset name
    var url: URL?               // future remote URL
    var orderIndex: Int = 0     // Add explicit ordering with default value
    
    init(id: UUID = UUID(), type: BlockContentType, name: String, fileName: String, url: URL? = nil, orderIndex: Int = 0) {
        self.id = id
        self.type = type
        self.name = name
        self.fileName = fileName
        self.url = url
        self.orderIndex = orderIndex
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
		return .softBell
	}
}

// MARK: - Meditation Block
@Model
final class MeditationBlock: Identifiable, DragulaItem {
    var id: UUID
    var name: String
    var durationInMinutes: Int
    var type: BlockType
    var blockStartBell: BellSound
    var blockIcon: String = "circle.fill"  // SF Symbol icon name with default value
    var orderIndex: Int = 0  // Add explicit ordering with default value
    @Relationship(deleteRule: .cascade) var media: [MediaResource]  // ← empty for MVP, uplevel later
    
    init(id: UUID = UUID(), name: String, durationInMinutes: Int, type: BlockType, blockStartBell: BellSound = .default, blockIcon: String? = nil, orderIndex: Int = 0, media: [MediaResource] = []) {
        self.id = id
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.type = type
        self.blockStartBell = blockStartBell
        self.blockIcon = blockIcon ?? type.icon
        self.orderIndex = orderIndex
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

// MARK: - Value Types for Routine Building (Non-persistent)

// Value type version of MediaResource for routine building
struct MediaInfo: Identifiable, Codable, Equatable {
	var id: UUID
	var type: BlockContentType
	var name: String
	var fileName: String
	var url: URL?
	
	init(id: UUID = UUID(), type: BlockContentType, name: String, fileName: String, url: URL? = nil) {
		self.id = id
		self.type = type
		self.name = name
		self.fileName = fileName
		self.url = url
	}
}

// Value type version of MeditationBlock for routine building
struct RoutineBlock: Identifiable, Equatable, Codable, DragulaItem {
	var id: UUID
	var name: String
	var durationInMinutes: Int
	var type: MeditationBlock.BlockType
	var blockStartBell: BellSound
	var blockIcon: String  // SF Symbol icon name
	var media: [MediaInfo]
	
	init(id: UUID = UUID(), name: String, durationInMinutes: Int, type: MeditationBlock.BlockType, blockStartBell: BellSound = .default, blockIcon: String? = nil, media: [MediaInfo] = []) {
		self.id = id
		self.name = name
		self.durationInMinutes = durationInMinutes
		self.type = type
		self.blockStartBell = blockStartBell
		self.blockIcon = blockIcon ?? type.icon
		self.media = media
	}
}

// MARK: - Routine
struct Routine: Equatable, Codable {
	var name: String
	var icon: String  // SF Symbol icon name
	var blocks: [RoutineBlock]
	var openingBell: BellSound
	var closingBell: BellSound
	var media: [MediaInfo]  // ← empty for MVP, uplevel later
	
	init(name: String, icon: String = "sun.max.fill", blocks: [RoutineBlock], openingBell: BellSound = .softBell, closingBell: BellSound = .softBell, media: [MediaInfo] = []) {
		self.name = name
		self.icon = icon
		self.blocks = blocks
		self.openingBell = openingBell
		self.closingBell = closingBell
		self.media = media
	}
	
	static func == (lhs: Routine, rhs: Routine) -> Bool {
		lhs.name == rhs.name &&
		lhs.icon == rhs.icon &&
		lhs.blocks == rhs.blocks &&
		lhs.openingBell == rhs.openingBell &&
		lhs.closingBell == rhs.closingBell &&
		lhs.media == rhs.media
	}
}

// MARK: - Saved Routine
@Model
final class SavedRoutine: Identifiable {
	var id: UUID
	
	// Instead of embedding Routine, we'll store its properties directly
	var routineName: String
	var routineIcon: String = "sun.max.fill"  // SF Symbol icon name with default value
	@Relationship(deleteRule: .cascade) var blocks: [MeditationBlock]
	var openingBell: BellSound
	var closingBell: BellSound
	@Relationship(deleteRule: .cascade) var media: [MediaResource]
	
	var createdAt: Date
	var lastModified: Date
	var version: Int
	var playCount: Int
	var lastPlayed: Date?
	
	// Helper method to get routine (instead of computed property)
    func getRoutine() -> Routine {
        Routine(
            name: routineName,
            icon: routineIcon,
            blocks: blocks.sorted(by: { $0.orderIndex < $1.orderIndex }).map { block in
                RoutineBlock(
                    id: block.id,
                    name: block.name,
                    durationInMinutes: block.durationInMinutes,
                    type: block.type,
                    blockStartBell: block.blockStartBell,
                    blockIcon: block.blockIcon,
                    media: block.media.sorted(by: { $0.orderIndex < $1.orderIndex }).map { media in
                        MediaInfo(
                            id: media.id,
                            type: media.type,
                            name: media.name,
                            fileName: media.fileName,
                            url: media.url
                        )
                    }
                )
            },
            openingBell: openingBell,
            closingBell: closingBell,
            media: media.sorted(by: { $0.orderIndex < $1.orderIndex }).map { media in
                MediaInfo(
                    id: media.id,
                    type: media.type,
                    name: media.name,
                    fileName: media.fileName,
                    url: media.url
                )
            }
        )
    }
	
	// Helper method to update from routine (preserves order and identity)
    func updateFromRoutine(_ routine: Routine) {
        routineName = routine.name
        routineIcon = routine.icon
        
        // Smart update of blocks to preserve order and identity
        updateBlocks(from: routine.blocks)
        
        // Smart update of media
        updateMedia(from: routine.media)
        
        openingBell = routine.openingBell
        closingBell = routine.closingBell
        lastModified = Date()
    }
    
    private func updateBlocks(from routineBlocks: [RoutineBlock]) {
        // Create a dictionary for quick lookup of existing blocks by ID
        var existingBlocksDict = Dictionary(uniqueKeysWithValues: blocks.map { ($0.id, $0) })
        
        // Prepare the new blocks array maintaining order
        var newBlocks: [MeditationBlock] = []
        
        for (index, routineBlock) in routineBlocks.enumerated() {
            if let existingBlock = existingBlocksDict[routineBlock.id] {
                // Update existing block in place (preserves SwiftData identity)
                existingBlock.name = routineBlock.name
                existingBlock.durationInMinutes = routineBlock.durationInMinutes
                existingBlock.type = routineBlock.type
                existingBlock.blockStartBell = routineBlock.blockStartBell
                existingBlock.blockIcon = routineBlock.blockIcon
                existingBlock.orderIndex = index  // Set the order based on position
                
                // Update media for this block
                updateBlockMedia(existingBlock, from: routineBlock.media)
                
                newBlocks.append(existingBlock)
                existingBlocksDict.removeValue(forKey: routineBlock.id)
            } else {
                // Create new block
                let newBlock = MeditationBlock(
                    id: routineBlock.id,
                    name: routineBlock.name,
                    durationInMinutes: routineBlock.durationInMinutes,
                    type: routineBlock.type,
                    blockStartBell: routineBlock.blockStartBell,
                    blockIcon: routineBlock.blockIcon,
                    orderIndex: index,
                    media: routineBlock.media.enumerated().map { (mediaIndex, mediaInfo) in
                        MediaResource(
                            id: mediaInfo.id,
                            type: mediaInfo.type,
                            name: mediaInfo.name,
                            fileName: mediaInfo.fileName,
                            url: mediaInfo.url,
                            orderIndex: mediaIndex
                        )
                    }
                )
                newBlocks.append(newBlock)
            }
        }
        
        // Update the blocks array
        blocks = newBlocks
    }
    
    private func updateBlockMedia(_ block: MeditationBlock, from mediaInfos: [MediaInfo]) {
        // Create a dictionary for quick lookup of existing media by ID
        var existingMediaDict = Dictionary(uniqueKeysWithValues: block.media.map { ($0.id, $0) })
        
        // Prepare the new media array maintaining order
        var newMedia: [MediaResource] = []
        
        for (index, mediaInfo) in mediaInfos.enumerated() {
            if let existingMedia = existingMediaDict[mediaInfo.id] {
                // Update existing media in place (preserves SwiftData identity)
                existingMedia.type = mediaInfo.type
                existingMedia.name = mediaInfo.name
                existingMedia.fileName = mediaInfo.fileName
                existingMedia.url = mediaInfo.url
                existingMedia.orderIndex = index  // Set the order based on position
                
                newMedia.append(existingMedia)
                existingMediaDict.removeValue(forKey: mediaInfo.id)
            } else {
                // Create new media
                let newMediaResource = MediaResource(
                    id: mediaInfo.id,
                    type: mediaInfo.type,
                    name: mediaInfo.name,
                    fileName: mediaInfo.fileName,
                    url: mediaInfo.url,
                    orderIndex: index
                )
                newMedia.append(newMediaResource)
            }
        }
        
        // Update the media array
        block.media = newMedia
    }
    
    private func updateMedia(from mediaInfos: [MediaInfo]) {
        // Create a dictionary for quick lookup of existing media by ID
        var existingMediaDict = Dictionary(uniqueKeysWithValues: media.map { ($0.id, $0) })
        
        // Prepare the new media array maintaining order
        var newMedia: [MediaResource] = []
        
        for (index, mediaInfo) in mediaInfos.enumerated() {
            if let existingMedia = existingMediaDict[mediaInfo.id] {
                // Update existing media in place (preserves SwiftData identity)
                existingMedia.type = mediaInfo.type
                existingMedia.name = mediaInfo.name
                existingMedia.fileName = mediaInfo.fileName
                existingMedia.url = mediaInfo.url
                existingMedia.orderIndex = index  // Set the order based on position
                
                newMedia.append(existingMedia)
                existingMediaDict.removeValue(forKey: mediaInfo.id)
            } else {
                // Create new media
                let newMediaResource = MediaResource(
                    id: mediaInfo.id,
                    type: mediaInfo.type,
                    name: mediaInfo.name,
                    fileName: mediaInfo.fileName,
                    url: mediaInfo.url,
                    orderIndex: index
                )
                newMedia.append(newMediaResource)
            }
        }
        
        // Update the media array
        media = newMedia
    }
	
	init(
		id: UUID = UUID(),
		routine: Routine,
		createdAt: Date = Date(),
		lastModified: Date = Date(),
		version: Int = 1,
		playCount: Int = 0,
		lastPlayed: Date? = nil
	) {
		self.id = id
		self.routineName = routine.name
		self.routineIcon = routine.icon
		self.blocks = routine.blocks.enumerated().map { (blockIndex, routineBlock) in
			MeditationBlock(
				id: routineBlock.id,
				name: routineBlock.name,
				durationInMinutes: routineBlock.durationInMinutes,
				type: routineBlock.type,
				blockStartBell: routineBlock.blockStartBell,
				blockIcon: routineBlock.blockIcon,
				orderIndex: blockIndex,
				media: routineBlock.media.enumerated().map { (mediaIndex, mediaInfo) in
					MediaResource(
						id: mediaInfo.id,
						type: mediaInfo.type,
						name: mediaInfo.name,
						fileName: mediaInfo.fileName,
						url: mediaInfo.url,
						orderIndex: mediaIndex
					)
				}
			)
		}
		self.openingBell = routine.openingBell
		self.closingBell = routine.closingBell
		self.media = routine.media.enumerated().map { (index, mediaInfo) in
            MediaResource(
                id: mediaInfo.id,
                type: mediaInfo.type,
                name: mediaInfo.name,
                fileName: mediaInfo.fileName,
                url: mediaInfo.url,
                orderIndex: index
            )
        }
		self.createdAt = createdAt
		self.lastModified = lastModified
		self.version = version
		self.playCount = playCount
		self.lastPlayed = lastPlayed
	}
	
	// Helper method to increment play count
	func recordPlay() {
		self.playCount += 1
		self.lastPlayed = Date()
		self.lastModified = Date()
	}
}

// MARK: - Sample Media Resources (for future use)
extension MediaInfo {
	static func sampleBellSounds() -> [MediaInfo] {
		[
			MediaInfo(type: .bell, name: "Tibetan Bowl", fileName: "tibetan_bowl.mp3"),
			MediaInfo(type: .bell, name: "Soft Bell", fileName: "soft_bell.mp3"),
			MediaInfo(type: .bell, name: "Digital Chime", fileName: "digital_chime.mp3")
			]
	}
	
	static func sampleAmbientSounds() -> [MediaInfo] {
		[
			MediaInfo(type: .ambient, name: "Rain Loop", fileName: "rain_loop.mp3"),
			MediaInfo(type: .ambient, name: "Ocean Waves", fileName: "ocean_waves.mp3"),
			MediaInfo(type: .ambient, name: "Forest Birds", fileName: "forest_birds.mp3"),
			MediaInfo(type: .ambient, name: "White Noise", fileName: "white_noise.mp3")
		]
	}
	
	static func sampleGuidedAudio() -> [MediaInfo] {
		[
			MediaInfo(type: .audio, name: "Breathing Guide", fileName: "breathing_guide.mp3"),
			MediaInfo(type: .audio, name: "Body Scan", fileName: "body_scan.mp3"),
			MediaInfo(type: .audio, name: "Loving Kindness", fileName: "loving_kindness.mp3")
		]
	}
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
