//
//  CommunityAPIClient.swift
//  Meditation Builder
//

import Foundation

@MainActor
final class CommunityAPIClient {
    static let shared = CommunityAPIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private weak var authManager: AuthManager?

    init(
        baseURL: URL = APIConfig.baseURL,
        session: URLSession = .shared,
        authManager: AuthManager? = nil
    ) {
        self.baseURL = baseURL
        self.session = session
        self.authManager = authManager

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
    }

    func configure(authManager: AuthManager) {
        self.authManager = authManager
    }

    // MARK: - Public API

    func browseRoutines(nextToken: String?, filters: BrowseFilters) async throws -> RoutineListResponse {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "pageSize", value: String(filters.pageSize)),
            URLQueryItem(name: "sort", value: filters.sort.rawValue)
        ]
        if let nextToken { items.append(URLQueryItem(name: "nextToken", value: nextToken)) }
        if let tag = filters.tag, !tag.isEmpty { items.append(URLQueryItem(name: "tag", value: tag)) }
        if let min = filters.minDurationMinutes {
            items.append(URLQueryItem(name: "minDuration", value: String(min * 60)))
        }
        if let max = filters.maxDurationMinutes {
            items.append(URLQueryItem(name: "maxDuration", value: String(max * 60)))
        }
        let request = try await makeRequest(path: "/routines", queryItems: items, method: "GET", requiresAuth: false)
        return try await perform(request)
    }

    func getRoutine(id: String) async throws -> CommunityRoutine {
        let request = try await makeRequest(path: "/routines/\(id)", method: "GET", requiresAuth: true)
        return try await perform(request)
    }

    func publishRoutine(
        _ routine: Routine,
        userDescription: String? = nil,
        musicAssetKeys: [UUID: String]? = nil
    ) async throws -> CommunityRoutine {
        let musicKeys: [UUID: String]
        if let musicAssetKeys {
            musicKeys = musicAssetKeys
        } else {
            musicKeys = try await AudioAssetService.uploadMusicAssets(for: routine) { contentType, ext in
                try await self.requestAudioUploadURL(contentType: contentType, fileExtension: ext)
            }
        }
        let payload = routine.toPublishPayload(userDescription: userDescription, musicAssetKeys: musicKeys)
        let body = try JSONSerialization.data(withJSONObject: payload)
        let request = try await makeRequest(path: "/routines", method: "POST", body: body, requiresAuth: true)
        let response: PublishResponse = try await perform(request)
        if let sub = authManager?.currentUserSub {
            PublishedRoutineStore.add(response.routineId, for: sub)
        }
        let uploadedAudioKeys = payload["audioAssetKeys"] as? [String]
        return CommunityRoutine(
            routineId: response.routineId,
            name: response.name,
            description: userDescription,
            tags: [],
            durationSeconds: payload["durationSeconds"] as? Int ?? 0,
            authorName: nil,
            authorSub: authManager?.currentUserSub,
            likeCount: 0,
            importCount: 0,
            blocks: nil,
            audioAssetKeys: uploadedAudioKeys,
            publishedAt: response.publishedAt,
            updatedAt: nil,
            isLikedByMe: nil,
            isImportedByMe: nil,
            taggingStatus: response.taggingStatus,
            score: nil
        )
    }

    func requestAudioUploadURL(contentType: String, fileExtension: String) async throws -> PresignAudioResponse {
        let payload: [String: String] = [
            "contentType": contentType,
            "fileExtension": fileExtension,
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let request = try await makeRequest(path: "/uploads/audio", method: "POST", body: body, requiresAuth: true)
        return try await perform(request)
    }

    func downloadMusicForImport(_ routine: CommunityRoutine) async throws -> [String: (fileName: String, displayName: String)] {
        guard let blocks = routine.blocks else { return [:] }
        var musicFiles: [String: (fileName: String, displayName: String)] = [:]
        for block in blocks where block.type == "music" {
            guard let assetKey = block.musicAssetKey else { continue }
            if musicFiles[assetKey] != nil { continue }
            let displayName = block.label ?? "Music"
            let downloaded = try await AudioAssetService.downloadMusic(
                assetKey: assetKey,
                displayName: displayName
            )
            musicFiles[assetKey] = (fileName: downloaded.storedFileName, displayName: downloaded.displayName)
        }
        return musicFiles
    }

    func deleteRoutine(id: String) async throws {
        let request = try await makeRequest(path: "/routines/\(id)", method: "DELETE", requiresAuth: true)
        let (_, response) = try await session.data(for: request)
        try validate(response: response)
        if let sub = authManager?.currentUserSub {
            PublishedRoutineStore.remove(id, for: sub)
        }
    }

    func importRoutine(id: String) async throws -> ImportResponse {
        let request = try await makeRequest(path: "/routines/\(id)/import", method: "POST", requiresAuth: true)
        return try await perform(request)
    }

    func likeRoutine(id: String) async throws -> Int {
        let request = try await makeRequest(path: "/routines/\(id)/like", method: "POST", requiresAuth: true)
        let response: LikeResponse = try await perform(request)
        return response.likeCount
    }

    func unlikeRoutine(id: String) async throws -> Int {
        let request = try await makeRequest(path: "/routines/\(id)/like", method: "DELETE", requiresAuth: true)
        let response: LikeResponse = try await perform(request)
        return response.likeCount
    }

    func getRecommendations(limit: Int = 10) async throws -> [CommunityRoutine] {
        
        let items = [URLQueryItem(name: "limit", value: String(limit))]
        let request = try await makeRequest(path: "/recommendations", queryItems: items, method: "GET", requiresAuth: true)
        let response: RecommendationsResponse = try await perform(request)
        return response.recommendations
    }

    func search(query: String, filters: SearchFilters) async throws -> [CommunityRoutine] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "sort", value: filters.sort.rawValue),
            URLQueryItem(name: "page", value: String(filters.page)),
            URLQueryItem(name: "pageSize", value: String(filters.pageSize))
        ]
        if let tag = filters.tag, !tag.isEmpty { items.append(URLQueryItem(name: "tag", value: tag)) }
        if let min = filters.minDurationMinutes {
            items.append(URLQueryItem(name: "minDuration", value: String(min * 60)))
        }
        if let max = filters.maxDurationMinutes {
            items.append(URLQueryItem(name: "maxDuration", value: String(max * 60)))
        }
        let request = try await makeRequest(path: "/search", queryItems: items, method: "GET", requiresAuth: false)
        let response: SearchResponse = try await perform(request)
        return response.results
    }

    func postActivity(_ activity: SessionActivity) async throws {
        let body = try encoder.encode(activity)
        let request = try await makeRequest(path: "/activity", method: "POST", body: body, requiresAuth: true)
        let _: ActivityResponse = try await perform(request)
    }

    // MARK: - Networking

    private func makeRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String,
        body: Data? = nil,
        requiresAuth: Bool
    ) async throws -> URLRequest {
        guard var components = URLComponents(url: baseURL.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))), resolvingAgainstBaseURL: false) else {
            throw CommunityAPIError.invalidURL
        }
        if !queryItems.isEmpty { components.queryItems = queryItems }
        guard let url = components.url else { throw CommunityAPIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        if requiresAuth {
            guard let token = try await authManager?.bearerToken(), !token.isEmpty else {
                throw CommunityAPIError.unauthorized
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else if let token = try await authManager?.bearerToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            try validate(response: response, data: data)
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw CommunityAPIError.decodingFailed
            }
        } catch let error as CommunityAPIError {
            throw error
        } catch {
            throw CommunityAPIError.network(error)
        }
    }

    private func validate(response: URLResponse, data: Data? = nil) throws {
        guard let http = response as? HTTPURLResponse else { return }
        switch http.statusCode {
        case 200...299, 204:
            return
        case 401:
            throw CommunityAPIError.unauthorized
        case 404:
            throw CommunityAPIError.notFound
        default:
            if let data,
               let apiError = try? decoder.decode(CommunityAPIErrorResponse.self, from: data) {
                throw CommunityAPIError.serverError(apiError.message)
            }
            throw CommunityAPIError.serverError("Request failed (\(http.statusCode)).")
        }
    }
}
