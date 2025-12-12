//
//  RoutineBuilderView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData
import Dragula
import os.log

struct RoutineBuilderView: View {
    let savedRoutineToEdit: SavedRoutine?
    
    @State private var routine: Routine
    @State private var editBlock: RoutineBlock? = nil
    @State private var showAddBlock = false
    @State private var isSaving = false
    @State private var showingSaveAlert = false
    @State private var routineName: String
    @State private var routineIcon: String
    @State private var showIconPicker = false
    @State private var isEditMode: Bool
    @State private var openSwipeCardID: UUID? = nil
    @State private var dragulaKey = UUID()
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.routineDataManager) private var dataManager

    
    // Initializer for creating new routine
    init() {
        self.savedRoutineToEdit = nil
        self._routine = State(initialValue: Routine(
            name: "New Routine",
            icon: "sun.max.fill",
            blocks: [
                RoutineBlock(name: "Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent),
                RoutineBlock(name: "Breathwork", durationInMinutes: 3, type: .breathwork, blockStartBell: .softBell),
                RoutineBlock(name: "Chanting", durationInMinutes: 4, type: .chanting, blockStartBell: .tibetanBowl)
            ],
            openingBell: .softBell,
            closingBell: .digitalChime
        ))
        self._routineName = State(initialValue: "New Routine")
        self._routineIcon = State(initialValue: "sun.max.fill")
        self._isEditMode = State(initialValue: false)
    }
    
    // Initializer for editing existing routine
    init(editingRoutine: SavedRoutine) {
        self.savedRoutineToEdit = editingRoutine
        self._routine = State(initialValue: editingRoutine.getRoutine())
        self._routineName = State(initialValue: editingRoutine.routineName)
        self._routineIcon = State(initialValue: editingRoutine.routineIcon)
        self._isEditMode = State(initialValue: true)
    }
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    var canSave: Bool {
        !routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !routine.blocks.isEmpty
    }
    
    func deleteBlock(_ block: RoutineBlock) {
        logger.info("Deleting block: \(block.name)", category: "RoutineBuilder")
        
        // Reset open swipe state
        openSwipeCardID = nil
        
        if let index = routine.blocks.firstIndex(where: { $0.id == block.id }) {
            withAnimation(.easeInOut(duration: 0.4)) {
                routine.blocks.remove(at: index)
            }
            logger.info("Block deleted successfully: \(block.name)", category: "RoutineBuilder")
        } else {
            logger.warning("Block not found for deletion: \(block.name)", category: "RoutineBuilder")
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            AppTheme.backgroundColor.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: { showIconPicker = true }) {
                        Image(systemName: routineIcon)
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 28, weight: .bold))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, AppTheme.Spacing.medium)
                    
                    TextField(LocalizedStringKey("routine.name.placeholder"), text: $routineName)
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(.white)
                        .textFieldStyle(PlainTextFieldStyle())
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.small)
                
                // Timeline + Block List with Dragula
                ScrollView(showsIndicators: false) {
                    if routine.blocks.isEmpty {
                        // Empty state
                        VStack(spacing: AppTheme.Spacing.large) {
                            Spacer()
                            
                            Button(action: { showAddBlock = true }) {
                                VStack(spacing: AppTheme.Spacing.medium) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accentColor.opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "plus")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(AppTheme.accentColor)
                                    }
                                    
                                    Text(LocalizedStringKey("routine.builder.add.block"))
                                        .font(AppTheme.Typography.headlineFont)
                                        .foregroundColor(AppTheme.lightGrey)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, AppTheme.Spacing.extraLarge)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                                        .foregroundColor(AppTheme.lightGrey.opacity(0.5))
                                )
                                .padding(.horizontal, AppTheme.Spacing.large)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Spacer()
                        }
                        .frame(minHeight: 200)
                    } else {
                        ZStack(alignment: .leading) {
                            // Timeline vertical line (scrolls with blocks)
                            if routine.blocks.count > 1 {
                                GeometryReader { geo in
                                    let blockHeight: CGFloat = 56 // Approximate block height (padding + card)
                                    let spacing: CGFloat = 20
                                    let totalHeight = CGFloat(routine.blocks.count) * blockHeight + CGFloat(routine.blocks.count - 1) * spacing
                                    Rectangle()
                                        .fill(AppTheme.lightGrey.opacity(AppTheme.Opacity.timeline))
                                        .frame(width: 2, height: totalHeight - blockHeight/2)
										.offset(x: 58, y: blockHeight/2 + AppTheme.Spacing.titleRoom)
                                }
                            }
                            
                            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                                DragulaView(items: $routine.blocks) { block in
                                    SwipeableBlockCard(
                                        block: block,
                                        isLast: block.id == routine.blocks.last?.id,
                                        onEdit: { editBlock = block },
                                        onDelete: { deleteBlock(block) },
                                        index: routine.blocks.firstIndex(where: { $0.id == block.id }) ?? 0,
                                        blocksCount: routine.blocks.count,
                                        openSwipeCardID: $openSwipeCardID
                                    )
                                    .frame(height: 56)
                                } dropView: { block in
                                    DropIndicatorView(block: block)
                                } dropCompleted: {
                                    // Drag and drop completed
                                }
								.environment(\.dragPreviewCornerRadius, AppTheme.CornerRadius.blockCard)
                            }
                            .id(dragulaKey)
                            .padding(.top, AppTheme.Spacing.titleRoom)
                            .padding(.bottom, 120) // Account for floating button and tab bar
							.padding(.horizontal, 24)
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Total Time & Save Button
                VStack(spacing: AppTheme.Spacing.medium) {
                    if !routine.blocks.isEmpty {
                        Text(String.localizedStringWithFormat(
                            String(localized: "total.time.format"),
                            totalTime
                        ))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    
                    Button(action: { showingSaveAlert = true }) {
                        Text(LocalizedStringKey(isEditMode ? "button.update" : "button.save"))
                            .font(AppTheme.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(canSave ? AppTheme.accentColor : AppTheme.accentColor.opacity(0.5))
                            )
                    }
                    .disabled(!canSave)
                    .padding(.horizontal, 40)
                }
                .padding(.bottom, 80) // Account for tab bar
            }
            
            // Floating Add Button
            Button(action: { showAddBlock = true }) {
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
            .padding(.bottom, 160)
            .shadow(radius: 8)
        }
        .sheet(item: $editBlock) { block in
            EditBlockView(block: block) { updatedBlock in
                logger.info("Block updated: \(block.name) -> \(updatedBlock.name)", category: "RoutineBuilder")
                withAnimation(.easeInOut(duration: 0.2)) {
                    // Force UI update by creating a new array
                    var updatedBlocks = routine.blocks
                    if let idx = updatedBlocks.firstIndex(where: { $0.id == updatedBlock.id }) {
                        updatedBlocks[idx] = updatedBlock
                    }
                    routine.blocks = updatedBlocks
                }
                // Force DragulaView recreation by updating the key
                dragulaKey = UUID()
                editBlock = nil
            }
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView { newBlock in
                logger.info("New block added: \(newBlock.name) (\(newBlock.type))", category: "RoutineBuilder")
                withAnimation(.easeInOut(duration: 0.2)) {
                    routine.blocks.append(newBlock)
                }
                showAddBlock = false
            }
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $routineIcon)
        }
        .alert(isEditMode ? "Update Routine" : "Save Routine", isPresented: $showingSaveAlert) {
            Button(isEditMode ? "Update" : "Save") {
                saveRoutine()
            }
            Button(LocalizedStringKey("button.cancel"), role: .cancel) {}
        } message: {
            Text(isEditMode ? "Update this routine?" : "Save this routine?")
        }
    }
    
    // MARK: - Private Methods
    
    private func saveRoutine() {
        logger.info("Saving routine: \(routineName) (\(routine.blocks.count) blocks)", category: "RoutineBuilder")
        
        Task {
            isSaving = true
            do {
                var routineToSave = routine
                routineToSave.name = routineName
                routineToSave.icon = routineIcon
                
                if isEditMode, let savedRoutine = savedRoutineToEdit {
                    // Update existing routine
                    logger.info("Updating existing routine: \(savedRoutine.routineName)", category: "RoutineBuilder")
                    try await dataManager.updateRoutine(savedRoutine, with: routineToSave)
                } else {
                    // Create new routine
                    logger.info("Creating new routine: \(routineName)", category: "RoutineBuilder")
                    try await dataManager.saveRoutine(routineToSave, name: routineName)
                }
                
                logger.info("Routine saved successfully", category: "RoutineBuilder")
                await MainActor.run {
                    dismiss()
                }
            } catch {
                logger.error("Failed to save routine: \(error)", category: "RoutineBuilder")
            }
            isSaving = false
        }
    }
}

