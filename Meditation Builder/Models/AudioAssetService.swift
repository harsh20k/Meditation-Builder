//
//  AudioAssetService.swift
//  Meditation Builder
//

import Foundation

struct PresignAudioResponse: Codable, Sendable {
    let assetKey: String
    let uploadUrl: String
    let expiresIn: Int
}

enum AudioAssetService {
    static func cdnURL(for assetKey: String) -> URL {
        var base = APIConfig.audioCDNBaseURL.absoluteString
        if base.hasSuffix("/") { base.removeLast() }
        guard let url = URL(string: "\(base)/\(assetKey)") else {
            return APIConfig.audioCDNBaseURL
        }
        return url
    }

    static func contentType(for fileName: String) -> (contentType: String, fileExtension: String) {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "mp3", "mpeg": return ("audio/mpeg", ext.isEmpty ? "mp3" : ext)
        case "wav": return ("audio/wav", "wav")
        case "aiff", "aif": return ("audio/aiff", ext.isEmpty ? "aiff" : ext)
        case "mp4": return ("audio/mp4", "mp4")
        default: return ("audio/m4a", ext.isEmpty ? "m4a" : ext)
        }
    }

    /// Upload all music files referenced by blocks; returns blockId → S3 asset key.
    static func uploadMusicAssets(
        for routine: Routine,
        presign: (String, String) async throws -> PresignAudioResponse
    ) async throws -> [UUID: String] {
        var fileToKey: [String: String] = [:]
        var blockKeys: [UUID: String] = [:]

        for block in routine.blocks {
            guard let fileName = block.musicFileName else { continue }
            guard let localURL = BlockMusicManager.shared.musicURL(for: fileName) else {
                throw CommunityAPIError.serverError("Music file missing: \(block.name)")
            }

            if fileToKey[fileName] == nil {
                let (contentType, ext) = contentType(for: fileName)
                let presignResponse = try await presign(contentType, ext)
                try await uploadLocalFile(at: localURL, presign: presignResponse, contentType: contentType)
                fileToKey[fileName] = presignResponse.assetKey
            }

            if let key = fileToKey[fileName] {
                blockKeys[block.id] = key
            }
        }

        return blockKeys
    }

    static func uploadLocalFile(
        at localURL: URL,
        presign: PresignAudioResponse,
        contentType: String
    ) async throws {
        guard let uploadURL = URL(string: presign.uploadUrl) else {
            throw CommunityAPIError.invalidURL
        }
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")

        let (_, response) = try await URLSession.shared.upload(for: request, fromFile: localURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw CommunityAPIError.serverError("Audio upload failed (\(code)).")
        }
    }

    static func downloadMusic(assetKey: String, displayName: String) async throws -> (storedFileName: String, displayName: String) {
        let url = cdnURL(for: assetKey)
        return try await BlockMusicManager.shared.importMusic(from: url, displayName: displayName)
    }
}
