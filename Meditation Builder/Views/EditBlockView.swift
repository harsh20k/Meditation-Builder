//
//  EditBlockView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import os.log

struct EditBlockView: View {
    @State var block: RoutineBlock
    @State private var showIconPicker = false
    @State private var showBellPicker = false
    var onSave: (RoutineBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.section) {
                    VStack(spacing: AppTheme.Spacing.extraLarge) {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            Button(action: { showIconPicker = true }) {
                                ZStack {
                                    Circle()
                                        .fill(AppTheme.accentColor)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: block.blockIcon)
                                        .foregroundColor(.white)
                                        .font(.system(size: 22, weight: .bold))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            TextField(LocalizedStringKey("block.name.placeholder"), text: $block.name)
                                .font(AppTheme.Typography.headlineFont)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(AppTheme.cardColor)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        
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
                            .foregroundColor(.white)
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
        }
    }
} 