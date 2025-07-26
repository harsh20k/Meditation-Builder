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
                
                // Beads Progress Indicator - positioned at top center
                BeadsView(
                    currentBlockIndex: 0,
                    totalBlocks: 0,
                    inBlockProgress: 0.0,
                    blockStartDate: Date(),
                    isRoutineSelected: false,
                    isPlaying: false
                )
                .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 60)
                
                // Carousel
                RoutineCarouselView(routines: savedRoutines)
            }
        }
    }
}

struct RoutineCarouselView: View {
    let routines: [SavedRoutine]
    
    // Constants for animation and layout
    private let spacing: CGFloat = 16
    private let cardWidth: CGFloat = 80
    private let dragThreshold: CGFloat = 50
    private let scaleRange: ClosedRange<CGFloat> = 0.7...1.0
    
    // State
    @State private var currentIndex: Int = 0
    @State private var offset: CGFloat = 0
    @GestureState private var dragOffset: CGFloat = 0
    
    // Haptic feedback generator
    private let haptic = UIImpactFeedbackGenerator(style: .light)
    
    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let xOffset = (totalWidth - cardWidth) / 2
            
            HStack(spacing: spacing) {
                ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                    routineIcon(for: routine)
                        .frame(width: cardWidth)
                        .scaleEffect(scale(for: index, in: geometry))
                        .opacity(opacity(for: index, in: geometry))
                }
            }
            .offset(x: xOffset + offset + dragOffset)
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let predictedEndOffset = value.predictedEndTranslation.width
                        let shouldSwipe = abs(predictedEndOffset) > dragThreshold
                        
                        if shouldSwipe {
                            let direction: CGFloat = predictedEndOffset < 0 ? -1 : 1
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
        let itemOffset = CGFloat(index) * (cardWidth + spacing)
        let distance = abs(itemOffset + offset + dragOffset)
        let percentageFromCenter = distance / (geometry.size.width / 2)
        return max(scaleRange.lowerBound,
                  min(scaleRange.upperBound,
                      1.0 - (percentageFromCenter * 0.3)))
    }
    
    private func opacity(for index: Int, in geometry: GeometryProxy) -> Double {
        let itemOffset = CGFloat(index) * (cardWidth + spacing)
        let distance = abs(itemOffset + offset + dragOffset)
        let percentageFromCenter = distance / (geometry.size.width / 2)
        return max(0.5, min(1.0, 1.0 - (percentageFromCenter * 0.5)))
    }
    
    private func updateOffset() {
        offset = -CGFloat(currentIndex) * (cardWidth + spacing)
    }
    
    private func clamp(_ value: Int, min minValue: Int, max maxValue: Int) -> Int {
        Swift.max(minValue, Swift.min(maxValue, value))
    }
}

// MARK: - Preview
#Preview {
    RoutinePlayerSelectionView()
} 