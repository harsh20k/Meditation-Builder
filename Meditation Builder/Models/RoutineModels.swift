//
//  RoutineModels.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import Foundation
import SwiftUI
import SwiftData
import Dragula

/**
 * RoutineModels.swift
 *
 * This file contains all models related to meditation routines, including
 * individual meditation blocks, routine composition, and persistent storage.
 * It defines both value types for routine building and SwiftData models for
 * persistent storage.
 *
 * ## Key Components:
 * - `MeditationBlock`: SwiftData model for individual meditation blocks
 * - `RoutineBlock`: Value type for routine building (non-persistent)
 * - `Routine`: Value type representing a complete meditation routine
 * - `SavedRoutine`: SwiftData model for persistent routine storage
 * - `MediaInfo`: Value type for media resources in routine building
 *
 * ## Architecture:
 * The file follows a dual-model pattern where value types (`Routine`, `RoutineBlock`)
 * are used for building and editing routines, while SwiftData models (`SavedRoutine`,
 * `MeditationBlock`) handle persistence. This separation allows for efficient
 * routine building without database overhead.
 *
 * ## Usage:
 * These models are used in:
 * - Routine builder interface
 * - Routine library management
 * - Routine editing and customization
 * - Data persistence and retrieval
 */

// MARK: - Meditation Block

/**
 * SwiftData model representing an individual meditation block within a routine.
 * 
 * A meditation block is a discrete unit of meditation practice with a specific
 * type, duration, and associated media resources. Blocks are ordered within
 * routines and can have different meditation techniques (silence, breathwork,
 * chanting, etc.).
 *
 * ## Properties:
 * - `id`: Unique identifier for the block
 * - `name`: Human-readable name for the block
 * - `durationInMinutes`: Planned duration in minutes
 * - `type`: The type of meditation technique
 * - `blockStartBell`: Bell sound to play when block starts
 * - `blockIcon`: SF Symbol icon for visual representation
 * - `orderIndex`: Position within the routine
 * - `isFavorite`: Whether this block is marked as favorite
 * - `media`: Associated media resources (cascade deleted)
 */
@Model
final class MeditationBlock: Identifiable, DragulaItem {
    /// Unique identifier for the meditation block
    var id: UUID
    
    /// Human-readable name for the block
    var name: String
    
    /// Planned duration of the block in minutes
    var durationInMinutes: Int
    
    /// The type of meditation technique for this block
    var type: BlockType
    
    /// Bell sound to play when this block starts
    var blockStartBell: BellSound
    
    /// SF Symbol icon name for visual representation (defaults to "circle.fill")
    var blockIcon: String = "circle.fill"
    
    /// Position within the routine (defaults to 0)
    var orderIndex: Int = 0
    
    /// Whether this block is marked as favorite
    var isFavorite: Bool = false
    
    /// Associated media resources (cascade deleted when block is deleted)
    @Relationship(deleteRule: .cascade) var media: [MediaResource]
    
    /// Theme this block belongs to (optional)
    @Relationship(deleteRule: .nullify, inverse: \Theme.blocks)
    var theme: Theme?
    
    /**
     * Initializes a new meditation block.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - name: Human-readable name for the block
     *   - durationInMinutes: Planned duration in minutes
     *   - type: The type of meditation technique
     *   - blockStartBell: Bell sound for block start (defaults to .default)
     *   - blockIcon: SF Symbol icon name (defaults to type.icon if nil)
     *   - orderIndex: Position within routine (defaults to 0)
     *   - isFavorite: Whether this block is marked as favorite (defaults to false)
     *   - media: Associated media resources (defaults to empty array)
     */
    init(id: UUID = UUID(), name: String, durationInMinutes: Int, type: BlockType, blockStartBell: BellSound = .default, blockIcon: String? = nil, orderIndex: Int = 0, isFavorite: Bool = false, media: [MediaResource] = []) {
        self.id = id
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.type = type
        self.blockStartBell = blockStartBell
        self.blockIcon = blockIcon ?? type.icon
        self.orderIndex = orderIndex
        self.isFavorite = isFavorite
        self.media = media
    }
    
