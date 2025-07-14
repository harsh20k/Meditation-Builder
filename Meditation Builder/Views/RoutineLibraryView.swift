//
//  RoutineLibraryView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData

struct RoutineLibraryView: View {
    @Query(sort: \SavedRoutine.lastModified, order: .reverse) private var savedRoutines: [SavedRoutine]
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: SavedRoutine? = nil
    @State private var playingRoutine: SavedRoutine? = nil
    
    private var dataManager: RoutineDataManager {
        RoutineDataManager(context: modelContext)
    }
    
    var filteredRoutines: [SavedRoutine] {
        if searchText.isEmpty {
            return savedRoutines
        }
        return savedRoutines.filter { routine in
            routine.routineName.localizedCaseInsensitiveContains(searchText) ||
            routine.getRoutine().blocks.contains { block in
                block.name.localizedCaseInsensitiveContains(searchText) ||
                block.type.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 28, weight: .bold))
                    Text(LocalizedStringKey("routine.library.title"))
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.small)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 16, weight: .medium))
                    
                    TextField(LocalizedStringKey("search.routines.placeholder"), text: $searchText)
                        .foregroundColor(.white)
                        .font(AppTheme.Typography.bodyFont)
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.cardColor)
                .cornerRadius(AppTheme.CornerRadius.large)
                .padding(.horizontal)
                .padding(.bottom, AppTheme.Spacing.large)
                
                // Routines List
                if filteredRoutines.isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppTheme.Spacing.large) {
                            ForEach(filteredRoutines) { routine in
                                RoutineCard(
                                    routine: routine,
                                    onPlay: { 
                                        playingRoutine = routine
                                        recordPlay(for: routine)
                                    },
                                    onEdit: { editingRoutine = routine }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 120) // Account for floating button and tab bar
                    }
                }
                
                Spacer()
            }
            
            // Floating Create Button
            Button(action: { showingRoutineBuilder = true }) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }
            }
            .padding(.trailing, AppTheme.Spacing.extraLarge)
            .padding(.bottom, 112)
            .shadow(radius: 8)
        }
        .sheet(isPresented: $showingRoutineBuilder) {
            RoutineBuilderView()
        }
        .sheet(item: $editingRoutine) { routine in
            RoutineBuilderView(editingRoutine: routine)
        }
        .sheet(item: $playingRoutine) { routine in
            RoutinePlayerView(routine: routine)
        }
    }
    
    // MARK: - Private Methods
    
    private func recordPlay(for routine: SavedRoutine) {
        Task {
            do {
                try await dataManager.recordPlay(for: routine)
            } catch {
                print("Failed to record play: \(error)")
            }
        }
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: SavedRoutine
    var onPlay: () -> Void
    var onEdit: () -> Void
    
    private var totalDuration: Int {
        routine.getRoutine().blocks.map(\.durationInMinutes).reduce(0, +)
    }
    
    private var blocksSummary: String {
        let blockTypes = routine.getRoutine().blocks.map(\.type.displayName)
        if blockTypes.count <= 3 {
            return blockTypes.joined(separator: " • ")
        } else {
            return blockTypes.prefix(2).joined(separator: " • ") + " • " + String.localizedStringWithFormat(
                String(localized: "routine.more.blocks.format"),
                blockTypes.count - 2
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header with custom icon and name
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: routine.routineIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppTheme.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.routineName)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text(String.localizedStringWithFormat(
                        String(localized: "routine.duration.format"),
                        totalDuration
                    ))
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                }
                
                Spacer()
            }
            
            // Blocks summary
            Text(blocksSummary)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundColor(AppTheme.lightGrey)
                .lineLimit(2)
            
            // Action buttons
            HStack(spacing: AppTheme.Spacing.medium) {
                // Play button
                Button(action: onPlay) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("Play")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentColor)
                    )
                }
                
                // Edit button
                Button(action: onEdit) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .medium))
                        Text("Edit")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(AppTheme.lightGrey)
                    .padding(.horizontal, AppTheme.Spacing.large)
                    .padding(.vertical, AppTheme.Spacing.small)
                    .background(
                        Capsule()
                            .fill(AppTheme.cardColor.opacity(0.8))
                    )
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .fill(AppTheme.cardColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                .stroke(Color.white.opacity(AppTheme.Opacity.border), lineWidth: 1)
        )
        .shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(AppTheme.cardColor)
                    .frame(width: 80, height: 80)
                
                if searchText.isEmpty {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 40, weight: .bold))
                } else {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.lightGrey)
                        .font(.system(size: 32, weight: .medium))
                }
            }
            
            VStack(spacing: AppTheme.Spacing.small) {
                Text(LocalizedStringKey(searchText.isEmpty ? "empty.no.routines" : "empty.no.results"))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(LocalizedStringKey(searchText.isEmpty 
                     ? "empty.create.first.routine"
                     : "empty.adjust.search.terms"))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.lightGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.extraLarge)
            }
            
            Spacer()
        }
    }
}

