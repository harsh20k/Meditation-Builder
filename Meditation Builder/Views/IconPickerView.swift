//
//  IconPickerView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) var dismiss
    
    // Categories of icons for routines
    private let iconCategories: [IconCategory] = [
        IconCategory(
            name: "Nature",
            icons: [
                "sun.max.fill",
                "moon.fill",
                "leaf.fill",
                "flame.fill",
                "drop.fill",
                "snow",
                "cloud.fill",
                "star.fill",
                "sunset.fill",
                "sunrise.fill"
            ]
        ),
        IconCategory(
            name: "Meditation",
            icons: [
                "figure.mind.and.body",
                "figure.seated.side",
                "figure.yoga",
                "heart.fill",
                "brain.head.profile",
                "lungs.fill",
                "eye.fill",
                "hands.sparkles.fill",
                "sparkles",
                "om.symbol"
            ]
        ),
        IconCategory(
            name: "Time & Focus",
            icons: [
                "clock.fill",
                "timer",
                "hourglass",
                "target",
                "scope",
                "circle.fill",
                "diamond.fill",
                "hexagon.fill",
                "triangle.fill",
                "square.fill"
            ]
        ),
        IconCategory(
            name: "Spiritual",
            icons: [
                "lotus",
                "infinity",
                "cross.fill",
                "moon.stars.fill",
                "peacesign",
                "yin.yang",
                "location.north.fill",
                "mountain.2.fill",
                "tree.fill",
                "aqi.medium"
            ]
        )
    ]
    
    @State private var selectedCategory = 0
    
    var body: some View {
        VStack(spacing: 0) {
            LiquidGlassSheetHeader(title: LocalizedStringKey("icon.picker.title"), onClose: { dismiss() })

            Picker("Category", selection: $selectedCategory) {
                ForEach(iconCategories.indices, id: \.self) { index in
                    Text(iconCategories[index].name)
                        .tag(index)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .padding(.bottom, AppTheme.Spacing.medium)

            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.medium), count: 5), spacing: AppTheme.Spacing.medium) {
                    ForEach(iconCategories[selectedCategory].icons, id: \.self) { iconName in
                        IconButton(
                            iconName: iconName,
                            isSelected: selectedIcon == iconName,
                            onTap: {
                                selectedIcon = iconName
                                dismiss()
                            }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
        .background(AppTheme.backgroundColor)
    }
}

// MARK: - Icon Category
struct IconCategory {
    let name: String
    let icons: [String]
}

// MARK: - Icon Button
struct IconButton: View {
    let iconName: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? AppTheme.accentColor : AppTheme.cardColor)
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppTheme.lightGrey)
            }
            .overlay(
                Circle()
                    .stroke(isSelected ? AppTheme.accentColor : Color.white.opacity(0.2), lineWidth: 2)
            )
            .shadow(color: isSelected ? AppTheme.accentColor.opacity(0.3) : AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    IconPickerView(selectedIcon: .constant("sun.max.fill"))
        .liquidGlassSheet(size: .compact)
}
