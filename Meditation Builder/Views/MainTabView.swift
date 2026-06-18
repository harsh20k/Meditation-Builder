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

    // MARK: - iOS 26 Native Liquid Glass TabView

    @available(iOS 26.0, *)
    private var nativeTabView: some View {
        TabView(selection: $selectedTab) {
            Tab(value: TabSelection.library) {
                libraryNavigationStack(path: $libraryPath)
            } label: {
                Label(LocalizedStringKey("tab.library"), systemImage: "books.vertical.fill")
            }

            Tab(value: TabSelection.music) {
                AmbientSoundMixerView()
            } label: {
                Label(LocalizedStringKey("tab.sounds"), systemImage: "waveform")
            }

            Tab(value: TabSelection.timer) {
                RoutinePlayerView(modelContext: modelContext)
            } label: {
                Label(LocalizedStringKey("tab.timer"), systemImage: "timer")
            }

            Tab(value: TabSelection.history) {
                SessionHistoryView()
            } label: {
                Label(LocalizedStringKey("tab.history"), systemImage: "clock.arrow.circlepath")
            }

            Tab(value: TabSelection.settings) {
                SettingsView()
            } label: {
                Label(LocalizedStringKey("tab.settings"), systemImage: "gearshape")
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .overlay(alignment: .bottomTrailing) {
            if selectedTab == .library && libraryPath.isEmpty {
                createRitualButton
            }
        }
    }

    // MARK: - Legacy Custom Tab Bar (iOS 18)

    private var legacyTabView: some View {
        NavigationStack(path: $legacyNavigationPath) {
            Group {
                switch selectedTab {
                case .library:
                    RoutineLibraryView(navigationPath: $legacyNavigationPath)
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
                ritualDestination(routine, path: $legacyNavigationPath)
            }
            .navigationDestination(for: RoutineBuilderDestination.self) { destination in
                routineBuilderDestination(destination)
            }
        }
        .liquidGlassNavigationBar()
        .safeAreaInset(edge: .bottom, spacing: 0) {
            CustomTabBar(
                selectedTab: $selectedTab,
                onTabTap: { tappedTab in
                    handleLegacyTabTap(tappedTab)
                }
            )
        }
        .overlay(alignment: .bottomTrailing) {
            if selectedTab == .library && legacyNavigationPath.isEmpty {
                createRitualButton
            }
        }
    }

    // MARK: - Shared Library Navigation

    private func libraryNavigationStack(path: Binding<NavigationPath>) -> some View {
        NavigationStack(path: path) {
            RoutineLibraryView(navigationPath: path)
                .navigationDestination(for: SavedRoutine.self) { routine in
                    ritualDestination(routine, path: path)
                }
                .navigationDestination(for: RoutineBuilderDestination.self) { destination in
                    routineBuilderDestination(destination)
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

    @ViewBuilder
    private func routineBuilderDestination(_ destination: RoutineBuilderDestination) -> some View {
        switch destination {
        case .create:
            RoutineBuilderView()
        case .edit(let routine):
            RoutineBuilderView(editingRoutine: routine)
        }
    }

    private var createRitualButton: some View {
        AppTheme.floatingActionButton(
            icon: "plus",
            action: {
                if #available(iOS 26.0, *) {
                    libraryPath.append(RoutineBuilderDestination.create)
                } else {
                    legacyNavigationPath.append(RoutineBuilderDestination.create)
                }
            }
        )
        .accessibilityLabel("Create new ritual")
        .padding(.trailing, AppTheme.Spacing.extraLarge)
        .padding(.bottom, AppTheme.Spacing.fabTabBarClearance)
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
}
