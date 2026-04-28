//
//  CardButtonDemoView.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import SwiftUI

struct CardButtonDemoView: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header Section
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Text("280,982")
                            .font(.system(size: 48, weight: .light, design: .serif))
                            .foregroundColor(AppTheme.offWhiteText)
                        
                        Text("free guided meditations and music tracks")
                            .font(AppTheme.Typography.captionFont)
                            .foregroundColor(AppTheme.lightGrey)
                            .multilineTextAlignment(.center)
                        
                        Button("Why we're free.") {
                            // Action here
                        }
                        .foregroundColor(AppTheme.accentColor)
                        .font(AppTheme.Typography.bodyFont)
                    }
                    .padding(.top, AppTheme.Spacing.extraLarge)
                    
                    // Card Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: AppTheme.Spacing.cardGrid),
//                        GridItem(.flexible(), spacing: AppTheme.Spacing.cardGrid),
						GridItem(.flexible(), spacing: AppTheme.Spacing.cardGrid),
                        GridItem(.flexible(), spacing: AppTheme.Spacing.cardGrid)
                    ], spacing: AppTheme.Spacing.cardGrid) {
                        
                        // First Row
                        AppTheme.cardButton(
                            icon: "headphones",
                            title: "Meditate",
                            action: { print("Meditate tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "moon",
                            title: "Sleep",
                            action: { print("Sleep tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "sun.max",
                            title: "Mornings",
                            action: { print("Mornings tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "leaf",
                            title: "Breathe",
                            action: { print("Breathe tapped") }
                        )
                        
                        // Second Row
                        AppTheme.cardButton(
                            icon: "drop",
                            title: "Beginners",
                            action: { print("Beginners tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "music.note",
                            title: "Music",
                            action: { print("Music tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "book",
                            title: "Courses",
                            action: { print("Courses tapped") }
                        )
                        
                        AppTheme.cardButton(
                            icon: "ribbon",
                            title: "Challenges",
                            action: { print("Challenges tapped") }
                        )
                    }
					.padding(.horizontal, AppTheme.Spacing.section)
                }
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
        .navigationTitle("Card Buttons Demo")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CardButtonDemoView()
    }
} 
