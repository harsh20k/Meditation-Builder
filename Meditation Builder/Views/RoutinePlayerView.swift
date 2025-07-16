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
	
	@State private var currentBlockIndex = 0
	@State private var blockStartDate = Date()
	@State private var blockEndDate = Date()
	@State private var isPlaying = true
	@State private var isPaused = false
	@State private var pausedDate: Date?
	@State private var totalPausedTime: TimeInterval = 0
	@State private var showingEndSessionAlert = false
	@State private var showingDiscardSessionAlert = false
	@State private var currentTime = Date() // Add this to trigger progress updates
	
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
	private var timeRemaining: Int {
		guard !isPaused else {
			// When paused, calculate remaining time based on when we paused
			let elapsedBeforePause = pausedDate?.timeIntervalSince(blockStartDate) ?? 0
			let adjustedElapsed = elapsedBeforePause - totalPausedTime
			let blockDuration = Double((currentBlock?.durationInMinutes ?? 0) * 60)
			return max(0, Int(blockDuration - adjustedElapsed))
		}
		
		let elapsed = currentTime.timeIntervalSince(blockStartDate) - totalPausedTime
		let blockDuration = Double((currentBlock?.durationInMinutes ?? 0) * 60)
		return max(0, Int(blockDuration - elapsed))
	}
	
	private var inBlockProgress: Double {
		guard let block = currentBlock else { return 0.0 }
		let blockDuration = Double(block.durationInMinutes * 60)
		
		let elapsed: TimeInterval
		if isPaused {
			elapsed = (pausedDate?.timeIntervalSince(blockStartDate) ?? 0) - totalPausedTime
		} else {
			elapsed = currentTime.timeIntervalSince(blockStartDate) - totalPausedTime
		}
		
		let progress = min(1.0, max(0.0, elapsed / blockDuration))
		
		// Log progress changes (but limit frequency to avoid spam)
		if progress > 0.0 && progress < 1.0 {
			print("⏱️ Timer Progress - Block: \(block.name), Elapsed: \(String(format: "%.1f", elapsed))s, Duration: \(blockDuration)s, Progress: \(String(format: "%.3f", progress))")
		}
		
		return progress
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
					// Large countdown timer with TimelineView for efficiency
					TimelineView(.periodic(from: blockStartDate, by: 1.0)) { context in
						Text(formatTime(timeRemaining))
							.font(.system(size: 72, weight: .bold, design: .default))
							.foregroundColor(.white)
							.monospacedDigit()
							.onChange(of: context.date) { _, newDate in
								// Update current time to trigger progress recalculation
								currentTime = newDate
								
								// Check if current block is complete on each timeline update
								if timeRemaining <= 0 && !isPaused {
									moveToNextBlock()
								}
							}
					}
					
					// Current → Next block indicator
					if let current = currentBlock {
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
				}
				
				// Block Progress Indicator - positioned at right edge
				BlockProgressIndicator(
					currentBlockIndex: currentBlockIndex,
					totalBlocks: totalBlocks,
					inBlockProgress: inBlockProgress,
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
		.onChange(of: timeRemaining) { _, newValue in
			if newValue <= 0 && !isPaused {
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
	}
	
	// MARK: - Timer Functions
	
	private func startTimer() {
		logger.info("Starting timer for routine: \(routine.routineName)", category: "Timer")
		
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
		totalPausedTime = 0
		
		print("🚀 Block Started - Index: \(currentBlockIndex), Name: \(block.name), Duration: \(block.durationInMinutes) minutes")
		logger.info("Starting block: \(block.name) (\(block.durationInMinutes) minutes)", category: "Timer")
	}
	
	private func togglePause() {
		isPaused.toggle()
		
		if isPaused {
			pausedDate = Date()
			logger.info("Timer paused", category: "Timer")
		} else {
			if let pauseStart = pausedDate {
				totalPausedTime += Date().timeIntervalSince(pauseStart)
				pausedDate = nil
			}
			logger.info("Timer resumed", category: "Timer")
		}
	}
	
	private func moveToNextBlock() {
		print("✅ Block Completed - Index: \(currentBlockIndex), Name: \(currentBlock?.name ?? "Unknown")")
		logger.info("Block completed: \(currentBlock?.name ?? "Unknown")", category: "Timer")
		
		currentBlockIndex += 1
		
		if currentBlockIndex >= routineData.blocks.count {
			// Routine completed
			print("🎉 Routine Completed - \(routine.routineName)")
			logger.info("Routine completed: \(routine.routineName)", category: "Timer")
			endSession(saveProgress: true)
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
	
	// MARK: - Session Management
	
	private func endSession(saveProgress: Bool) {
		logger.info("Session \(saveProgress ? "ended" : "discarded") for routine: \(routine.routineName)", category: "Timer")
		
		if saveProgress {
			// Record the session
			Task {
				do {
					try await dataManager.recordPlay(for: routine)
					logger.info("Session recorded successfully", category: "Timer")
				} catch {
					logger.error("Failed to record session: \(error)", category: "Timer")
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