    // MARK: - Block Type
    
    /**
     * Defines the different types of meditation techniques that can be used in blocks.
     * Each type has specific properties including display names, icons, and default durations.
     */
    enum BlockType: String, CaseIterable, Codable {
        /// Silent meditation with no guidance
        case silence = "silence"
        /// Breathing exercises and techniques
        case breathwork = "breathwork"
        /// Chanting or mantra repetition
        case chanting = "chanting"
        /// Guided visualization exercises
        case visualization = "visualization"
        /// Body awareness and scanning techniques
        case bodyScan = "body_scan"
        /// Walking meditation
        case walking = "walking"
        /// Custom meditation technique
        case custom = "custom"
        
        /**
         * User-friendly display name for the block type.
         * Uses localized strings for internationalization.
         */
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
        
        /**
         * Localized string key for use in SwiftUI views.
         * Provides type-safe localization support.
         */
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
        
        /**
         * SF Symbol icon name associated with this block type.
         * Used for visual representation in the UI.
         */
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
        
        /**
         * Default duration in minutes for this block type.
         * Provides sensible defaults for new blocks.
         */
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

// MARK: - Theme

/**
 * Defines the type of meditation content a theme can be applied to.
 */
enum ThemeType: String, Codable {
    /// Theme can only be applied to routines
    case routine = "routine"
    /// Theme can only be applied to blocks
    case block = "block"
    /// Theme can be applied to both routines and blocks
    case both = "both"
}

/**
 * SwiftData model representing a theme that can be applied to routines or blocks.
 * 
 * Themes provide a way to categorize and organize meditation content. They are
 * designed to be extensible for future features while maintaining a simple initial
 * implementation.
 *
 * ## Properties:
 * - `id`: Unique identifier
 * - `name`: Display name for the theme
 * - `icon`: SF Symbol name for visual representation
 * - `themeType`: What type of content this theme can be applied to
 * - `color`: Theme color for visual distinction
 * - `version`: Schema version for future migrations
 * - `metadata`: Extensible properties for future features
 */
@Model
final class Theme: Identifiable {
    /// Unique identifier for the theme
    var id: UUID
    
    /// Display name for the theme
    var name: String
    
    /// SF Symbol name for visual representation
    var icon: String
    
    /// What type of content this theme can be applied to
    var themeType: ThemeType
    
    /// Theme color stored as hex string (e.g. "#FF0000" for red)
    var colorHex: String = "#0000FF"  // Default to blue
    
    /// Schema version for future migrations
    var version: Int = 1
    
    /// Extensible properties for future features
    var metadata: [String: String] = [:]
    
    /// Routines associated with this theme (one-to-many)
    @Relationship(deleteRule: .nullify)
    var routines: [SavedRoutine] = []
    
    /// Blocks associated with this theme (one-to-many)
    @Relationship(deleteRule: .nullify)
    var blocks: [MeditationBlock] = []
    
    /**
     * Initializes a new theme.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - name: Display name for the theme
     *   - icon: SF Symbol name
     *   - themeType: What type of content this theme can be applied to
     *   - color: Theme color
     *   - version: Schema version (defaults to 1)
     *   - metadata: Additional properties (defaults to empty)
     */
    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        themeType: ThemeType,
        color: String = "#0000FF",
        version: Int = 1,
        metadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.themeType = themeType
        self.colorHex = color
        self.version = version
        self.metadata = metadata
    }
}

// MARK: - Value Types for Routine Building

/**
 * Value type version of MediaResource for routine building.
 * 
 * This struct is used during routine building and editing to avoid
 * SwiftData overhead. It's converted to/from MediaResource when
 * saving or loading routines.
 */
struct MediaInfo: Identifiable, Codable, Equatable {
    /// Unique identifier for the media resource
    var id: UUID
    
    /// The type of content this resource represents
    var type: BlockContentType
    
    /// Human-readable name for the resource
    var name: String
    
    /// Local file name or bundle asset identifier
    var fileName: String
    
