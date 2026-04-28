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
	@Query(filter: #Predicate<SavedRoutine> { routine in
		!routine.isDeleted
	}, sort: \SavedRoutine.lastModified, order: .reverse) private var allSavedRoutines: [SavedRoutine]
	@Environment(\.modelContext) private var modelContext
	@Environment(\.routineDataManager) private var dataManager
	@Binding var navigationPath: NavigationPath
	
	@State private var searchText = ""
	@State private var editingRoutine: SavedRoutine? = nil
	@State private var playingRoutine: SavedRoutine? = nil
	@State private var routineToDelete: SavedRoutine? = nil
	@State private var showingDeleteAlert = false
	@State private var selectedRoutine: SavedRoutine? = nil
	
	// Use allSavedRoutines directly since query already filters deleted routines
	private var savedRoutines: [SavedRoutine] {
		allSavedRoutines
	}
	
	var filteredRoutines: [SavedRoutine] {
		let nonFavoriteRoutines = savedRoutines.filter { !$0.isFavorite }
		
		if searchText.isEmpty {
			return nonFavoriteRoutines
		}
		return nonFavoriteRoutines.filter { routine in
			routine.routineName.localizedCaseInsensitiveContains(searchText) ||
			routine.getRoutine().blocks.contains { block in
				block.name.localizedCaseInsensitiveContains(searchText) ||
				block.type.displayName.localizedCaseInsensitiveContains(searchText)
			}
		}
	}
	
	var favoriteRoutines: [SavedRoutine] {
		savedRoutines.filter { $0.isFavorite }
	}
	
	// MARK: - Pinned Rituals Section
	private var pinnedRitualsSection: some View {
		VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
			// Section Header
			HStack {
				Text(LocalizedStringKey("pinned.rituals.title"))
					.font(AppTheme.Typography.headlineFont)
					.foregroundColor(AppTheme.offWhiteText)
				
				Spacer()
				
				// Pin icon
				Image(systemName: "pin.fill")
					.font(.system(size: 16, weight: .medium))
					.foregroundColor(AppTheme.accentColor)
			}
			.padding(.horizontal, AppTheme.Spacing.medium)
			
			// Horizontal Scrollable Carousel
			ScrollView(.horizontal, showsIndicators: false) {
				LazyHStack(spacing: AppTheme.Spacing.small) {
					ForEach(favoriteRoutines) { routine in
						FavoriteRoutineCard(
							routine: routine,
							onTap: {
								logger.info("Favorite routine tapped: \(routine.routineName)", category: "RoutineLibrary")
								navigationPath.append(routine)
							},
							onPlay: {
								playingRoutine = routine
								recordPlay(for: routine)
							},
							onEdit: { editingRoutine = routine },
							onDelete: { deleteRoutine(routine) }
						)
						.frame(width: 200)
					}
				}
				.padding(.horizontal, AppTheme.Spacing.medium)
			}
		}
