//
//  BlockMusicManager.swift
//  Meditation Builder
//

import Foundation
import os.log

private let musicManagerLog = os.Logger(subsystem: "com.meditation.builder", category: "BlockMusicManager")

/// Manages per-block custom music files stored in the app sandbox.
/// Files are copied into Documents/BlockMusic/ on import and referenced by filename only,
/// so the stored path stays valid across app restarts.
final class BlockMusicManager {
    static let shared = BlockMusicManager()
    private init() { ensureDirectoryExists() }

    // MARK: - Storage

    private var musicDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BlockMusic", isDirectory: true)
    }

    private func ensureDirectoryExists() {
        try? FileManager.default.createDirectory(at: musicDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public API

    /// Copies the file at a security-scoped URL into the BlockMusic directory.
    /// - Returns: The stored filename (UUID + original extension) used to retrieve the file later.
    func importMusic(from securityScopedURL: URL) throws -> (storedFileName: String, displayName: String) {
        let accessing = securityScopedURL.startAccessingSecurityScopedResource()
        defer { if accessing { securityScopedURL.stopAccessingSecurityScopedResource() } }

        let ext = securityScopedURL.pathExtension
        let displayName = securityScopedURL.deletingPathExtension().lastPathComponent
        let storedFileName = "\(UUID().uuidString).\(ext)"
        let destination = musicDirectory.appendingPathComponent(storedFileName)

        try FileManager.default.copyItem(at: securityScopedURL, to: destination)
        musicManagerLog.info("Imported music '\(displayName)' as '\(storedFileName)'")
        return (storedFileName, displayName)
    }

    /// Resolves a stored filename to its on-disk URL. Returns nil if the file no longer exists.
    func musicURL(for fileName: String) -> URL? {
        let url = musicDirectory.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// Permanently removes a stored music file from disk.
    func deleteMusic(fileName: String) {
        let url = musicDirectory.appendingPathComponent(fileName)
        do {
            try FileManager.default.removeItem(at: url)
            musicManagerLog.info("Deleted music file '\(fileName)'")
        } catch {
            musicManagerLog.warning("Could not delete music file '\(fileName)': \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Downloads remote audio from the CDN and stores it locally.
    func importMusic(from remoteURL: URL, displayName: String) async throws -> (storedFileName: String, displayName: String) {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        let ext = remoteURL.pathExtension.isEmpty ? "m4a" : remoteURL.pathExtension
        let storedFileName = "\(UUID().uuidString).\(ext)"
        let destination = musicDirectory.appendingPathComponent(storedFileName)
        try data.write(to: destination)
        musicManagerLog.info("Downloaded music '\(displayName)' as '\(storedFileName)'")
        return (storedFileName, displayName)
    }
}
