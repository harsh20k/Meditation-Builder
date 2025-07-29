	//
	//  AnimationPlaygroundView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI

struct BreathworkPillView: View {
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
		}
			// center in a dark canvas
		.padding(40)
		.background(Color.black)
	}
}

struct BreathworkPillView_Previews: PreviewProvider {
	static var previews: some View {
		BreathworkPillView()
			.previewLayout(.sizeThatFits)
	}
}
#Preview {
	BreathworkPillView()
}
