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
    @State private var tabHapticTrigger = 0
    @State private var showCreateRoutine = false
    @Environment(AuthManager.self) private var authManager
    @Environment(\.modelContext) private var modelContext
    @State private var libraryPath = NavigationPath()
    @State private var legacyNavigationPath = NavigationPath()

    @State private var routineToEdit: SavedRoutine?
    @State private var routineToDelete: SavedRoutine?
    @State private var routineToPlay: SavedRoutine?
    @State private var showDeleteAlert = false

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                nativeTabView
            } else {
                legacyTabView
            }
        }
        .sheet(item: $routineToEdit) { routine in
            RoutineBuilderView(editingRoutine: routine, isModal: true)
        }
        .fullScreenCover(isPresented: $showCreateRoutine) {
            RoutineBuilderView(isModal: true)
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
            if newTab == .create {
                openCreateRitual()
                return
            }
            tabHapticTrigger += 1
            logger.info("Tab changed to: \(newTab)", category: "Navigation")
        }
    }

    // MARK: - iOS 26 Native Liquid Glass TabView

    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabSelection.library) {
                libraryNavigationStack(path: $libraryPath)
            } label: {
                Label(LocalizedStringKey("tab.library"), systemImage: "books.vertical.fill")
            }

            Tab(value: TabSelection.community) {
                CommunityHomeView()
            } label: {
                Label(LocalizedStringKey("tab.community"), systemImage: "person.3.fill")
            }

            Tab(value: TabSelection.timer) {
                RoutinePlayerView(modelContext: modelContext, showsCloseButton: false)
            } label: {
                Label(LocalizedStringKey("tab.timer"), systemImage: "timer")
            }

            Tab(value: TabSelection.settings) {
                SettingsView()
            } label: {
                Label(LocalizedStringKey("tab.settings"), systemImage: "gearshape")
            }

            Tab(value: TabSelection.create, role: .search) {
                Color.clear
                    .accessibilityHidden(true)
            } label: {
                Label(LocalizedStringKey("tab.create"), systemImage: "plus")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sensoryFeedback(.selection, trigger: tabHapticTrigger)
    }

    // MARK: - Legacy Custom Tab Bar (iOS 18)

    private var legacyTabView: some View {
        NavigationStack(path: $legacyNavigationPath) {
            Group {
                switch selectedTab {
                case .library, .create:
                    RoutineLibraryView(navigationPath: $legacyNavigationPath)
                case .community:
                    CommunityHomeView()
                case .timer:
                    RoutinePlayerView(modelContext: modelContext, showsCloseButton: false)
                case .settings:
                    SettingsView()
                }
            }
            .animation(.easeInOut(duration: 0.18), value: selectedTab)
            .navigationDestination(for: SavedRoutine.self) { routine in
                ritualDestination(routine, path: $legacyNavigationPath)
            }
        }
        .liquidGlassNavigationBar()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(
                selectedTab: $selectedTab,
                onTabTap: { tappedTab in
                    handleLegacyTabTap(tappedTab)
                },
                onCreateTap: openCreateRitual
            )
        }
    }

    // MARK: - Shared Library Navigation

    private func libraryNavigationStack(path: Binding<NavigationPath>) -> some View {
        NavigationStack(path: path) {
            RoutineLibraryView(navigationPath: path)
                .navigationDestination(for: SavedRoutine.self) { routine in
                    ritualDestination(routine, path: path)
                }
        }
        .liquidGlassNavigationBar()
    }

    private func ritualDestination(_ routine: SavedRoutine, path: Binding<NavigationPath>) -> some View {
        RitualPageView(
            routine: routine,
            onEdit: { r in
                path.wrappedValue.removeLast()
                routineToEdit = r
            },
            onDelete: { r in
                path.wrappedValue.removeLast()
                routineToDelete = r
                showDeleteAlert = true
            },
            onPlay: { r in
                path.wrappedValue.removeLast()
                routineToPlay = r
            }
        )
    }

    private func openCreateRitual() {
        tabHapticTrigger += 1
        selectedTab = .library
        showCreateRoutine = true
    }

    private func handleLegacyTabTap(_ tappedTab: TabSelection) {
        if tappedTab == selectedTab {
            logger.info("Same tab tapped, popping to root: \(tappedTab)", category: "Navigation")
            withAnimation(.easeInOut(duration: 0.3)) {
                legacyNavigationPath = NavigationPath()
            }
        } else {
            logger.info("Different tab tapped, switching to: \(tappedTab)", category: "Navigation")
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedTab = tappedTab
                legacyNavigationPath = NavigationPath()
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
                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environment(AuthManager())
}
