//
//  EditBlockView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import UniformTypeIdentifiers
import os.log

struct EditBlockView: View {
    @State var block: RoutineBlock
    @State private var showIconPicker = false
    @State private var showBellPicker = false
    @State private var showMusicPicker = false
    @State private var musicImportError: String? = nil
    var onSave: (RoutineBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.section) {
                    VStack(spacing: AppTheme.Spacing.extraLarge) {
                        // Icon + Name
                        HStack(spacing: AppTheme.Spacing.medium) {
                            Button(action: { showIconPicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentColor)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: block.blockIcon)
                                        .foregroundColor(AppTheme.offWhiteText)
                                        .font(.system(size: 22, weight: .bold))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            TextField(LocalizedStringKey("block.name.placeholder"), text: $block.name)
                                .font(AppTheme.Typography.headlineFont)
                                .foregroundColor(AppTheme.offWhiteText)
                                .padding(12)
                                .background(AppTheme.cardColor)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        
                        // Duration
                        Stepper(value: $block.durationInMinutes, in: 1...60) {
                            Text(String.localizedStringWithFormat(
                                String(localized: "duration.with.value.format"),
                                block.durationInMinutes
                            ))
                                .font(AppTheme.Typography.bodyFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        
                        // Bell Selection
                        Button(action: { showBellPicker = true }) {
                            HStack(spacing: AppTheme.Spacing.medium) {
                                Image(systemName: block.blockStartBell.icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                Text(String.localizedStringWithFormat(
                                    NSLocalizedString("edit.block.start.bell.format", comment: "Start bell display"),
                                    block.blockStartBell.displayName
                                ))
                                    .font(AppTheme.Typography.bodyFont)
                                    .foregroundColor(AppTheme.lightGrey)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppTheme.lightGrey)
                            }
                            .padding(.horizontal, AppTheme.Spacing.small)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Music Selection
                        Divider()
                            .background(Color.white.opacity(0.1))
                            .padding(.horizontal, AppTheme.Spacing.small)

                        if let displayName = block.musicDisplayName {
                            // Music file set — show name + clear button
                            HStack(spacing: AppTheme.Spacing.medium) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                                Text(displayName)
                                    .font(AppTheme.Typography.bodyFont)
                                    .foregroundColor(AppTheme.offWhiteText)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    if let fileName = block.musicFileName {
                                        BlockMusicManager.shared.deleteMusic(fileName: fileName)
                                    }
                                    block.musicFileName = nil
                                    block.musicDisplayName = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(AppTheme.lightGrey)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, AppTheme.Spacing.small)
                        } else {
                            // No music — show picker button
                            Button(action: { showMusicPicker = true }) {
                                HStack(spacing: AppTheme.Spacing.medium) {
                                    Image(systemName: "music.note")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppTheme.accentColor)
                                    Text("Add Music")
                                        .font(AppTheme.Typography.bodyFont)
                                        .foregroundColor(AppTheme.lightGrey)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.lightGrey)
                                }
                                .padding(.horizontal, AppTheme.Spacing.small)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }

                        if let error = musicImportError {
                            Text(error)
                                .font(AppTheme.Typography.bodyFont)
                                .foregroundColor(.red)
                                .padding(.horizontal, AppTheme.Spacing.small)
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.extraLarge)
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .fill(AppTheme.cardColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                            .stroke(Color.white.opacity(AppTheme.Opacity.border), lineWidth: 1)
                    )
                    .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
                    
                    Button(action: {
                        logger.info("Saving edited block: \(block.name) (\(block.durationInMinutes) min, bell: \(block.blockStartBell.displayName))", category: "EditBlock")
                        onSave(block)
                        dismiss()
                    }) {
                        Text(LocalizedStringKey("button.save"))
                            .font(AppTheme.Typography.buttonFont)
                            .foregroundColor(AppTheme.offWhiteText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(AppTheme.accentColor)
                            )
                    }
                    .padding(.horizontal)
                    Spacer()
                }
            }
            .navigationTitle(LocalizedStringKey("block.edit.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button.cancel")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $block.blockIcon)
            }
            .sheet(isPresented: $showBellPicker) {
                BellPickerView(selected: block.blockStartBell) { selectedBell in
                    block.blockStartBell = selectedBell
                }
            }
            .fileImporter(
                isPresented: $showMusicPicker,
                allowedContentTypes: [.mp3, .mpeg4Audio, .aiff, .wav, .audio],
                allowsMultipleSelection: false
            ) { result in
                musicImportError = nil
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        let (storedFileName, displayName) = try BlockMusicManager.shared.importMusic(from: url)
                        block.musicFileName = storedFileName
                        block.musicDisplayName = displayName
                    } catch {
                        musicImportError = "Could not import file: \(error.localizedDescription)"
                        logger.error("Music import failed: \(error.localizedDescription)", category: "EditBlock")
                    }
                case .failure(let error):
                    musicImportError = "Could not open file: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview("Edit Block View") {
    EditBlockView(
        block: RoutineBlock(
            name: "Breathwork Session",
            durationInMinutes: 8,
            type: .breathwork,
            blockStartBell: .softBell,
            blockIcon: "leaf.fill"
        )
    ) { updatedBlock in
        print("Block updated: \(updatedBlock.name) - \(updatedBlock.durationInMinutes) minutes")
    }
}

#Preview("Edit Block View - Long Name") {
    EditBlockView(
        block: RoutineBlock(
            name: "Very Long Meditation Block Name That Might Wrap",
            durationInMinutes: 15,
            type: .visualization,
            blockStartBell: .tibetanBowl,
            blockIcon: "eye.fill"
        )
    ) { updatedBlock in
        print("Block updated: \(updatedBlock.name) - \(updatedBlock.durationInMinutes) minutes")
    }
}

#Preview("Edit Block View - Short Duration") {
    EditBlockView(
        block: RoutineBlock(
            name: "Quick Focus",
            durationInMinutes: 2,
            type: .silence,
            blockStartBell: .silent,
            blockIcon: "bell.slash.fill"
        )
    ) { updatedBlock in
        print("Block updated: \(updatedBlock.name) - \(updatedBlock.durationInMinutes) minutes")
    }
}
