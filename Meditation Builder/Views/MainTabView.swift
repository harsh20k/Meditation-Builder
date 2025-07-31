//
//  MainTabView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import os.log

struct MainTabView: View {
    @State private var selectedTab: TabSelection = .library
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area with NavigationStack
            NavigationStack(path: $navigationPath) {
                // Content based on selected tab
                Group {
                    switch selectedTab {
                    case .library:
                        RoutineLibraryView(navigationPath: $navigationPath)
                    case .music:
//                        PlaceholderView(
//                            icon: "music.note",
//                            title: String(localized: "tab.music"),
//                            description: String(localized: "tab.music.description")
//                        )
//                        AudioTestView()
                        MeditationAnimationPlayground()
                    case .timer:
                        RoutinePlayerView(modelContext: modelContext)
                    case .history:
                        SessionHistoryView()
                    case .settings:
                        LoggingSettingsView()
                    }
                }
                .navigationDestination(for: SavedRoutine.self) { routine in
                    RitualPageView(
                        routine: routine,
                        onEdit: { routine in
                            // Navigate back and show edit sheet
                            navigationPath.removeLast()
                            // Note: We'll need to handle edit state differently
                        },
                        onDelete: { routine in
                            // Navigate back and show delete alert
                            navigationPath.removeLast()
                            // Note: We'll need to handle delete state differently
                        },
                        onPlay: { routine in
                            // Navigate back and start playing
                            navigationPath.removeLast()
                            // Note: We'll need to handle play state differently
                        }
                    )
                }
            }
            .ignoresSafeArea(.keyboard) // Prevent tab bar from moving with keyboard
            
            // Global Custom Tab Bar - always visible
            VStack {
                Spacer()
                CustomTabBar(
                    selectedTab: $selectedTab,
                    onTabTap: { tappedTab in
                        handleTabTap(tappedTab)
                    }
                )
            }
        }
        .onAppear {
            logger.info("MainTabView appeared", category: "Navigation")
        }
        .onChange(of: selectedTab) { _, newTab in
            logger.info("Tab changed to: \(newTab)", category: "Navigation")
        }
    }
    
    // MARK: - Tab Navigation Logic
    
    private func handleTabTap(_ tappedTab: TabSelection) {
        if tappedTab == selectedTab {
            // Same tab tapped - pop to root (native iOS behavior)
            logger.info("Same tab tapped, popping to root: \(tappedTab)", category: "Navigation")
            withAnimation(.easeInOut(duration: 0.3)) {
                navigationPath = NavigationPath()
            }
        } else {
            // Different tab tapped - switch tabs and reset navigation
            logger.info("Different tab tapped, switching to: \(tappedTab)", category: "Navigation")
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tappedTab
                navigationPath = NavigationPath()
            }
        }
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
