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
    
    var body: some View {
        HStack(spacing: beadSpacing) {
            ForEach(0..<beadCount, id: \.self) { index in
                Circle()
                    .stroke(Color.white, lineWidth: 1.5)
                    .background(
                        Circle()
                            .fill(beadFillColor(for: index))
                    )
                    .frame(width: beadSize, height: beadSize)
                    .animation(.easeInOut(duration: 0.3), value: currentBlockIndex)
                    .animation(.easeInOut(duration: 0.3), value: inBlockProgress)
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
        if index == currentBlockIndex - 1 {
            return inBlockProgress > 0.5 // Fill when more than halfway through
        }
        
        // Previous blocks are fully filled
        return index < currentBlockIndex - 1
    }
    
    private func isBeadPartiallyFilled(_ index: Int) -> Bool {
        guard isRoutineSelected && isPlaying else { return false }
        
        // Only the current block can be partially filled
        if index == currentBlockIndex - 1 {
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