//		.padding(.bottom, AppTheme.Spacing.large)
	}
	
	var body: some View {
		ZStack(alignment: .bottomTrailing) {
			AppTheme.backgroundColor.ignoresSafeArea()

			ScrollView {
				VStack(spacing: 0) {
					// Header
					HStack {
						Text(LocalizedStringKey("routine.library.title"))
							.font(AppTheme.Typography.titleFont)
							.foregroundColor(AppTheme.offWhiteText)
						Spacer()
					}
					.padding(.horizontal, AppTheme.Spacing.medium)
					.padding(.top, AppTheme.Spacing.section)
					.padding(.bottom, AppTheme.Spacing.large)

					// Pinned Rituals Section
					if !favoriteRoutines.isEmpty {
						pinnedRitualsSection

						AppTheme.separator(
							color: AppTheme.lightGrey.opacity(0.2),
							horizontalPadding: AppTheme.Spacing.medium,
							verticalPadding: AppTheme.Spacing.medium
						)
					}

					// Routines List
					if filteredRoutines.isEmpty {
						LibraryEmptyStateView(searchText: searchText)
					} else {
						LazyVGrid(columns: [
							GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
							GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
						], spacing: AppTheme.Spacing.medium) {
							ForEach(filteredRoutines) { routine in
								CompactRoutineCard(
									routine: routine,
									onTap: {
										logger.info("Routine tapped: \(routine.routineName)", category: "RoutineLibrary")
										navigationPath.append(routine)
									},
									onPlay: {
										playingRoutine = routine
										recordPlay(for: routine)
									},
									onEdit: { editingRoutine = routine },
									onDelete: { deleteRoutine(routine) }
								)
								.scrollTransition(.animated(.easeInOut)) { content, phase in
									content.opacity(phase.isIdentity ? 1 : 0.6)
								}
							}
						}
						.padding(.horizontal, AppTheme.Spacing.medium)
						.padding(.bottom, AppTheme.Spacing.extraLarge)
					}
				}
			}
			.scrollIndicators(.hidden)

			// Floating Create Button
			AppTheme.floatingActionButton(
				icon: "plus",
				backgroundColor: AppTheme.accentColor,
				foregroundColor: AppTheme.backgroundColor,
				size: 56,
				action: {
					navigationPath.append(RoutineBuilderDestination.create)
				}
			)
			.accessibilityLabel("Create new ritual")
			.padding(.trailing, AppTheme.Spacing.extraLarge)
			.padding(.bottom, AppTheme.Spacing.extraLarge)
		}
		.sheet(item: $editingRoutine) { routine in
			RoutineBuilderView(editingRoutine: routine)
		}
		.fullScreenCover(item: $playingRoutine) { routine in
			RoutinePlayerView(routine: routine, modelContext: modelContext)
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
		.statusBar(hidden: true)
		.sensoryFeedback(.impact(flexibility: .soft), trigger: filteredRoutines.count)
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

//struct ScalableButtonStyle: ButtonStyle {
//	var scaleAmount: CGFloat = 0.95
//	
//	func makeBody(configuration: Configuration) -> some View {
//		configuration.label
//		.scaleEffect(configuration.isPressed ? scaleAmount : 1)
//		.animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
//	}
//}

// MARK: - Routine Card OLD
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
                        .foregroundColor(AppTheme.offWhiteText)
                        .lineLimit(2)
                    
                    Text(String.localizedStringWithFormat(
                        String(localized: "routine.duration.format.simplified"),
                        totalDuration
                    ))
                        .font(isSelected ? AppTheme.Typography.headlineFont : AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                }
                
                Spacer()
                
                // Play button - only show when not selected
                if !isSelected {
                    Button(action: onPlay) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 40, height: 40)
                            Image(systemName: "play.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.lightGrey)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
			}
			
				            // Blocks summary or block icons
            if isSelected {
                // Horizontal scrollable list of block icons
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.medium) {
                        ForEach(Array(blockIcons.enumerated()), id: \.offset) { index, iconName in
                            ZStack {
//                                Circle()
//                                    .fill(AppTheme.accentColor.opacity(0.2))
//                                    .frame(width: 32, height: 32)
                                Image(systemName: iconName)
									.font(.system(size: 22, weight: .ultraLight))
                                    .foregroundColor(AppTheme.lightGrey)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                }
            } else {
                // Regular blocks summary text
                Text(blocksSummary)
					.font(AppTheme.Typography.captionFont)
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
						.foregroundColor(AppTheme.offWhiteText)
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
							.foregroundColor(AppTheme.offWhiteText)
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
				.stroke(isSelected ? AppTheme.accentColor.opacity(0.05) : Color.white.opacity(AppTheme.Opacity.border), lineWidth: isSelected ? 2 : 0)
		)
//		.shadow(color: AppTheme.Shadows.card, radius: 4, x: 0, y: 2)
		.onTapGesture(perform: onTap)
	}
}

// MARK: - Base Routine Card
struct BaseRoutineCard<Content: View>: View {
    let routine: SavedRoutine
    let onTap: () -> Void
    let onPlay: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let content: Content
    let cardStyle: CardStyle
    
    @State private var showingMenu = false
    
    private var totalDuration: Int {
        routine.getRoutine().blocks.map(\.durationInMinutes).reduce(0, +)
    }
    
    init(
        routine: SavedRoutine,
        onTap: @escaping () -> Void,
        onPlay: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        cardStyle: CardStyle = .standard,
        @ViewBuilder content: () -> Content
    ) {
        self.routine = routine
        self.onTap = onTap
        self.onPlay = onPlay
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.cardStyle = cardStyle
        self.content = content()
    }
    
    var body: some View {
        Button(action: onTap) {
            content
                .frame(maxWidth: .infinity, minHeight: cardStyle.minHeight, alignment: .leading)
                .padding(cardStyle.padding)
                .background(
                    RoundedRectangle(cornerRadius: cardStyle.cornerRadius)
                        .fill(cardStyle.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cardStyle.cornerRadius)
                        .stroke(cardStyle.borderColor, lineWidth: cardStyle.borderWidth)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Common UI Components
    
    @ViewBuilder
    func headerContent() -> some View {
        HStack {
            Image(systemName: routine.routineIcon)
                .font(.system(size: 24, weight: .ultraLight))
                .foregroundColor(AppTheme.accentColor)
            
            if cardStyle.showDurationInHeader {
                Text(String.localizedStringWithFormat(
                    String(localized: "routine.duration.format.simplified"),
                    totalDuration
                ))
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(AppTheme.lightGrey)
            }
            
            Spacer()
            
            menuButton
        }
    }
    
    @ViewBuilder
    func titleContent() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.routineName)
                .font(cardStyle.titleFont)
                .foregroundColor(AppTheme.offWhiteText)
                .lineLimit(cardStyle.titleLineLimit)
                .multilineTextAlignment(.leading)
            
            if !cardStyle.showDurationInHeader {
                Text(String.localizedStringWithFormat(
                    String(localized: "routine.duration.format.simplified"),
                    totalDuration
                ))
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(AppTheme.lightGrey)
            }
        }
    }
    
    @ViewBuilder
    var menuButton: some View {
        Menu {
            Button(action: onPlay) {
                HStack {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text(LocalizedStringKey("button.play"))
                        .font(AppTheme.Typography.bodyFont)
                }
            }
            .foregroundColor(AppTheme.accentColor)
            
            if !routine.isSystemRoutine {
                Group {
                    Button(action: onEdit) {
                        Text(LocalizedStringKey("button.edit"))
                            .font(AppTheme.Typography.bodyFont)
                    }
                    .foregroundColor(AppTheme.lightGrey)
                    
                    Button(action: onDelete) {
                        Text(LocalizedStringKey("button.delete"))
                            .font(AppTheme.Typography.bodyFont)
                    }
                    .foregroundColor(Color.red.opacity(0.7))
                }
                .padding(.vertical, 2)
                .background(AppTheme.backgroundColor)
            } else {
                Button(action: {}) {
                    HStack {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .medium))
                        Text("System Routine")
                            .font(AppTheme.Typography.bodyFont)
                    }
                }
                .foregroundColor(AppTheme.lightGrey)
                .disabled(true)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .foregroundColor(routine.isSystemRoutine ? AppTheme.lightGrey.opacity(0.5) : AppTheme.lightGrey)
                .background(Color.black.opacity(0.3))
        }
        .menuStyle(CustomMenuStyle())
    }
}

