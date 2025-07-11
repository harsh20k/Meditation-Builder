//
//  RoutineLibraryView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct RoutineLibraryView: View {
    @State private var savedRoutines: [SavedRoutine] = [
        SavedRoutine(
            id: UUID(),
            name: "Morning Meditation",
            routine: Routine(
                blocks: [
                    MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 5, type: .silence),
                    MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 10, type: .breathwork),
                    MeditationBlock(id: UUID(), name: "Visualization", durationInMinutes: 8, type: .visualization)
                ],
                transitionBells: [TransitionBell(soundName: "Soft Bell"), TransitionBell(soundName: "Tibetan Bowl")]
            ),
            createdAt: Date(),
            lastModified: Date()
        ),
        SavedRoutine(
            id: UUID(),
            name: "Evening Wind Down",
            routine: Routine(
                blocks: [
                    MeditationBlock(id: UUID(), name: "Body Scan", durationInMinutes: 15, type: .bodyScan),
                    MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 10, type: .silence)
                ],
                transitionBells: [TransitionBell(soundName: "Soft Bell")]
            ),
            createdAt: Date().addingTimeInterval(-86400),
            lastModified: Date().addingTimeInterval(-3600)
        ),
        SavedRoutine(
            id: UUID(),
            name: "Quick Focus",
            routine: Routine(
                blocks: [
                    MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 3, type: .breathwork),
                    MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 2, type: .silence)
                ],
                transitionBells: [TransitionBell(soundName: "Digital Chime")]
            ),
            createdAt: Date().addingTimeInterval(-172800),
            lastModified: Date().addingTimeInterval(-7200)
        )
    ]
    
    @State private var searchText = ""
    @State private var showingRoutineBuilder = false
    @State private var editingRoutine: SavedRoutine? = nil
    @State private var playingRoutine: SavedRoutine? = nil
    
    var filteredRoutines: [SavedRoutine] {
        if searchText.isEmpty {
            return savedRoutines.sorted { $0.lastModified > $1.lastModified }
        }
        return savedRoutines.filter { routine in
            routine.name.localizedCaseInsensitiveContains(searchText) ||
            routine.routine.blocks.contains { block in
                block.name.localizedCaseInsensitiveContains(searchText) ||
                block.type.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }.sorted { $0.lastModified > $1.lastModified }
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
                    Text("Routine Library")
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
                    
                    TextField("Search routines...", text: $searchText)
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
                                    onPlay: { playingRoutine = routine },
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
            // TODO: Pass the routine to edit to RoutineBuilderView
            RoutineBuilderView()
        }
        .sheet(item: $playingRoutine) { routine in
            RoutinePlayerView(routine: routine)
        }
    }
}

// MARK: - Routine Card
struct RoutineCard: View {
    let routine: SavedRoutine
    var onPlay: () -> Void
    var onEdit: () -> Void
    
    private var totalDuration: Int {
        routine.routine.blocks.map(\.durationInMinutes).reduce(0, +)
    }
    
    private var blocksSummary: String {
        let blockTypes = routine.routine.blocks.map(\.type.rawValue)
        if blockTypes.count <= 3 {
            return blockTypes.joined(separator: " • ")
        } else {
            return blockTypes.prefix(2).joined(separator: " • ") + " • +\(blockTypes.count - 2) more"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            // Header with lotus icon and name
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Text("🪷")
                        .font(.system(size: 24))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    Text("⏱ Duration: \(totalDuration) min")
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
                Text(searchText.isEmpty ? "No Routines Yet" : "No Results Found")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(searchText.isEmpty 
                     ? "Create your first meditation routine to get started"
                     : "Try adjusting your search terms")
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
                    
                    Text("Playing: \(routine.name)")
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Player functionality coming soon...")
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
            .navigationTitle("Routine Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
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
                        Text("Routine Library")
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
                        
                        TextField("Search routines...", text: $searchText)
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
        
        RoutineCard(
            routine: SavedRoutine(
                name: "Morning Meditation",
                routine: Routine(
                    blocks: [
                        MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 5, type: .silence),
                        MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 10, type: .breathwork),
                        MeditationBlock(id: UUID(), name: "Visualization", durationInMinutes: 8, type: .visualization),
                        MeditationBlock(id: UUID(), name: "Body Scan", durationInMinutes: 12, type: .bodyScan)
                    ],
                    transitionBells: [
                        TransitionBell(soundName: "Soft Bell"),
                        TransitionBell(soundName: "Tibetan Bowl"),
                        TransitionBell(soundName: "Digital Chime")
                    ]
                )
            ),
            onPlay: {},
            onEdit: {}
        )
        .padding()
    }
} 