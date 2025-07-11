//
//  TimelineBlockCard.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct TimelineBlockCard: View {
    let block: MeditationBlock
    let isLast: Bool
    var onEdit: () -> Void
    var onDrag: (_ dragState: (from: Int?, to: Int?)) -> Void
    var onDragEnd: () -> Void
    let index: Int
    let blocksCount: Int
    @Binding var draggingBlock: MeditationBlock?
    let bell: TransitionBell?
    var onBellTap: (() -> Void)? = nil
    let reorderMode: Bool
    
    // Drag state
    @State private var isDragging = false
    @State private var dragOffset: CGSize = .zero
    @State private var isLongPressed = false
    @GestureState private var longPressState = false
    @State private var lastDragIndex: Int? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Debug info
            if reorderMode {
                Text("Reorder Mode Active")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(4)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
                    .position(x: 50, y: 20)
            }
            // Timeline node
            VStack {
                Spacer()
                Circle()
                    .fill(AppTheme.accentColor)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                    .padding(.leading, 28)
                Spacer()
            }
            .frame(width: 40)
            
            // Block Card
            HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: block.type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.name)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(block.durationInMinutes) min")
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                }
                Spacer()
                
                if !isLast {
                    Button(action: { onBellTap?() }) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding(.bottom, 2)
                }
                
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(AppTheme.Opacity.overlay))
                        )
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.white.opacity(AppTheme.Opacity.border), lineWidth: 1)
            )
            .shadow(color: AppTheme.Shadows.card, radius: isDragging ? 12 : 4, x: 0, y: isDragging ? 8 : 2)
            .padding(.leading, AppTheme.Spacing.medium)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .rotation3DEffect(
                .degrees(isDragging ? 5 : 0),
                axis: (x: 1, y: 0, z: 0)
            )
            .opacity(isDragging ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isDragging)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .offset(dragOffset)
        .zIndex(isDragging ? 1000 : 0)
        .onTapGesture {
            print("Tap detected - reorderMode: \(reorderMode)")
        }
        .gesture(
            reorderMode ? 
            LongPressGesture(minimumDuration: 0.3)
                .updating($longPressState) { currentState, gestureState, _ in
                    print("Long press updating: \(currentState)")
                    gestureState = currentState
                }
                .onEnded { _ in
                    print("Long press ended - reorderMode: \(reorderMode)")
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isLongPressed = true
                        isDragging = true
                        draggingBlock = block
                    }
                }
                .simultaneously(with: 
                    DragGesture()
                        .onChanged { value in
                            if isLongPressed {
                                print("Drag changed - translation: \(value.translation)")
                                dragOffset = value.translation
                                
                                // Calculate potential drop index based on drag position
                                let dragThreshold: CGFloat = 40
                                let currentIndex = index
                                let dragDistance = value.translation.height
                                
                                if abs(dragDistance) > dragThreshold {
                                    let direction = dragDistance > 0 ? 1 : -1
                                    let newIndex = max(0, min(blocksCount - 1, currentIndex + direction))
                                    
                                    if newIndex != currentIndex && newIndex != lastDragIndex {
                                        print("Calling onDrag from \(currentIndex) to \(newIndex)")
                                        // Haptic feedback
                                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                        impactFeedback.impactOccurred()
                                        
                                        lastDragIndex = newIndex
                                        onDrag((from: currentIndex, to: newIndex))
                                    }
                                }
                            }
                        }
                        .onEnded { value in
                            if isLongPressed {
                                print("Drag ended")
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    dragOffset = .zero
                                    isDragging = false
                                    isLongPressed = false
                                    draggingBlock = nil
                                    lastDragIndex = nil
                                }
                                
                                // Call drag end handler
                                onDragEnd()
                            }
                        }
                ) : nil
        )
        .onChange(of: longPressState) { _, newValue in
            if !newValue && isLongPressed {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isDragging = false
                    isLongPressed = false
                    draggingBlock = nil
                    dragOffset = .zero
                    lastDragIndex = nil
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("TimelineBlockCard") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        VStack(spacing: 20) {
            // Preview with bell (not last block)
            TimelineBlockCard(
                block: MeditationBlock(
                    id: UUID(),
                    name: "Breathwork",
                    durationInMinutes: 5,
                    type: .breathwork
                ),
                isLast: false,
                onEdit: {},
                onDrag: { _ in },
                onDragEnd: {},
                index: 0,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Soft Bell"),
                onBellTap: {},
                reorderMode: true
            )
            
            // Preview without bell (last block)
            TimelineBlockCard(
                block: MeditationBlock(
                    id: UUID(),
                    name: "Silence",
                    durationInMinutes: 10,
                    type: .silence
                ),
                isLast: true,
                onEdit: {},
                onDrag: { _ in },
                onDragEnd: {},
                index: 2,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: nil,
                onBellTap: {},
                reorderMode: true
            )
            
            // Preview with long name
            TimelineBlockCard(
                block: MeditationBlock(
                    id: UUID(),
                    name: "Very Long Meditation Block Name That Might Wrap",
                    durationInMinutes: 15,
                    type: .visualization
                ),
                isLast: false,
                onEdit: {},
                onDrag: { _ in },
                onDragEnd: {},
                index: 1,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Tibetan Bowl"),
                onBellTap: {},
                reorderMode: true
            )
            
            // Preview with custom block
            TimelineBlockCard(
                block: MeditationBlock(
                    id: UUID(),
                    name: "Custom Block",
                    durationInMinutes: 8,
                    type: .custom
                ),
                isLast: false,
                onEdit: {},
                onDrag: { _ in },
                onDragEnd: {},
                index: 3,
                blocksCount: 4,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Digital Chime"),
                onBellTap: {},
                reorderMode: true
            )
        }
        .padding()
    }
}

#Preview("All Block Types") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 16) {
                ForEach(MeditationBlock.BlockType.allCases, id: \.self) { blockType in
                    TimelineBlockCard(
                        block: MeditationBlock(
                            id: UUID(),
                            name: blockType.rawValue,
                            durationInMinutes: blockType.defaultDuration,
                            type: blockType
                        ),
                        isLast: blockType == .custom,
                        onEdit: {},
                        onDrag: { _ in },
                        onDragEnd: {},
                        index: MeditationBlock.BlockType.allCases.firstIndex(of: blockType) ?? 0,
                        blocksCount: MeditationBlock.BlockType.allCases.count,
                        draggingBlock: .constant(nil),
                        bell: blockType != .custom ? TransitionBell(soundName: "Soft Bell") : nil,
                        onBellTap: {},
                        reorderMode: true
                    )
                }
            }
            .padding()
        }
    }
}

#Preview("Single Block") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        TimelineBlockCard(
            block: MeditationBlock(
                id: UUID(),
                name: "Body Scan",
                durationInMinutes: 12,
                type: .bodyScan
            ),
            isLast: true,
            onEdit: {},
            onDrag: { _ in },
            onDragEnd: {},
            index: 0,
            blocksCount: 1,
            draggingBlock: .constant(nil),
            bell: nil,
            onBellTap: {},
            reorderMode: true
        )
        .padding()
    }
} 