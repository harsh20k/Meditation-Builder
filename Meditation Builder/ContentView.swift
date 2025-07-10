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
            case .silence: return "bell.fill"
            case .breathwork: return "leaf.fill"
            case .chanting: return "om.symbol"
            case .visualization: return "eye.fill"
            case .bodyScan: return "figure.mind.and.body"
            case .walking: return "figure.walk"
            case .custom: return "sparkles"
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
        case "None": return "None"
        case "Soft Bell": return "Soft Bell"
        case "Tibetan Bowl": return "Tibetan Bowl"
        case "Digital Chime": return "Digital Chime"
        default: return soundName
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
        transitionBells: [TransitionBell(soundName: "Soft Bell"), TransitionBell(soundName: "Soft Bell")]
    )
    @State private var editBlock: MeditationBlock? = nil
    @State private var showAddBlock = false
    @State private var isSaving = false
    @State private var draggingBlock: MeditationBlock? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var dragIndex: Int? = nil
    @State private var blockOffsets: [UUID: CGFloat] = [:]
    @GestureState private var isDetectingLongPress = false
    @State private var showBellPickerIndex: IdentifiableInt? = nil
    
    let bgColor = Color(red: 34/255, green: 38/255, blue: 45/255) // #22262D
    let cardColor = Color(red: 42/255, green: 46/255, blue: 55/255) // #2A2E37
    let orange = Color(red: 1.0, green: 122/255, blue: 0) // #FF7A00
    let lightGrey = Color(red: 176/255, green: 176/255, blue: 176/255) // #B0B0B0
    
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
        routine.transitionBells = Array(repeating: TransitionBell(soundName: "Soft Bell"), count: newBlocks.count > 0 ? newBlocks.count - 1 : 0)
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
        ZStack(alignment: .bottomTrailing) {
            bgColor.ignoresSafeArea()
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Routine")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(orange)
                        .font(.system(size: 28, weight: .bold))
                }
                .padding(.horizontal)
                .padding(.top, 24)
                .padding(.bottom, 8)
                
                // Timeline + Block List
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        // Timeline vertical line (scrolls with blocks)
                        if routine.blocks.count > 1 {
                            GeometryReader { geo in
                                let blockHeight: CGFloat = 76 // Approximate block height (padding + card)
                                let spacing: CGFloat = 20
                                let totalHeight = CGFloat(routine.blocks.count) * blockHeight + CGFloat(routine.blocks.count - 1) * spacing
                                Rectangle()
                                    .fill(lightGrey.opacity(0.25))
                                    .frame(width: 2, height: totalHeight - blockHeight/2)
                                    .offset(x: 54, y: blockHeight/2)
                            }
                        }
                        VStack(spacing: 20) {
                            ForEach(Array(routine.blocks.enumerated()), id: \ .element.id) { (idx, block) in
                                TimelineBlockCard(
                                    block: block,
                                    isLast: idx == routine.blocks.count - 1,
                                    orange: orange,
                                    cardColor: cardColor,
                                    lightGrey: lightGrey,
                                    onEdit: { editBlock = block },
                                    onDrag: { dragState in
                                        if let from = dragState.from, let to = dragState.to {
                                            moveBlock(from: from, to: to)
                                        }
                                    },
                                    index: idx,
                                    blocksCount: routine.blocks.count,
                                    draggingBlock: $draggingBlock,
                                    bell: idx < routine.transitionBells.count ? routine.transitionBells[idx] : nil,
                                    onBellTap: {
                                        showBellPickerIndex = IdentifiableInt(value: idx)
                                    }
                                )
                                .frame(height: 76)
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.bottom, 80)
                    }
                }
                .frame(maxHeight: .infinity)
                
                // Total Time & Save Button
                VStack(spacing: 16) {
                    Text("Total \(totalTime) min")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Button(action: { isSaving = true }) {
                        Text("SAVE")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(orange)
                            )
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 72)
            }
            // Floating Add Button
            Button(action: { showAddBlock = true }) {
                ZStack {
                    Circle()
                        .fill(orange)
                        .frame(width: 56, height: 56)
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 28, weight: .bold))
                }
            }
            .padding(.trailing, 24)
            .padding(.bottom, 112)
            .shadow(radius: 8)
            // Tab Bar
            VStack {
                Spacer()
                CustomTabBar(bgColor: bgColor, orange: orange)
            }
        }
        .sheet(item: $showBellPickerIndex) { identifiable in
            let idx = identifiable.value
            BellPickerView(selected: routine.transitionBells[idx]) { bell in
                routine.transitionBells[idx] = bell
                showBellPickerIndex = nil
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
                    routine.transitionBells.append(TransitionBell(soundName: "Soft Bell"))
                }
                showAddBlock = false
            }
        }
    }
}

