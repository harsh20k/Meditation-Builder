	//
	//  RoutinePlayerView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI
import os.log

struct RoutinePlayerView: View {
	let routine: SavedRoutine
	@Environment(\.dismiss) private var dismiss
	@Environment(\.modelContext) private var modelContext
	@Environment(\.scenePhase) private var scenePhase
	
	// MARK: - Debug Configuration
	#if DEBUG
	private let isDebugMode = true // Set to true for 5-second blocks, false for normal duration
	#else
	private let isDebugMode = false
	#endif
	
	@State private var currentBlockIndex = 0
	@State private var routineStartDate = Date() // Track when routine started
	@State private var blockStartDate = Date()
	@State private var blockEndDate = Date()
	@State private var isPlaying = true
	@State private var isPaused = false
	@State private var pausedDate: Date?
	@State private var totalPausedTime: TimeInterval = 0
	@State private var blockPausedTime: TimeInterval = 0
	@State private var actualMeditationTimeAtPause: Int = 0
	@State private var showingEndSessionAlert = false
	@State private var showingDiscardSessionAlert = false
	@State private var showingFinishAlert = false
	@State private var currentTime = Date() // Add this to trigger progress updates
	
	// Session tracking - Event-based approach
	@State private var sessionRecord: SessionRecord?
	@State private var sessionStarted = false
	
	private var dataManager: RoutineDataManager {
		RoutineDataManager(context: modelContext)
	}
	
	private var routineData: Routine {
		routine.getRoutine()
	}
	
	private var currentBlock: RoutineBlock? {
		guard currentBlockIndex < routineData.blocks.count else { return nil }
		return routineData.blocks[currentBlockIndex]
	}
	
	private var nextBlock: RoutineBlock? {
		let nextIndex = currentBlockIndex + 1
		guard nextIndex < routineData.blocks.count else { return nil }
		return routineData.blocks[nextIndex]
	}
	
	private var totalBlocks: Int {
		routineData.blocks.count
	}
	
	private var completedBlocks: Int {
		currentBlockIndex
	}
	
	private var remainingBlocks: Int {
		max(0, totalBlocks - currentBlockIndex - 1)
	}
	
	// Computed properties for time-based values
	private var elapsedTime: Int {
		guard !isPaused else {
			// When paused, return the elapsed time at the moment of pausing
			let elapsedBeforePause = pausedDate?.timeIntervalSince(routineStartDate) ?? 0
			return max(0, Int(elapsedBeforePause))
		}
		
		let elapsed = currentTime.timeIntervalSince(routineStartDate) - totalPausedTime
		return max(0, Int(elapsed))
	}
	
	private var inBlockProgress: Double {
		guard let block = currentBlock else { return 0.0 }
		
		// MARK: - Debug Mode: Use 5 seconds for all blocks
		let blockDuration: Double
		if isDebugMode {
			blockDuration = 5.0 // 5 seconds for debugging
		} else {
			blockDuration = Double(block.durationInMinutes * 60)
		}
		
		let elapsed: TimeInterval
		if isPaused {
			// When paused, use the time when we paused minus block paused time
			elapsed = (pausedDate?.timeIntervalSince(blockStartDate) ?? 0) - blockPausedTime
		} else {
			// When not paused, use current time minus block paused time
			elapsed = currentTime.timeIntervalSince(blockStartDate) - blockPausedTime
		}
		
		let progress = min(1.0, max(0.0, elapsed / blockDuration))
		
		// Log progress changes (but limit frequency to avoid spam)
		// if progress > 0.0 && progress < 1.0 {
		// 	print("⏱️ Timer Progress - Block: \(block.name), Elapsed: \(String(format: "%.1f", elapsed))s, Duration: \(blockDuration)s, Progress: \(String(format: "%.3f", progress))")
		// }
		
		return progress
	}
	
	// Check if all blocks are completed
	private var isRoutineComplete: Bool {
		currentBlockIndex >= routineData.blocks.count
	}

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				// Pure black background for OLED - spans entire screen
				Color.black
					.ignoresSafeArea(.all, edges: .all)
				
				// Close button - positioned at top right
				Button(action: {
					endSession(saveProgress: false)
				}) {
					Image(systemName: "xmark")
						.foregroundColor(.white)
						.font(.system(size: 20, weight: .medium))
						.frame(width: 44, height: 44)
						.background(Color.black.opacity(0.3))
						.clipShape(Circle())
				}
				.position(x: geometry.size.width - 44, y: geometry.safeAreaInsets.top + 60)
				
