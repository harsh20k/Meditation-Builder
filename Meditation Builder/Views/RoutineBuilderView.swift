//
//  RoutineBuilderView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import Dragula

struct RoutineBuilderView: View {
    @State private var routine = Routine(
        blocks: [
            MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 5, type: .silence),
            MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 3, type: .breathwork),
            MeditationBlock(id: UUID(), name: "Chanting", durationInMinutes: 4, type: .chanting)
        ],
        transitionBells: [TransitionBell(soundName: "Soft Bell"), TransitionBell(soundName: "Soft Bell")]
    )
    @State private var editBlock: MeditationBlock? = nil
    @State private var showAddBlock = false
    @State private var isSaving = false
    @State private var showBellPickerIndex: IdentifiableInt? = nil
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    func updateTransitionBells() {
        // Update transition bells array to match blocks count
        let bellsNeeded = max(0, routine.blocks.count - 1)
        if routine.transitionBells.count > bellsNeeded {
            routine.transitionBells = Array(routine.transitionBells.prefix(bellsNeeded))
        } else if routine.transitionBells.count < bellsNeeded {
            let additionalBells = Array(repeating: TransitionBell(soundName: "Soft Bell"), count: bellsNeeded - routine.transitionBells.count)
            routine.transitionBells.append(contentsOf: additionalBells)
        }
    }
    
    func deleteBlock(at index: Int) {
        routine.blocks.remove(at: index)
        updateTransitionBells()
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 28, weight: .bold))
                    Text("Routine")
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.small)
                
                // Timeline + Block List with Dragula
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        // Timeline vertical line (scrolls with blocks)
                        if routine.blocks.count > 1 {
                            GeometryReader { geo in
                                let blockHeight: CGFloat = 76 // Approximate block height (padding + card)
                                let spacing: CGFloat = 20
                                let totalHeight = CGFloat(routine.blocks.count) * blockHeight + CGFloat(routine.blocks.count - 1) * spacing
                                Rectangle()
                                    .fill(AppTheme.lightGrey.opacity(AppTheme.Opacity.timeline))
                                    .frame(width: 2, height: totalHeight - blockHeight/2)
                                    .offset(x: 54, y: blockHeight/2)
                            }
                        }
                        
                        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                            DragulaView(items: $routine.blocks) { block in
                                TimelineBlockCard(
                                    block: block,
                                    isLast: block.id == routine.blocks.last?.id,
                                    onEdit: { editBlock = block },
                                    index: routine.blocks.firstIndex(where: { $0.id == block.id }) ?? 0,
                                    blocksCount: routine.blocks.count,
                                    bell: getBell(for: block),
                                    onBellTap: {
                                        if let index = routine.blocks.firstIndex(where: { $0.id == block.id }) {
                                            showBellPickerIndex = IdentifiableInt(value: index)
                                        }
                                    }
                                )
                                .frame(height: 76)
                            } dropView: { block in
                                DropIndicatorView(block: block)
                            } dropCompleted: {
                                updateTransitionBells()
                            }
                            .environment(\.dragPreviewCornerRadius, AppTheme.CornerRadius.large)
                        }
                        .padding(.vertical, AppTheme.Spacing.extraLarge)
                        .padding(.bottom, 80)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Total Time & Save Button
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text("Total \(totalTime) min")
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Button(action: { isSaving = true }) {
                        Text("SAVE")
                            .font(AppTheme.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accentColor)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 72)
            }
            
            // Floating Add Button
            Button(action: { showAddBlock = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }
            }
            .padding(.trailing, AppTheme.Spacing.extraLarge)
            .padding(.bottom, 112)
            .shadow(radius: 8)
            
            // Tab Bar
            VStack {
                Spacer()
                CustomTabBar()
            }
        }
        .sheet(item: $showBellPickerIndex) { identifiable in
            let idx = identifiable.value
            BellPickerView(selected: routine.transitionBells[idx]) { bell in
                routine.transitionBells[idx] = bell
                showBellPickerIndex = nil
            }
        }
        .sheet(item: $editBlock) { block in
            EditBlockView(block: block) { updatedBlock in
                if let idx = routine.blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
                    routine.blocks[idx] = updatedBlock
                }
                editBlock = nil
            }
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView { newBlock in
                routine.blocks.append(newBlock)
                updateTransitionBells()
                showAddBlock = false
            }
        }
    }
    
    // Helper function to get bell for a block
    private func getBell(for block: MeditationBlock) -> TransitionBell? {
        guard let index = routine.blocks.firstIndex(where: { $0.id == block.id }),
              index < routine.transitionBells.count else { return nil }
        return routine.transitionBells[index]
    }
}

// MARK: - Drop Indicator View
struct DropIndicatorView: View {
    let block: MeditationBlock
    
    var body: some View {
        Rectangle()
            .fill(AppTheme.accentColor.opacity(0.3))
            .frame(height: 4)
            .clipShape(.rect(cornerRadius: 2))
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.leading, 56) // Align with timeline
    }
} 
 
