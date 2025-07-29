//
//  TimelineBlockCard.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct TimelineBlockCard: View {
    let block: RoutineBlock
    let isLast: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    let index: Int
    let blocksCount: Int
    
    var body: some View {
		ZStack(alignment: .center) {
            // Timeline node - visual connector between blocks
//            VStack {
//                Spacer()
//                Circle()
//                    .fill(AppTheme.accentColor)
//                    .frame(width: 16, height: 16)
//                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
//                    .padding(.leading, 28)
//                Spacer()
//            }
//            .frame(width: 40)
            
            // Main block card content
            HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                // Block icon with background circle
                ZStack {
                    Circle()
						.fill(AppTheme.blockColor.gradient)
                        .frame(width: 40, height: 40)
                    Image(systemName: block.blockIcon)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .ultraLight))
                }
                
                // Block details (name, duration, bell info)
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.name)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(spacing: 8) {
                        // Duration display
                        Text(String.localizedStringWithFormat(
                    NSLocalizedString("component.duration.format", comment: "Block duration"),
                    block.durationInMinutes
                ))
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.lightGrey)
                        
                        // Bell indicator (only show for non-first blocks with non-silent bells)
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
                
                // Action buttons (edit/delete)
                HStack(spacing: AppTheme.Spacing.small) {
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
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color.red.opacity(0.7))
                            )
                    }
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 16)
            .background(
				RoundedRectangle(cornerRadius: AppTheme.CornerRadius.blockCard)
					.fill(AppTheme.blockColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.blockCard)
                    .stroke(Color.white.opacity(AppTheme.Opacity.border), lineWidth: 1)
            )
            .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
            .padding(.horizontal, AppTheme.Spacing.medium)
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
                block: RoutineBlock(
                    name: "Breathwork",
                    durationInMinutes: 5,
                    type: .breathwork,
                    blockStartBell: .softBell
                ),
                isLast: false,
                onEdit: {},
                onDelete: {},
                index: 0,
                blocksCount: 3
            )
            
            // Preview second block (shows bell since index > 0)
            TimelineBlockCard(
                block: RoutineBlock(
                    name: "Visualization",
                    durationInMinutes: 8,
                    type: .visualization,
                    blockStartBell: .tibetanBowl
                ),
                isLast: false,
                onEdit: {},
                onDelete: {},
                index: 1,
                blocksCount: 3
            )
            
            // Preview last block
            TimelineBlockCard(
                block: RoutineBlock(
                    name: "Body Scan",
                    durationInMinutes: 12,
                    type: .bodyScan,
                    blockStartBell: .digitalChime
                ),
                isLast: true,
                onEdit: {},
                onDelete: {},
                index: 2,
                blocksCount: 3
            )
            
            // Preview with silent bell
            TimelineBlockCard(
                block: RoutineBlock(
                    name: "Custom Block",
                    durationInMinutes: 8,
                    type: .custom,
                    blockStartBell: .silent
                ),
                isLast: false,
                onEdit: {},
                onDelete: {},
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
                        block: RoutineBlock(
                            name: blockType.rawValue,
                            durationInMinutes: blockType.defaultDuration,
                            type: blockType,
                            blockStartBell: index == 0 ? .silent : BellSound.allCases[index % BellSound.allCases.count]
                        ),
                        isLast: blockType == .custom,
                        onEdit: {},
                        onDelete: {},
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
            block: RoutineBlock(
                name: "Body Scan",
                durationInMinutes: 12,
                type: .bodyScan,
                blockStartBell: .tibetanBowl
            ),
            isLast: true,
            onEdit: {},
            onDelete: {},
            index: 1,
            blocksCount: 1
        )
        .padding()
    }
} 
