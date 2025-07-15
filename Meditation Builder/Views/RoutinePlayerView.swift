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
	
	@State private var currentBlockIndex = 0
	@State private var timeRemaining = 0
	@State private var isPlaying = true
	@State private var isPaused = false
	@State private var timer: Timer?
	@State private var inBlockProgress = 0.0 // 0.0 to 1.0
	@State private var showingEndSessionAlert = false
	@State private var showingDiscardSessionAlert = false
	
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
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
					// Pure black background for OLED - spans entire screen
				Color.black
					.ignoresSafeArea(.all, edges: .all)
				
				VStack(spacing: 0) {
						// Header with close button
					HStack {
						Spacer()
						
							// Close button
						Button(action: {
							stopTimer()
							dismiss()
						}) {
							Image(systemName: "xmark")
								.foregroundColor(.white)
								.font(.system(size: 20, weight: .medium))
								.frame(width: 44, height: 44)
								.background(Color.black.opacity(0.3))
								.clipShape(Circle())
						}
					}
					.padding(.horizontal, 20)
					.padding(.top, 60)
					
						// Routine Name
					Text(routine.routineName)
						.font(.system(size: 17, weight: .semibold, design: .default))
						.foregroundColor(.white)
						.lineLimit(2)
						.multilineTextAlignment(.center)
						.padding(.horizontal, 20)
						.padding(.top, 20)
					
					Spacer()
					
						// Main Timer Display
					VStack(spacing: 16) {
							// Large countdown timer
						Text(formatTime(timeRemaining))
							.font(.system(size: 72, weight: .bold, design: .default))
							.foregroundColor(.white)
							.monospacedDigit()
						
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
							.padding(.horizontal, 20)
						}
					}
					
					Spacer()
					
						// Play/Pause Control
					VStack(spacing: 0) {
							// Play/Pause button - always in the same position
						Button(action: togglePause) {
							Text(isPaused ? "▶" : "❙❙")
								.font(.system(size: 32, weight: .regular, design: .default))
								.foregroundColor(.white)
						}
						.buttonStyle(PlainButtonStyle())
						.padding(.bottom, 20)
						
							// Pause state controls - appear below the play button
						if isPaused {
							VStack(spacing: 12) {
									// End Session Button
								Button(action: { showingEndSessionAlert = true }) {
									Text("End Session")
										.font(.system(size: 16, weight: .medium, design: .default))
										.foregroundColor(.black)
										.frame(maxWidth: .infinity)
										.frame(height: 44)
										.background(Color.white)
										.cornerRadius(22)
								}
								.padding(.horizontal, 40)
								
									// Discard Session Button
								Button(action: { showingDiscardSessionAlert = true }) {
									Text("Discard Session")
										.font(.system(size: 16, weight: .medium, design: .default))
										.foregroundColor(.white)
								}
								.buttonStyle(PlainButtonStyle())
							}
						}
					}
					.padding(.bottom, 60)
				}
				
					// Block Progress Indicator (right edge)
				VStack(spacing: 12) {
						// Completed blocks (top)
					ForEach(0..<completedBlocks, id: \.self) { _ in
						Circle()
							.fill(Color.white)
							.frame(width: 8, height: 8)
					}
					
						// Current block progress (middle)
					if currentBlock != nil {
						VStack(spacing: 4) {
							ForEach(0..<5, id: \.self) { index in
								let progress = inBlockProgress * 5
								let isFilled = Double(index) < progress
								
								Circle()
									.fill(isFilled ? Color.white : Color.clear)
									.stroke(Color.white.opacity(0.3), lineWidth: 1)
									.frame(width: 6, height: 6)
							}
						}
					}
					
						// Remaining blocks (bottom)
					ForEach(0..<remainingBlocks, id: \.self) { _ in
						Circle()
							.stroke(Color.white, lineWidth: 1)
							.frame(width: 8, height: 8)
					}
				}
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
				.padding(.trailing, 20)
			}
		}
		.onAppear {
			startTimer()
		}
		.onDisappear {
			stopTimer()
		}
		.statusBarHidden(true)
		.preferredColorScheme(.dark)
		.ignoresSafeArea(.all, edges: .all)
		.alert("End Session", isPresented: $showingEndSessionAlert) {
			Button("Cancel", role: .cancel) { }
			Button("End Session", role: .destructive) {
				endSession()
			}
		} message: {
			Text("Are you sure you want to end this meditation session? Your progress will be saved.")
		}
		.alert("Discard Session", isPresented: $showingDiscardSessionAlert) {
			Button("Cancel", role: .cancel) { }
			Button("Discard", role: .destructive) {
				discardSession()
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
		
		let block = routineData.blocks[currentBlockIndex]
		timeRemaining = block.durationInMinutes * 60
		
		logger.info("Starting block: \(block.name) (\(block.durationInMinutes) minutes)", category: "Timer")
		
		timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
			if !isPaused {
				timeRemaining -= 1
				updateInBlockProgress()
				
				if timeRemaining <= 0 {
					moveToNextBlock()
				}
			}
		}
	}
	
	private func stopTimer() {
		timer?.invalidate()
		timer = nil
		logger.info("Timer stopped", category: "Timer")
	}
	
	private func togglePause() {
		isPaused.toggle()
		logger.info("Timer \(isPaused ? "paused" : "resumed")", category: "Timer")
	}
	
	private func updateInBlockProgress() {
		guard let block = currentBlock else { return }
		let totalSeconds = Double(block.durationInMinutes * 60)
		let elapsedSeconds = totalSeconds - Double(timeRemaining)
		inBlockProgress = elapsedSeconds / totalSeconds
	}
	
	private func moveToNextBlock() {
		logger.info("Block completed: \(currentBlock?.name ?? "Unknown")", category: "Timer")
		
		currentBlockIndex += 1
		inBlockProgress = 0.0
		
		if currentBlockIndex >= routineData.blocks.count {
				// Routine completed
			logger.info("Routine completed: \(routine.routineName)", category: "Timer")
			
				// Record the completed session
			Task {
				do {
					try await dataManager.recordPlay(for: routine)
					logger.info("Completed session recorded successfully", category: "Timer")
				} catch {
					logger.error("Failed to record completed session: \(error)", category: "Timer")
				}
			}
			
			stopTimer()
			dismiss()
		} else {
				// Start next block
			let nextBlock = routineData.blocks[currentBlockIndex]
			timeRemaining = nextBlock.durationInMinutes * 60
			logger.info("Starting next block: \(nextBlock.name)", category: "Timer")
		}
	}
	
	private func formatTime(_ seconds: Int) -> String {
		let minutes = seconds / 60
		let remainingSeconds = seconds % 60
		return String(format: "%d:%02d", minutes, remainingSeconds)
	}
	
		// MARK: - Session Management
	
	private func endSession() {
		logger.info("User ended session for routine: \(routine.routineName)", category: "Timer")
		
			// Record the session as completed
		Task {
			do {
				try await dataManager.recordPlay(for: routine)
				logger.info("Session recorded successfully", category: "Timer")
			} catch {
				logger.error("Failed to record session: \(error)", category: "Timer")
			}
		}
		
		stopTimer()
		dismiss()
	}
	
	private func discardSession() {
		logger.info("User discarded session for routine: \(routine.routineName)", category: "Timer")
		
			// Don't record the session - just stop and dismiss
		stopTimer()
		dismiss()
	}
}

#Preview {
	// Create a sample routine for preview
	let sampleRoutine = SavedRoutine(
	routine: Routine(
	name: "Morning Meditation",
	icon: "sunrise.fill",
	blocks: [
	RoutineBlock(name: "Breathwork", durationInMinutes: 5, type: .breathwork, blockStartBell: .softBell),
	RoutineBlock(name: "Chanting", durationInMinutes: 10, type: .chanting, blockStartBell: .tibetanBowl),
	RoutineBlock(name: "Silence", durationInMinutes: 15, type: .silence, blockStartBell: .silent)
	],
	openingBell: .softBell,
	closingBell: .digitalChime
	)
	)
	
	RoutinePlayerView(routine: sampleRoutine)
}
