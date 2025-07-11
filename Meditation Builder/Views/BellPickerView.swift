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
    let bells = ["None", "Soft Bell", "Tibetan Bowl", "Digital Chime"]
    
    var bellIcon: (String) -> String = { name in
        switch name {
        case "None": return "bell.slash.fill"
        case "Soft Bell": return "bell.fill"
        case "Tibetan Bowl": return "circle.grid.cross"
        case "Digital Chime": return "waveform"
        default: return "bell"
        }
    }
    
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
                            ForEach(bells, id: \.self) { name in
                                HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accentColor)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: bellIcon(name))
                                            .foregroundColor(.white)
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    if selected?.soundName == name || (selected == nil && name == "None") {
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
                                    onSelect(name == "None" ? nil : TransitionBell(soundName: name))
                                    dismiss()
                                }
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.extraLarge)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Select Bell")
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