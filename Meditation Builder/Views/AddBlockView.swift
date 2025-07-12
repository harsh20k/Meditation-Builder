//
//  AddBlockView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct AddBlockView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var customName = ""
    @State private var customDuration = 5
    var onAdd: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    var filteredDefaultBlocks: [MeditationBlock.BlockType] {
        let blocks = MeditationBlock.BlockType.allCases.filter { $0 != .custom }
        if searchText.isEmpty {
            return blocks
        }
        return blocks.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.accentColor)
                        TextField(LocalizedStringKey("search.blocks.placeholder"), text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(AppTheme.cardColor)
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.small)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            Text(LocalizedStringKey("blocks.tab.default"))
                                .font(.headline)
                                .foregroundColor(selectedTab == 0 ? AppTheme.accentColor : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == 0 ? AppTheme.cardColor.opacity(0.7) : Color.clear)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        Button(action: { selectedTab = 1 }) {
                            Text(LocalizedStringKey("blocks.tab.custom"))
                                .font(.headline)
                                .foregroundColor(selectedTab == 1 ? AppTheme.accentColor : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == 1 ? AppTheme.cardColor.opacity(0.7) : Color.clear)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                    }
                    .background(AppTheme.cardColor.opacity(0.5))
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.medium)
                    
                    if selectedTab == 0 {
                        // Default blocks list
                        ScrollView(showsIndicators: false) {
                            ZStack(alignment: .leading) {
                                if filteredDefaultBlocks.count > 1 {
                                    GeometryReader { geo in
                                        let blockHeight: CGFloat = 76
                                        let spacing: CGFloat = 20
                                        let totalHeight = CGFloat(filteredDefaultBlocks.count) * blockHeight + CGFloat(filteredDefaultBlocks.count - 1) * spacing
                                        Rectangle()
                                            .fill(AppTheme.lightGrey.opacity(AppTheme.Opacity.timeline))
                                            .frame(width: 2, height: totalHeight - blockHeight/2)
                                            .offset(x: 54, y: blockHeight/2)
                                    }
                                }
                                VStack(spacing: AppTheme.Spacing.large) {
                                    ForEach(filteredDefaultBlocks, id: \.self) { blockType in
                                        HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                                            ZStack {
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: blockType.icon)
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 22, weight: .bold))
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(blockType.titleKey)
                                                    .font(AppTheme.Typography.headlineFont)
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Text(String.localizedStringWithFormat(
                                                    String(localized: "duration.with.value.format"),
                                                    blockType.defaultDuration
                                                ))
                                                    .font(AppTheme.Typography.bodyFont)
                                                    .foregroundColor(AppTheme.lightGrey)
                                            }
                                            Spacer()
                                            Button(action: {
                                                let newBlock = MeditationBlock(
                                                    id: UUID(),
                                                    name: blockType.displayName,
                                                    durationInMinutes: blockType.defaultDuration,
                                                    type: blockType
                                                )
                                                onAdd(newBlock)
                                                dismiss()
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(AppTheme.accentColor)
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: "plus")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 20, weight: .bold))
                                                }
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
                                        .frame(height: 76)
                                    }
                                }
                                .padding(.vertical, AppTheme.Spacing.extraLarge)
                                .padding(.bottom, 80)
                            }
                        }
                    } else {
                        // Custom block
                        VStack(spacing: AppTheme.Spacing.extraLarge) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentColor)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22, weight: .bold))
                                }
                                TextField(LocalizedStringKey("block.name.placeholder"), text: $customName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Stepper(value: $customDuration, in: 1...60) {
                                Text(String.localizedStringWithFormat(
                                    String(localized: "duration.with.value.format"),
                                    customDuration
                                ))
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.lightGrey)
                            }
                            Button(action: {
                                let newBlock = MeditationBlock(
                                    id: UUID(),
                                    name: customName.isEmpty ? String(localized: "block.type.custom") : customName,
                                    durationInMinutes: customDuration,
                                    type: .custom
                                )
                                onAdd(newBlock)
                                dismiss()
                            }) {
                                Text(LocalizedStringKey("block.create.custom"))
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                            .fill(AppTheme.accentColor)
                                    )
                            }
                            .disabled(customName.isEmpty)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("block.add.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
    }
} 