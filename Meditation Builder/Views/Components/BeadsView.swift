	//  BeadsView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI

struct BeadsView: View {
	let currentBlockIndex: Int
	let totalBlocks: Int
	let inBlockProgress: Double
	let blockStartDate: Date
	let isRoutineSelected: Bool
	let isPlaying: Bool
	
		// Configuration
	private let beadSize: CGFloat = 8
	private let beadSpacing: CGFloat = 12
	private let defaultBeadCount = 4
	private let capsuleWidth: CGFloat = 32 // Wider than circle for capsule effect
	
	var body: some View {
		HStack(spacing: beadSpacing) {
			ForEach(0..<beadCount, id: \.self) { index in
				beadShape(for: index)
					.frame(width: beadWidth(for: index), height: beadSize)
					.animation(.easeInOut(duration: 0.4), value: currentBlockIndex)
					.animation(.easeInOut(duration: 0.4), value: inBlockProgress)
			}
		}
		.frame(maxWidth: .infinity)
		.padding(.top, 20)
	}
	
		// MARK: - Computed Properties
	
	private var beadCount: Int {
		if !isRoutineSelected {
			return defaultBeadCount
		} else {
			return totalBlocks
		}
	}
	
	private func isBeadFilled(_ index: Int) -> Bool {
		guard isRoutineSelected && isPlaying else { return false }
		
			// If this is the current block, check if it should be partially filled
		if index == currentBlockIndex {
			return inBlockProgress > 0.5 // Fill when more than halfway through
		}
		
			// Previous blocks are fully filled
		return index < currentBlockIndex
	}
	
	private func isBeadPartiallyFilled(_ index: Int) -> Bool {
		guard isRoutineSelected && isPlaying else { return false }
		
			// Only the current block can be partially filled
		if index == currentBlockIndex {
			return inBlockProgress > 0.0 && inBlockProgress <= 0.5
		}
		
		return false
	}
	
	private func beadFillColor(for index: Int) -> Color {
		if isBeadFilled(index) {
			return .white
		} else if isBeadPartiallyFilled(index) {
			return .white.opacity(0.5)
		} else {
			return .clear
		}
	}
	
	private func beadShape(for index: Int) -> some View {
		AnyView(
			MorphingShape(
				isCurrentBlock: isCurrentBlock(index),
				fillColor: beadFillColor(for: index),
				capsuleWidth: capsuleWidth,
				beadSize: beadSize
			)
		)
	}
	
	private func beadWidth(for index: Int) -> CGFloat {
		if isCurrentBlock(index) {
			return capsuleWidth
		} else {
			return beadSize
		}
	}
	
	private func isCurrentBlock(_ index: Int) -> Bool {
		guard isRoutineSelected && isPlaying else { return false }
		
			// When currentBlockIndex is 0, we're on the first block (index 0)
			// When currentBlockIndex is 1, we're on the second block (index 1)
			// So the current block is at index currentBlockIndex
		let isCurrent = index == currentBlockIndex
		
		return isCurrent
	}
}

// MARK: - Morphing Shape

struct MorphingShape: View {
	let isCurrentBlock: Bool
	let fillColor: Color
	let capsuleWidth: CGFloat
	let beadSize: CGFloat
	
	@State private var morphProgress: Double = 0.0
	
	var body: some View {
		ZStack {
				// Background fill
			MorphingPath(
				morphProgress: morphProgress,
				capsuleWidth: capsuleWidth,
				beadSize: beadSize
			)
			.fill(fillColor)
			
				// Stroke outline
			MorphingPath(
				morphProgress: morphProgress,
				capsuleWidth: capsuleWidth,
				beadSize: beadSize
			)
			.stroke(Color.white, lineWidth: 1.5)
		}
		.onChange(of: isCurrentBlock) { _, newValue in
			withAnimation(.easeInOut(duration: 0.4)) {
				morphProgress = newValue ? 1.0 : 0.0
			}
		}
		.onAppear {
			morphProgress = isCurrentBlock ? 1.0 : 0.0
		}
	}
}

struct MorphingPath: Shape {
	var morphProgress: Double
	let capsuleWidth: CGFloat
	let beadSize: CGFloat
	
	var animatableData: Double {
		get { morphProgress }
		set { morphProgress = newValue }
	}
	
	func path(in rect: CGRect) -> Path {
		let center = CGPoint(x: rect.midX, y: rect.midY)
		let radius = min(rect.width, rect.height) / 2
		
		var path = Path()
		
			// Interpolated shape between circle and capsule
		let capsuleHeight = beadSize
		let capsuleWidthValue = capsuleWidth
		
			// Interpolate width and corner radius
		let currentWidth = beadSize + (capsuleWidthValue - beadSize) * morphProgress
		let currentHeight = beadSize
		let cornerRadius = (beadSize / 2) * morphProgress
		
		let currentRect = CGRect(
			x: center.x - currentWidth / 2,
			y: center.y - currentHeight / 2,
			width: currentWidth,
			height: currentHeight
		)
		
		path.addRoundedRect(in: currentRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
		return path
	}
}

#Preview {
	ZStack {
		Color.black.ignoresSafeArea()
		
		VStack(spacing: 40) {
				// Scenario 1: Routine selected and playing (some blocks completed)
			BeadsView(
				currentBlockIndex: 2,
				totalBlocks: 5,
				inBlockProgress: 0.7,
				blockStartDate: Date(),
				isRoutineSelected: true,
				isPlaying: true
			)
			
				// Scenario 1b: Session just started (first circle should be capsule)
			BeadsView(
				currentBlockIndex: 0,
				totalBlocks: 3,
				inBlockProgress: 0.1,
				blockStartDate: Date(),
				isRoutineSelected: true,
				isPlaying: true
			)
			
				// Scenario 1c: Second block in progress (first circle filled, second circle capsule)
			BeadsView(
				currentBlockIndex: 1,
				totalBlocks: 3,
				inBlockProgress: 0.5,
				blockStartDate: Date(),
				isRoutineSelected: true,
				isPlaying: true
			)
			
				// Scenario 2: Routine not selected (shows 4 empty circles)
			BeadsView(
				currentBlockIndex: 0,
				totalBlocks: 0,
				inBlockProgress: 0.0,
				blockStartDate: Date(),
				isRoutineSelected: false,
				isPlaying: false
			)
			
				// Scenario 3: Routine selected but not playing (shows empty circles for all blocks)
			BeadsView(
				currentBlockIndex: 0,
				totalBlocks: 6,
				inBlockProgress: 0.0,
				blockStartDate: Date(),
				isRoutineSelected: true,
				isPlaying: false
			)
			
				// Scenario 4: Routine completed
			BeadsView(
				currentBlockIndex: 5,
				totalBlocks: 5,
				inBlockProgress: 1.0,
				blockStartDate: Date(),
				isRoutineSelected: true,
				isPlaying: true
			)
		}
		.position(x: 250, y: 400)
	}
}
