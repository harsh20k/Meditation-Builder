	//
	//  MeditationRoutineColumnView.swift
	//  Demo
	//
	//  Created by Harsh’s AI Friend on 15-Jul-2025.
	//

import SwiftUI
import Combine

	// MARK: — Building blocks
fileprivate struct BigCircle: View {
	let filled: Bool
	let size:   CGFloat            // NEW
	var body: some View {
		Circle()
			.strokeBorder(.white, lineWidth: 3)
			.background(Circle().foregroundColor(filled ? .white : .clear))
			.frame(width: size, height: size)   // NEW
	}
}

fileprivate struct SmallDot: View {
	let filled: Bool
	var body: some View {
		Circle()
			.strokeBorder(.white, lineWidth: 1)
			.background(Circle().foregroundColor(filled ? .white : .clear))
			.frame(width: 6, height: 6)
	}
}

	// MARK: — Main view (vertical column; travel uses shared spring)
struct MeditationRoutineColumnView: View {
	
		// 🎚️  Tweak away
		// 1️⃣  Put these near the top of the view for clarity
	
	private let totalBlocks: Int
	private let ticksPerBlock = 5
	
		// Layout constants (tweak in code; no runtime controls here)
	private let ballSize: CGFloat = 20
	private let pileSpacing: CGFloat = 6
	private let dotSpacing: CGFloat = 5
	private let tickInterval: Double = 0.2  // dot fill speed (seconds)
	
		// Shared animation controls (bound to right‑side sliders)
	@Binding var duration: Double
	@Binding var bounce: Double
	
		// MODEL
	private struct Ball: Identifiable, Equatable {
		let id = UUID()
		var atTop = false
	}
	
		// STATE
	@State private var balls: [Ball] = []
	@State private var tick = 0
	@State private var isTravelling = false
	@State private var timerC: AnyCancellable?
	
		// Animation driven by shared bindings from parent
	private var travelAnim: Animation {
		.spring(duration: duration, bounce: bounce)
	}
	
	@Namespace private var ns
	
	init(blocks: Int = 3, duration: Binding<Double>, bounce: Binding<Double>) {
		self.totalBlocks = blocks
		self._duration = duration
		self._bounce = bounce
	}
	
	var body: some View {
		GeometryReader { geo in
			VStack(spacing: 0) {
				
					// 1️⃣ TOP pile (solid) — uses shared spring
				VStack(spacing: pileSpacing) {
					ForEach(balls.filter(\.atTop)) { ball in
						BigCircle(filled: true,  size: ballSize)
							.matchedGeometryEffect(id: ball.id, in: ns)
					}
				}
				.frame(maxHeight: .infinity, alignment: .bottom)
				.animation(travelAnim, value: balls)      // pile re-centres w/ shared spring
				
					// 2️⃣ Five fixed dots
				if !allBlocksDone {
					VStack(spacing: dotSpacing) {
						ForEach((0..<ticksPerBlock).reversed(), id: \.self) { i in
							SmallDot(filled: tick > i)
								.animation(.easeInOut(duration: 0.2), value: tick)
						}
					}
					.padding(.vertical, 24)
				}
				
					// 3️⃣ BOTTOM pile (outline)
				VStack(spacing: pileSpacing) {
					ForEach(balls.filter { !$0.atTop }) { ball in
						BigCircle(filled: false, size: ballSize)
							.matchedGeometryEffect(id: ball.id, in: ns)
					}
				}
				.frame(maxHeight: .infinity, alignment: .top)
				.animation(travelAnim, value: balls)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.contentShape(Rectangle())
			.onTapGesture(perform: startIfNeeded)
			.onAppear { reset() }
		}
		.background(Color.black.ignoresSafeArea())
	}
}

	// MARK: — Logic
private extension MeditationRoutineColumnView {
	
	func startIfNeeded() {
		guard timerC == nil else { return }
		tickOnce()
		timerC = Timer.publish(every: tickInterval, on: .main, in: .common)
			.autoconnect()
			.sink { _ in tickOnce() }
	}
	
	func tickOnce() {
		guard !isTravelling else { return }
		if tick < ticksPerBlock {
			withAnimation { tick += 1 }
			if tick == ticksPerBlock { finishedBlock() }
		}
	}
	
	func finishedBlock() {
		guard let idx = balls.firstIndex(where: { !$0.atTop }) else {
			timerC?.cancel(); timerC = nil
			DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
				reset()
				startIfNeeded()
			}
			return
		}
		isTravelling = true
		
			// dots fade back to outline as the big circle “passes”
		for step in (0..<ticksPerBlock).reversed() {
			let delay = Double(ticksPerBlock - 1 - step) * 0.1
			DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
				withAnimation(.easeInOut(duration: 0.15)) { tick = step }
			}
		}
		
			// launch the outline circle upward (short pause so dots can reset)
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
			withAnimation(travelAnim) {
				balls[idx].atTop = true        // flight uses shared duration/bounce spring
			}
			
				// allow travelAnim to complete before re-enabling ticks
			DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
				isTravelling = false
				tick = 0
			}
		}
	}
	
	var allBlocksDone: Bool { balls.allSatisfy(\.atTop) }
	
	func reset() {
		balls = (0..<totalBlocks).map { _ in Ball() }
		tick = 0
	}
}

	// MARK: - Playground (meditation animation + duration/bounce sliders)
struct MeditationAnimationPlayground: View {
	@State private var duration: Double = 0.95
	@State private var bounce:   Double = 0.66
	
	var body: some View {
		ZStack(alignment: .trailing) {
				// Main animation placed toward the right edge
			MeditationRoutineColumnView(blocks: 4, duration: $duration, bounce: $bounce)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
				.padding(.trailing, 40)
			
				// Controls in a compact card at bottom-left so they don't cover the animation
			VStack(spacing: 8) {
				Spacer()
				ControlsPanel(duration: $duration, bounce: $bounce)
					.padding(.leading, 16)
					.padding(.bottom, 16)
					.frame(maxWidth: 240, alignment: .leading)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
		}
		.background(Color.black.ignoresSafeArea())
	}
}

fileprivate struct ParamSliderRow: View {
	let title: String
	@Binding var value: Double
	var range: ClosedRange<Double>
	var format: String
	
	var body: some View {
		HStack {
			Text(title)
				.font(.caption2)
				.frame(width: 72, alignment: .leading)
			Slider(value: $value, in: range)
			Text(String(format: format, value))
				.font(.caption2)
				.monospacedDigit()
				.foregroundColor(.white.opacity(0.8))
		}
	}
}

fileprivate struct ControlsPanel: View {
	@Binding var duration: Double
	@Binding var bounce: Double
	
	var body: some View {
		VStack(spacing: 8) {
			ParamSliderRow(title: "Duration", value: $duration, range: 0.05...2.0, format: "%.2fs")
			ParamSliderRow(title: "Bounce",   value: $bounce,   range: 0.0...1.0, format: "%.2f")
		}
		.padding()
		.background(.ultraThinMaterial)
		.clipShape(RoundedRectangle(cornerRadius: 12))
	}
}

#Preview {
	MeditationAnimationPlayground()
	.preferredColorScheme(.dark)
}