// MARK: - Card Style Configuration
struct CardStyle {
    let backgroundColor: Color
    let borderColor: Color
    let borderWidth: CGFloat
    let cornerRadius: CGFloat
    let padding: CGFloat
    let minHeight: CGFloat
    let titleFont: Font
    let titleLineLimit: Int
    let showDurationInHeader: Bool
    
    static let standard = CardStyle(
        backgroundColor: AppTheme.cardColor,
        borderColor: Color.clear,
        borderWidth: 0,
        cornerRadius: AppTheme.CornerRadius.medium,
        padding: AppTheme.Spacing.medium,
        minHeight: 120.0,
        titleFont: AppTheme.Typography.headlineFont,
        titleLineLimit: 2,
        showDurationInHeader: true
    )
    
    static let favorite = CardStyle(
        backgroundColor: AppTheme.cardColor,
        borderColor: AppTheme.accentColor.opacity(0.3),
        borderWidth: 1,
        cornerRadius: AppTheme.CornerRadius.medium,
        padding: AppTheme.Spacing.medium,
        minHeight: 140.0,
        titleFont: AppTheme.Typography.headlineFont,
        titleLineLimit: 2,
        showDurationInHeader: false
    )
}

// MARK: - Compact Routine Card
struct CompactRoutineCard: View {
    let routine: SavedRoutine
    var onTap: () -> Void
    var onPlay: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        BaseRoutineCard(
            routine: routine,
            onTap: onTap,
            onPlay: onPlay,
            onEdit: onEdit,
            onDelete: onDelete,
            cardStyle: .standard
        ) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                // Header with icon, duration, and menu
                HStack {
                    Image(systemName: routine.routineIcon)
                        .font(.system(size: 24, weight: .ultraLight))
                        .foregroundColor(AppTheme.accentColor)
                    
                    Text(String.localizedStringWithFormat(
                        String(localized: "routine.duration.format.simplified"),
                        routine.getRoutine().blocks.map(\.durationInMinutes).reduce(0, +)
                    ))
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
                    
                    Spacer()
                    
                    Menu {
                        Button(action: onPlay) {
                            HStack {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .medium))
                                Text(LocalizedStringKey("button.play"))
                                    .font(AppTheme.Typography.bodyFont)
                            }
                        }
                        .foregroundColor(AppTheme.accentColor)
                        
