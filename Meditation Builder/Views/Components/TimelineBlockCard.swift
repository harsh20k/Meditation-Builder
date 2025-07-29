	//
	//  TimelineBlockCard.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI

// MARK: - Design System Components

struct PillDesignTokens {
    // Colors
    static let lightMint = Color(red: 0.65, green: 0.88, blue: 0.78)
    static let deepTeal = Color(red: 0.18, green: 0.58, blue: 0.48)
    static let iconLight = Color(red: 0.45, green: 0.82, blue: 0.72)
    static let iconDark = Color(red: 0.15, green: 0.55, blue: 0.45)
    
    // Gradients
    static let mainGradient = LinearGradient(
        colors: [lightMint, deepTeal],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let iconGradient = LinearGradient(
        colors: [iconLight, iconDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let highlightGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.3),
            Color.white.opacity(0.15),
            Color.clear
        ],
        startPoint: .top,
        endPoint: .center
    )
    
    static let textGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.95),
            Color.white.opacity(0.85)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let primaryShadow = (color: Color.black.opacity(0.25), radius: CGFloat(10), x: CGFloat(0), y: CGFloat(6))
    static let subtleShadow = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
    static let glowShadow = (color: deepTeal.opacity(0.2), radius: CGFloat(16), x: CGFloat(0), y: CGFloat(8))
    
    // Icon shadows
    static let iconShadow = (color: Color.black.opacity(0.3), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(3))
    static let iconGlow = (color: Color.white.opacity(0.4), radius: CGFloat(6), x: CGFloat(0), y: CGFloat(0))
    
    // Text shadows
    static let textShadow = (color: Color.black.opacity(0.2), radius: CGFloat(2), x: CGFloat(0), y: CGFloat(1))
    static let subtleTextShadow = (color: Color.black.opacity(0.15), radius: CGFloat(1), x: CGFloat(0), y: CGFloat(1))
}

struct PillBackground: View {
    var body: some View {
        Capsule()
            .fill(PillDesignTokens.mainGradient)
            .overlay(
                // Top highlight
                Capsule()
                    .fill(PillDesignTokens.highlightGradient)
            )
            .overlay(
                // Subtle inner border
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.5
                    )
            )
            .shadow(
                color: PillDesignTokens.primaryShadow.color,
                radius: PillDesignTokens.primaryShadow.radius,
                x: PillDesignTokens.primaryShadow.x,
                y: PillDesignTokens.primaryShadow.y
            )
            .shadow(
                color: PillDesignTokens.glowShadow.color,
                radius: PillDesignTokens.glowShadow.radius,
                x: PillDesignTokens.glowShadow.x,
                y: PillDesignTokens.glowShadow.y
            )
    }
}

struct PillIcon: View {
    let iconName: String
    
    var body: some View {
        ZStack {
            // Icon background
            Circle()
                .fill(PillDesignTokens.iconGradient)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: PillDesignTokens.iconShadow.color,
                    radius: PillDesignTokens.iconShadow.radius,
                    x: PillDesignTokens.iconShadow.x,
                    y: PillDesignTokens.iconShadow.y
                )
            
            // Icon with gradient
            Image(systemName: iconName)
                .foregroundStyle(PillDesignTokens.textGradient)
                .font(.system(size: 20, weight: .ultraLight))
                .shadow(
                    color: PillDesignTokens.iconGlow.color,
                    radius: PillDesignTokens.iconGlow.radius,
                    x: PillDesignTokens.iconGlow.x,
                    y: PillDesignTokens.iconGlow.y
                )
        }
    }
}

struct PillText: View {
    let text: String
    let isTitle: Bool
    
    var body: some View {
        Text(text)
            .font(isTitle ? AppTheme.Typography.headlineFont : AppTheme.Typography.bodyFont)
            .foregroundStyle(PillDesignTokens.textGradient)
            .shadow(
                color: isTitle ? PillDesignTokens.textShadow.color : PillDesignTokens.subtleTextShadow.color,
                radius: isTitle ? PillDesignTokens.textShadow.radius : PillDesignTokens.subtleTextShadow.radius,
                x: isTitle ? PillDesignTokens.textShadow.x : PillDesignTokens.subtleTextShadow.x,
                y: isTitle ? PillDesignTokens.textShadow.y : PillDesignTokens.subtleTextShadow.y
            )
    }
}

struct PillActionButton: View {
    let iconName: String
    let isDestructive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .foregroundStyle(PillDesignTokens.textGradient)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isDestructive ? [
                                    Color.red.opacity(0.7),
                                    Color.red.opacity(0.5)
                                ] : [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Circle()
                                .stroke(
                                    Color.white.opacity(0.3),
                                    lineWidth: 0.5
                                )
                        )
                )
                .shadow(
                    color: PillDesignTokens.subtleShadow.color,
                    radius: PillDesignTokens.subtleShadow.radius,
                    x: PillDesignTokens.subtleShadow.x,
                    y: PillDesignTokens.subtleShadow.y
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Main TimelineBlockCard

struct TimelineBlockCard: View {
    let block: RoutineBlock
    let isLast: Bool
    var onEdit: () -> Void
    var onDelete: () -> Void
    let index: Int
    let blocksCount: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Block icon
            PillIcon(iconName: block.blockIcon)
            
            // Block details
            VStack(alignment: .leading, spacing: 4) {
                PillText(text: block.name, isTitle: true)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    // Duration
                    PillText(
                        text: String.localizedStringWithFormat(
                            NSLocalizedString("component.duration.format", comment: "Block duration"),
                            block.durationInMinutes
                        ),
                        isTitle: false
                    )
                    
                    // Bell indicator
                    if index > 0 && block.blockStartBell != .silent {
                        HStack(spacing: 4) {
                            Image(systemName: block.blockStartBell.icon)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(PillDesignTokens.textGradient)
                                .shadow(
                                    color: Color.white.opacity(0.3),
                                    radius: 2,
                                    x: 0,
                                    y: 0
                                )
                            
                            PillText(text: block.blockStartBell.displayName, isTitle: false)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                        }
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                PillActionButton(
                    iconName: "pencil",
                    isDestructive: false,
                    action: onEdit
                )
                
                PillActionButton(
                    iconName: "trash",
                    isDestructive: true,
                    action: onDelete
                )
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(PillBackground())
        .padding(.horizontal, AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview
#Preview("TimelineBlockCard") {
    ZStack {
        Color.black.ignoresSafeArea()
        
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
        Color.black.ignoresSafeArea()
        
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
        Color.black.ignoresSafeArea()
        
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
