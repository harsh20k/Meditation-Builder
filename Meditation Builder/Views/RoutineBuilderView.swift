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
    
    // Enhanced drag state
    @State private var hoverIndex: Int? = nil
    @State private var isReordering = false
    @State private var draggedBlockIndex: Int? = nil
    @State private var reorderMode = false
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    func moveBlock(from source: Int, to destination: Int) {
        guard source != destination, 
              source < routine.blocks.count, 
              destination < routine.blocks.count,
              source >= 0,
              destination >= 0 else { return }
        
        var newBlocks = routine.blocks
        let moved = newBlocks.remove(at: source)
        newBlocks.insert(moved, at: destination)
        
        // Update transition bells
        var newBells = routine.transitionBells
        if newBells.count > 0 {
            if source < newBells.count {
                let bell = newBells.remove(at: source)
                if destination <= newBells.count {
                    newBells.insert(bell, at: destination)
                } else {
                    newBells.append(bell)
                }
            }
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            routine.blocks = newBlocks
            routine.transitionBells = newBells
        }
    }
    
    func deleteBlock(at index: Int) {
        routine.blocks.remove(at: index)
        if routine.transitionBells.indices.contains(index) {
            routine.transitionBells.remove(at: index)
        } else if routine.transitionBells.indices.contains(index - 1) {
            routine.transitionBells.remove(at: index - 1)
        }
    }
    
    func handleDrag(from source: Int?, to destination: Int?) {
        guard let from = source, let to = destination else { return }
        
        print("handleDrag called - from: \(from), to: \(to)")
        
        if from != to {
            // Update visual feedback immediately
            hoverIndex = to
            draggedBlockIndex = from
            print("Updated hoverIndex: \(hoverIndex), draggedBlockIndex: \(draggedBlockIndex)")
        }
    }
    
    func handleDragEnd() {
        print("handleDragEnd called")
        // Perform the actual reordering when drag ends
        if let from = draggedBlockIndex, let to = hoverIndex, from != to {
            print("Moving block from \(from) to \(to)")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                moveBlock(from: from, to: to)
            }
        } else {
            print("No reorder needed - from: \(draggedBlockIndex), to: \(hoverIndex)")
        }
        
        // Reset drag state
        hoverIndex = nil
        draggedBlockIndex = nil
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Routine")
                            .font(AppTheme.Typography.titleFont)
                            .foregroundColor(.white)
                        if reorderMode {
                            Text("Reorder Mode: ON")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                    
                    // Reorder mode toggle
                    Button(action: {
                        print("Reorder button tapped - current mode: \(reorderMode)")
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            reorderMode.toggle()
                        }
                        print("Reorder mode changed to: \(reorderMode)")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: reorderMode ? "checkmark.circle.fill" : "arrow.up.arrow.down")
                                .font(.system(size: 16, weight: .medium))
                            Text(reorderMode ? "Done" : "Reorder")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(reorderMode ? .green : AppTheme.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(reorderMode ? Color.green.opacity(0.2) : AppTheme.accentColor.opacity(0.2))
                        )
                    }
                    
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 28, weight: .bold))
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
                                VStack(spacing: 0) {
                                    // Drop zone indicator
                                    DropZoneIndicator(isActive: hoverIndex == idx)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 8)
                                    
                                    // Block card
                                    TimelineBlockCard(
                                        block: block,
                                        isLast: idx == routine.blocks.count - 1,
                                        onEdit: { editBlock = block },
                                        onDrag: handleDrag,
                                        onDragEnd: handleDragEnd,
                                        index: idx,
                                        blocksCount: routine.blocks.count,
                                        draggingBlock: $draggingBlock,
                                        bell: idx < routine.transitionBells.count ? routine.transitionBells[idx] : nil,
                                        onBellTap: {
                                            showBellPickerIndex = IdentifiableInt(value: idx)
                                        },
                                        reorderMode: reorderMode
                                    )
                                    .frame(height: 76)
                                    .opacity(draggedBlockIndex == idx ? 0.3 : 1.0)
                                    .animation(.easeInOut(duration: 0.2), value: draggedBlockIndex)
                                    .overlay(
                                        reorderMode ? 
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.green, lineWidth: 2)
                                            .opacity(0.5) : nil
                                    )
                                }
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