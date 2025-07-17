
//  BlockProgressIndicator.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct BlockProgressIndicator: View {
	let currentBlockIndex: Int
	let totalBlocks: Int
	let inBlockProgress: Double
	let blockStartDate: Date
	
	// Animation parameters - keeping for potential future use
	var breathingDuration: Double = 2.0
	var pulseDuration: Double = 1.5
	var rotationDuration: Double = 10.0
	var glowDuration: Double = 1.0
	var enableBreathing: Bool = true
	var enablePulse: Bool = true
	var enableRotation: Bool = true
	var enableGlow: Bool = true
	
	// Animation state for the traveling circle effect
	@State private var balls: [Ball] = []
	@State private var tickProgress: Int = 0
	@State private var isTravelling = false
	@State private var animationTrigger = false
	
	@Namespace private var ballNamespace
	
	// Configuration
	private let ticksPerBlock = 5
	private let ballSize: CGFloat = 12
	private let pileSpacing: CGFloat = 8
	private let dotSpacing: CGFloat = 6
	private let travelDuration: Double = 0.8
	private let travelBounce: Double = 0.4
	private let maxVisibleBalls = 4 // Maximum balls to show before using stacked symbol
	
	// Model for animated balls
	private struct Ball: Identifiable, Equatable {
		let id = UUID()
		var atTop = false
		let originalIndex: Int
		
		init(originalIndex: Int) {
			self.originalIndex = originalIndex
		}
	}
	
	// Computed properties
	private var completedBlocks: Int {
		currentBlockIndex
	}
	
	private var remainingBlocks: Int {
		// Include current block in remaining count for visual representation
		max(0, totalBlocks - currentBlockIndex)
	}
	
	// Get balls that represent current and future blocks (not yet completed)
	private var remainingBalls: [Ball] {
		balls.filter { !$0.atTop }
	}
	

	
	private var currentTicksFromProgress: Int {
		let calculated = Int(floor(inBlockProgress * Double(ticksPerBlock)))
		return min(calculated, ticksPerBlock)
	}
	
	private var travelAnimation: Animation {
		.spring(duration: travelDuration, bounce: travelBounce)
	}
	
	// Helper computed properties for stacked display
	private var shouldUseStackedCompleted: Bool {
		completedBlocks > maxVisibleBalls
	}
	
	private var shouldUseStackedRemaining: Bool {
		remainingBlocks > maxVisibleBalls
	}
	
	private var visibleCompletedBalls: Int {
		shouldUseStackedCompleted ? maxVisibleBalls : completedBlocks
	}
	
	private var visibleRemainingBalls: Int {
		shouldUseStackedRemaining ? maxVisibleBalls : remainingBlocks
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Top pile - completed blocks (filled circles or stacked symbol)
			VStack(spacing: pileSpacing) {
				if shouldUseStackedCompleted {
					// Show stack symbol with some individual balls for animation
					ZStack {
						StackedCompletedCircles()
						
						// Count text positioned to the left
						Text("\(completedBlocks)")
							.font(.system(size: 8, weight: .bold))
							.foregroundColor(.white)
							.background(Color.black.opacity(0.7))
							.clipShape(Circle())
							.frame(width: 12, height: 12)
							.offset(x: -8, y: 0)
					}
					
					// Show last few individual balls for animation continuity
					ForEach(Array(balls.filter(\.atTop).suffix(2)), id: \.id) { ball in
						FilledCircle()
							.matchedGeometryEffect(id: ball.id, in: ballNamespace)
							.opacity(0.0) // Invisible but maintains animation
					}
				} else {
					// Individual balls for few completed blocks
					ForEach(Array(balls.filter(\.atTop).reversed().prefix(visibleCompletedBalls)), id: \.id) { ball in
						FilledCircle()
							.matchedGeometryEffect(id: ball.id, in: ballNamespace)
					}
				}
			}
			.frame(maxHeight: .infinity, alignment: .bottom)
			.animation(travelAnimation, value: balls)
			
			// Middle section - progress dots (only show if not all blocks are done)
			if currentBlockIndex < totalBlocks {
				VStack(spacing: dotSpacing) {
					ForEach((0..<ticksPerBlock).reversed(), id: \.self) { index in
						ProgressDot(filled: tickProgress > index)
							.animation(.easeInOut(duration: 0.2), value: tickProgress)
					}
				}
				.padding(.vertical, 24)
			}
			
			// Bottom pile - remaining blocks (outline circles or stacked symbol)
			VStack(spacing: pileSpacing) {
				if shouldUseStackedRemaining {
					// Show stack symbol with some individual balls for animation
					ZStack {
						StackedRemainingCircles()
						
						// Count text positioned to the left
						Text("\(remainingBlocks)")
							.font(.system(size: 8, weight: .bold))
							.foregroundColor(.white)
							.background(Color.black.opacity(0.7))
							.clipShape(Circle())
							.frame(width: 12, height: 12)
							.offset(x: -8, y: 0)
					}
					
					// Show first few individual balls for animation continuity  
					ForEach(Array(remainingBalls.prefix(2)), id: \.id) { ball in
						OutlineCircle()
							.matchedGeometryEffect(id: ball.id, in: ballNamespace)
							.opacity(0.0) // Invisible but maintains animation
					}
				} else {
					// Individual balls for few remaining blocks
					ForEach(Array(remainingBalls.prefix(visibleRemainingBalls)), id: \.id) { ball in
						OutlineCircle()
							.matchedGeometryEffect(id: ball.id, in: ballNamespace)
					}
				}
			}
			.frame(maxHeight: .infinity, alignment: .top)
			.animation(travelAnimation, value: balls)
		}
		.onAppear {
			initializeBalls()
			updateTickProgress()
		}
		.onChange(of: totalBlocks) { _, _ in
			initializeBalls()
		}
		.onChange(of: currentBlockIndex) { oldValue, newValue in
			if newValue > oldValue && !isTravelling && newValue > 0 {
				// Block completed - trigger ball travel animation
				moveBallToTop()
			}
			updateTickProgress()
		}
		.onChange(of: inBlockProgress) { _, newValue in
			// Force update tick progress when progress changes
			updateTickProgress()
		}
		.onChange(of: blockStartDate) { _, _ in
			// Reset when block starts - delay slightly to avoid immediate calculation
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				updateTickProgress()
			}
		}
	}
	
	// MARK: - Helper Views
	
	private func FilledCircle() -> some View {
		Circle()
			.fill(Color.white)
			.frame(width: ballSize, height: ballSize)
	}
	
	private func OutlineCircle() -> some View {
		Circle()
			.stroke(Color.white, lineWidth: 2)
			.frame(width: ballSize, height: ballSize)
	}
	
	private func ProgressDot(filled: Bool) -> some View {
		Circle()
			.stroke(Color.white.opacity(0.4), lineWidth: 1)
			.background(
				Circle()
					.fill(filled ? Color.white : Color.clear)
			)
			.frame(width: 6, height: 6)
	}
	
	private func StackedCompletedCircles() -> some View {
		ZStack {
			// Bottom circle (slightly larger)
			Circle()
				.fill(Color.white.opacity(0.6))
				.frame(width: ballSize + 2, height: ballSize + 2)
				.offset(y: 1)
			
			// Top circle (normal size)
			Circle()
				.fill(Color.white)
				.frame(width: ballSize, height: ballSize)
				.offset(y: -1)
		}
	}
	
	private func StackedRemainingCircles() -> some View {
		ZStack {
			// Bottom circle (slightly larger)
			Circle()
				.stroke(Color.white.opacity(0.6), lineWidth: 2)
				.frame(width: ballSize + 2, height: ballSize + 2)
				.offset(y: 1)
			
			// Top circle (normal size)
			Circle()
				.stroke(Color.white, lineWidth: 2)
				.frame(width: ballSize, height: ballSize)
				.offset(y: -1)
		}
	}
	
	// MARK: - Animation Logic
	
	private func initializeBalls() {
		// Create balls for all blocks
		balls = (0..<totalBlocks).map { index in
			var ball = Ball(originalIndex: index)
			// Set balls as completed if they're already done
			ball.atTop = index < currentBlockIndex
			return ball
		}
	}
	
	private func updateTickProgress() {
		let newTicks = currentTicksFromProgress
		
		// Always update tick progress when not travelling
		if !isTravelling {
			withAnimation(.easeInOut(duration: 0.2)) {
				tickProgress = newTicks
			}
		}
	}
	
	private func moveBallToTop() {
		// Find the current ball that should move to top
		guard let ballIndex = balls.firstIndex(where: { $0.originalIndex == currentBlockIndex - 1 }) else { return }
		
		isTravelling = true
		
		// Animate dots emptying as ball travels
		let dotEmptyDuration = 0.15
		for step in (0..<ticksPerBlock).reversed() {
			let delay = Double(ticksPerBlock - 1 - step) * 0.1
			DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
				withAnimation(.easeInOut(duration: dotEmptyDuration)) {
					tickProgress = step
				}
			}
		}
		
		// Start ball travel after brief delay
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			withAnimation(travelAnimation) {
				balls[ballIndex].atTop = true
			}
			
			// Reset travelling state after animation completes
			DispatchQueue.main.asyncAfter(deadline: .now() + travelDuration + 0.1) {
				isTravelling = false
				tickProgress = 0
			}
		}
	}
}

#Preview {
	ZStack {
		Color.black.ignoresSafeArea()
		
		VStack(spacing: 40) {
			// Scenario 1: Few blocks (normal display)
			BlockProgressIndicator(
				currentBlockIndex: 1,
				totalBlocks: 3,
				inBlockProgress: 0.6,
				blockStartDate: Date()
			)
			
			// Scenario 2: Many blocks (stacked display)
			BlockProgressIndicator(
				currentBlockIndex: 2,
				totalBlocks: 8,
				inBlockProgress: 0.3,
				blockStartDate: Date()
			)
			
			// Scenario 3: Many completed blocks
			BlockProgressIndicator(
				currentBlockIndex: 6,
				totalBlocks: 8,
				inBlockProgress: 0.8,
				blockStartDate: Date()
			)
			
			// Scenario 4: Routine completed
			BlockProgressIndicator(
				currentBlockIndex: 8,
				totalBlocks: 8,
				inBlockProgress: 1.0,
				blockStartDate: Date()
			)
		}
		.position(x: 350, y: 400)
	}
} 