    /// Optional remote URL for cloud-based content
    var url: URL?
    
    /**
     * Initializes a new media info value.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - type: The content type of this resource
     *   - name: Human-readable name
     *   - fileName: Local file name or bundle asset identifier
     *   - url: Optional remote URL
     */
    init(id: UUID = UUID(), type: BlockContentType, name: String, fileName: String, url: URL? = nil) {
        self.id = id
        self.type = type
        self.name = name
        self.fileName = fileName
        self.url = url
    }
}

/**
 * Value type version of MeditationBlock for routine building.
 * 
 * This struct is used during routine building and editing to avoid
 * SwiftData overhead. It's converted to/from MeditationBlock when
 * saving or loading routines.
 */
struct RoutineBlock: Identifiable, Equatable, Codable, DragulaItem {
    /// Unique identifier for the block
    var id: UUID
    
    /// Human-readable name for the block
    var name: String
    
    /// Planned duration of the block in minutes
    var durationInMinutes: Int
    
    /// The type of meditation technique for this block
    var type: MeditationBlock.BlockType
    
    /// Bell sound to play when this block starts
    var blockStartBell: BellSound
    
    /// SF Symbol icon name for visual representation
    var blockIcon: String
    
    /// Associated media resources
    var media: [MediaInfo]
    
    /// Whether this block is marked as favorite
    var isFavorite: Bool = false
    
    /**
     * Initializes a new routine block value.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - name: Human-readable name for the block
     *   - durationInMinutes: Planned duration in minutes
     *   - type: The type of meditation technique
     *   - blockStartBell: Bell sound for block start (defaults to .default)
     *   - blockIcon: SF Symbol icon name (defaults to type.icon if nil)
     *   - media: Associated media resources (defaults to empty array)
     *   - isFavorite: Whether this block is marked as favorite (defaults to false)
     */
    init(id: UUID = UUID(), name: String, durationInMinutes: Int, type: MeditationBlock.BlockType, blockStartBell: BellSound = .default, blockIcon: String? = nil, media: [MediaInfo] = [], isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.durationInMinutes = durationInMinutes
        self.type = type
        self.blockStartBell = blockStartBell
        self.blockIcon = blockIcon ?? type.icon
        self.media = media
        self.isFavorite = isFavorite
    }
}

// MARK: - Routine

/**
 * Value type representing a complete meditation routine.
 * 
 * A routine is a sequence of meditation blocks with associated metadata
 * like opening/closing bells and media resources. This struct is used
 * for routine building and editing, then converted to SavedRoutine for
 * persistence.
 *
 * ## Properties:
 * - `name`: Human-readable name for the routine
 * - `icon`: SF Symbol icon for visual representation
 * - `blocks`: Ordered sequence of meditation blocks
 * - `openingBell`: Bell sound to play when routine starts
 * - `closingBell`: Bell sound to play when routine ends
 * - `media`: Associated media resources for the routine
 */
struct Routine: Equatable, Codable {
    /// Human-readable name for the routine
    var name: String
    
    /// SF Symbol icon name for visual representation (defaults to "sun.max.fill")
    var icon: String
    
    /// Ordered sequence of meditation blocks
    var blocks: [RoutineBlock]
    
    /// Bell sound to play when the routine starts (defaults to .softBell)
    var openingBell: BellSound
    
    /// Bell sound to play when the routine ends (defaults to .softBell)
    var closingBell: BellSound
    
    /// Associated media resources for the routine (empty for MVP)
    var media: [MediaInfo]
    
    /**
     * Initializes a new routine.
     *
     * - Parameters:
     *   - name: Human-readable name for the routine
     *   - icon: SF Symbol icon name (defaults to "sun.max.fill")
     *   - blocks: Ordered sequence of meditation blocks
     *   - openingBell: Bell sound for routine start (defaults to .softBell)
     *   - closingBell: Bell sound for routine end (defaults to .softBell)
     *   - media: Associated media resources (defaults to empty array)
     */
    init(name: String, icon: String = "sun.max.fill", blocks: [RoutineBlock], openingBell: BellSound = .softBell, closingBell: BellSound = .softBell, media: [MediaInfo] = []) {
        self.name = name
        self.icon = icon
        self.blocks = blocks
        self.openingBell = openingBell
        self.closingBell = closingBell
        self.media = media
    }
    
