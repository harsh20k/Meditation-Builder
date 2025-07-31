//
//  RitualPageView.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import SwiftUI
import SwiftData
import os.log

// MARK: - Ritual Page View Model
@MainActor
class RitualPageViewModel: ObservableObject {
    @Published var routine: SavedRoutine
    @Published var isLoading = false
    @Published var showingEditSheet = false
    @Published var showingDeleteAlert = false
    @Published var showingPlaySheet = false
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.meditationbuilder", category: "RitualPage")
    
    init(routine: SavedRoutine) {
        self.routine = routine
        logger.info("RitualPageViewModel initialized for routine: \(routine.routineName)")
    }
    
    var routineData: Routine {
        routine.getRoutine()
    }
    
    var totalDuration: Int {
        routineData.blocks.map(\.durationInMinutes).reduce(0, +)
    }
    
    var blockCount: Int {
        routineData.blocks.count
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: routine.createdAt)
    }
    
    var formattedLastModified: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: routine.lastModified)
    }
    
    var formattedLastPlayed: String? {
        guard let lastPlayed = routine.lastPlayed else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastPlayed)
    }
    
    func editRoutine() {
		logger.info("Edit routine requested: \(self.routine.routineName)")
        showingEditSheet = true
    }
    
    func deleteRoutine() {
		logger.info("Delete routine requested: \(self.routine.routineName)")
        showingDeleteAlert = true
    }
    
    func confirmDeleteRoutine() {
		logger.info("Confirming deletion of routine: \(self.routine.routineName)")
        // This will be handled by the parent view
    }
    
    func playRoutine() {
        logger.info("Play routine requested: \(self.routine.routineName)")
        showingPlaySheet = true
    }
    
    func toggleFavorite() {
        logger.info("Toggle favorite requested for routine: \(self.routine.routineName)")
        
        // Optimistically update the UI immediately
        withAnimation(.easeInOut(duration: 0.2)) {
            routine.isFavorite.toggle()
        }
        
        do {
            if routine.isFavorite {
                try RoutineDataManager.shared.setRoutineFavorite(routine)
            } else {
                try RoutineDataManager.shared.unsetRoutineFavorite(routine)
            }
        } catch {
            logger.error("Failed to toggle favorite status: \(error.localizedDescription)")
            // Revert the optimistic update if the operation failed
            withAnimation(.easeInOut(duration: 0.2)) {
                routine.isFavorite.toggle()
            }
        }
    }
}

// MARK: - Ritual Page View
struct RitualPageView: View {
    	@StateObject private var viewModel: RitualPageViewModel
	@Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    
    let onEdit: (SavedRoutine) -> Void
    let onDelete: (SavedRoutine) -> Void
    let onPlay: (SavedRoutine) -> Void
    
