//
//  RoutinePlayerSelectionView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

// MARK: - Empty State View
struct RoutineEmptyStateView: View {
    var body: some View {
        VStack {
            Spacer()
            Text("No routine selected")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - No Routine State
struct NoRoutineState: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoutineEmptyStateView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
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
            }
        }
    }
} 