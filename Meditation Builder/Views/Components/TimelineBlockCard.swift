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
    let index: Int
    let blocksCount: Int
    
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
                    
                    HStack(spacing: 8) {
                        Text("\(block.durationInMinutes) min")
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.lightGrey)
                        
                        if index > 0 && block.blockStartBell != .silent {
                            HStack(spacing: 4) {
                                Image(systemName: block.blockStartBell.icon)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                Text(block.blockStartBell.displayName)
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppTheme.lightGrey)
                            }
                        }
                    }
                }
                Spacer()
                
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
            // Preview first block (no bell shown since index 0)
            TimelineBlockCard(
                block: MeditationBlock(
                    name: "Breathwork",
                    durationInMinutes: 5,
                    type: .breathwork,
                    blockStartBell: .softBell
                ),
                isLast: false,
                onEdit: {},
                index: 0,
                blocksCount: 3
            )
            
            // Preview middle block (shows bell)
            TimelineBlockCard(
                block: MeditationBlock(
                    name: "Silence",
                    durationInMinutes: 10,
                    type: .silence,
                    blockStartBell: .tibetanBowl
                ),
                isLast: false,
                onEdit: {},
                index: 1,
                blocksCount: 3
            )
            
            // Preview last block
            TimelineBlockCard(
                block: MeditationBlock(
                    name: "Very Long Meditation Block Name That Might Wrap",
                    durationInMinutes: 15,
                    type: .visualization,
                    blockStartBell: .digitalChime
                ),
                isLast: true,
                onEdit: {},
                index: 2,
                blocksCount: 3
            )
            
            // Preview with silent bell
            TimelineBlockCard(
                block: MeditationBlock(
                    name: "Custom Block",
                    durationInMinutes: 8,
                    type: .custom,
                    blockStartBell: .silent
                ),
                isLast: false,
                onEdit: {},
                index: 1,
                blocksCount: 4
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
                ForEach(Array(MeditationBlock.BlockType.allCases.enumerated()), id: \.element) { index, blockType in
                    TimelineBlockCard(
                        block: MeditationBlock(
                            name: blockType.rawValue,
                            durationInMinutes: blockType.defaultDuration,
                            type: blockType,
                            blockStartBell: index == 0 ? .silent : BellSound.allCases[index % BellSound.allCases.count]
                        ),
                        isLast: blockType == .custom,
                        onEdit: {},
                        index: index,
                        blocksCount: MeditationBlock.BlockType.allCases.count
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
                name: "Body Scan",
                durationInMinutes: 12,
                type: .bodyScan,
                blockStartBell: .tibetanBowl
            ),
            isLast: true,
            onEdit: {},
            index: 1,
            blocksCount: 1
        )
        .padding()
    }
} 
