	//
	//  RoutinePlayerSelectionView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI
import SwiftData

struct RoutinePlayerSelectionView: View {
	@Query(sort: \SavedRoutine.lastModified, order: .reverse) private var allSavedRoutines: [SavedRoutine]
	
		// Filter out soft-deleted routines
	private var savedRoutines: [SavedRoutine] {
		allSavedRoutines.filter { !$0.isDeleted }
	}
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				AppTheme.backgroundColor.ignoresSafeArea()
				
				VStack(spacing: 0) {
						// Beads Progress Indicator
					BeadsView(
						currentBlockIndex: 0,
						totalBlocks: 0,
						inBlockProgress: 0.0,
						blockStartDate: Date(),
						isRoutineSelected: false,
						isPlaying: false
					)
					.padding(.top, geometry.safeAreaInsets.top + 60)
					
						// Spacer to push carousel to vertical center
					Spacer()
					
						// Carousel
					RoutineCarouselView(routines: savedRoutines)
						.frame(height: 160) // Height to accommodate icon and text
					
						// Spacer for bottom padding
					Spacer()
				}
			}
		}
	}
}

struct RoutineCarouselView: View {
	let routines: [SavedRoutine]
	
		// Constants for animation and layout
	private let spacing: CGFloat = 24 // Increased spacing between items
	private let cardWidth: CGFloat = 80
	private var itemWidth: CGFloat { cardWidth * 1.5 }
	private let dragThreshold: CGFloat = 50
	private let scaleRange: ClosedRange<CGFloat> = 0.7...1.0
	
		// State
	@State private var currentIndex: Int = 0
	@State private var offset: CGFloat = 0
	@GestureState private var dragOffset: CGFloat = 0
	
		// Haptic feedback generator
	private let haptic = UIImpactFeedbackGenerator(style: .light)
	
	private func resistedDrag(_ translation: CGFloat) -> CGFloat {
		let maxDrag = itemWidth + spacing
		let absTrans = abs(translation)
		if absTrans <= maxDrag {
			return translation
		}
			// Beyond one item width, apply 20% resistance on extra drag
		let extra = (absTrans - maxDrag) * 0.2
		return (translation > 0 ? maxDrag : -maxDrag) + (translation > 0 ? extra : -extra)
	}
	
	var body: some View {
		GeometryReader { geometry in
			let totalWidth = geometry.size.width
			let xOffset = (totalWidth - cardWidth) / 2
			
			ZStack {
				HStack(spacing: spacing) {
					ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
						VStack(spacing: 12) {
								// Icon
							routineIcon(for: routine)
								.frame(width: cardWidth)
							
								// Routine Name
							Text(routine.routineName)
								.font(AppTheme.Typography.captionFont)
								.foregroundColor(AppTheme.offWhiteText)
								.multilineTextAlignment(.center)
								.lineLimit(2)
								.frame(width: cardWidth * 1.5)
						}
						.scaleEffect(scale(for: index, in: geometry))
						.opacity(opacity(for: index, in: geometry))
					}
				}
				.contentShape(Rectangle()) // make the entire area tappable/draggable
			}
			.offset(x: xOffset + offset + dragOffset)
			.gesture(
				DragGesture()
					.updating($dragOffset) { value, state, _ in
							// Apply resistance to drag gesture
						state = resistedDrag(value.translation.width)
					}
					.onEnded { value in
						let dragDistance = value.translation.width
						let shouldSwipe = abs(dragDistance) > dragThreshold
						
						if shouldSwipe {
							let direction: CGFloat = dragDistance < 0 ? -1 : 1
							withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
								currentIndex = clamp(
									currentIndex - Int(direction),
									min: 0,
									max: routines.count - 1
								)
								updateOffset()
							}
							haptic.impactOccurred()
						} else {
							withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
								updateOffset()
							}
						}
					}
			)
		}
		.onAppear {
			updateOffset()
		}
		.onChange(of: routines) { _ in
			updateOffset()
		}
	}
	
	private func routineIcon(for routine: SavedRoutine) -> some View {
		ZStack {
			Circle()
				.fill(AppTheme.cardColor)
				.frame(width: cardWidth, height: cardWidth)
			
			Image(systemName: routine.routineIcon)
				.font(.system(size: 32, weight: .ultraLight))
				.foregroundColor(AppTheme.accentColor)
		}
	}
	
	private func scale(for index: Int, in geometry: GeometryProxy) -> CGFloat {
		let itemOffset = CGFloat(index) * (itemWidth + spacing)
		let distance = abs(itemOffset + offset + dragOffset)
		let percentageFromCenter = distance / (geometry.size.width / 2)
		let raw = 1.0 - (percentageFromCenter * 0.3)
		return min(scaleRange.upperBound, max(scaleRange.lowerBound, raw))
	}
	
	private func opacity(for index: Int, in geometry: GeometryProxy) -> Double {
		let itemOffset = CGFloat(index) * (itemWidth + spacing)
		let distance = abs(itemOffset + offset + dragOffset)
		let percentageFromCenter = distance / (geometry.size.width / 2)
		return max(0.5, min(1.0, 1.0 - (percentageFromCenter * 0.5)))
	}
	
	private func updateOffset() {
		offset = -CGFloat(currentIndex) * (itemWidth + spacing)
	}
	
	private func clamp(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
		Swift.max(minValue, Swift.min(maxValue, value))
	}
}

	// MARK: - Preview
#Preview {
	RoutinePlayerSelectionView()
} 
