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
}

struct TransitionBell: Equatable {
    var soundName: String
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
            MeditationBlock(id: UUID(), name: "Silence", durationInMinutes: 5),
            MeditationBlock(id: UUID(), name: "Breathwork", durationInMinutes: 3),
            MeditationBlock(id: UUID(), name: "Chanting", durationInMinutes: 4)
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
                            .font(.title2).bold()
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
                        VStack(spacing: 0) {
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
                                .padding(.top, idx == 0 ? 16 : 8)
                                
                                if idx < routine.blocks.count - 1 {
                                    TransitionBellView(
                                        bell: routine.transitionBells[idx],
                                        onTap: { showBellPickerIndex = IdentifiableInt(value: idx) }
                                    )
                                    .padding(.horizontal, 32)
                                }
                            }
                        }
                        .padding(.bottom, 32)
                    }
                    
                    Text("Total Time: \(totalTime) min")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity)
                        .background(Color.clear)
                    
                    Button(action: { isStarting = true }) {
                        Text("Start Routine")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                Capsule()
                                    .fill(Color.white)
                            )
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
                .padding(.bottom, 100) // Higher to clear Start Routine button
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
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.white)
                .padding(.trailing, 8)
            VStack(alignment: .leading) {
                Text(block.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Text("\(block.durationInMinutes) min")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundColor(.white)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color(red: 0.09, green: 0.09, blue: 0.11))
        )
        .overlay(
            Capsule()
                .stroke(Color.white, lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// MARK: - TransitionBellView
struct TransitionBellView: View {
    var bell: TransitionBell?
    var onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: "bell")
                    .foregroundColor(.yellow)
                Text(bell?.soundName ?? "Tap to Set Transition Bell")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - EditBlockView (Stub)
struct EditBlockView: View {
    @State var block: MeditationBlock
    var onSave: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 24) {
            Text("Edit Block")
                .font(.title2).bold()
            TextField("Name", text: $block.name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper(value: $block.durationInMinutes, in: 1...60) {
                Text("Duration: \(block.durationInMinutes) min")
            }
            Button("Save") {
                onSave(block)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - AddBlockView (Stub)
struct AddBlockView: View {
    @State private var name: String = ""
    @State private var duration: Int = 5
    var onAdd: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(spacing: 24) {
            Text("Add Block")
                .font(.title2).bold()
            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Stepper(value: $duration, in: 1...60) {
                Text("Duration: \(duration) min")
            }
            Button("Add") {
                let newBlock = MeditationBlock(id: UUID(), name: name.isEmpty ? "New Block" : name, durationInMinutes: duration)
                onAdd(newBlock)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - BellPickerView (Stub)
struct BellPickerView: View {
    @State var selected: TransitionBell?
    var onSelect: (TransitionBell?) -> Void
    @Environment(\.dismiss) var dismiss
    let bells = ["None", "Soft Bell", "Tibetan Bowl", "Digital Chime"]
    var body: some View {
        VStack(spacing: 24) {
            Text("Select Transition Bell")
                .font(.title2).bold()
            ForEach(bells, id: \ .self) { name in
                Button(action: {
                    onSelect(name == "None" ? nil : TransitionBell(soundName: name))
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "bell")
                        Text(name)
                        if selected?.soundName == name { Image(systemName: "checkmark") }
                    }
                }
            }
        }
        .padding()
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
