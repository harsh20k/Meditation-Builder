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
}

// MARK: - Ritual Page View
struct RitualPageView: View {
    	@StateObject private var viewModel: RitualPageViewModel
	@Environment(\.modelContext) private var modelContext
    
    let onEdit: (SavedRoutine) -> Void
    let onDelete: (SavedRoutine) -> Void
    
    init(routine: SavedRoutine, onEdit: @escaping (SavedRoutine) -> Void, onDelete: @escaping (SavedRoutine) -> Void) {
        self._viewModel = StateObject(wrappedValue: RitualPageViewModel(routine: routine))
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header Section
                    headerSection
                    
                    // Statistics Section
                    statisticsSection
                    
                    // Blocks Section
                    blocksSection
                    
                    // Action Buttons
                    actionButtonsSection
                }
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.extraLarge)
            }
        }
        		.navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showingEditSheet) {
            RoutineBuilderView(editingRoutine: viewModel.routine)
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
            HStack {
                Image(systemName: viewModel.routine.routineIcon)
                    .font(.system(size: 48, weight: .ultraLight))
                    .foregroundColor(AppTheme.accentColor)
                    .frame(width: 80, height: 80)
                    .background(AppTheme.cardColor)
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text(viewModel.routine.routineName)
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(AppTheme.offWhiteText)
                        .lineLimit(2)
                    
                    Text(String.localizedStringWithFormat(
                        String(localized: "routine.duration.format"),
                        viewModel.totalDuration
                    ))
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            .background(AppTheme.cardColor)
            .cornerRadius(AppTheme.CornerRadius.large)
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
            ], spacing: AppTheme.Spacing.medium) {
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
        VStack(spacing: AppTheme.Spacing.medium) {
            if !viewModel.routine.isSystemRoutine {
                Button(action: viewModel.editRoutine) {
                    HStack {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                        Text(LocalizedStringKey("button.edit"))
                            .font(AppTheme.Typography.buttonFont)
                    }
                    .foregroundColor(AppTheme.offWhiteText)
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.medium)
                    .background(AppTheme.accentColor)
                    .cornerRadius(AppTheme.CornerRadius.button)
                }
                
                Button(action: viewModel.deleteRoutine) {
                    HStack {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                        Text(LocalizedStringKey("button.delete"))
                            .font(AppTheme.Typography.buttonFont)
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(AppTheme.Spacing.medium)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(AppTheme.CornerRadius.button)
                }
            }
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
                    .foregroundColor(AppTheme.accentColor)
                
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
            VStack(alignment: .leading, spacing: 2) {
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
            onDelete: { _ in }
        )
    }
} 
