import Foundation
import AVFoundation

/// AuditoriumManager
///
/// Manages bell scheduling and playback for a meditation routine, supporting opening, block, and closing bells.
/// Uses AVAudioEngine and AVAudioPlayerNode for precise timing. Designed for integration with the main app.
final class AuditoriumManager: ObservableObject {
    /// The audio engine responsible for audio signal processing and playback.
    private let audioEngine = AVAudioEngine()
    /// The player node used to schedule and play bell audio files.
    private let playerNode  = AVAudioPlayerNode()
    /// Dictionary mapping bell names to their preloaded AVAudioFile instances.
    private var audioFiles: [String: AVAudioFile] = [:]
    /// Indicates whether the audio engine is currently running.
    private var isEngineRunning = false
    
    /// Initializes the AuditoriumManager, configures the audio session, preloads bell audio files, and sets up the audio engine.
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
    
    /**
     Schedules a full routine: opening bell, block bells, and closing bell.
     - Parameters:
        - openingBell: Name of the opening bell sound (without extension)
        - openingOffset: Offset in seconds for the opening bell (default 0)
        - blockBells: Array of (offsetSeconds, bellName) for each block
        - closingBell: Name of the closing bell sound (without extension)
        - closingOffset: Offset in seconds for closing bell
     */
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
    
    /**
     Schedules a routine by extracting bell information from a SavedRoutine model.
     - Parameter savedRoutine: The SavedRoutine instance containing all routine and block data.
     - Note: The blockStartBell of the first block is always ignored. Defaults are used if bells are not specified.
     */
    func scheduleRoutineVerbatim(savedRoutine: SavedRoutine) {
        // Default bell names
        let openingBellName = "opening_bell"
        let closingBellName = "closing_bell"
        let blockBellName = "soft_bell"
        
        // Schedule opening bell at 0s
        schedule(sound: openingBellName, at: 0)
        
        // Calculate block start offsets and schedule block bells (skip first block)
        let blocks = savedRoutine.blocks.sorted { $0.orderIndex < $1.orderIndex }
		
		#if DEBUG
		let isDebugMode = true // Set to true for 5-second blocks, false for normal duration
		#else
		let isDebugMode = false
		#endif
        
		var currentOffset: TimeInterval = 0
        for (index, block) in blocks.enumerated() {
            let duration = Double(block.durationInMinutes * 60)
			let debug_duration = Double(10)
            if index > 0 {
                // For all blocks except the first, schedule the blockStartBell
                let bellSound: String
                switch block.blockStartBell {
                case .silent:
                    continue // skip silent
                case .softBell:
                    bellSound = blockBellName
                case .tibetanBowl:
                    bellSound = "tibetan_bowl"
                case .digitalChime:
                    bellSound = "digital_chime"
                }
                schedule(sound: bellSound, at: currentOffset)
            }
			if isDebugMode {
				currentOffset += debug_duration
			} else {
				currentOffset += duration
			}
        }
        // Schedule closing bell at the end
        schedule(sound: closingBellName, at: currentOffset)
    }
    
    /// Stops playback and pauses the audio engine.
    func stop() {
        playerNode.stop()
        audioEngine.pause()
        isEngineRunning = false
    }
    
    // MARK: - Private
    
    /// Configures the AVAudioSession for playback and mixing with other audio sources.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("🔈 Failed to configure audio session:", error)
        }
    }
    
    /// Attaches and connects the AVAudioPlayerNode to the AVAudioEngine, then starts the engine and player node.
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
    
    /**
     Preloads a list of audio files from the app bundle into AVAudioFile instances for rapid scheduling.
     - Parameter names: Filenames (without extension) of the MP3 resources.
     */
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
    
    /**
     Schedules a preloaded audio file to play at a specified offset relative to the player's current sample time.
     - Parameters:
        - name: The key identifying the preloaded AVAudioFile.
        - offsetSeconds: Number of seconds after the session start to play the sound.
     */
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
