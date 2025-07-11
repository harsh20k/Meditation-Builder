//
//  RoutineBuilderView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

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
    @State private var draggingBlock: MeditationBlock? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var dragIndex: Int? = nil
    @State private var blockOffsets: [UUID: CGFloat] = [:]
    @GestureState private var isDetectingLongPress = false
    @State private var showBellPickerIndex: IdentifiableInt? = nil
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    func moveBlock(from source: Int, to destination: Int) {
        guard source != destination, source < routine.blocks.count, destination < routine.blocks.count else { return }
        var newBlocks = routine.blocks
        let moved = newBlocks.remove(at: source)
        newBlocks.insert(moved, at: destination)
        routine.blocks = newBlocks
        // For simplicity, clear all bells after reorder
        routine.transitionBells = Array(repeating: TransitionBell(soundName: "Soft Bell"), count: newBlocks.count > 0 ? newBlocks.count - 1 : 0)
    }
    
    func deleteBlock(at index: Int) {
        routine.blocks.remove(at: index)
        if routine.transitionBells.indices.contains(index) {
            routine.transitionBells.remove(at: index)
        } else if routine.transitionBells.indices.contains(index - 1) {
            routine.transitionBells.remove(at: index - 1)
        }
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
                
                // Timeline + Block List
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
                        VStack(spacing: AppTheme.Spacing.large) {
                            ForEach(Array(routine.blocks.enumerated()), id: \.element.id) { (idx, block) in
                                TimelineBlockCard(
                                    block: block,
                                    isLast: idx == routine.blocks.count - 1,
                                    onEdit: { editBlock = block },
                                    onDrag: { dragState in
                                        if let from = dragState.from, let to = dragState.to {
                                            moveBlock(from: from, to: to)
                                        }
                                    },
                                    index: idx,
                                    blocksCount: routine.blocks.count,
                                    draggingBlock: $draggingBlock,
                                    bell: idx < routine.transitionBells.count ? routine.transitionBells[idx] : nil,
                                    onBellTap: {
                                        showBellPickerIndex = IdentifiableInt(value: idx)
                                    }
                                )
                                .frame(height: 76)
                            }
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
                if routine.blocks.count > 1 {
                    routine.transitionBells.append(TransitionBell(soundName: "Soft Bell"))
                }
                showAddBlock = false
            }
        }
    }
} 