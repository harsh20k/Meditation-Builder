import Foundation
import AVFoundation
import Observation

/// Manages bell scheduling and playback for a meditation routine.
/// Supports opening, block, and closing bells with pause/resume.
/// Uses AVAudioEngine and AVAudioPlayerNode for precise timing.
@MainActor
@Observable
final class AuditoriumEngine {
    private let audioEngine = AVAudioEngine()
    private let playerNode  = AVAudioPlayerNode()
    private var audioFiles: [String: AVAudioFile] = [:]

    private struct BellEvent {
        let name: String
        let offset: TimeInterval
    }
    private var allEvents: [BellEvent] = []
    private var remainingEvents: [BellEvent] = []
    private var anchorSampleTime: AVAudioFramePosition?
    private var isEngineRunning = false
    private nonisolated(unsafe) var interruptionObserver: NSObjectProtocol?
    private nonisolated(unsafe) var routeChangeObserver: NSObjectProtocol?

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
        registerAudioSessionObservers()
    }

    deinit {
        if let obs = interruptionObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = routeChangeObserver  { NotificationCenter.default.removeObserver(obs) }
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
		allEvents.removeAll()
		if let openingBell = openingBell {
			allEvents.append(BellEvent(name: openingBell, offset: openingOffset))
		}
		for (offset, bell) in blockBells {
			if let bell = bell {
				allEvents.append(BellEvent(name: bell, offset: offset))
			}
		}
		if let closingBell = closingBell, let closingOffset = closingOffset {
			allEvents.append(BellEvent(name: closingBell, offset: closingOffset))
		}
		remainingEvents = allEvents
		
			// Capture current engine sample-time as anchor
		if let nodeTime = playerNode.lastRenderTime,
		   let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
			anchorSampleTime = playerTime.sampleTime
		}
		
			// Schedule all pending events relative to now
		for event in remainingEvents {
			schedule(sound: event.name, at: event.offset)
		}
	}
	
	/**
	 Pauses the current routine, computes which bell events remain, and updates their offsets.
	 - Returns: true if pause was successful, false if already paused or engine state invalid.
	 - Error Cases: Returns false and prints an error if the engine is not running or anchor time is missing.
	 */
    @discardableResult
    func pauseRoutine() -> Bool {
        guard isEngineRunning else {
            logger.warning("pauseRoutine: Engine is not running.", category: "Audio")
            return false
        }
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime),
              let anchor = anchorSampleTime,
              let firstFile = audioFiles.values.first else {
            logger.warning("pauseRoutine: Unable to get timing info or audio files.", category: "Audio")
            return false
        }
        let sampleRate = firstFile.processingFormat.sampleRate
        let elapsedSamples = playerTime.sampleTime - anchor
        let elapsedSeconds = TimeInterval(elapsedSamples) / sampleRate
        remainingEvents = allEvents
            .filter { $0.offset > elapsedSeconds }
            .map { BellEvent(name: $0.name, offset: $0.offset - elapsedSeconds) }
        playerNode.stop()
        audioEngine.pause()
        isEngineRunning = false
        logger.info("Routine paused. Remaining events: \(remainingEvents.count)", category: "Audio")
        return true
    }
	
	/**
	 Resumes a paused routine by re-anchoring and scheduling remaining bell events.
	 - Returns: true if resume was successful, false if already running or no events to resume.
	 - Error Cases: Returns false and prints an error if the engine fails to start or there are no events.
	 */
    @discardableResult
    func resumeRoutine() -> Bool {
        guard !isEngineRunning else {
            logger.warning("resumeRoutine: Engine is already running.", category: "Audio")
            return false
        }
        guard !remainingEvents.isEmpty else {
            logger.warning("resumeRoutine: No remaining events to schedule.", category: "Audio")
            return false
        }
        do {
            try audioEngine.start()
            playerNode.play()
            isEngineRunning = true
        } catch {
            logger.error("Failed to restart audio engine: \(error)", category: "Audio")
            isEngineRunning = false
            return false
        }
        guard let nodeTime = playerNode.lastRenderTime,
              let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            logger.warning("resumeRoutine: Unable to get timing info after restart.", category: "Audio")
            return false
        }
        anchorSampleTime = playerTime.sampleTime
        for event in remainingEvents {
            schedule(sound: event.name, at: event.offset)
        }
        logger.info("Routine resumed. Scheduled \(remainingEvents.count) events.", category: "Audio")
        return true
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
		let isDebugMode = false // Set to true for 5-second blocks, false for normal duration
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
	
    /// Configures AVAudioSession for background-safe playback.
    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            logger.error("Failed to configure audio session: \(error)", category: "Audio")
        }
    }

    /// Registers observers for audio session interruptions and route changes.
    private func registerAudioSessionObservers() {
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }

        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
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
            logger.info("Audio interruption began — pausing bells.", category: "Audio")
            _ = pauseRoutine()
        case .ended:
            let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                logger.info("Audio interruption ended — resuming bells.", category: "Audio")
                _ = resumeRoutine()
            }
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ notification: Notification) {
        guard let info = notification.userInfo,
              let reasonValue = info[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else { return }

        if reason == .oldDeviceUnavailable {
            logger.info("Audio route changed (headphones disconnected) — pausing.", category: "Audio")
            _ = pauseRoutine()
        }
    }
	
    /// Attaches and connects the AVAudioPlayerNode, then starts the engine.
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
            logger.error("Failed to start audio engine: \(error)", category: "Audio")
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
                logger.warning("Could not load audio file: \(name)", category: "Audio")
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
        logger.debug("Scheduled '\(name)' at offset \(offsetSeconds)s", category: "Audio")
    }
}
