//
//  MainTabView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import os.log

// MARK: - Navigation Destination Types
enum RoutineBuilderDestination: Hashable {
    case create
    case edit(SavedRoutine)
}

struct MainTabView: View {
    @State private var selectedTab: TabSelection = .library
    @Environment(\.modelContext) private var modelContext
    @State private var navigationPath = NavigationPath()

    // State driving sheets/covers from navigation callbacks
    @State private var routineToEdit: SavedRoutine?
    @State private var routineToDelete: SavedRoutine?
    @State private var routineToPlay: SavedRoutine?
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                switch selectedTab {
                case .library:
                    RoutineLibraryView(navigationPath: $navigationPath)
                case .music:
                    AmbientSoundMixerView()
                case .timer:
                    RoutinePlayerView(modelContext: modelContext)
                case .history:
                    SessionHistoryView()
                case .settings:
                    SettingsView()
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
            .navigationDestination(for: SavedRoutine.self) { routine in
                RitualPageView(
                    routine: routine,
                    onEdit: { r in
                        navigationPath.removeLast()
                        routineToEdit = r
                    },
                    onDelete: { r in
                        navigationPath.removeLast()
                        routineToDelete = r
                        showDeleteAlert = true
                    },
                    onPlay: { r in
                        navigationPath.removeLast()
                        routineToPlay = r
                    }
                )
            }
            .navigationDestination(for: RoutineBuilderDestination.self) { destination in
                switch destination {
                case .create:
                    RoutineBuilderView()
                case .edit(let routine):
                    RoutineBuilderView(editingRoutine: routine)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(
                selectedTab: $selectedTab,
                onTabTap: { tappedTab in
                    handleTabTap(tappedTab)
                }
            )
        }
        .sheet(item: $routineToEdit) { routine in
            RoutineBuilderView(editingRoutine: routine)
        }
        .fullScreenCover(item: $routineToPlay) { routine in
            RoutinePlayerView(routine: routine, modelContext: modelContext)
        }
        .confirmationDialog(
            "Delete Routine",
            isPresented: $showDeleteAlert,
            presenting: routineToDelete
        ) { routine in
            Button("Delete \"\(routine.routineName)\"", role: .destructive) {
                try? RoutineDataManager.shared.deleteRoutine(routine)
                routineToDelete = nil
            }
            Button("Cancel", role: .cancel) {
                routineToDelete = nil
            }
        } message: { routine in
            Text("This will delete \"\(routine.routineName)\". Session history will be preserved.")
        }
        .ignoresSafeArea(.keyboard)
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
                        .foregroundColor(AppTheme.offWhiteText)
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
                            .font(AppTheme.Typography.headlineFontLarge)
                            .foregroundColor(AppTheme.offWhiteText)
                        
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
