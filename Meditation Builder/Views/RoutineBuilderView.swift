//
//  RoutineBuilderView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData
import Dragula

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
    
    func deleteBlock(at index: Int) {
        routine.blocks.remove(at: index)
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
                        .padding(.vertical, AppTheme.Spacing.extraLarge)
                        .padding(.bottom, 120) // Account for floating button and tab bar
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Total Time & Save Button
                VStack(spacing: AppTheme.Spacing.medium) {
                    Text(String.localizedStringWithFormat(
                        String(localized: "total.time.format"),
                        totalTime
                    ))
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Button(action: { showingSaveAlert = true }) {
                        Text(LocalizedStringKey(isEditMode ? "button.update" : "button.save"))
                            .font(AppTheme.Typography.buttonFont)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? AppTheme.accentColor.opacity(0.5) : AppTheme.accentColor)
                            )
                    }
                    .disabled(routineName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .padding(.horizontal)
                }
                .padding(.bottom, 112) // Account for tab bar
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
            .padding(.bottom, 112)
            .shadow(radius: 8)
        }
        .sheet(item: $editBlock) { block in
            EditBlockView(block: block) { updatedBlock in
                if let idx = routine.blocks.firstIndex(where: { $0.id == updatedBlock.id }) {
                    routine.blocks[idx] = updatedBlock
                }
                editBlock = nil
            }
        }
        .sheet(isPresented: $showAddBlock) {
            AddBlockView { newBlock in
                routine.blocks.append(newBlock)
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
        Task {
            isSaving = true
            do {
                var routineToSave = routine
                routineToSave.name = routineName
                routineToSave.icon = routineIcon
                
                if isEditMode, let savedRoutine = savedRoutineToEdit {
                    // Update existing routine
                    try await dataManager.updateRoutine(savedRoutine, with: routineToSave)
                } else {
                    // Create new routine
                    try await dataManager.saveRoutine(routineToSave, name: routineName)
                }
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to save routine: \(error)")
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
 
