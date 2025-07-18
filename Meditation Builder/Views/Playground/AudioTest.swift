	//
	//  AudioTest.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 18/07/25.
	//

import SwiftUI
import AVFoundation

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

final class AudioTester: ObservableObject {
	private let audioEngine = AVAudioEngine()
	private let playerNode  = AVAudioPlayerNode()
	private var audioFiles: [String: AVAudioFile] = [:]
	private var anchorHostTime: UInt64? = nil
	
	init() {
		configureAudioSession()
		preloadAudioFiles([
			"opening_bell",
			"soft_bell",
			"digital_chime",
			"closing_bell"
		])
		setupEngine()
		print("🔊 Loaded audio files:", audioFiles.keys)
	}
	
		// MARK: Public
	
	func startSession() {
			// Record host time reference
		if let nodeTime = playerNode.lastRenderTime,
		   let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
			anchorHostTime = playerTime.hostTime
			print("🌟 anchorHostTime:", anchorHostTime!)
		} else {
			print("⚠️ Unable to obtain engine hostTime anchor")
		}
			// Schedule bells
		print("⏱ Scheduling bell 'opening_bell' at offset 0s")
		schedule(sound: "opening_bell", at: 0)
		print("⏱ Scheduling bell 'soft_bell' at offset 10s")
		schedule(sound: "soft_bell", at: 10)
		print("⏱ Scheduling bell 'digital_chime' at offset 10s")
		schedule(sound: "digital_chime", at: 10)
		print("⏱ Scheduling bell 'closing_bell' at offset 20s")
		schedule(sound: "closing_bell", at: 20)
	}
	
	func stopEngine() {
		print("⏹ stopEngine called")
		playerNode.stop()
		audioEngine.pause()
	}
	
		// MARK: Setup
	
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
	
		// MARK: Scheduling
	
	private func schedule(sound name: String, at offsetSeconds: TimeInterval) {
		guard let file = audioFiles[name], let anchor = anchorHostTime else { return }
			// Calculate hostTime for this bell
		let fireHostTime = anchor + UInt64(offsetSeconds * Double(NSEC_PER_SEC))
		print("   → fireHostTime:", fireHostTime)
		let atTime = AVAudioTime(hostTime: fireHostTime)
		playerNode.scheduleFile(file, at: atTime, completionHandler: nil)
		print("   ✓ Scheduled '\(name)'")
	}
}

	// Preview for SwiftUI Canvas
struct AudioTestView_Previews: PreviewProvider {
	static var previews: some View {
		AudioTestView()
	}
}
