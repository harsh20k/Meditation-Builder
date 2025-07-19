	//
	//  RoutineLibraryView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI
import SwiftData
import os.log

struct RoutineLibraryView: View {
	@Query(sort: \SavedRoutine.lastModified, order: .reverse) private var allSavedRoutines: [SavedRoutine]
	@Environment(\.modelContext) private var modelContext
	
	@State private var searchText = ""
	@State private var showingRoutineBuilder = false
	@State private var editingRoutine: SavedRoutine? = nil
	@State private var playingRoutine: SavedRoutine? = nil
	@State private var routineToDelete: SavedRoutine? = nil
	@State private var showingDeleteAlert = false
	@State private var selectedRoutine: SavedRoutine? = nil
	
	private var dataManager: RoutineDataManager {
		RoutineDataManager(context: modelContext)
	}
	
		// Filter out soft-deleted routines
	private var savedRoutines: [SavedRoutine] {
		allSavedRoutines.filter { !$0.isDeleted }
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
						//                    Image(systemName: "books.vertical.fill")
						//                        .foregroundColor(AppTheme.accentColor)
						//                        .font(.system(size: 28, weight: .bold))
					Text(LocalizedStringKey("routine.library.title"))
						.font(AppTheme.Typography.titleFont)
						.foregroundColor(.white)
						//                    Spacer()
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
					
					if !searchText.isEmpty {
						Button(action: {
							searchText = ""
						}) {
							Image(systemName: "xmark.circle.fill")
								.foregroundColor(AppTheme.lightGrey)
								.font(.system(size: 16, weight: .medium))
						}
						.buttonStyle(PlainButtonStyle())
					}
				}
				.padding(AppTheme.Spacing.medium)
				.background(AppTheme.searchBar)
				.cornerRadius(AppTheme.CornerRadius.button)
				.padding(.horizontal)
				.padding(.bottom, AppTheme.Spacing.large)
				
