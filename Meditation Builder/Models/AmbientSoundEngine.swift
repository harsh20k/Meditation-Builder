//
//  AmbientSoundEngine.swift
//  Meditation Builder
//

import AVFoundation
import Observation

// MARK: - Ambient Sound Definition

struct AmbientSound: Identifiable, Sendable {
    let id: String
    let displayName: String
    let icon: String
    let fileName: String

    static let catalog: [AmbientSound] = [
        AmbientSound(id: "rain",         displayName: "Rain",          icon: "cloud.rain.fill",    fileName: "ambient_rain"),
        AmbientSound(id: "forest",       displayName: "Forest",        icon: "leaf.fill",           fileName: "ambient_forest"),
        AmbientSound(id: "ocean",        displayName: "Ocean",         icon: "water.waves",         fileName: "ambient_ocean"),
        AmbientSound(id: "wind",         displayName: "Wind",          icon: "wind",                fileName: "ambient_wind"),
        AmbientSound(id: "fire",         displayName: "Fire",          icon: "flame.fill",          fileName: "ambient_fire"),
        AmbientSound(id: "bowls",        displayName: "Singing Bowls", icon: "circle.hexagonpath",  fileName: "ambient_bowls"),
        AmbientSound(id: "white_noise",  displayName: "White Noise",   icon: "waveform.path",       fileName: "ambient_white_noise"),
    ]
}

// MARK: - Per-track state (observable by SwiftUI)

@Observable
final class AmbientTrack: Identifiable {
    let sound: AmbientSound
    var isEnabled: Bool = false
    var volume: Float = 0.7

    var id: String { sound.id }

    init(sound: AmbientSound) {
        self.sound = sound
    }
}

// MARK: - Engine

@MainActor
@Observable
final class AmbientSoundEngine {
    static let shared = AmbientSoundEngine()

    // Public observable state
    private(set) var tracks: [AmbientTrack] = AmbientSound.catalog.map { AmbientTrack(sound: $0) }
    var masterVolume: Float = 1.0 {
        didSet { applyMasterVolume() }
    }

    // AVFoundation internals
    private let engine = AVAudioEngine()
    private let masterMixer = AVAudioMixerNode()
    private var players: [String: AVAudioPlayerNode] = [:]
    private var files: [String: AVAudioFile] = [:]
    private var isRunning = false
    private nonisolated(unsafe) var isShuttingDown = false

    private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?
    private nonisolated(unsafe) var routeChangeObserver: NSObjectProtocol?

    init() {
        configureAudioSession()
        setupEngine()
        registerObservers()
        loadPersistedMix()
    }

    deinit {
        isShuttingDown = true
        if let obs = interruptionObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = routeChangeObserver { NotificationCenter.default.removeObserver(obs) }
        MainActor.assumeIsolated {
            for player in players.values { player.stop() }
            engine.stop()
        }
    }

    // MARK: - Public API

    func setEnabled(_ enabled: Bool, for trackID: String) {
        guard let track = tracks.first(where: { $0.id == trackID }) else { return }
        track.isEnabled = enabled
        if enabled {
            startTrack(trackID)
        } else {
            stopTrack(trackID)
        }
        persistMix()
    }

    func setVolume(_ volume: Float, for trackID: String) {
        guard let track = tracks.first(where: { $0.id == trackID }) else { return }
        track.volume = volume
        players[trackID]?.volume = volume * masterVolume
        persistMix()
    }

    func stopAll() {
        for track in tracks where track.isEnabled {
            stopTrack(track.id)
        }
    }

    // MARK: - Private: Engine Setup

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            DispatchQueue.main.async {
                logger.error("AmbientSoundEngine: audio session config failed: \(error)", category: "Audio")
            }
        }
    }

    private func setupEngine() {
        engine.attach(masterMixer)
        engine.connect(masterMixer, to: engine.mainMixerNode, format: nil)

        for sound in AmbientSound.catalog {
            guard let url = Bundle.main.url(forResource: sound.fileName, withExtension: "mp3"),
                  let file = try? AVAudioFile(forReading: url) else {
                DispatchQueue.main.async {
                    logger.warning("AmbientSoundEngine: missing audio file '\(sound.fileName)'", category: "Audio")
                }
                continue
            }
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: masterMixer, format: file.processingFormat)
            players[sound.id] = player
            files[sound.id] = file
        }

        do {
            try engine.start()
            isRunning = true
        } catch {
            DispatchQueue.main.async {
                logger.error("AmbientSoundEngine: engine start failed: \(error)", category: "Audio")
            }
        }
    }

    private func startTrack(_ id: String) {
        guard let player = players[id], let file = files[id] else { return }
        guard let track = tracks.first(where: { $0.id == id }) else { return }

        if !isRunning { try? engine.start(); isRunning = true }
        player.volume = track.volume * masterVolume
        scheduleLooping(player: player, file: file)
        player.play()
        DispatchQueue.main.async {
            logger.info("Ambient track started: \(id)", category: "Audio")
        }
    }

    private func stopTrack(_ id: String) {
        players[id]?.stop()
        DispatchQueue.main.async {
            logger.info("Ambient track stopped: \(id)", category: "Audio")
        }
    }

    private func scheduleLooping(player: AVAudioPlayerNode, file: AVAudioFile) {
        player.scheduleFile(file, at: nil) { [weak self, weak player] in
            Task { @MainActor [weak self, weak player] in
                guard let self, let player, !self.isShuttingDown else { return }
                if let trackID = self.players.first(where: { $0.value === player })?.key,
                   let track = self.tracks.first(where: { $0.id == trackID }),
                   track.isEnabled {
                    self.scheduleLooping(player: player, file: file)
                }
            }
        }
    }

    private func applyMasterVolume() {
        for track in tracks {
            players[track.id]?.volume = track.volume * masterVolume
        }
    }

    // MARK: - Persistence

    private static let mixKey = "AmbientMix"

    private func persistMix() {
        var dict: [String: [String: Any]] = [:]
        for track in tracks {
            dict[track.id] = ["enabled": track.isEnabled, "volume": track.volume]
        }
        UserDefaults.standard.set(dict, forKey: Self.mixKey)
    }

    private func loadPersistedMix() {
        guard let dict = UserDefaults.standard.dictionary(forKey: Self.mixKey) as? [String: [String: Any]] else { return }
        for track in tracks {
            if let entry = dict[track.id] {
                track.isEnabled = entry["enabled"] as? Bool ?? false
                track.volume = (entry["volume"] as? Double).map { Float($0) } ?? 0.7
                if track.isEnabled { startTrack(track.id) }
            }
        }
    }

    // MARK: - Interruption Handling

    private func registerObservers() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil, queue: .main
        ) { [weak self] notification in
            self?.handleRouteChange(notification)
        }
    }

    private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        switch type {
        case .began:
            stopAll()
        case .ended:
            let opts = AVAudioSession.InterruptionOptions(
                rawValue: info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0)
            if opts.contains(.shouldResume) {
                for track in tracks where track.isEnabled { startTrack(track.id) }
            }
        @unknown default: break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue),
              reason == .oldDeviceUnavailable else { return }
        stopAll()
    }
}
