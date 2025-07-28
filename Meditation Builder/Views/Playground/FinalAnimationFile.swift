import SwiftUI
import UIKit

	// PreferenceKey to capture each item's center X position
struct CarouselCellKey: PreferenceKey {
	static var defaultValue: [Int: CGFloat] = [:]
	static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}

	// Simple model for demo items
struct RoutineStory: Identifiable {
	let id = UUID()
	let title: String
	let color: Color
}

struct MeditationAnimationPlayground: View {
	private let stories: [RoutineStory] = [
		.init(title: "Morning Flow", color: .blue),
		.init(title: "Energy Boost", color: .orange),
		.init(title: "Evening Calm", color: .purple),
		.init(title: "Deep Focus", color: .green),
		.init(title: "Wind Down", color: .pink)
	]
	
	@State private var positions: [Int: CGFloat] = [:]
	@State private var currentIndex: Int = 0
	
	private let itemWidth = UIScreen.main.bounds.width * 0.7
	private let spacing: CGFloat = 16
	
	var body: some View {
		ZStack {
			Color.black.ignoresSafeArea()
			VStack(spacing: 24) {
				
					// Display the currently centered story title
				Text(stories[currentIndex].title)
					.font(.subheadline)
					.foregroundColor(.white)
					.padding(.top, 4)
				
				ScrollView(.horizontal, showsIndicators: false) {
					HStack(spacing: spacing) {
						ForEach(Array(stories.enumerated()), id: \.offset) { index, story in
							RoundedRectangle(cornerRadius: 12)
								.fill(story.color)
								.frame(width: itemWidth, height: 150)
								.overlay(
									Text(story.title)
										.font(.title2)
										.bold()
										.foregroundColor(.white)
								)
								.scaleEffect(currentIndex == index ? 1.0 : 0.8)
								.animation(.easeInOut(duration: 0.2), value: currentIndex)
								// Capture each card's center X
								.background(
									GeometryReader { geo in
										Color.clear.preference(
											key: CarouselCellKey.self,
											value: [index: geo.frame(in: .global).midX]
										)
									}
								)
						}
					}
					.padding(.horizontal, (UIScreen.main.bounds.width - itemWidth) / 2)
				}
				.onPreferenceChange(CarouselCellKey.self) { prefs in
					positions = prefs
					detectCenterItem()
				}
				
				Spacer()
			}
		}
	}
	
		/// Finds which item is nearest the screen center and triggers a light haptic when it changes.
	private func detectCenterItem() {
		let screenCenter = UIScreen.main.bounds.width / 2
		if let nearest = positions.min(by: { abs($0.value - screenCenter) < abs($1.value - screenCenter) }) {
			let newIndex = nearest.key
			if newIndex != currentIndex {
				currentIndex = newIndex
				UIImpactFeedbackGenerator(style: .light).impactOccurred()
			}
		}
	}
}

#Preview {
	MeditationAnimationPlayground()
		.preferredColorScheme(.dark)
}
