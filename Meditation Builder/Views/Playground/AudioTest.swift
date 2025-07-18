/**
 AudioTest.swift
 Meditation Builder
 
 A simple SwiftUI view and audio tester that demonstrates AVAudioEngine-based scheduling
 of bell sounds (opening, soft bell, digital chime, closing) at specified time offsets,
 without using notifications. Useful for verifying audio scheduling and timing logic.
 */

import SwiftUI
import AVFoundation

	/// A SwiftUI view that displays a "Start Session" button and tests audio bell playback.
	/// When the button is tapped, the associated AudioTester schedules and plays bell sounds.
struct AudioTestView: View {
	@StateObject private var audioTester = AudioTester()
	
	var body: some View {
		VStack {
			Spacer()
			Button("Start Session") {
				audioTester.startSession()
			}
			.font(.headline)
			.padding()
			.background(Color.orange)
			.foregroundColor(.white)
			.cornerRadius(24)
			Spacer()
		}
		.background(Color.black.ignoresSafeArea())
		.onDisappear {
			audioTester.stopEngine()
		}
	}
}

/**
 AudioTester
 
 Manages an AVAudioEngine and AVAudioPlayerNode to schedule and play bell audio files
 at precise time offsets, using the engine's hostTime timeline. Configures the audio session
 for background playback and preloads audio resources for rapid scheduling.
 */
final class AudioTester: ObservableObject {
	private let audioEngine = AVAudioEngine()
	private let playerNode  = AVAudioPlayerNode()
	private var audioFiles: [String: AVAudioFile] = [:]
	
	init() {
		configureAudioSession()
		preloadAudioFiles([
			"opening_bell"
		])
		setupEngine()
		print("🔊 Loaded audio files:", audioFiles.keys)
	}
	
		// MARK: Public
	
		/// Begins a test session by scheduling
		/// the opening bell sounds at 0s, 10s, and 20s offsets.
	func startSession() {
		schedule(sound: "opening_bell", at: 0)
		schedule(sound: "opening_bell", at: 10)
		schedule(sound: "opening_bell", at: 20)
	}
	
		/// Stops all audio playback and pauses the audio engine.
		/// Call this when the view disappears or the session should be terminated.
	func stopEngine() {
		print("⏹ stopEngine called")
		playerNode.stop()
		audioEngine.pause()
	}
	
		// MARK: Setup
	
		/// Configures the AVAudioSession for playback and mixes with other audio,
		/// enabling background playback of scheduled bell sounds.
	private func configureAudioSession() {
		let session = AVAudioSession.sharedInstance()
		do {
			try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
			try session.setActive(true)
		} catch {
			print("🔈 Failed to configure audio session:", error)
		}
	}
	
		/// Attaches and connects the AVAudioPlayerNode to the AVAudioEngine,
		/// using the first loaded audio file's processingFormat, then starts the engine
		/// and begins playback on the node.
	private func setupEngine() {
		audioEngine.attach(playerNode)
		if let firstFile = audioFiles.values.first {
			audioEngine.connect(playerNode,
								to: audioEngine.mainMixerNode,
								format: firstFile.processingFormat)
		} else {
			audioEngine.connect(playerNode,
								to: audioEngine.mainMixerNode,
								format: nil)
		}
		do {
			try audioEngine.start()
			playerNode.play()
		} catch {
			print("🎛 Failed to start audio engine:", error)
		}
	}
	
		/// Preloads a list of audio files from the app bundle into AVAudioFile instances
		/// for rapid scheduling during the test session.
		///
		/// - Parameter names: Filenames (without extension) of the MP3 resources.
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
			// Calculate sample offset and schedule relative to the player's current sample time
		let sampleRate = file.processingFormat.sampleRate
		let sampleOffset = AVAudioFramePosition(offsetSeconds * sampleRate)
		let futureSampleTime = playerTime.sampleTime + sampleOffset
		let atTime = AVAudioTime(sampleTime: futureSampleTime, atRate: sampleRate)
		playerNode.scheduleFile(file, at: atTime, completionHandler: nil)
		print("   ✓ Scheduled '\(name)' at sampleTime \(futureSampleTime)")
	}
}

	// Preview for SwiftUI Canvas
struct AudioTestView_Previews: PreviewProvider {
	static var previews: some View {
		AudioTestView()
	}
}