// MARK: - TimelineBlockCard
struct TimelineBlockCard: View {
    let block: MeditationBlock
    let isLast: Bool
    let orange: Color
    let cardColor: Color
    let lightGrey: Color
    var onEdit: () -> Void
    var onDrag: (_ dragState: (from: Int?, to: Int?)) -> Void
    let index: Int
    let blocksCount: Int
    @Binding var draggingBlock: MeditationBlock?
    let bell: TransitionBell?
    var onBellTap: (() -> Void)? = nil
    @State private var offset: CGFloat = 0
    @GestureState private var dragTranslation: CGSize = .zero
    @State private var isSwiped: Bool = false
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Timeline node
            VStack {
                Spacer()
                Circle()
                    .fill(orange)
                    .frame(width: 16, height: 16)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 2))
                    .padding(.leading, 28)
                Spacer()
            }
            .frame(width: 40)
            
            // Block Card
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(orange)
                        .frame(width: 40, height: 40)
                    Image(systemName: block.type.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 22, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("\(block.durationInMinutes) min")
                        .font(.system(size: 15, weight: .regular, design: .rounded))
                        .foregroundColor(lightGrey)
                }
                Spacer()
                if !isLast {
                    Button(action: { onBellTap?() }) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(orange)
                            .font(.system(size: 18, weight: .bold))
                    }
                    .padding(.bottom, 2)
                }
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.08))
                        )
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.07), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
            .padding(.leading, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - CustomTabBar
struct CustomTabBar: View {
    let bgColor: Color
    let orange: Color
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            ZStack {
                Circle()
                    .fill(orange)
                    .frame(width: 44, height: 44)
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "hammer")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Image(systemName: "gearshape")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .frame(height: 56)
        .background(bgColor)
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - EditBlockView
struct EditBlockView: View {
    @State var block: MeditationBlock
    var onSave: (MeditationBlock) -> Void
    @Environment(\.dismiss) var dismiss
    
    let bgColor = Color(red: 34/255, green: 38/255, blue: 45/255) // #22262D
    let cardColor = Color(red: 42/255, green: 46/255, blue: 55/255) // #2A2E37
    let orange = Color(red: 1.0, green: 122/255, blue: 0) // #FF7A00
    let lightGrey = Color(red: 176/255, green: 176/255, blue: 176/255) // #B0B0B0
    
    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()
                VStack(spacing: 32) {
                    VStack(spacing: 24) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(orange)
                                    .frame(width: 40, height: 40)
                                Image(systemName: block.type.icon)
                                    .foregroundColor(.white)
                                    .font(.system(size: 22, weight: .bold))
                            }
                            TextField("Name", text: $block.name)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(cardColor)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 8)
                        Stepper(value: $block.durationInMinutes, in: 1...60) {
                            Text("Duration: \(block.durationInMinutes) min")
                                .font(.system(size: 15, weight: .regular, design: .rounded))
                                .foregroundColor(lightGrey)
                        }
                        .padding(.horizontal, 8)
                    }
                    .padding(.vertical, 24)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(cardColor)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                    
                    Button(action: {
                        onSave(block)
                        dismiss()
                    }) {
                        Text("Save")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(orange)
                            )
                    }
                    .padding(.horizontal)
                    Spacer()
                }
            }
            .navigationTitle("Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(orange)
                }
            }
        }
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
    
    let bgColor = Color(red: 34/255, green: 38/255, blue: 45/255) // #22262D
    let cardColor = Color(red: 42/255, green: 46/255, blue: 55/255) // #2A2E37
    let orange = Color(red: 1.0, green: 122/255, blue: 0) // #FF7A00
    let lightGrey = Color(red: 176/255, green: 176/255, blue: 176/255) // #B0B0B0
    
    var filteredDefaultBlocks: [MeditationBlock.BlockType] {
        let blocks = MeditationBlock.BlockType.allCases.filter { $0 != .custom }
        if searchText.isEmpty {
            return blocks
        }
        return blocks.filter { $0.rawValue.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(orange)
                        TextField("Search blocks...", text: $searchText)
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(cardColor)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Tab selector
                    HStack(spacing: 0) {
                        Button(action: { selectedTab = 0 }) {
                            Text("Default")
                                .font(.headline)
                                .foregroundColor(selectedTab == 0 ? orange : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == 0 ? cardColor.opacity(0.7) : Color.clear)
                                .cornerRadius(12)
                        }
                        Button(action: { selectedTab = 1 }) {
                            Text("Custom")
                                .font(.headline)
                                .foregroundColor(selectedTab == 1 ? orange : .white.opacity(0.7))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == 1 ? cardColor.opacity(0.7) : Color.clear)
                                .cornerRadius(12)
                        }
                    }
                    .background(cardColor.opacity(0.5))
                    .cornerRadius(14)
                    .padding(.horizontal)
                    .padding(.top, 12)
                    
                    if selectedTab == 0 {
                        // Timeline + Block List
                        ScrollView(showsIndicators: false) {
                            ZStack(alignment: .leading) {
                                if filteredDefaultBlocks.count > 1 {
                                    GeometryReader { geo in
                                        let blockHeight: CGFloat = 76
                                        let spacing: CGFloat = 20
                                        let totalHeight = CGFloat(filteredDefaultBlocks.count) * blockHeight + CGFloat(filteredDefaultBlocks.count - 1) * spacing
                                        Rectangle()
                                            .fill(lightGrey.opacity(0.25))
                                            .frame(width: 2, height: totalHeight - blockHeight/2)
                                            .offset(x: 54, y: blockHeight/2)
                                    }
                                }
                                VStack(spacing: 20) {
                                    ForEach(filteredDefaultBlocks, id: \.self) { blockType in
                                        HStack(alignment: .center, spacing: 16) {
                                            ZStack {
                                                Circle()
                                                    .fill(orange)
                                                    .frame(width: 40, height: 40)
                                                Image(systemName: blockType.icon)
                                                    .foregroundColor(.white)
                                                    .font(.system(size: 22, weight: .bold))
                                            }
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(blockType.rawValue)
                                                    .font(.system(size: 17, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .lineLimit(2)
                                                    .truncationMode(.tail)
                                                    .fixedSize(horizontal: false, vertical: true)
                                                Text("\(blockType.defaultDuration) min")
                                                    .font(.system(size: 15, weight: .regular, design: .rounded))
                                                    .foregroundColor(lightGrey)
                                            }
                                            Spacer()
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
                                                ZStack {
                                                    Circle()
                                                        .fill(orange)
                                                        .frame(width: 36, height: 36)
                                                    Image(systemName: "plus")
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 20, weight: .bold))
                                                }
                                            }
                                        }
                                        .padding(.vertical, 18)
                                        .padding(.horizontal, 20)
                                        .background(
                                            RoundedRectangle(cornerRadius: 16)
                                                .fill(cardColor)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                        )
                                        .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                                        .frame(height: 76)
                                    }
                                }
                                .padding(.vertical, 24)
                                .padding(.bottom, 80)
                            }
                        }
                    } else {
                        // Custom block
                        VStack(spacing: 24) {
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(orange)
                                        .frame(width: 40, height: 40)
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.white)
                                        .font(.system(size: 22, weight: .bold))
                                }
                                TextField("Block name", text: $customName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            Stepper(value: $customDuration, in: 1...60) {
                                Text("Duration: \(customDuration) min")
                                    .font(.subheadline)
                                    .foregroundColor(lightGrey)
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
                                            .fill(orange)
                                    )
                            }
                            .disabled(customName.isEmpty)
                            Spacer()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(orange)
                }
            }
        }
    }
}

