//
//  CommunityModels.swift
//  Meditation Builder
//

import Foundation

// MARK: - Community Routine

struct CommunityBlock: Codable, Identifiable, Equatable, Hashable, Sendable {
    let blockId: String
    let type: String
    let durationSeconds: Int?
    let soundKey: String?
    let musicAssetKey: String?
    let label: String?

    var id: String { blockId }
}

struct CommunityRoutine: Codable, Identifiable, Equatable, Hashable, Sendable {
    let routineId: String
    let name: String
    var description: String?
    var tags: [String]
    let durationSeconds: Int
    var authorName: String?
    var authorSub: String?
    var likeCount: Int
    var importCount: Int
    var blocks: [CommunityBlock]?
    var audioAssetKeys: [String]?
    var publishedAt: Date?
    var updatedAt: Date?
    var isLikedByMe: Bool?
    var isImportedByMe: Bool?
    var taggingStatus: String?
    var score: Double?

    var id: String { routineId }

    init(
        routineId: String,
        name: String,
        description: String? = nil,
        tags: [String] = [],
        durationSeconds: Int,
        authorName: String? = nil,
        authorSub: String? = nil,
        likeCount: Int = 0,
        importCount: Int = 0,
        blocks: [CommunityBlock]? = nil,
        audioAssetKeys: [String]? = nil,
        publishedAt: Date? = nil,
        updatedAt: Date? = nil,
        isLikedByMe: Bool? = nil,
        isImportedByMe: Bool? = nil,
        taggingStatus: String? = nil,
        score: Double? = nil
    ) {
        self.routineId = routineId
        self.name = name
        self.description = description
        self.tags = tags
        self.durationSeconds = durationSeconds
        self.authorName = authorName
        self.authorSub = authorSub
        self.likeCount = likeCount
        self.importCount = importCount
        self.blocks = blocks
        self.audioAssetKeys = audioAssetKeys
        self.publishedAt = publishedAt
        self.updatedAt = updatedAt
        self.isLikedByMe = isLikedByMe
        self.isImportedByMe = isImportedByMe
        self.taggingStatus = taggingStatus
        self.score = score
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        routineId = try container.decode(String.self, forKey: .routineId)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        authorSub = try container.decodeIfPresent(String.self, forKey: .authorSub)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        importCount = try container.decodeIfPresent(Int.self, forKey: .importCount) ?? 0
        blocks = try container.decodeIfPresent([CommunityBlock].self, forKey: .blocks)
        audioAssetKeys = try container.decodeIfPresent([String].self, forKey: .audioAssetKeys)
        publishedAt = try container.decodeIfPresent(Date.self, forKey: .publishedAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        isLikedByMe = try container.decodeIfPresent(Bool.self, forKey: .isLikedByMe)
        isImportedByMe = try container.decodeIfPresent(Bool.self, forKey: .isImportedByMe)
        taggingStatus = try container.decodeIfPresent(String.self, forKey: .taggingStatus)
        score = try container.decodeIfPresent(Double.self, forKey: .score)
    }

    var durationMinutes: Int { max(1, durationSeconds / 60) }

    var isTaggingPending: Bool { taggingStatus == "pending" }

    /// Converts API blocks into local `RoutineBlock` values for import.
    func toLocalBlocks(
        musicFiles: [String: (fileName: String, displayName: String)] = [:]
    ) -> [RoutineBlock] {
        guard let blocks else { return [] }
        return blocks.enumerated().map { index, block in
            let minutes = max(1, (block.durationSeconds ?? 60) / 60)
            let blockType: MeditationBlock.BlockType
            switch block.type {
            case "bell": blockType = .silence
            case "music": blockType = .custom
            default: blockType = .breathwork
            }
            var routineBlock = RoutineBlock(
                id: UUID(uuidString: block.blockId) ?? UUID(),
                name: block.label ?? "Block \(index + 1)",
                durationInMinutes: minutes,
                type: blockType,
                blockStartBell: BellSound.from(apiSoundKey: block.soundKey)
            )
            if block.type == "music", let key = block.musicAssetKey, let music = musicFiles[key] {
                routineBlock.musicFileName = music.fileName
                routineBlock.musicDisplayName = music.displayName
            }
            return routineBlock
        }
    }

    func toLocalRoutine(
        musicFiles: [String: (fileName: String, displayName: String)] = [:]
    ) -> Routine {
        Routine(
            name: name,
            icon: "globe",
            blocks: toLocalBlocks(musicFiles: musicFiles),
            isSystemRoutine: false
        )
    }
}

// MARK: - Filters

enum BrowseSort: String, CaseIterable, Codable, Sendable {
    case newest
    case popular

