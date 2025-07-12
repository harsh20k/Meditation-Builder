//
//  MainTabView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: TabSelection = .timer
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content based on selected tab
            Group {
                switch selectedTab {
                case .library:
                    RoutineLibraryView()
                case .music:
                    PlaceholderView(
                        icon: "music.note",
                        title: String(localized: "tab.music"),
                        description: String(localized: "tab.music.description")
                    )
                case .timer:
                    RoutineBuilderView()
                case .tools:
                    PlaceholderView(
                        icon: "hammer",
                        title: String(localized: "tab.tools"),
                        description: String(localized: "tab.tools.description")
                    )
                case .settings:
                    PlaceholderView(
                        icon: "gearshape",
                        title: String(localized: "tab.settings"),
                        description: String(localized: "tab.settings.description")
                    )
                }
            }
            
            // Custom Tab Bar
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard) // Prevent tab bar from moving with keyboard
    }
}

// MARK: - Placeholder View for Unimplemented Tabs
struct PlaceholderView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.section) {
                // Header
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 28, weight: .bold))
                    Text(title)
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                
                Spacer()
                
                // Content
                VStack(spacing: AppTheme.Spacing.extraLarge) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.cardColor)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: icon)
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 60, weight: .bold))
                    }
                    
                    VStack(spacing: AppTheme.Spacing.medium) {
                        Text(LocalizedStringKey("coming.soon"))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(description)
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.lightGrey)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.Spacing.extraLarge)
                    }
                }
                
                Spacer()
                Spacer() // Extra space for tab bar
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
} 