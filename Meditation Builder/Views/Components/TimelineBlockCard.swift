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