    /**
     * Equality comparison for routines.
     * Compares all properties to determine if routines are identical.
     */
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

/**
 * SwiftData model for persistent storage of meditation routines.
 * 
 * This model stores routine data in the database and provides methods
 * for converting between value types (for building/editing) and
 * persistent models (for storage). It includes metadata like creation
 * dates, version tracking, and soft delete support.
 *
 * ## Properties:
 * - `id`: Unique identifier for the saved routine
 * - `routineName`: Human-readable name for the routine
 * - `routineIcon`: SF Symbol icon for visual representation
 * - `blocks`: Ordered sequence of meditation blocks (cascade deleted)
 * - `openingBell`: Bell sound to play when routine starts
 * - `closingBell`: Bell sound to play when routine ends
 * - `media`: Associated media resources (cascade deleted)
 * - `createdAt`: When the routine was created
 * - `lastModified`: When the routine was last modified
 * - `version`: Version number for change tracking
 * - `playCount`: Number of times the routine has been played
 * - `lastPlayed`: When the routine was last played
 * - `isDeleted`: Soft delete flag
 * - `deletedAt`: When the routine was soft deleted
 * - `isFavorite`: Whether this routine is marked as favorite
 */
@Model
final class SavedRoutine: Identifiable {
    /// Unique identifier for the saved routine
    var id: UUID
    
    /// Human-readable name for the routine
    var routineName: String
    
    /// SF Symbol icon name for visual representation (defaults to "sun.max.fill")
    var routineIcon: String = "sun.max.fill"
    
    /// Ordered sequence of meditation blocks (cascade deleted when routine is deleted)
    @Relationship(deleteRule: .cascade) var blocks: [MeditationBlock]
    
    /// Bell sound to play when the routine starts
    var openingBell: BellSound
    
    /// Bell sound to play when the routine ends
    var closingBell: BellSound
    
    /// Associated media resources (cascade deleted when routine is deleted)
    @Relationship(deleteRule: .cascade) var media: [MediaResource]
    
    /// When the routine was created
    var createdAt: Date
    
    /// When the routine was last modified
    var lastModified: Date
    
    /// Version number for change tracking
    var version: Int
    
    /// Number of times the routine has been played
    var playCount: Int
    
    /// When the routine was last played (nil if never played)
    var lastPlayed: Date?
    
    /// Soft delete flag - routines marked as deleted are hidden from users
    var isDeleted: Bool = false
    
    /// When the routine was soft deleted (nil if not deleted)
    var deletedAt: Date?
    
    /// Whether this routine is marked as favorite
    var isFavorite: Bool = false
    
    /// Theme this routine belongs to (optional)
    @Relationship(deleteRule: .nullify, inverse: \Theme.routines)
    var theme: Theme?
    
    // MARK: - Conversion Methods
    
    /**
     * Converts the saved routine to a value type for building and editing.
     * 
     * This method creates a `Routine` struct with all the data from this
     * saved routine, properly ordered and converted to value types.
     *
     * - Returns: A `Routine` value type representation of this saved routine
     */
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
                    },
                    isFavorite: block.isFavorite
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
    
    /**
     * Updates this saved routine from a value type routine.
     * 
     * This method preserves order and identity by smartly updating existing
     * blocks and media resources rather than recreating them. This ensures
     * that SwiftData relationships remain intact.
     *
     * - Parameter routine: The value type routine to update from
     */
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
        
        // Preserve favorite status during updates
        // isFavorite remains unchanged
    }
    
    // MARK: - Private Update Methods
    