					// Routines List
				if filteredRoutines.isEmpty {
					LibraryEmptyStateView(searchText: searchText)
				} else {
					ScrollView(showsIndicators: false) {
						LazyVStack(spacing: AppTheme.Spacing.large) {
							ForEach(filteredRoutines) { routine in
								RoutineCard(
									routine: routine,
									isSelected: selectedRoutine?.id == routine.id,
									onPlay: {
										playingRoutine = routine
										recordPlay(for: routine)
									},
									onEdit: { editingRoutine = routine },
									onDelete: { deleteRoutine(routine) },
									onTap: {
										withAnimation(.spring(duration: 0.2)) {
											selectedRoutine = routine
										}
									}
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
		.fullScreenCover(item: $playingRoutine) { routine in
			RoutinePlayerView(routine: routine)
		}
		.alert(LocalizedStringKey("alert.delete.routine.title"), isPresented: $showingDeleteAlert) {
			Button(LocalizedStringKey("button.cancel"), role: .cancel) {
				routineToDelete = nil
			}
			Button(LocalizedStringKey("button.delete"), role: .destructive) {
				confirmDeleteRoutine()
			}
		} message: {
			if let routine = routineToDelete {
				Text(String.localizedStringWithFormat(
					NSLocalizedString("alert.delete.routine.message", comment: "Delete routine confirmation"),
					routine.routineName
				))
			}
		}
	}
	
		// MARK: - Private Methods
	
	private func recordPlay(for routine: SavedRoutine) {
		logger.info("Starting routine playback: \(routine.routineName)", category: "RoutineLibrary")
		
			// Validate that the routine is not soft-deleted
		guard !routine.isDeleted else {
			logger.error("Cannot play soft-deleted routine: \(routine.routineName)", category: "RoutineLibrary")
			return
		}
		
			// Debug logging: Print routine blocks
		logRoutineBlocks(routine)
		
		Task {
			do {
				try await dataManager.recordPlay(for: routine)
				logger.info("Play recorded for routine: \(routine.routineName)", category: "RoutineLibrary")
			} catch {
				logger.error("Failed to record play: \(error)", category: "RoutineLibrary")
			}
		}
	}
	
	private func logRoutineBlocks(_ routine: SavedRoutine) {
		let routineData = routine.getRoutine()
		
		logger.debug("Playing routine '\(routine.routineName)'", category: "RoutineLibrary")
		logger.debug("Routine blocks in order:", category: "RoutineLibrary")
		
		for (index, block) in routineData.blocks.enumerated() {
			let blockNumber = index + 1
			let blockName = block.name
			let duration = "\(block.durationInMinutes) min"
			
			if index == 0 {
					// First block - don't show bell
				logger.debug("  \(blockNumber). \(blockName) (\(duration))", category: "RoutineLibrary")
			} else {
					// Other blocks - show bell
				let bell = block.blockStartBell.displayName
				logger.debug("  \(blockNumber). \(blockName) (\(duration)) - Bell: \(bell)", category: "RoutineLibrary")
			}
		}
		
		let totalDuration = routineData.blocks.map(\.durationInMinutes).reduce(0, +)
		logger.debug("Total duration: \(totalDuration) minutes", category: "RoutineLibrary")
		logger.debug("Opening bell: \(routineData.openingBell.displayName)", category: "RoutineLibrary")
		logger.debug("Closing bell: \(routineData.closingBell.displayName)", category: "RoutineLibrary")
	}
	
	private func deleteRoutine(_ routine: SavedRoutine) {
		routineToDelete = routine
		showingDeleteAlert = true
	}
	
	private func confirmDeleteRoutine() {
		guard let routine = routineToDelete else { return }
		
		logger.info("Confirming deletion of routine: \(routine.routineName)", category: "RoutineLibrary")
		
		withAnimation(.easeInOut(duration: 0.3)) {
			Task {
				do {
					try dataManager.deleteRoutine(routine)
					logger.info("Routine deleted successfully: \(routine.routineName)", category: "RoutineLibrary")
				} catch {
					logger.error("Failed to delete routine: \(error)", category: "RoutineLibrary")
				}
			}
		}
		
		routineToDelete = nil
		showingDeleteAlert = false
	}
}

struct ScalableButtonStyle: ButtonStyle {
	var scaleAmount: CGFloat = 0.95
	
	func makeBody(configuration: Configuration) -> some View {
		configuration.label
		.scaleEffect(configuration.isPressed ? scaleAmount : 1)
		.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
	}
}

// MARK: - Routine Card
struct RoutineCard: View {
	let routine: SavedRoutine
	let isSelected: Bool
	var onPlay: () -> Void
	var onEdit: () -> Void
	var onDelete: () -> Void
	var onTap: () -> Void
	
	private var totalDuration: Int {
		routine.getRoutine().blocks.map(\.durationInMinutes).reduce(0, +)
	}
	
	    private var blocksSummary: String {
        let blockNames = routine.getRoutine().blocks.map(\.name)
        if blockNames.count <= 3 {
            return blockNames.joined(separator: " • ")
        } else {
            return blockNames.prefix(2).joined(separator: " • ") + " • " + String.localizedStringWithFormat(
                String(localized: "routine.more.blocks.format"),
                blockNames.count - 2
            )
        }
    }
    
    private var blockIcons: [String] {
		routine.getRoutine().blocks.map(\.blockIcon)
    }
	
	var body: some View {
		VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {

			// Header with custom icon and name
            HStack(spacing: AppTheme.Spacing.medium) {
                if !isSelected {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentColor.opacity(0.2))
                            .frame(width: 48, height: 48)
                        Image(systemName: routine.routineIcon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppTheme.accentColor)
                    }
                }
				
				VStack(alignment: .leading, spacing: 4) {
                    Text(routine.routineName)
                        .font(isSelected ? AppTheme.Typography.headlineFontLarge : AppTheme.Typography.headlineFont)
                        .foregroundColor(.white)
                        .lineLimit(2)
					
					Text(String.localizedStringWithFormat(
						String(localized: "routine.duration.format.simplified"),
						totalDuration
					))
					.font(isSelected ? AppTheme.Typography.headlineFont : AppTheme.Typography.bodyFont)
					.foregroundColor(AppTheme.lightGrey)
				}
				
				Spacer()
			}
			
				            // Blocks summary or block icons
            if isSelected {
                // Horizontal scrollable list of block icons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(Array(blockIcons.enumerated()), id: \.offset) { index, iconName in
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentColor.opacity(0.2))
                                    .frame(width: 32, height: 32)
                                Image(systemName: iconName)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.accentColor)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            } else {
                // Regular blocks summary text
                Text(blocksSummary)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(AppTheme.lightGrey)
                    .lineLimit(2)
            }
			
				// Action buttons - only show when selected
			if isSelected {
				HStack(spacing: AppTheme.Spacing.medium) {
						// Play button
					Button(action: onPlay) {
						HStack(spacing: AppTheme.Spacing.small) {
							Image(systemName: "play.fill")
								.font(.system(size: 14, weight: .bold))
							Text(LocalizedStringKey("button.play"))
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
							Text(LocalizedStringKey("button.edit"))
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
					
						// Delete button
					Button(action: onDelete) {
						Image(systemName: "trash")
							.font(.system(size: 14, weight: .medium))
							.foregroundColor(.white)
							.padding(.horizontal, AppTheme.Spacing.medium)
							.padding(.vertical, AppTheme.Spacing.small)
							.background(
								Capsule()
									.fill(Color.red.opacity(0.8))
							)
					}
					
					Spacer()
				}
			}
		}
		.padding(AppTheme.Spacing.large)
		.background(
			RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
				.fill(AppTheme.cardColor)
		)
		.overlay(
			RoundedRectangle(cornerRadius: AppTheme.CornerRadius.extraLarge)
				.stroke(isSelected ? AppTheme.accentColor : Color.white.opacity(AppTheme.Opacity.border), lineWidth: isSelected ? 2 : 1)
		)
		.shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
		.onTapGesture(perform: onTap)
	}
}

// MARK: - Library Empty State View
struct LibraryEmptyStateView: View {
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

// MARK: - Placeholder Routine Player View (Removed - now using dedicated RoutinePlayerView.swift)

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
					
					LibraryEmptyStateView(searchText: searchText)
					
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
			isSelected: false,
			onPlay: {},
			onEdit: {},
			onDelete: {},
			onTap: {}
		)
		.padding()
	}
}