    init(routine: SavedRoutine, onEdit: @escaping (SavedRoutine) -> Void, onDelete: @escaping (SavedRoutine) -> Void, onPlay: @escaping (SavedRoutine) -> Void) {
        self._viewModel = StateObject(wrappedValue: RitualPageViewModel(routine: routine))
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onPlay = onPlay
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.medium) {
                    // Header Section
                    headerSection
                    
                    // Action Buttons
                    actionButtonsSection
					
					// Blocks Section
					blocksSection
				
                    // Statistics Section (Scrollable)
                    statisticsSectionScrollable
                    
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $viewModel.showingEditSheet) {
            RoutineBuilderView(editingRoutine: viewModel.routine)
        }
        .fullScreenCover(isPresented: $viewModel.showingPlaySheet) {
            RoutinePlayerView(routine: viewModel.routine, modelContext: modelContext)
        }
        .alert(LocalizedStringKey("alert.delete.routine.title"), isPresented: $viewModel.showingDeleteAlert) {
            Button(LocalizedStringKey("button.cancel"), role: .cancel) { }
            			Button(LocalizedStringKey("button.delete"), role: .destructive) {
				onDelete(viewModel.routine)
			}
        } message: {
            Text(String.localizedStringWithFormat(
                NSLocalizedString("alert.delete.routine.message", comment: "Delete routine confirmation"),
                viewModel.routine.routineName
            ))
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            // Icon and Title
            VStack(alignment: .center, spacing: AppTheme.Spacing.small) {
                Text(viewModel.routine.routineName)
                    .font(AppTheme.Typography.titleFont)
                    .foregroundColor(AppTheme.offWhiteText)
                    .lineLimit(2)
                
                Text(String.localizedStringWithFormat(
                    String(localized: "routine.duration.format.simplified"),
                    viewModel.totalDuration
                ))
                .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
            }
            .padding(AppTheme.Spacing.section)
        }
    }
    
    // MARK: - Statistics Section
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("ritual.statistics.title"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
				StatRitualPageCard(
                    title: LocalizedStringKey("ritual.statistics.blocks"),
                    value: "\(viewModel.blockCount)",
                    icon: "list.bullet"
                )
                
				StatRitualPageCard(
                    title: LocalizedStringKey("ritual.statistics.playCount"),
                    value: "\(viewModel.routine.playCount)",
                    icon: "play.circle"
                )
                
				StatRitualPageCard(
                    title: LocalizedStringKey("ritual.statistics.created"),
                    value: viewModel.formattedCreatedDate,
                    icon: "calendar"
                )
                
				StatRitualPageCard(
                    title: LocalizedStringKey("ritual.statistics.modified"),
                    value: viewModel.formattedLastModified,
                    icon: "clock"
                )
            }
        }
    }
    
    // MARK: - Statistics Section (Scrollable)
    private var statisticsSectionScrollable: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("ritual.statistics.title"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    StatRitualPageCard(
                        title: LocalizedStringKey("ritual.statistics.blocks"),
                        value: "\(viewModel.blockCount)",
                        icon: "list.bullet"
                    )
                    .frame(width: 140)
                    
                    StatRitualPageCard(
                        title: LocalizedStringKey("ritual.statistics.playCount"),
                        value: "\(viewModel.routine.playCount)",
                        icon: "play.circle"
                    )
                    .frame(width: 140)
                    
                    StatRitualPageCard(
                        title: LocalizedStringKey("ritual.statistics.created"),
                        value: viewModel.formattedCreatedDate,
                        icon: "calendar"
                    )
                    .frame(width: 140)
                    
                    StatRitualPageCard(
                        title: LocalizedStringKey("ritual.statistics.modified"),
                        value: viewModel.formattedLastModified,
                        icon: "clock"
                    )
                    .frame(width: 140)
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
            }
        }
    }
    
    // MARK: - Blocks Section
    private var blocksSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("ritual.blocks.title"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(viewModel.routineData.blocks.enumerated()), id: \.element.id) { index, block in
                    BlockRowView(block: block, index: index + 1)
                }
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.small) {
                
                // Play Button (always visible)
                AppTheme.cardButton(
                    icon: "play.fill",
                    title: String(localized: "button.play"),
                    action: viewModel.playRoutine
                )
                
                // Pin/Unpin Button (always visible)
                AppTheme.toggleButton(
                    icon: "pin",
                    activeIcon: "pin.fill",
                    title: String(localized: "button.pin"),
                    activeTitle: String(localized: "button.unpin"),
                    isActive: viewModel.routine.isFavorite,
                    action: viewModel.toggleFavorite
                )
                
                if !viewModel.routine.isSystemRoutine {
                    AppTheme.cardButton(
                        icon: "pencil",
                        title: String(localized: "button.edit"),
                        action: viewModel.editRoutine
                    )
                    
                    AppTheme.cardButton(
                        icon: "trash",
                        title: String(localized: "button.delete"),
                        action: viewModel.deleteRoutine
                    )
                } else {
                    // Placeholder cards to maintain grid layout
                    Color.clear
                        .frame(height: 72) // 9x grid unit
                    
                    Color.clear
                        .frame(height: 72) // 9x grid unit
                }
            }
            .padding(.horizontal, AppTheme.Spacing.medium)
        }
    }
}

// MARK: - Stat Card
struct StatRitualPageCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
					.foregroundColor(AppTheme.offWhiteText)
                
                Text(title)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
                
                Spacer()
            }
            
            Text(value)
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

// MARK: - Block Row View
struct BlockRowView: View {
    let block: RoutineBlock
    let index: Int
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Block number
            Text("\(index)")
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24, height: 24)
                .background(AppTheme.accentColor.opacity(0.2))
                .clipShape(Circle())
            
            // Block icon
            Image(systemName: block.blockIcon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 32, height: 32)
            
            // Block info
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(block.name)
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.offWhiteText)
                
                Text(block.type.displayName)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
            }
            
            Spacer()
            
            // Duration
            Text(String.localizedStringWithFormat(
                String(localized: "duration.with.value.format"),
                block.durationInMinutes
            ))
            .font(AppTheme.Typography.captionFont)
            .foregroundColor(AppTheme.lightGrey)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}

#Preview {
    NavigationView {
        RitualPageView(
            routine: SavedRoutine(
                routine: Routine(
                    name: "Morning Meditation",
                    icon: "sun.max.fill",
                    blocks: [
                        RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                        RoutineBlock(name: "Breathwork", durationInMinutes: 3, type: .breathwork, blockStartBell: .softBell),
                        RoutineBlock(name: "Chanting", durationInMinutes: 4, type: .chanting, blockStartBell: .tibetanBowl)
                    ],
                    openingBell: .softBell,
                    closingBell: .digitalChime
                )
            ),
            onEdit: { _ in },
            onDelete: { _ in },
            onPlay: { _ in }
        )
    }
}