// MARK: - Placeholder Routine Player View
struct RoutinePlayerView: View {
    let routine: SavedRoutine
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.section) {
                    Text("🧘‍♀️")
                        .font(.system(size: 80))
                    
                    Text(String.localizedStringWithFormat(
                        String(localized: "player.playing.format"),
                        routine.routineName
                    ))
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(LocalizedStringKey("player.coming.soon"))
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle(LocalizedStringKey("player.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button.done")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Routine Library") {
    RoutineLibraryView()
}

#Preview("Empty State") {
    struct EmptyLibraryView: View {
        @State private var savedRoutines: [SavedRoutine] = []
        @State private var searchText = ""
        @State private var showingRoutineBuilder = false
        @State private var editingRoutine: SavedRoutine? = nil
        @State private var playingRoutine: SavedRoutine? = nil
        @State private var selectedTab: TabSelection = .library
        
        var body: some View {
            ZStack(alignment: .bottomTrailing) {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "books.vertical.fill")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 28, weight: .bold))
                        Text(LocalizedStringKey("routine.library.title"))
                            .font(AppTheme.Typography.titleFont)
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.extraLarge)
                    .padding(.bottom, AppTheme.Spacing.small)
                    
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 16, weight: .medium))
                        
                        TextField(LocalizedStringKey("search.routines.placeholder"), text: $searchText)
                            .foregroundColor(.white)
                            .font(AppTheme.Typography.bodyFont)
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(AppTheme.cardColor)
                    .cornerRadius(AppTheme.CornerRadius.large)
                    .padding(.horizontal)
                    .padding(.bottom, AppTheme.Spacing.large)
                    
                    EmptyStateView(searchText: searchText)
                    
                    Spacer()
                }
                
                // Floating Create Button
                Button(action: { showingRoutineBuilder = true }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentColor)
                            .frame(width: 56, height: 56)
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold))
                    }
                }
                .padding(.trailing, AppTheme.Spacing.extraLarge)
                .padding(.bottom, 112)
                .shadow(radius: 8)
                
                // Tab Bar
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: $selectedTab)
                }
            }
        }
    }
    
    return EmptyLibraryView()
}

#Preview("Single Routine Card") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        let sampleRoutine = SavedRoutine(
            routine: Routine(
                name: "Morning Meditation",
                icon: "sun.max.fill",
                blocks: [
                    RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                    RoutineBlock(name: "Breathwork", durationInMinutes: 10, type: .breathwork, blockStartBell: .softBell),
                    RoutineBlock(name: "Visualization", durationInMinutes: 8, type: .visualization, blockStartBell: .tibetanBowl),
                    RoutineBlock(name: "Body Scan", durationInMinutes: 12, type: .bodyScan, blockStartBell: .digitalChime)
                ],
                openingBell: .softBell,
                closingBell: .tibetanBowl
            )
        )
        sampleRoutine.playCount = 15
        sampleRoutine.lastPlayed = Date().addingTimeInterval(-900) // 15 minutes ago
        
        return RoutineCard(
            routine: sampleRoutine,
            onPlay: {},
            onEdit: {}
        )
        .padding()
    }
} 