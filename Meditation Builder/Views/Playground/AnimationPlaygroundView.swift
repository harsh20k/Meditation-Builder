	//
	//  AnimationPlaygroundView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI

struct BreathworkPillView: View {
	@State private var tapLocation: CGPoint?
	@State private var isGlowing = false
	
	// Computed property for glow effect
	private var glowEffect: some View {
		Group {
			if let location = tapLocation, isGlowing {
				Circle()
					.fill(
						RadialGradient(
							colors: [
								Color.white.opacity(0.6),
								Color.white.opacity(0.3),
								Color.clear
							],
							center: .center,
							startRadius: 0,
							endRadius: 70
						)
					)
					.frame(width: 140, height: 140)
					.position(location)
					.scaleEffect(isGlowing ? 1.0 : 0.8)
					.opacity(isGlowing ? 1.0 : 0.0)
					.animation(.easeOut(duration: 0.3), value: isGlowing)
			}
		}
	}
	
	var body: some View {
		ZStack {
				// MARK: • Timeline dots behind the pill
			VStack(spacing: 8) {
				ForEach(0..<6, id: \.self) { _ in
					Circle()
						.fill(Color.white.opacity(0.15))
						.frame(width: 4, height: 4)
				}
			}
			
				// MARK: • Capsule + contents
			HStack(spacing: 10) {
					// Leaf icon
				Image(systemName: "leaf.fill")
					.resizable()
					.aspectRatio(contentMode: .fit)
					.frame(width: 24, height: 24)
					// use a subtle highlight gradient on the icon
					.foregroundStyle(
						LinearGradient(
							gradient: Gradient(colors: [Color.white.opacity(0.8), Color.white.opacity(0.6)]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				
					// Primary label
				Text("Breathwork")
					.font(.system(size: 20, weight: .medium, design: .serif))
					.foregroundColor(Color.white.opacity(0.95))
				
				Spacer()
				
					// Secondary label
				Text("3 min")
					.font(.system(size: 16, weight: .regular, design: .default))
					.foregroundColor(Color.white.opacity(0.90))
			}
			.padding(.vertical, 10)
			.padding(.horizontal, 16)
			.background(
				// Pill shape with gradient, shadow, inner glow
				Capsule()
					.fill(
						LinearGradient(
							gradient: Gradient(colors: [
								Color(red: 0.50, green: 0.83, blue: 0.78),  // mint-green
								Color(red: 0.23, green: 0.56, blue: 0.50)   // deep teal
							]),
							startPoint: .topLeading,
							endPoint: .bottomTrailing
						)
					)
				// soft drop shadow
					.shadow(color: Color.black.opacity(0.7), radius: 12, x: 0, y: 2)
				// subtle top-left highlight for raised effect
					.shadow(color: Color.white.opacity(0.4), radius: 4, x: -2, y: -2)
				// inner shadow on bottom-right
					.overlay(
						Capsule()
							.stroke(Color.black.opacity(0.85), lineWidth: 2)
							.blur(radius: 3)
							.offset(x: -1, y: -1)
							.mask(
								Capsule()
									.fill(
										LinearGradient(
											gradient: Gradient(colors: [Color.black, Color.clear]),
											startPoint: .bottomTrailing,
											endPoint: .topLeading
										)
									)
							)
					)
				// faint inner‐highlight at top edge
					.overlay(
						Capsule()
							.stroke(Color.white.opacity(1.0), lineWidth: 2)
							.blur(radius: 1)
							.offset(x: 1 ,y: 1)
							.mask(
								Capsule()
									.fill(
										LinearGradient(
											gradient: Gradient(colors: [Color.black, Color.clear]),
											startPoint: .topLeading,
											endPoint: .bottomTrailing
										)
									)
							)
					)
			)
			// Interactive glow overlay
			.overlay(
				glowEffect
			)
			// Tap gesture
			.onTapGesture { location in
				tapLocation = location
				isGlowing = true
				
				// Auto-hide the glow after a short delay
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
					withAnimation(.easeInOut(duration: 0.4)) {
						isGlowing = false
					}
				}
			}
		}
			// center in a dark canvas

	}
}

struct BreathworkPillView_Previews: PreviewProvider {
	static var previews: some View {
		BreathworkPillView()
			.previewLayout(.sizeThatFits)
	}
}
#Preview {
	VStack(spacing: 10) {
		BreathworkPillView()
		BreathworkPillView()
		BreathworkPillView()
	}
	.padding(40)
	.background(Color.black)
}