                        if !routine.isSystemRoutine {
                            Group {
                                Button(action: onEdit) {
                                    Text(LocalizedStringKey("button.edit"))
                                        .font(AppTheme.Typography.bodyFont)
                                }
                                .foregroundColor(AppTheme.lightGrey)
                                
                                Button(action: onDelete) {
                                    Text(LocalizedStringKey("button.delete"))
                                        .font(AppTheme.Typography.bodyFont)
                                }
                                .foregroundColor(Color.red.opacity(0.7))
                            }
                            .padding(.vertical, 2)
                            .background(AppTheme.backgroundColor)
                        } else {
                            Button(action: {}) {
                                HStack {
                                    Image(systemName: "info.circle")
                                        .font(.system(size: 14, weight: .medium))
                                    Text("System Routine")
                                        .font(AppTheme.Typography.bodyFont)
                                }
                            }
                            .foregroundColor(AppTheme.lightGrey)
                            .disabled(true)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            .foregroundColor(routine.isSystemRoutine ? AppTheme.lightGrey.opacity(0.5) : AppTheme.lightGrey)
                            .background(Color.black.opacity(0.3))
                    }
                    .menuStyle(CustomMenuStyle())
                }
                
                Spacer()
                
                // Title
                Text(routine.routineName)
                    .font(AppTheme.Typography.headlineFont)
                    .foregroundColor(AppTheme.offWhiteText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

// MARK: - Custom Menu Style
struct CustomMenuStyle: MenuStyle {
    func makeBody(configuration: Configuration) -> some View {
        Menu(configuration)
            .background(AppTheme.backgroundColor)
            .foregroundColor(AppTheme.lightGrey)
            .menuIndicator(.hidden)
    }
}

// MARK: - Favorite Routine Card
struct FavoriteRoutineCard: View {
    let routine: SavedRoutine
    var onTap: () -> Void
    var onPlay: () -> Void
    var onEdit: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: AppTheme.Spacing.medium) {
            // Routine name
            Text(routine.routineName)
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
                .lineLimit(1...2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Circular play button
            Button(action: onPlay) {
                ZStack {
                    Circle()
                        .fill(AppTheme.offWhiteText)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.backgroundColor)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(AppTheme.Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: 80.0, alignment: .leading)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppTheme.offWhiteText.opacity(0.3),
                            AppTheme.offWhiteText.opacity(0.1),
                            AppTheme.offWhiteText.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Library Empty State View
struct LibraryEmptyStateView: View {
	let searchText: String
	@State private var breatheScale: CGFloat = 1.0
	@State private var breatheOpacity: Double = 0.3
	@Environment(\.accessibilityReduceMotion) private var reduceMotion

	var body: some View {
		VStack(spacing: AppTheme.Spacing.extraLarge) {
			Spacer()

			ZStack {
				if searchText.isEmpty && !reduceMotion {
					// Breathing rings — only when no search and reduce motion is off
					Circle()
						.stroke(AppTheme.accentColor.opacity(breatheOpacity * 0.5), lineWidth: 1)
						.frame(width: 120, height: 120)
						.scaleEffect(breatheScale * 1.4)
					Circle()
						.stroke(AppTheme.accentColor.opacity(breatheOpacity * 0.3), lineWidth: 1)
						.frame(width: 120, height: 120)
						.scaleEffect(breatheScale * 1.8)
				}

				Circle()
					.fill(AppTheme.accentColor.opacity(0.1))
					.frame(width: 100, height: 100)
					.scaleEffect(breatheScale)

				if searchText.isEmpty {
					Image(systemName: "sparkle")
						.foregroundColor(AppTheme.accentColor)
						.font(.system(size: 38, weight: .ultraLight))
						.symbolEffect(.pulse, isActive: !reduceMotion)
				} else {
					Image(systemName: "magnifyingglass")
						.foregroundColor(AppTheme.lightGrey)
						.font(.system(size: 32, weight: .light))
				}
			}
			.onAppear {
				guard searchText.isEmpty && !reduceMotion else { return }
				withAnimation(
					.easeInOut(duration: 4.0).repeatForever(autoreverses: true)
				) {
					breatheScale = 1.12
					breatheOpacity = 0.7
				}
			}

			VStack(spacing: AppTheme.Spacing.medium) {
				Text(LocalizedStringKey(searchText.isEmpty ? "empty.no.routines" : "empty.no.results"))
					.font(AppTheme.Typography.headlineFontLarge)
					.foregroundColor(AppTheme.offWhiteText)

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
		.accessibilityElement(children: .combine)
		.accessibilityLabel(searchText.isEmpty ? "No rituals yet. Tap the plus button to create your first ritual." : "No results found for your search.")
	}
}

// MARK: - Placeholder Routine Player View (Removed - now using dedicated RoutinePlayerView.swift)

// MARK: - Preview
#Preview("Routine Library") {
    struct PreviewRoutineLibrary: View {
        @State private var savedRoutines: [SavedRoutine] = [
            SavedRoutine(
                routine: Routine(
                    name: "Morning Meditation",
                    icon: "sun.max.fill",
                    blocks: [
                        RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                        RoutineBlock(name: "Breathwork", durationInMinutes: 10, type: .breathwork, blockStartBell: .softBell),
                        RoutineBlock(name: "Visualization", durationInMinutes: 8, type: .visualization, blockStartBell: .tibetanBowl)
                    ],
                    openingBell: .softBell,
                    closingBell: .tibetanBowl
                )
            ),
            SavedRoutine(
                routine: Routine(
                    name: "Evening Wind Down",
                    icon: "moon.stars.fill",
                    blocks: [
                        RoutineBlock(name: "Body Scan", durationInMinutes: 10, type: .bodyScan, blockStartBell: .silent),
                        RoutineBlock(name: "Deep Relaxation", durationInMinutes: 15, type: .silence, blockStartBell: .tibetanBowl)
                    ],
                    openingBell: .tibetanBowl,
                    closingBell: .softBell
                )
            ),
            SavedRoutine(
                routine: Routine(
                    name: "Quick Focus",
                    icon: "target",
                    blocks: [
                        RoutineBlock(name: "Mindful Breathing", durationInMinutes: 3, type: .breathwork, blockStartBell: .silent),
                        RoutineBlock(name: "Present Moment", durationInMinutes: 5, type: .silence, blockStartBell: .digitalChime)
                    ],
                    openingBell: .digitalChime,
                    closingBell: .digitalChime
                )
            ),
            SavedRoutine(
                routine: Routine(
                    name: "Deep Sleep",
                    icon: "bed.double.fill",
                    blocks: [
                        RoutineBlock(name: "Progressive Relaxation", durationInMinutes: 8, type: .bodyScan, blockStartBell: .silent),
                        RoutineBlock(name: "Sleep Induction", durationInMinutes: 12, type: .silence, blockStartBell: .tibetanBowl)
                    ],
                    openingBell: .softBell,
                    closingBell: .digitalChime
                )
            ),
            SavedRoutine(
                routine: Routine(
                    name: "Energy Boost",
                    icon: "bolt.fill",
                    blocks: [
                        RoutineBlock(name: "Quick Breathing", durationInMinutes: 2, type: .breathwork, blockStartBell: .silent),
                        RoutineBlock(name: "Energy Visualization", durationInMinutes: 6, type: .visualization, blockStartBell: .digitalChime)
                    ],
                    openingBell: .digitalChime,
                    closingBell: .softBell
                )
            )
        ]
        
        // Set some routines as favorites
        init() {
            savedRoutines[0].isFavorite = true  // Morning Meditation
            savedRoutines[1].isFavorite = true  // Evening Wind Down
            savedRoutines[2].isFavorite = true  // Quick Focus
            savedRoutines[3].isFavorite = true  // Deep Sleep
            savedRoutines[4].isFavorite = true  // Energy Boost
        }
        
        var body: some View {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack {
                            Text(LocalizedStringKey("routine.library.title"))
                                .font(AppTheme.Typography.titleFont)
                                .foregroundColor(AppTheme.offWhiteText)
                            Text(LocalizedStringKey("routine.library.title"))
                                .font(AppTheme.Typography.captionFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.extraLarge)
                    .padding(.bottom, AppTheme.Spacing.small)
                    
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.large) {
                            // Favorites Section
                            let favoriteRoutines = savedRoutines.filter { $0.isFavorite }
                            if !favoriteRoutines.isEmpty {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                    Text("Favorites")
                                        .font(AppTheme.Typography.headlineFont)
                                        .foregroundColor(AppTheme.offWhiteText)
                                        .padding(.horizontal)
                                    
                                    LazyVGrid(columns: [
                                        GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
                                        GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
                                    ], spacing: AppTheme.Spacing.medium) {
                                        ForEach(favoriteRoutines) { routine in
                                            FavoriteRoutineCard(
                                                routine: routine,
                                                onTap: {},
                                                onPlay: {},
                                                onEdit: {},
                                                onDelete: {}
                                            )
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            
                            // All Routines Section
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                Text("All Routines")
                                    .font(AppTheme.Typography.headlineFont)
                                    .foregroundColor(AppTheme.offWhiteText)
                                    .padding(.horizontal)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
                                    GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
                                ], spacing: AppTheme.Spacing.medium) {
                                    ForEach(savedRoutines) { routine in
                                        CompactRoutineCard(
                                            routine: routine,
                                            onTap: {},
                                            onPlay: {},
                                            onEdit: {},
                                            onDelete: {}
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, AppTheme.Spacing.extraLarge)
                    }
                }
            }
        }
    }
    
    return PreviewRoutineLibrary()
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
                        VStack {
                            Text(LocalizedStringKey("routine.library.title"))
                                .font(AppTheme.Typography.titleFont)
                                .foregroundColor(AppTheme.offWhiteText)
                            Text(LocalizedStringKey("routine.library.title"))
                                .font(AppTheme.Typography.captionFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.extraLarge)
                    .padding(.bottom, AppTheme.Spacing.small)
                    
                    LibraryEmptyStateView(searchText: searchText)
                    
                    Spacer()
                }
                
                // Floating Create Button
                Button(action: { showingRoutineBuilder = true }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.tabBar)
                            .frame(width: 56, height: 56)
                        Image(systemName: "plus")
                            .foregroundColor(.gray)
                            .font(.system(size: 28, weight: .bold))
                    }
                }
                .padding(.trailing, AppTheme.Spacing.section)
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

#Preview("Compact Routine Card Grid") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        let sampleRoutines = [
            SavedRoutine(
                routine: Routine(
                    name: "Morning Meditation",
                    icon: "sun.max.fill",
                    blocks: [
                        RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                        RoutineBlock(name: "Breathwork", durationInMinutes: 10, type: .breathwork, blockStartBell: .softBell)
                    ],
                    openingBell: .softBell,
                    closingBell: .tibetanBowl
                )
            ),
            SavedRoutine(
                routine: Routine(
                    name: "Quick Focus",
                    icon: "target",
                    blocks: [
                        RoutineBlock(name: "Mindful Breathing", durationInMinutes: 3, type: .breathwork, blockStartBell: .silent)
                    ],
                    openingBell: .digitalChime,
                    closingBell: .digitalChime
                )
            )
        ]
        
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
                GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
            ], spacing: AppTheme.Spacing.medium) {
                ForEach(sampleRoutines) { routine in
                    CompactRoutineCard(
                        routine: routine,
						onTap: {},
                        onPlay: {},
                        onEdit: {},
                        onDelete: {}
                    )
                }
            }
            .padding()
        }
    }
}
