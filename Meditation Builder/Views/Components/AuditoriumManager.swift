import Foundation
import AVFoundation

/// AuditoriumManager
///
/// Manages bell scheduling and playback for a meditation routine, supporting opening, block, and closing bells.
/// Uses AVAudioEngine and AVAudioPlayerNode for precise timing. Designed for integration with the main app.
final class AuditoriumManager: ObservableObject {
    private let audioEngine = AVAudioEngine()
    private let playerNode  = AVAudioPlayerNode()
    private var audioFiles: [String: AVAudioFile] = [:]
    private var isEngineRunning = false
    
    init() {
        configureAudioSession()
        preloadAudioFiles([
            "opening_bell",
            "soft_bell",
            "digital_chime",
            "closing_bell",
            "tibetan_bowl"
        ])
        setupEngine()
    }
    
    // MARK: - Public API
    
    /// Schedules a full routine: opening bell, block bells, and closing bell.
    /// - Parameters:
    ///   - openingBell: Name of the opening bell sound (without extension)
    ///   - blockBells: Array of (offsetSeconds, bellName) for each block
    ///   - closingBell: Name of the closing bell sound (without extension)
    ///   - closingOffset: Offset in seconds for closing bell
    func scheduleRoutine(openingBell: String?, openingOffset: TimeInterval = 0,
                        blockBells: [(offset: TimeInterval, bell: String?)],
                        closingBell: String?, closingOffset: TimeInterval?) {
        if let openingBell = openingBell {
            schedule(sound: openingBell, at: openingOffset)
        }
        for (offset, bell) in blockBells {
            if let bell = bell {
                schedule(sound: bell, at: offset)
            }
        }
        if let closingBell = closingBell, let closingOffset = closingOffset {
            schedule(sound: closingBell, at: closingOffset)
        }
    }
    
    /// Stops playback and pauses the engine.
    func stop() {
        playerNode.stop()
        audioEngine.pause()
        isEngineRunning = false
    }
    
    // MARK: - Private
    
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("🔈 Failed to configure audio session:", error)
        }
    }
    
    private func setupEngine() {
        audioEngine.attach(playerNode)
        if let firstFile = audioFiles.values.first {
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: firstFile.processingFormat)
        } else {
            audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: nil)
        }
        do {
            try audioEngine.start()
            playerNode.play()
            isEngineRunning = true
        } catch {
            print("🎛 Failed to start audio engine:", error)
        }
    }
    
    private func preloadAudioFiles(_ names: [String]) {
        for name in names {
            guard
                let url = Bundle.main.url(forResource: name, withExtension: "mp3"),
                let file = try? AVAudioFile(forReading: url)
            else {
                print("⚠️ Could not load audio file:", name)
                continue
            }
            audioFiles[name] = file
        }
    }
    
    /// Schedules a preloaded audio file to play at a specified offset relative to the player's current sample time.
    private func schedule(sound name: String, at offsetSeconds: TimeInterval) {
        guard let file = audioFiles[name],
              let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else { return }
        let sampleRate = file.processingFormat.sampleRate
        let sampleOffset = AVAudioFramePosition(offsetSeconds * sampleRate)
        let futureSampleTime = playerTime.sampleTime + sampleOffset
        let atTime = AVAudioTime(sampleTime: futureSampleTime, atRate: sampleRate)
        playerNode.scheduleFile(file, at: atTime, completionHandler: nil)
        print("   ✓ Scheduled '\(name)' at sampleTime \(futureSampleTime)")
    }
} 