// MARK: - Swipeable Block Card
struct SwipeableBlockCard: View {
    let block: RoutineBlock
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    let index: Int
    let blocksCount: Int
    @Binding var openSwipeCardID: UUID?
    
    @State private var offset: CGFloat = 0
    @State private var isPressed: Bool = false
    @State private var isDeleting: Bool = false
    
    private let deleteButtonWidth: CGFloat = 80
    private let maxSwipeDistance: CGFloat = -120
    private let snapThreshold: CGFloat = -80 // Distance to snap to open state
    
    private var isSwiped: Bool {
        openSwipeCardID == block.id
    }
    
    var body: some View {
        ZStack {
            // Delete background (only visible when swiped)
            HStack {
                Spacer()
                                Button(action: {
                    // Start deletion animation
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isDeleting = true
                        offset = -UIScreen.main.bounds.width // Slide completely off screen
                    }
                    
                    // Call onDelete after animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 18, weight: .medium))
                        .frame(width: 60, height: 60)
                        .background(Color.red)
                        .clipShape(Circle())
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                }, perform: {})
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 20)
                .opacity(isSwiped ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: isSwiped)
            }
            .frame(maxWidth: .infinity)
            
            // Main card
            TimelineBlockCard(
                block: block,
                isLast: isLast,
                index: index,
                blocksCount: blocksCount
            )
            .offset(x: offset)
            .opacity(isDeleting ? 0.0 : 1.0)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        // Only allow left swipe (negative values)
                        if value.translation.width < 0 {
                            // Limit the swipe distance
                            offset = max(value.translation.width, maxSwipeDistance)
                        }
                    }
                    .onEnded { value in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if value.translation.width < snapThreshold {
                                // Snap to open state (show delete button)
                                offset = maxSwipeDistance
                                openSwipeCardID = block.id
                            } else {
                                // Snap back to closed state
                                offset = 0
                                openSwipeCardID = nil
                            }
                        }
                    }
            )
            .onTapGesture {
                if isSwiped {
                    // Close swipe state when tapping while swiped
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offset = 0
                        openSwipeCardID = nil
                    }
                } else {
                    // Trigger edit action when tapping normally
                    onEdit()
                }
            }
            .onChange(of: isSwiped) { _, newValue in
                // Update offset when swipe state changes externally
                withAnimation(.easeInOut(duration: 0.3)) {
                    offset = newValue ? maxSwipeDistance : 0
                }
            }
        }
    }
}

