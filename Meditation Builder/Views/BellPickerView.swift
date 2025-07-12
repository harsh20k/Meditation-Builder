//
//  BellPickerView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct BellPickerView: View {
    @State var selected: TransitionBell?
    var onSelect: (TransitionBell?) -> Void
    @Environment(\.dismiss) var dismiss
    let bells = BellSound.allCases
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        if bells.count > 1 {
                            GeometryReader { geo in
                                let blockHeight: CGFloat = 76
                                let spacing: CGFloat = 20
                                let totalHeight = CGFloat(bells.count) * blockHeight + CGFloat(bells.count - 1) * spacing
                                Rectangle()
                                    .fill(AppTheme.lightGrey.opacity(AppTheme.Opacity.timeline))
                                    .frame(width: 2, height: totalHeight - blockHeight/2)
                                    .offset(x: 54, y: blockHeight/2)
                            }
                        }
                        VStack(spacing: AppTheme.Spacing.large) {
                            ForEach(bells, id: \.self) { bellSound in
                                HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accentColor)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: bellSound.icon)
                                            .foregroundColor(.white)
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(bellSound.titleKey)
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    if selected?.soundName == bellSound.displayName || (selected == nil && bellSound == .silent) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(AppTheme.accentColor)
                                            .font(.system(size: 24, weight: .bold))
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
                                .onTapGesture {
                                    onSelect(bellSound == .silent ? nil : TransitionBell(soundName: bellSound.displayName))
                                    dismiss()
                                }
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.extraLarge)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("bell.picker.title"))
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