// MARK: - BellPickerView
struct BellPickerView: View {
    @State var selected: TransitionBell?
    var onSelect: (TransitionBell?) -> Void
    @Environment(\.dismiss) var dismiss
    let bells = ["None", "Soft Bell", "Tibetan Bowl", "Digital Chime"]
    
    let bgColor = Color(red: 34/255, green: 38/255, blue: 45/255) // #22262D
    let cardColor = Color(red: 42/255, green: 46/255, blue: 55/255) // #2A2E37
    let orange = Color(red: 1.0, green: 122/255, blue: 0) // #FF7A00
    let lightGrey = Color(red: 176/255, green: 176/255, blue: 176/255) // #B0B0B0
    
    var bellIcon: (String) -> String = { name in
        switch name {
        case "None": return "bell.slash.fill"
        case "Soft Bell": return "bell.fill"
        case "Tibetan Bowl": return "circle.grid.cross"
        case "Digital Chime": return "waveform"
        default: return "bell"
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                bgColor.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    ZStack(alignment: .leading) {
                        if bells.count > 1 {
                            GeometryReader { geo in
                                let blockHeight: CGFloat = 76
                                let spacing: CGFloat = 20
                                let totalHeight = CGFloat(bells.count) * blockHeight + CGFloat(bells.count - 1) * spacing
                                Rectangle()
                                    .fill(lightGrey.opacity(0.25))
                                    .frame(width: 2, height: totalHeight - blockHeight/2)
                                    .offset(x: 54, y: blockHeight/2)
                            }
                        }
                        VStack(spacing: 20) {
                            ForEach(bells, id: \.self) { name in
                                HStack(alignment: .center, spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(orange)
                                            .frame(width: 40, height: 40)
                                        Image(systemName: bellIcon(name))
                                            .foregroundColor(.white)
                                            .font(.system(size: 22, weight: .bold))
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(name)
                                            .font(.system(size: 17, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                    Spacer()
                                    if selected?.soundName == name || (selected == nil && name == "None") {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(orange)
                                            .font(.system(size: 24, weight: .bold))
                                    }
                                }
                                .padding(.vertical, 18)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(cardColor)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.07), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)
                                .frame(height: 76)
                                .onTapGesture {
                                    onSelect(name == "None" ? nil : TransitionBell(soundName: name))
                                    dismiss()
                                }
                            }
                        }
                        .padding(.vertical, 24)
                        .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Select Bell")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(orange)
                }
            }
        }
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
