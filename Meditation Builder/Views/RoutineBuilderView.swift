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
    @State private var refreshID = UUID()
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private var dataManager: RoutineDataManager {
        RoutineDataManager(context: modelContext)
    }
    
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
        
        if let index = routine.blocks.firstIndex(where: { $0.id == block.id }) {
            withAnimation(.easeInOut(duration: 0.3)) {
                routine.blocks.remove(at: index)
                refreshID = UUID() // Force view refresh
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
                    
                    TextField("Routine Name", text: $routineName)
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
                                    
                                    Text("+ Add Meditation Block")
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
                                    let blockHeight: CGFloat = 76 // Approximate block height (padding + card)
                                    let spacing: CGFloat = 20
                                    let totalHeight = CGFloat(routine.blocks.count) * blockHeight + CGFloat(routine.blocks.count - 1) * spacing
                                    Rectangle()
                                        .fill(AppTheme.lightGrey.opacity(AppTheme.Opacity.timeline))
                                        .frame(width: 2, height: totalHeight - blockHeight/2)
                                        .offset(x: 54, y: blockHeight/2)
                                }
                            }
                            
                            LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                                DragulaView(items: $routine.blocks) { block in
                                    TimelineBlockCard(
                                        block: block,
                                        isLast: block.id == routine.blocks.last?.id,
                                        onEdit: { editBlock = block },
                                        onDelete: { deleteBlock(block) },
                                        index: routine.blocks.firstIndex(where: { $0.id == block.id }) ?? 0,
                                        blocksCount: routine.blocks.count
                                    )
                                    .frame(height: 76)
                                } dropView: { block in
                                    DropIndicatorView(block: block)
                                } dropCompleted: {
                                    // Drag and drop completed
                                }
                                .environment(\.dragPreviewCornerRadius, AppTheme.CornerRadius.large)
                            }
                            .id(refreshID)
                            .padding(.vertical, AppTheme.Spacing.extraLarge)
                            .padding(.bottom, 120) // Account for floating button and tab bar
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
                    refreshID = UUID() // Force view refresh
                }
                editBlock = nil
            }
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView { newBlock in
                logger.info("New block added: \(newBlock.name) (\(newBlock.type))", category: "RoutineBuilder")
                withAnimation(.easeInOut(duration: 0.2)) {
                    routine.blocks.append(newBlock)
                    refreshID = UUID() // Force view refresh
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
            Button("Cancel", role: .cancel) {}
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

// MARK: - Drop Indicator View
struct DropIndicatorView: View {
    let block: RoutineBlock
    
    var body: some View {
        Rectangle()
            .fill(AppTheme.accentColor.opacity(0.3))
            .frame(height: 4)
            .clipShape(.rect(cornerRadius: 2))
            .padding(.horizontal, AppTheme.Spacing.medium)
            .padding(.leading, 56) // Align with timeline
    }
} 
 