				// Routine Name - positioned at top center
				Text(routine.routineName)
					.font(.system(size: 17, weight: .semibold, design: .default))
					.foregroundColor(.white)
					.lineLimit(2)
					.multilineTextAlignment(.center)
					.frame(width: geometry.size.width - 40)
					.position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 120)
				
				// Main Timer Display - positioned at center
				VStack(spacing: 16) {
					// Large elapsed timer with TimelineView for efficiency
					TimelineView(.periodic(from: routineStartDate, by: 1.0)) { context in
						Text(formatTime(elapsedTime))
							.font(.system(size: 72, weight: .bold, design: .default))
							.foregroundColor(.white)
							.monospacedDigit()
							.onChange(of: context.date) { _, newDate in
								// Update current time to trigger progress recalculation
								currentTime = newDate
								
								// Check if current block is complete on each timeline update
								if !isRoutineComplete && inBlockProgress >= 1.0 && !isPaused {
									moveToNextBlock()
								}
							}
					}
					
					// Current block indicator or completion message
					if isRoutineComplete {
						Text("Routine Complete")
							.font(.system(size: 17, weight: .regular, design: .default))
							.foregroundColor(.white.opacity(0.8))
							.lineLimit(2)
							.multilineTextAlignment(.center)
							.frame(width: geometry.size.width - 40)
					} else if let current = currentBlock {
						HStack(spacing: 0) {
							Text(current.name)
								.font(.system(size: 17, weight: .regular, design: .default))
								.foregroundColor(.white)
							
							if let next = nextBlock {
								Text(" → ")
									.font(.system(size: 17, weight: .regular, design: .default))
									.foregroundColor(.white.opacity(0.6))
								
								Text(next.name)
									.font(.system(size: 17, weight: .regular, design: .default))
									.foregroundColor(.white.opacity(0.6))
							}
						}
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.frame(width: geometry.size.width - 40)
					}
				}
				.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
				
				// Play/Pause Controls - positioned at bottom with fixed coordinates
				ZStack {
					// Play/Pause button - always in the same position
					Button(action: togglePause) {
						Text(isPaused ? "▶" : "❙❙")
							.font(.system(size: 72, weight: .regular, design: .default))
							.foregroundColor(.white)
					}
					.buttonStyle(PlainButtonStyle())
					.position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 180)
					
					// Pause state controls - shown with opacity animation
					if isPaused {
						VStack(spacing: 8) {
							// End Session Button
							Button(action: { showingEndSessionAlert = true }) {
								Text("End Session")
									.font(.system(size: 14, weight: .medium, design: .default))
									.foregroundColor(.black)
									.frame(width: 120, height: 36)
									.background(Color.white)
									.cornerRadius(18)
									.padding(8)
							}
							
							// Discard Session Button
							Button(action: { showingDiscardSessionAlert = true }) {
								Text("Discard Session")
									.font(.system(size: 14, weight: .medium, design: .default))
									.foregroundColor(.red)
							}
							.buttonStyle(PlainButtonStyle())
						}
						.position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 80)
						.opacity(isPaused ? 1.0 : 0.0)
						.animation(.easeInOut(duration: 0.3), value: isPaused)
					}
					
					// Finish button - shown when routine is complete
					if isRoutineComplete {
						Button(action: { showingFinishAlert = true }) {
							Text("Finish")
								.font(.system(size: 14, weight: .medium, design: .default))
								.foregroundColor(.black)
								.frame(width: 120, height: 36)
								.background(Color.white)
								.cornerRadius(18)
								.padding(8)
						}
						.position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 80)
						.opacity(isRoutineComplete ? 1.0 : 0.0)
						.animation(.easeInOut(duration: 0.3), value: isRoutineComplete)
					}
				}
				
				// Block Progress Indicator - positioned at right edge
				BlockProgressIndicator(
					currentBlockIndex: currentBlockIndex,
					totalBlocks: totalBlocks,
					inBlockProgress: isRoutineComplete ? 1.0 : inBlockProgress,
					blockStartDate: blockStartDate
				)
				.position(x: geometry.size.width - 20, y: geometry.size.height / 2)
			}
		}
		.onAppear {
			startTimer()
		}
		.onDisappear {
			cleanup()
		}
		.onChange(of: scenePhase) { _, newPhase in
			switch newPhase {
			case .background, .inactive:
				// App is backgrounded, pause if playing
				if isPlaying && !isPaused {
					togglePause()
				}
			case .active:
				// App is active again - user can manually resume if desired
				break
			@unknown default:
				break
			}
		}
		.onChange(of: inBlockProgress) { _, newValue in
			if !isRoutineComplete && newValue >= 1.0 && !isPaused {
				moveToNextBlock()
			}
		}
		.statusBarHidden(true)
		.preferredColorScheme(.dark)
		.ignoresSafeArea(.all, edges: .all)
		.alert("End Session", isPresented: $showingEndSessionAlert) {
			Button("Cancel", role: .cancel) { }
			Button("End Session", role: .destructive) {
				endSession(saveProgress: true)
			}
		} message: {
			Text("Are you sure you want to end this meditation session? Your progress will be saved.")
		}
		.alert("Discard Session", isPresented: $showingDiscardSessionAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Discard", role: .destructive) {
				endSession(saveProgress: false)
			}
		} message: {
			Text("Are you sure you want to discard this session? Your progress will not be recorded.")
		}
		.alert("Finish Session", isPresented: $showingFinishAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Finish", role: .destructive) {
				endSession(saveProgress: true)
			}
		} message: {
			Text("Are you sure you want to finish this meditation session? Your session will be recorded.")
		}
	}
	
	// MARK: - Timer Functions
	
	private func startTimer() {
		logger.info("Starting timer for routine: \(routine.routineName)", category: "Timer")
		
		// Initialize routine start time
		routineStartDate = Date()
		currentTime = Date()
		
		// Create lightweight session record for event tracking
		sessionRecord = SessionRecord(routineID: routine.id)
		sessionRecord?.addEvent(.start(routineStartDate))
		sessionStarted = true
		
		print("🚀 MEDITATION STARTED")
		print("   Routine: \(routine.routineName)")
		print("   Session ID: \(sessionRecord?.id ?? UUID())")
		print("   Start Time: \(routineStartDate)")
		
		guard currentBlockIndex < routineData.blocks.count else {
			logger.info("Timer completed - no more blocks", category: "Timer")
			return
		}
		
		startCurrentBlock()
	}
	
	private func startCurrentBlock() {
		let block = routineData.blocks[currentBlockIndex]
		blockStartDate = Date()
		currentTime = Date() // Initialize current time
		blockPausedTime = 0
		
		// MARK: - Debug Mode: Log actual duration being used
		let actualDuration: String
		if isDebugMode {
			actualDuration = "5 seconds (debug mode)"
		} else {
			actualDuration = "\(block.durationInMinutes) minutes"
		}
		
		logger.info("Starting block: \(block.name) (\(actualDuration))", category: "Timer")
		
		print("▶️ BLOCK STARTED - Index: \(currentBlockIndex + 1)/\(totalBlocks)")
		print("   Block: \(block.name)")
		print("   Type: \(block.type.displayName)")
		print("   Duration: \(actualDuration)")
		print("   Start Time: \(blockStartDate)")
		
		// No immediate database writes - events are recorded at session end
	}
	
	private func togglePause() {
		isPaused.toggle()
		
		if isPaused {
			pausedDate = Date()
			// Store the actual meditation time at the moment of pausing (excluding previous paused time)
			actualMeditationTimeAtPause = Int(pausedDate!.timeIntervalSince(routineStartDate) - totalPausedTime)
			
			// Record pause event
			sessionRecord?.addEvent(.pause(pausedDate!))
			
			logger.info("Timer paused", category: "Timer")
			print("⏸️ MEDITATION PAUSED")
			print("   Pause Time: \(pausedDate ?? Date())")
			print("   Elapsed Before Pause: \(formatTime(actualMeditationTimeAtPause))")
			print("   Current Block Elapsed: \(formatTime(max(0, Int(pausedDate!.timeIntervalSince(blockStartDate) - blockPausedTime))))")
		} else {
			if let pauseStart = pausedDate {
				let resumeTime = Date()
				let pauseDuration = resumeTime.timeIntervalSince(pauseStart)
				// Ensure pause duration is positive and reasonable (not more than 24 hours)
				guard pauseDuration > 0 && pauseDuration < 86400 else {
					logger.warning("Invalid pause duration: \(pauseDuration)s - resetting pause state", category: "Timer")
					pausedDate = nil
					return
				}
				
				totalPausedTime += pauseDuration
				blockPausedTime += pauseDuration
				pausedDate = nil
				
				// Record resume event
				sessionRecord?.addEvent(.resume(resumeTime))
				
				logger.info("Timer resumed", category: "Timer")
				print("▶️ MEDITATION RESUMED")
				print("   Resume Time: \(resumeTime)")
				print("   Pause Duration: \(String(format: "%.1f", pauseDuration))s")
				print("   Total Paused Time: \(String(format: "%.1f", totalPausedTime))s")
				print("   Block Paused Time: \(String(format: "%.1f", blockPausedTime))s")
			} else {
				logger.warning("Resume called but no pause start time recorded", category: "Timer")
			}
		}
	}
	
	private func moveToNextBlock() {
		logger.info("Block completed: \(currentBlock?.name ?? "Unknown")", category: "Timer")
		
		// CRITICAL: Capture timing values for logging
		let completionTime = Date()
		let capturedBlockStartDate = blockStartDate
		let capturedBlockPausedTime = blockPausedTime
		let capturedCurrentBlock = currentBlock
		
		// Calculate actual block duration (excluding paused time)
		let blockDuration = max(0, Int(completionTime.timeIntervalSince(capturedBlockStartDate) - capturedBlockPausedTime))
		
		print("✅ BLOCK COMPLETED - Index: \(currentBlockIndex + 1)/\(totalBlocks)")
		print("   Block: \(capturedCurrentBlock?.name ?? "Unknown")")
		print("   Duration: \(formatTime(blockDuration))")
		print("   Block Paused Time: \(String(format: "%.1f", capturedBlockPausedTime))s")
		print("   Completion Time: \(completionTime)")
		
		// No immediate database writes - detailed block timing will be reconstructed from events
		
		currentBlockIndex += 1
		
		if currentBlockIndex >= routineData.blocks.count {
			// Routine completed - but timer keeps running
			logger.info("Routine completed: \(routine.routineName) - Timer continues", category: "Timer")
			print("🎉 ROUTINE COMPLETED - Timer continues for overshoot tracking")
		} else {
			// Start next block
			startCurrentBlock()
			let nextBlock = routineData.blocks[currentBlockIndex]
			logger.info("Starting next block: \(nextBlock.name)", category: "Timer")
		}
	}
	
	private func formatTime(_ seconds: Int) -> String {
		let minutes = seconds / 60
		let remainingSeconds = seconds % 60
		return String(format: "%d:%02d", minutes, remainingSeconds)
	}
	
	// MARK: - Timing Validation
	
	/// Validates and returns the current actual meditation time, ensuring consistency
	private func getValidatedActualMeditationTime() -> Int {
		let currentTime = Date()
		let rawSessionDuration = currentTime.timeIntervalSince(routineStartDate)
		
		if isPaused {
			// If currently paused, use the stored time at pause
			return actualMeditationTimeAtPause
		} else {
			// If not paused, calculate current time minus total paused time
			let calculatedTime = Int(rawSessionDuration - totalPausedTime)
			
			// Validation: ensure calculated time is non-negative and reasonable
			guard calculatedTime >= 0 && calculatedTime < 86400 else {
				logger.warning("Invalid meditation time calculated: \(calculatedTime)s - using fallback", category: "Timer")
				return max(0, Int(rawSessionDuration)) // Fallback to raw duration if negative
			}
			
			return calculatedTime
		}
	}
	
	// MARK: - Session Management
	
	private func endSession(saveProgress: Bool) {
		logger.info("Session \(saveProgress ? "ended" : "discarded") for routine: \(routine.routineName)", category: "Timer")
		
		// Record finish event
		let finishTime = Date()
		sessionRecord?.addEvent(.finish(finishTime))
		
		// Calculate actual meditation time using validated method
		let actualMeditationTime = getValidatedActualMeditationTime()
		
		let action = saveProgress ? "FINISH" : "DISCARD"
		print("🛑 SESSION \(action)")
		print("   Routine: \(routine.routineName)")
		print("   Current Block: \(currentBlockIndex + 1)/\(totalBlocks)")
		print("   Duration: \(formatTime(actualMeditationTime))")
		print("   Total Paused Time: \(String(format: "%.1f", totalPausedTime))s")
		print("   Is Paused: \(isPaused)")
		print("   End Time: \(finishTime)")
		
		// Complete the session using deferred event-based approach
		if let sessionRecord = sessionRecord {
			Task {
				do {
					// Single call to complete session using event record
					try await dataManager.completeSession(using: sessionRecord, routine: routine, wasDiscarded: !saveProgress)
					logger.info("Session \(saveProgress ? "saved" : "discarded") successfully", category: "Session")
				} catch {
					logger.error("Failed to complete session: \(error)", category: "Session")
				}
			}
		}
		
		cleanup()
		dismiss()
	}
	
	private func cleanup() {
		// Ensure all timers and resources are cleaned up
		logger.info("Cleaning up timer resources", category: "Timer")
	}
}

#Preview {
		// Create a sample routine for preview
	let sampleRoutine = SavedRoutine(
		routine: Routine(
			name: "Morning Meditation",
			icon: "sunrise.fill",
			blocks: [
				RoutineBlock(name: "Breathwork", durationInMinutes: 1, type: .breathwork, blockStartBell: .softBell),
				RoutineBlock(name: "Chanting", durationInMinutes: 1, type: .chanting, blockStartBell: .tibetanBowl),
				RoutineBlock(name: "Silence", durationInMinutes: 1, type: .silence, blockStartBell: .silent)
			],
			openingBell: .softBell,
			closingBell: .digitalChime
		)
	)
	
	RoutinePlayerView(routine: sampleRoutine)
}