    var displayName: String {
        switch self {
        case .newest: return String(localized: "community.sort.newest")
        case .popular: return String(localized: "community.sort.popular")
        }
    }
}

struct BrowseFilters: Equatable, Sendable {
    var tag: String?
    var minDurationMinutes: Int?
    var maxDurationMinutes: Int?
    var sort: BrowseSort = .newest
    var pageSize: Int = 20
}

enum SearchSort: String, CaseIterable, Sendable {
    case textMatch = "_text_match"
    case likeCount = "likeCount:desc"
    case publishedAt = "publishedAt:desc"
}

struct SearchFilters: Equatable, Sendable {
    var tag: String?
    var minDurationMinutes: Int?
    var maxDurationMinutes: Int?
    var sort: SearchSort = .textMatch
    var page: Int = 1
    var pageSize: Int = 20
}

// MARK: - API Responses

struct RoutineListResponse: Codable, Sendable {
    let routines: [CommunityRoutine]
    let nextToken: String?
    let count: Int?
}

struct SearchResponse: Codable, Sendable {
    let results: [CommunityRoutine]
    let found: Int
    let page: Int
    let pageSize: Int
}

struct RecommendationsResponse: Codable, Sendable {
    let recommendations: [CommunityRoutine]
    let cacheHit: Bool?
    let cachedAt: Date?
    let expiresAt: Date?
}

struct LikeResponse: Codable, Sendable {
    let likeCount: Int
}

struct ImportResponse: Codable, Sendable {
    let routineId: String
    let routine: CommunityRoutine
    let importedAt: Date
    let alreadyImported: Bool?
}

struct PublishResponse: Codable, Sendable {
    let routineId: String
    let name: String
    let publishedAt: Date
    let taggingStatus: String?
}

struct ActivityResponse: Codable, Sendable {
    let accepted: Bool
}

// MARK: - Session Activity

struct SessionActivity: Codable, Sendable {
    let sessionDurationSeconds: Int
    let routinesPlayed: [String]
    var tagsEngaged: [String]?
    var blockTypes: [String]?
}

// MARK: - API Error

extension Notification.Name {
    /// Posted when a routine's like state changes (`userInfo`: `routineId`, `likeCount`, `isLiked`).
    static let communityRoutineLikeDidChange = Notification.Name("mb.communityRoutineLikeDidChange")
}

struct CommunityAPIErrorResponse: Codable, Sendable {
    let error: String
    let message: String
    let requestId: String?
}

enum CommunityAPIError: LocalizedError, Sendable {
    case invalidURL
    case unauthorized
    case notFound
    case serverError(String)
    case decodingFailed
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL."
        case .unauthorized: return "Please sign in to continue."
        case .notFound: return "Routine not found."
        case .serverError(let message): return message
        case .decodingFailed: return "Unexpected response from server."
        case .network(let error): return error.localizedDescription
        }
    }
}

// MARK: - Published Routine Tracking

enum PublishedRoutineStore {
    private static func key(for sub: String) -> String { "mb.published.\(sub)" }

    static func ids(for sub: String) -> [String] {
        UserDefaults.standard.stringArray(forKey: key(for: sub)) ?? []
    }

    static func add(_ routineId: String, for sub: String) {
        var ids = Set(ids(for: sub))
        ids.insert(routineId)
        UserDefaults.standard.set(Array(ids), forKey: key(for: sub))
    }

    static func remove(_ routineId: String, for sub: String) {
        var ids = ids(for: sub)
        ids.removeAll { $0 == routineId }
        UserDefaults.standard.set(ids, forKey: key(for: sub))
    }
}

// MARK: - BellSound API Mapping

extension BellSound {
    static func from(apiSoundKey: String?) -> BellSound {
        switch apiSoundKey {
        case "singing_bowl_c", "tibetan_bowl": return .tibetanBowl
        case "soft_bell": return .softBell
        case "digital_chime": return .digitalChime
        default: return .silent
        }
    }

    var apiSoundKey: String? {
        switch self {
        case .silent: return nil
        case .softBell: return "soft_bell"
        case .tibetanBowl: return "singing_bowl_c"
        case .digitalChime: return "digital_chime"
        }
    }
}

// MARK: - Routine → Publish Payload

extension Routine {
    func toPublishPayload(
        userDescription: String? = nil,
        musicAssetKeys: [UUID: String] = [:]
    ) -> [String: Any] {
        let totalSeconds = blocks.reduce(0) { $0 + $1.durationInMinutes * 60 }
        var audioKeys = Set<String>()

        let blockPayloads = blocks.enumerated().map { index, block -> [String: Any] in
            if block.musicFileName != nil, let assetKey = musicAssetKeys[block.id] {
                audioKeys.insert(assetKey)
                return [
                    "blockId": block.id.uuidString,
                    "type": "music",
                    "durationSeconds": block.durationInMinutes * 60,
                    "label": block.name,
                    "musicAssetKey": assetKey,
                ]
            }
            if block.blockStartBell != .silent, let key = block.blockStartBell.apiSoundKey {
                return [
                    "blockId": block.id.uuidString,
                    "type": "bell",
                    "soundKey": key,
                    "label": block.name,
                ]
            }
            _ = index
            return [
                "blockId": block.id.uuidString,
                "type": "timer",
                "durationSeconds": block.durationInMinutes * 60,
                "label": block.name,
            ]
        }

        var payload: [String: Any] = [
            "name": name,
            "durationSeconds": max(totalSeconds, 60),
            "blocks": blockPayloads,
        ]
        if !audioKeys.isEmpty {
            payload["audioAssetKeys"] = Array(audioKeys).sorted()
        }
        if let userDescription, !userDescription.isEmpty {
            payload["userDescription"] = userDescription
        }
        return payload
    }
}
