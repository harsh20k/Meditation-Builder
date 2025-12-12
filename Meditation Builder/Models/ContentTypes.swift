//
//  ContentTypes.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import Foundation
import SwiftUI
import SwiftData

/**
 * ContentTypes.swift
 *
 * This file contains all content-related type definitions for the meditation app,
 * including media content types, bell sounds, and related enums. These types
 * are used throughout the app to categorize and manage different kinds of
 * meditation content and audio resources.
 *
 * ## Key Components:
 * - `BlockContentType`: Defines the types of media content that can be associated with meditation blocks
 * - `BellSound`: Represents different bell sounds used for transitions and notifications
 * - `MediaResource`: SwiftData model for persistent media storage
 *
 * ## Usage:
 * These types are primarily used in:
 * - Routine building and editing
 * - Media resource management
 * - Bell sound selection for blocks and routines
 * - Content categorization and filtering
 */

// MARK: - Block Content Type

/**
 * Defines the different types of media content that can be associated with meditation blocks.
 * Each content type has specific display properties and is used to categorize media resources.
 */
enum BlockContentType: String, Codable, CaseIterable {
    /// Bell sounds used for transitions and notifications
    case bell = "bell"
    /// Guided audio content (narrated meditation instructions)
    case audio = "audio"
    /// Video content for visual meditation guidance
    case video = "video"
    /// Ambient background sounds (nature, white noise, etc.)
    case ambient = "ambient"
    
    /**
     * User-friendly display name for the content type.
     * Uses localized strings for internationalization.
     */
    var displayName: String {
        switch self {
        case .bell: return String(localized: "content.type.bell")
        case .audio: return String(localized: "content.type.audio")
        case .video: return String(localized: "content.type.video")
        case .ambient: return String(localized: "content.type.ambient")
        }
    }
    
    /**
     * Localized string key for use in SwiftUI views.
     * Provides type-safe localization support.
     */
    var titleKey: LocalizedStringKey {
        switch self {
        case .bell: return LocalizedStringKey("content.type.bell")
        case .audio: return LocalizedStringKey("content.type.audio")
        case .video: return LocalizedStringKey("content.type.video")
        case .ambient: return LocalizedStringKey("content.type.ambient")
        }
    }
    
    /**
     * SF Symbol icon name associated with this content type.
     * Used for visual representation in the UI.
     */
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

/**
 * SwiftData model representing a media resource that can be associated with meditation blocks.
 * 
 * Media resources can be audio files, video files, or other content that enhances
 * the meditation experience. They are stored locally by default but can also
 * reference remote URLs for future cloud-based content.
 *
 * ## Properties:
 * - `id`: Unique identifier for the media resource
 * - `type`: The content type (bell, audio, video, ambient)
 * - `name`: Human-readable name for the resource
 * - `fileName`: Local file name or bundle asset identifier
 * - `url`: Optional remote URL for cloud-based content
 * - `orderIndex`: Position in ordered collections
 */
@Model
final class MediaResource: Identifiable {
    /// Unique identifier for the media resource
    var id: UUID
    
    /// The type of content this resource represents
    var type: BlockContentType
    
    /// Human-readable name for the resource (e.g., "Guided Chant", "Rain Loop")
    var name: String
    
    /// Local file name or bundle asset identifier
    var fileName: String
    
    /// Optional remote URL for future cloud-based content
    var url: URL?
    
    /// Position in ordered collections (defaults to 0)
    var orderIndex: Int = 0
    
    /**
     * Initializes a new media resource.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - type: The content type of this resource
     *   - name: Human-readable name
     *   - fileName: Local file name or bundle asset identifier
     *   - url: Optional remote URL
     *   - orderIndex: Position in ordered collections
     */
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

/**
 * Represents different bell sounds that can be used for meditation transitions and notifications.
 * 
 * Bell sounds are used to mark the beginning and end of meditation blocks, as well as
 * the opening and closing of entire routines. They provide audio cues to help users
 * stay focused and aware of their meditation progress.
 */
enum BellSound: String, CaseIterable, Equatable, Codable {
    /// No sound (silent transition)
    case silent = "silent"
    /// Gentle, soft bell sound
    case softBell = "soft_bell"
    /// Traditional Tibetan singing bowl sound
    case tibetanBowl = "tibetan_bowl"
    /// Modern digital chime sound
    case digitalChime = "digital_chime"
    
    /**
     * User-friendly display name for the bell sound.
     * Uses localized strings for internationalization.
     */
    var displayName: String {
        switch self {
        case .silent: return String(localized: "bell.silent")
        case .softBell: return String(localized: "bell.soft")
        case .tibetanBowl: return String(localized: "bell.tibetan")
        case .digitalChime: return String(localized: "bell.digital")
        }
    }
    
    /**
     * Localized string key for use in SwiftUI views.
     * Provides type-safe localization support.
     */
    var titleKey: LocalizedStringKey {
        switch self {
        case .silent: return LocalizedStringKey("bell.silent")
        case .softBell: return LocalizedStringKey("bell.soft")
        case .tibetanBowl: return LocalizedStringKey("bell.tibetan")
        case .digitalChime: return LocalizedStringKey("bell.digital")
        }
    }
    
    /**
     * SF Symbol icon name associated with this bell sound.
     * Used for visual representation in the UI.
     */
    var icon: String {
        switch self {
        case .silent: return "bell.slash.fill"
        case .softBell: return "bell.fill"
        case .tibetanBowl: return "circle.grid.cross"
        case .digitalChime: return "waveform"
        }
    }
    
    /**
     * Default bell sound to use when none is specified.
     * Provides a sensible fallback for new blocks and routines.
     */
    static var `default`: BellSound {
        return .softBell
    }
}

// MARK: - Legacy Support

/**
 * Legacy bell sound structure for migration from older app versions.
 * 
 * This struct provides backward compatibility for users upgrading from
 * previous versions of the app that used different bell sound naming conventions.
 *
 * @deprecated Use `BellSound` enum instead
 */
@available(*, deprecated, message: "Use BellSound instead")
struct TransitionBell: Equatable {
    /// Legacy sound name identifier
    var soundName: String
    
    /**
     * User-friendly display name for the legacy bell sound.
     */
    var displayName: String {
        switch soundName {
        case "None": return "Silent"
        case "Soft Bell": return "Soft Bell"
        case "Tibetan Bowl": return "Tibetan Bowl"
        case "Digital Chime": return "Digital Chime"
        default: return soundName
        }
    }
    
    /**
     * Converts legacy bell sound to the new `BellSound` enum.
     * Used for data migration and backward compatibility.
     */
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