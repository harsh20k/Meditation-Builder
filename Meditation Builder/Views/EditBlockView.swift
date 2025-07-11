//
//  EditBlockView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct EditBlockView: View {
    @State var block: MeditationBlock
    var onSave: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: AppTheme.Spacing.section) {
                    VStack(spacing: AppTheme.Spacing.extraLarge) {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentColor)
                                    .frame(width: 40, height: 40)
                                Image(systemName: block.type.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 22, weight: .bold))
                            }
                            TextField("Name", text: $block.name)
                                .font(AppTheme.Typography.headlineFont)
                                .foregroundColor(.white)
                                .padding(12)
                                .background(AppTheme.cardColor)
                                .cornerRadius(AppTheme.CornerRadius.small)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
                        
                        Stepper(value: $block.durationInMinutes, in: 1...60) {
                            Text("Duration: \(block.durationInMinutes) min")
                                .font(AppTheme.Typography.bodyFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                        .padding(.horizontal, AppTheme.Spacing.small)
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
                        onSave(block)
                        dismiss()
                    }) {
                        Text("Save")
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
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
    }
} 