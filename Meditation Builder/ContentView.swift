//
//  ContentView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

// MARK: - Data Models
struct MeditationBlock: Identifiable, Equatable {
    let id: UUID
    var name: String
    var durationInMinutes: Int
    var type: BlockType
    
    enum BlockType: String, CaseIterable {
        case silence = "Silence"
        case breathwork = "Breathwork"
        case chanting = "Chanting"
        case visualization = "Visualization"
        case bodyScan = "Body Scan"
        case walking = "Walking"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .silence: return "🔕"
            case .breathwork: return "🌬️"
            case .chanting: return "🕉️"
            case .visualization: return "👁️"
            case .bodyScan: return "🧘"
            case .walking: return "🚶"
            case .custom: return "✨"
            }
        }
        
        var defaultDuration: Int {
            switch self {
            case .silence: return 5
            case .breathwork: return 3
            case .chanting: return 4
            case .visualization: return 6
            case .bodyScan: return 8
            case .walking: return 10
            case .custom: return 5
            }
        }
    }
}

struct TransitionBell: Equatable {
    var soundName: String
    
    var displayName: String {
        switch soundName {
        case "None": return "🔕 None"
        case "Soft Bell": return "🔔 Soft Bell"
        case "Tibetan Bowl": return "🪘 Tibetan Bowl"
        case "Digital Chime": return "🎵 Digital Chime"
        default: return "🔔 \(soundName)"
        }
    }
}

struct Routine {
    var blocks: [MeditationBlock]
    var transitionBells: [TransitionBell?] // size = blocks.count - 1
}

// MARK: - IdentifiableInt for sheet index
struct IdentifiableInt: Identifiable {
    var id: Int { value }
    let value: Int
}

// MARK: - Main View
struct RoutineBuilderView: View {
    @State private var routine = Routine(
        blocks: [
            MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 5, type: .silence),
            MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 3, type: .breathwork),
            MeditationBlock(id: UUID(), name: "Chanting", durationInMinutes: 4, type: .chanting)
        ],
        transitionBells: [nil, nil]
    )
    @State private var editBlock: MeditationBlock? = nil
    @State private var showAddBlock = false
    @State private var showBellPickerIndex: IdentifiableInt? = nil
    @State private var isSaving = false
    @State private var isStarting = false
    @State private var draggingBlock: MeditationBlock? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var dragIndex: Int? = nil
    @State private var blockOffsets: [UUID: CGFloat] = [:]
    @GestureState private var isDetectingLongPress = false
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    func moveBlock(from source: Int, to destination: Int) {
        guard source != destination, source < routine.blocks.count, destination < routine.blocks.count else { return }
        var newBlocks = routine.blocks
        let moved = newBlocks.remove(at: source)
        newBlocks.insert(moved, at: destination)
        routine.blocks = newBlocks
        // For simplicity, clear all bells after reorder
        routine.transitionBells = Array(repeating: nil, count: newBlocks.count > 0 ? newBlocks.count - 1 : 0)
    }
    
    func deleteBlock(at index: Int) {
        routine.blocks.remove(at: index)
        if routine.transitionBells.indices.contains(index) {
            routine.transitionBells.remove(at: index)
        } else if routine.transitionBells.indices.contains(index - 1) {
            routine.transitionBells.remove(at: index - 1)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color(red: 0.07, green: 0.07, blue: 0.07).ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Your Routine")
                            .font(.largeTitle).bold()
                            .foregroundColor(.white)
                        Spacer()
                        Button("Save") {
                            isSaving = true // Placeholder
                        }
                        .foregroundColor(.white)
                        .padding(.trailing, 8)
                    }
                    .padding([.top, .horizontal])
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(Array(routine.blocks.enumerated()), id: \ .element.id) { (idx, block) in
                                DraggableSwipeableBlock(
                                    block: block,
                                    onEdit: { editBlock = block },
                                    onDelete: { deleteBlock(at: idx) },
                                    onDrag: { dragState in
                                        if let from = dragState.from, let to = dragState.to {
                                            moveBlock(from: from, to: to)
                                        }
                                    },
                                    index: idx,
                                    blocksCount: routine.blocks.count,
                                    draggingBlock: $draggingBlock
                                )
                                .padding(.horizontal)
                                
                                if idx < routine.blocks.count - 1 {
                                    TransitionBellView(
                                        bell: routine.transitionBells[idx],
                                        onTap: { showBellPickerIndex = IdentifiableInt(value: idx) }
                                    )
                                    .padding(.horizontal, 48)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    
                    // Footer
                    VStack(spacing: 16) {
                        Text("Total Time: \(totalTime) min")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                        
                        Button(action: { isStarting = true }) {
                            Text("Start Routine")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(Color.blue)
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                    }
                    .background(Color.clear)
                }
                // Floating Add Button (higher position)
                Button(action: { showAddBlock = true }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
                            .frame(width: 56, height: 56)
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white, lineWidth: 2)
                            )
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 28, weight: .bold))
                    }
                }
                .padding(.trailing, 24)
                .padding(.bottom, 120) // Higher to clear Start Routine button
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
                    if routine.blocks.count > 1 {
                        routine.transitionBells.append(nil)
                    }
                    showAddBlock = false
                }
            }
            .sheet(item: $showBellPickerIndex) { identifiable in
                let idx = identifiable.value
                BellPickerView(selected: routine.transitionBells[idx]) { bell in
                    routine.transitionBells[idx] = bell
                    showBellPickerIndex = nil
                }
            }
        }
    }
}