    /**
     * Smartly updates blocks from routine blocks while preserving identity.
     * 
     * This method updates existing blocks in place when possible to maintain
     * SwiftData relationships, and creates new blocks only when necessary.
     *
     * - Parameter routineBlocks: The routine blocks to update from
     */
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
                existingBlock.isFavorite = routineBlock.isFavorite
                
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
                    isFavorite: routineBlock.isFavorite,
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
    
    /**
     * Smartly updates media for a specific block while preserving identity.
     *
     * - Parameters:
     *   - block: The block to update media for
     *   - mediaInfos: The media infos to update from
     */
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
    
    /**
     * Smartly updates routine-level media while preserving identity.
     *
     * - Parameter mediaInfos: The media infos to update from
     */
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
    
    // MARK: - Initialization
    
    /**
     * Initializes a new saved routine from a value type routine.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - routine: The value type routine to create from
     *   - createdAt: When the routine was created (defaults to current date)
     *   - lastModified: When the routine was last modified (defaults to current date)
     *   - version: Version number (defaults to 1)
     *   - playCount: Number of times played (defaults to 0)
     *   - lastPlayed: When last played (defaults to nil)
     *   - isFavorite: Whether this routine is marked as favorite (defaults to false)
     */
    init(
        id: UUID = UUID(),
        routine: Routine,
        createdAt: Date = Date(),
        lastModified: Date = Date(),
        version: Int = 1,
        playCount: Int = 0,
        lastPlayed: Date? = nil,
        isFavorite: Bool = false
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
        self.isFavorite = isFavorite
    }
    
    // MARK: - Helper Methods
    
    /**
     * Records a play of this routine.
     * 
     * Increments the play count and updates the last played timestamp.
     * Also updates the last modified date to reflect the change.
     */
    func recordPlay() {
        self.playCount += 1
        self.lastPlayed = Date()
        self.lastModified = Date()
    }
}

// MARK: - Sample Data

/**
 * Sample media resources for demonstration and testing purposes.
 * 
 * These extensions provide sample data that can be used during development
 * or for first-time users who need example content.
 */
extension MediaInfo {
    /**
     * Sample bell sounds for demonstration.
     *
     * - Returns: Array of sample bell sound media infos
     */
    static func sampleBellSounds() -> [MediaInfo] {
        [
            MediaInfo(type: .bell, name: "Tibetan Bowl", fileName: "tibetan_bowl.mp3"),
            MediaInfo(type: .bell, name: "Soft Bell", fileName: "soft_bell.mp3"),
            MediaInfo(type: .bell, name: "Digital Chime", fileName: "digital_chime.mp3")
        ]
    }
    
    /**
     * Sample ambient sounds for demonstration.
     *
     * - Returns: Array of sample ambient sound media infos
     */
    static func sampleAmbientSounds() -> [MediaInfo] {
        [
            MediaInfo(type: .ambient, name: "Rain Loop", fileName: "rain_loop.mp3"),
            MediaInfo(type: .ambient, name: "Ocean Waves", fileName: "ocean_waves.mp3"),
            MediaInfo(type: .ambient, name: "Forest Birds", fileName: "forest_birds.mp3"),
            MediaInfo(type: .ambient, name: "White Noise", fileName: "white_noise.mp3")
        ]
    }
    
    /**
     * Sample guided audio for demonstration.
     *
     * - Returns: Array of sample guided audio media infos
     */
    static func sampleGuidedAudio() -> [MediaInfo] {
        [
            MediaInfo(type: .audio, name: "Breathing Guide", fileName: "breathing_guide.mp3"),
            MediaInfo(type: .audio, name: "Body Scan", fileName: "body_scan.mp3"),
            MediaInfo(type: .audio, name: "Loving Kindness", fileName: "loving_kindness.mp3")
        ]
    }
}

// MARK: - Utility Types

/**
 * Utility type for sheet presentation with integer values.
 * 
 * This struct wraps an integer value to make it identifiable for use
 * in SwiftUI sheets and other views that require identifiable content.
 */
struct IdentifiableInt: Identifiable {
    /// The integer value wrapped by this struct
    let value: Int
    
    /// The identifier (same as the value)
    var id: Int { value }
} 
