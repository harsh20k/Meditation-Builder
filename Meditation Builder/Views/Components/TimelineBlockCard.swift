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
    static let mintGreen = Color(red: 0.50, green: 0.83, blue: 0.78)
    static let deepTeal = Color(red: 0.23, green: 0.56, blue: 0.50)
    
    // Gradients
    static let mainGradient = LinearGradient(
        gradient: Gradient(colors: [mintGreen, deepTeal]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let iconGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.8),
            Color.white.opacity(0.6)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Shadows
    static let dropShadow = (color: Color.black.opacity(0.7), radius: CGFloat(12), x: CGFloat(0), y: CGFloat(2))
    static let highlightShadow = (color: Color.white.opacity(0.4), radius: CGFloat(4), x: CGFloat(-2), y: CGFloat(-2))
    
    // Inner shadows and strokes
    static let innerShadowStroke = (color: Color.black.opacity(0.85), width: CGFloat(2), blur: CGFloat(3))
    static let innerHighlightStroke = (color: Color.white.opacity(1.0), width: CGFloat(2), blur: CGFloat(1))
    
    // Text styles
    static let primaryTextColor = Color.white.opacity(0.95)
    static let secondaryTextColor = Color.white.opacity(0.90)
    
    // Gradients for text and buttons
    static let textGradient = LinearGradient(
        gradient: Gradient(colors: [
            Color.white.opacity(0.95),
            Color.white.opacity(0.85)
        ]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Additional shadows
    static let subtleShadow = (color: Color.black.opacity(0.15), radius: CGFloat(4), x: CGFloat(0), y: CGFloat(2))
}

struct PillBackground: View {
    var body: some View {
        Capsule()
            .fill(PillDesignTokens.mainGradient)
            // soft drop shadow
            .shadow(
                color: PillDesignTokens.dropShadow.color,
                radius: PillDesignTokens.dropShadow.radius,
                x: PillDesignTokens.dropShadow.x,
                y: PillDesignTokens.dropShadow.y
            )
            // subtle top-left highlight for raised effect
            .shadow(
                color: PillDesignTokens.highlightShadow.color,
                radius: PillDesignTokens.highlightShadow.radius,
                x: PillDesignTokens.highlightShadow.x,
                y: PillDesignTokens.highlightShadow.y
            )
            // inner shadow on bottom-right
            .overlay(
                Capsule()
                    .stroke(PillDesignTokens.innerShadowStroke.color, lineWidth: PillDesignTokens.innerShadowStroke.width)
                    .blur(radius: PillDesignTokens.innerShadowStroke.blur)
                    .offset(x: -1, y: -1)
                    .mask(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.clear]),
                                    startPoint: .bottomTrailing,
                                    endPoint: .topLeading
                                )
                            )
                    )
            )
            // faint inner‐highlight at top edge
            .overlay(
                Capsule()
                    .stroke(PillDesignTokens.innerHighlightStroke.color, lineWidth: PillDesignTokens.innerHighlightStroke.width)
                    .blur(radius: PillDesignTokens.innerHighlightStroke.blur)
                    .offset(x: 1, y: 1)
                    .mask(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.black, Color.clear]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
    }
}

struct PillIcon: View {
    let iconName: String
    
    var body: some View {
        Image(systemName: iconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 24, height: 24)
            .foregroundStyle(PillDesignTokens.iconGradient)
    }
}

struct PillText: View {
    let text: String
    let isTitle: Bool
    
    var body: some View {
        Text(text)
            .font(isTitle ? 
                .system(size: 20, weight: .medium, design: .serif) :
                .system(size: 16, weight: .regular, design: .default))
            .foregroundColor(isTitle ? 
                PillDesignTokens.primaryTextColor :
                PillDesignTokens.secondaryTextColor)
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
    let index: Int
    let blocksCount: Int
    
    var body: some View {
        HStack(spacing: 10) {
            // Block icon
            PillIcon(iconName: block.blockIcon)
            
            // Block details
            HStack {
                PillText(text: block.name, isTitle: true)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Spacer()
                
                // Duration
                PillText(
                    text: String.localizedStringWithFormat(
                        NSLocalizedString("component.duration.format", comment: "Block duration"),
                        block.durationInMinutes
                    ),
                    isTitle: false
                )
            }
            
            // Bell indicator (commented out for now)
            /*
            if index > 0 && block.blockStartBell != .silent {
                Image(systemName: block.blockStartBell.icon)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(PillDesignTokens.secondaryTextColor)
                
                // Bell name hidden for now - might add back later
                PillText(text: block.blockStartBell.displayName, isTitle: false)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
            }
            */
            
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
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
            index: 1,
            blocksCount: 1
        )
        .padding()
    }
}