// MARK: - Drop Indicator View
struct DropIndicatorView: View {
    let block: RoutineBlock
    
    var body: some View {
        Rectangle()
			.fill(AppTheme.accentCompColor.opacity(0.8))
            .frame(height: 40)
            .clipShape(.rect(cornerRadius: 32))
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.horizontal, 20) // Align with timeline
    }
}

#Preview("Routine Builder - New Routine") {
    RoutineBuilderView()
        .environment(\.modelContext, try! ModelContainer(for: SavedRoutine.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
        .environment(\.routineDataManager, RoutineDataManager.shared)
}

#Preview("Routine Builder - Empty State") {
    struct EmptyRoutineBuilder: View {
        var body: some View {
            RoutineBuilderView()
                .environment(\.modelContext, try! ModelContainer(for: SavedRoutine.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
                .environment(\.routineDataManager, RoutineDataManager.shared)
                .onAppear {
                    // This will show the empty state since the default routine has blocks
                    // In a real scenario, you'd modify the initializer to start with empty blocks
                }
        }
    }
    
    return EmptyRoutineBuilder()
}

#Preview("Routine Builder - Editing Existing") {
    let sampleRoutine = SavedRoutine(
        routine: Routine(
            name: "Morning Meditation",
            icon: "sunrise.fill",
            blocks: [
                RoutineBlock(name: "Breathwork", durationInMinutes: 5, type: .breathwork, blockStartBell: .softBell),
                RoutineBlock(name: "Silence", durationInMinutes: 10, type: .silence, blockStartBell: .silent),
                RoutineBlock(name: "Visualization", durationInMinutes: 8, type: .visualization, blockStartBell: .tibetanBowl),
                RoutineBlock(name: "Body Scan", durationInMinutes: 7, type: .bodyScan, blockStartBell: .digitalChime)
            ],
            openingBell: .softBell,
            closingBell: .tibetanBowl
        )
    )
    
    return RoutineBuilderView(editingRoutine: sampleRoutine)
        .environment(\.modelContext, try! ModelContainer(for: SavedRoutine.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
        .environment(\.routineDataManager, RoutineDataManager.shared)
}

#Preview("Routine Builder - Long Routine") {
    let longRoutine = SavedRoutine(
        routine: Routine(
            name: "Extended Meditation Session",
            icon: "moon.stars.fill",
            blocks: [
                RoutineBlock(name: "Opening Breathwork", durationInMinutes: 3, type: .breathwork, blockStartBell: .softBell),
                RoutineBlock(name: "Mindful Silence", durationInMinutes: 15, type: .silence, blockStartBell: .silent),
                RoutineBlock(name: "Guided Visualization", durationInMinutes: 12, type: .visualization, blockStartBell: .tibetanBowl),
                RoutineBlock(name: "Body Awareness", durationInMinutes: 10, type: .bodyScan, blockStartBell: .digitalChime),
                RoutineBlock(name: "Walking Meditation", durationInMinutes: 8, type: .walking, blockStartBell: .softBell),
                RoutineBlock(name: "Chanting Practice", durationInMinutes: 6, type: .chanting, blockStartBell: .tibetanBowl),
                RoutineBlock(name: "Closing Silence", durationInMinutes: 5, type: .silence, blockStartBell: .silent)
            ],
            openingBell: .tibetanBowl,
            closingBell: .digitalChime
        )
    )
    
    return RoutineBuilderView(editingRoutine: longRoutine)
        .environment(\.modelContext, try! ModelContainer(for: SavedRoutine.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
        .environment(\.routineDataManager, RoutineDataManager.shared)
}

#Preview("Routine Builder - Short Routine") {
    let shortRoutine = SavedRoutine(
        routine: Routine(
            name: "Quick Focus",
            icon: "target",
            blocks: [
                RoutineBlock(name: "Mindful Breathing", durationInMinutes: 2, type: .breathwork, blockStartBell: .softBell),
                RoutineBlock(name: "Present Moment", durationInMinutes: 3, type: .silence, blockStartBell: .silent)
            ],
            openingBell: .digitalChime,
            closingBell: .digitalChime
        )
    )
    
    return RoutineBuilderView(editingRoutine: shortRoutine)
        .environment(\.modelContext, try! ModelContainer(for: SavedRoutine.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext)
        .environment(\.routineDataManager, RoutineDataManager.shared)
} 
 
