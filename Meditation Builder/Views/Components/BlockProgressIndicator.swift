
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
	
	private var currentTicksFromProgress: Int {
		let calculated = Int(floor(inBlockProgress * Double(ticksPerBlock)))
		return min(calculated, ticksPerBlock)
	}
	
	private var travelAnimation: Animation {
		.spring(duration: travelDuration, bounce: travelBounce)
	}
	
	var body: some View {
		VStack(spacing: 0) {
			// Top pile - completed blocks (filled circles)
			VStack(spacing: pileSpacing) {
				ForEach(balls.filter(\.atTop)) { ball in
					FilledCircle()
						.matchedGeometryEffect(id: ball.id, in: ballNamespace)
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
			
			// Bottom pile - remaining blocks (outline circles)
			VStack(spacing: pileSpacing) {
				ForEach(balls.filter { !$0.atTop }) { ball in
					OutlineCircle()
						.matchedGeometryEffect(id: ball.id, in: ballNamespace)
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
			if newValue > oldValue && !isTravelling {
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
			print("🔄 Progress Update - inBlockProgress: \(String(format: "%.3f", inBlockProgress)), Ticks: \(newTicks)")
			withAnimation(.easeInOut(duration: 0.2)) {
				tickProgress = newTicks
			}
		}
	}
	
	private func moveBallToTop() {
		guard let ballIndex = balls.firstIndex(where: { !$0.atTop }) else { return }
		
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
		
		BlockProgressIndicator(
			currentBlockIndex: 1,
			totalBlocks: 5,
			inBlockProgress: 0.6,
			blockStartDate: Date()
		)
		.position(x: 350, y: 400)
	}
} 


