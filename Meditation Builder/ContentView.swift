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
    
    var totalTime: Int {
        routine.blocks.map { $0.durationInMinutes }.reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.black.ignoresSafeArea()
                VStack(spacing: 0) {
                    HStack {
                        Text("Your Routine")
                            .font(.title2).bold()
                            .foregroundColor(.white)
                        Spacer()
                        Button("Save") {
                            isSaving = true // Placeholder
                        }
                        .foregroundColor(.blue)
                        .padding(.trailing, 8)
                    }
                    .padding([.top, .horizontal])
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(routine.blocks.indices, id: \ .self) { idx in
                                RoutineBlockView(
                                    block: routine.blocks[idx],
                                    onEdit: { editBlock = routine.blocks[idx] },
                                    onDrag: {} // Placeholder
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
                            Button(action: { showAddBlock = true }) {
                                Text("+ Add Block")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(
                                        Capsule()
                                            .stroke(Color.gray.opacity(0.7), lineWidth: 2)
                                    )
                            }
                            .padding(.top, 24)
                        }
                        .padding(.bottom, 32)
                    }
                    
                    Text("Total Time: \(totalTime) min")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .frame(maxWidth: .infinity)
                    
                    Button(action: { isStarting = true }) {
                        Text("Start Routine")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.bottom, 12)
                    }
                }
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

// MARK: - RoutineBlockView
struct RoutineBlockView: View {
    let block: MeditationBlock
    var onEdit: () -> Void
    var onDrag: () -> Void // Placeholder for drag
    var body: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.gray)
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
            Button("Edit") { onEdit() }
                .foregroundColor(.blue)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.13, green: 0.13, blue: 0.15))
        )
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
