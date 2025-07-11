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
    let index: Int
    let blocksCount: Int
    @Binding var draggingBlock: MeditationBlock?
    let bell: TransitionBell?
    var onBellTap: (() -> Void)? = nil
    
    @State private var offset: CGFloat = 0
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var isSwiped: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
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
            .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
            .padding(.leading, AppTheme.Spacing.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                index: 0,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Soft Bell"),
                onBellTap: {}
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
                index: 2,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: nil,
                onBellTap: {}
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
                index: 1,
                blocksCount: 3,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Tibetan Bowl"),
                onBellTap: {}
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
                index: 3,
                blocksCount: 4,
                draggingBlock: .constant(nil),
                bell: TransitionBell(soundName: "Digital Chime"),
                onBellTap: {}
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
                        index: MeditationBlock.BlockType.allCases.firstIndex(of: blockType) ?? 0,
                        blocksCount: MeditationBlock.BlockType.allCases.count,
                        draggingBlock: .constant(nil),
                        bell: blockType != .custom ? TransitionBell(soundName: "Soft Bell") : nil,
                        onBellTap: {}
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
            index: 0,
            blocksCount: 1,
            draggingBlock: .constant(nil),
            bell: nil,
            onBellTap: {}
        )
        .padding()
    }
} 