// MARK: - DraggableSwipeableBlock
struct DraggableSwipeableBlock: View {
    let block: MeditationBlock
    var onEdit: () -> Void
    var onDelete: () -> Void
    var onDrag: (_ dragState: (from: Int?, to: Int?)) -> Void
    let index: Int
    let blocksCount: Int
    @Binding var draggingBlock: MeditationBlock?
    @State private var offset: CGFloat = 0
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var isSwiped: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Swipe to delete background
            HStack {
                Spacer()
                Button(action: {
                    withAnimation { isSwiped = false }
                    onDelete()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            
            RoutineBlockView(block: block, onEdit: onEdit)
                .offset(x: isSwiped ? -80 : dragTranslation.width)
                .gesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .updating($dragTranslation) { value, state, _ in
                            if abs(value.translation.width) > abs(value.translation.height) {
                                state = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.width < -60 {
                                withAnimation { isSwiped = true }
                            } else if value.translation.width > 40 {
                                withAnimation { isSwiped = false }
                            }
                        }
                )
                .simultaneousGesture(
                    LongPressGesture(minimumDuration: 0.2)
                        .onEnded { _ in
                            draggingBlock = block
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            if draggingBlock == block {
                                offset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if draggingBlock == block {
                                let dragThreshold: CGFloat = 40
                                var from = index
                                var to = index
                                if value.translation.height < -dragThreshold && index > 0 {
                                    to = index - 1
                                } else if value.translation.height > dragThreshold && index < blocksCount - 1 {
                                    to = index + 1
                                }
                                if from != to {
                                    onDrag((from: from, to: to))
                                }
                                offset = 0
                                draggingBlock = nil
                            }
                        }
                )
                .offset(y: draggingBlock == block ? offset : 0)
                .animation(.spring(), value: offset)
        }
        .animation(.spring(), value: isSwiped)
    }
}

// MARK: - RoutineBlockView
struct RoutineBlockView: View {
    let block: MeditationBlock
    var onEdit: () -> Void
    var body: some View {
        HStack(spacing: 16) {
            // Block type icon
            Text(block.type.icon)
                .font(.title2)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(block.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                Text("\(block.durationInMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Reorder handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
                .font(.caption)
            
            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.12, green: 0.12, blue: 0.14))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - TransitionBellView
struct TransitionBellView: View {
    var bell: TransitionBell?
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Text(bell?.displayName ?? "🔔 Set Bell")
                    .font(.footnote)
                    .foregroundColor(.gray)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

// MARK: - EditBlockView
struct EditBlockView: View {
    @State var block: MeditationBlock
    var onSave: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                HStack {
                    Text(block.type.icon)
                        .font(.title)
                    TextField("Name", text: $block.name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.headline)
                }
                
                Stepper(value: $block.durationInMinutes, in: 1...60) {
                    Text("Duration: \(block.durationInMinutes) min")
                        .font(.subheadline)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(block)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - AddBlockView
struct AddBlockView: View {
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var customName = ""
    @State private var customDuration = 5
    var onAdd: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    var filteredDefaultBlocks: [MeditationBlock.BlockType] {
        let blocks = MeditationBlock.BlockType.allCases.filter { $0 != .custom }
        if searchText.isEmpty {
            return blocks
        }
        return blocks.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search blocks...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Tab selector
                Picker("Block Type", selection: $selectedTab) {
                    Text("Default").tag(0)
                    Text("Custom").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if selectedTab == 0 {
                    // Default blocks
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredDefaultBlocks, id: \.self) { blockType in
                                Button(action: {
                                    let newBlock = MeditationBlock(
                                        id: UUID(),
                                        name: blockType.rawValue,
                                        durationInMinutes: blockType.defaultDuration,
                                        type: blockType
                                    )
                                    onAdd(newBlock)
                                    dismiss()
                                }) {
                                    HStack(spacing: 16) {
                                        Text(blockType.icon)
                                            .font(.title2)
                                            .frame(width: 40, height: 40)
                                            .background(
                                                Circle()
                                                    .fill(Color.blue.opacity(0.2))
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(blockType.rawValue)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text("\(blockType.defaultDuration) min")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.blue)
                                            .font(.title2)
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(.systemGray6))
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                } else {
                    // Custom block
                    VStack(spacing: 24) {
                        HStack {
                            Text("✨")
                                .font(.title)
                                .frame(width: 40, height: 40)
                                .background(
                                    Circle()
                                        .fill(Color.purple.opacity(0.2))
                                )
                            
                            TextField("Block name", text: $customName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.headline)
                        }
                        
                        Stepper(value: $customDuration, in: 1...60) {
                            Text("Duration: \(customDuration) min")
                                .font(.subheadline)
                        }
                        
                        Button(action: {
                            let newBlock = MeditationBlock(
                                id: UUID(),
                                name: customName.isEmpty ? "Custom Block" : customName,
                                durationInMinutes: customDuration,
                                type: .custom
                            )
                            onAdd(newBlock)
                            dismiss()
                        }) {
                            Text("Add Custom Block")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.purple)
                                )
                        }
                        .disabled(customName.isEmpty)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - BellPickerView
struct BellPickerView: View {
    @State var selected: TransitionBell?
    var onSelect: (TransitionBell?) -> Void
    @Environment(\.dismiss) var dismiss
    let bells = ["None", "Soft Bell", "Tibetan Bowl", "Digital Chime"]
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                ForEach(bells, id: \.self) { name in
                    Button(action: {
                        onSelect(name == "None" ? nil : TransitionBell(soundName: name))
                        dismiss()
                    }) {
                        HStack {
                            Text(name == "None" ? "🔕" : "🔔")
                                .font(.title2)
                            Text(name)
                                .font(.headline)
                            Spacer()
                            if selected?.soundName == name {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Select Bell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .background(Color(.systemBackground))
    }
}

struct ContentView: View {
    var body: some View {
        RoutineBuilderView()
    }
}

// MARK: - Preview
#Preview {
    RoutineBuilderView()
}
