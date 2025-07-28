	//
	//  RoutinePlayerView.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
	//

import SwiftUI
import os.log
import SwiftData

// MARK: - Shared Player Layout
struct PlayerLayout<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea(.all, edges: .all)
                content
            }
        }
        .statusBarHidden(true)
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.all, edges: .all)
    }
}

// MARK: - Player Header View
struct PlayerHeaderView: View {
    let routineName: String
    let onClose: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Close button - positioned at top right
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .position(x: geometry.size.width - 44, y: geometry.safeAreaInsets.top + 60)
                
                // Routine Name - positioned at top center
                Text(routineName)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: geometry.size.width - 40)
                    .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 120)
            }
        }
    }
}

// MARK: - Timer Display View
struct TimerDisplayView: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Large elapsed timer with TimelineView for efficiency
            TimelineView(.periodic(from: viewModel.routineStartDate, by: 1.0)) { context in
                Text(viewModel.formatTime(viewModel.elapsedTime))
                    .font(.system(size: 72, weight: .bold, design: .default))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .onChange(of: context.date) { _, newDate in
                        viewModel.updateCurrentTime(newDate)
                    }
            }
            
            // Current block indicator or completion message
            if viewModel.isRoutineComplete {
                Text(LocalizedStringKey("routine.complete"))
                    .font(.system(size: 17, weight: .regular, design: .default))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            } else if let current = viewModel.currentBlock {
                HStack(spacing: 0) {
                    Text(current.name)
                        .font(.system(size: 17, weight: .regular, design: .default))
                        .foregroundColor(.white)
                    
                    if let next = viewModel.nextBlock {
                        Text(" → ")
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Text(next.name)
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .lineLimit(2)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Player Controls View
struct PlayerControlsView: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Play/Pause button - always in the same position
                Button(action: { viewModel.togglePause() }) {
                    Text(viewModel.isPaused ? "▶" : "❙❙")
                        .font(.system(size: 72, weight: .regular, design: .default))
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
                .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 180)
                
                // Pause state controls - shown with opacity animation
                if viewModel.isPaused {
                    VStack(spacing: 8) {
                        // End Session Button
                        Button(action: { viewModel.showingEndSessionAlert = true }) {
                            Text(LocalizedStringKey("button.end.session"))
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.black)
                                .frame(width: 120, height: 36)
                                .background(Color.white)
                                .cornerRadius(18)
                                .padding(8)
                        }
                        
                        // Discard Session Button
                        Button(action: { viewModel.showingDiscardSessionAlert = true }) {
                            Text(LocalizedStringKey("button.discard.session"))
                                .font(.system(size: 14, weight: .medium, design: .default))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 80)
                    .opacity(viewModel.isPaused ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isPaused)
                }
                
                // Finish button - shown when routine is complete
                if viewModel.isRoutineComplete {
                    Button(action: { viewModel.showingFinishAlert = true }) {
                        Text(LocalizedStringKey("button.finish"))
                            .font(.system(size: 14, weight: .medium, design: .default))
                            .foregroundColor(.black)
                            .frame(width: 120, height: 36)
                            .background(Color.white)
                            .cornerRadius(18)
                            .padding(8)
                    }
                    .position(x: geometry.size.width / 2, y: geometry.size.height - geometry.safeAreaInsets.bottom - 80)
                    .opacity(viewModel.isRoutineComplete ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.isRoutineComplete)
                }
            }
        }
    }
}

// MARK: - State-Specific Views

struct PreSessionState: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    let onStartSession: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Player Header
                PlayerHeaderView(
                    routineName: viewModel.routineData.name,
                    onClose: onClose
                )
                
                // Pre-session content
                VStack(spacing: 24) {
                    // Routine info
                    VStack(spacing: 16) {
                        Text(viewModel.routineData.name)
                            .font(.system(size: 28, weight: .bold, design: .default))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("\(viewModel.totalBlocks) blocks • \(viewModel.routineData.blocks.map(\.durationInMinutes).reduce(0, +)) minutes")
                            .font(.system(size: 17, weight: .regular, design: .default))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Large play button
                    Button(action: onStartSession) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.black)
                                .offset(x: 4, y: 0)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Beads Progress Indicator - positioned at top center
                BeadsView(
                    currentBlockIndex: 0,
                    totalBlocks: viewModel.totalBlocks,
                    inBlockProgress: 0.0,
                    blockStartDate: Date(),
                    isRoutineSelected: true,
                    isPlaying: false
                )
                .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 60)
            }
        }
    }
}

struct ActiveSessionState: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    let onClose: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Player Header
                PlayerHeaderView(
                    routineName: viewModel.routineData.name,
                    onClose: onClose
                )
                
                // Timer Display - positioned at center
                TimerDisplayView(viewModel: viewModel)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Player Controls - positioned at bottom
                PlayerControlsView(viewModel: viewModel)
                
                // Beads Progress Indicator - positioned at top center
                BeadsView(
                    currentBlockIndex: viewModel.currentBlockIndex,
                    totalBlocks: viewModel.totalBlocks,
                    inBlockProgress: viewModel.isRoutineComplete ? 1.0 : viewModel.inBlockProgress,
                    blockStartDate: viewModel.blockStartDate,
                    isRoutineSelected: true,
                    isPlaying: !viewModel.isPaused
                )
                .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 60)
            }
        }
    }
}

// MARK: - Main Routine Player View
struct RoutinePlayerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var viewModel: RoutinePlayerViewModel
    @State private var sessionStarted = false
    
    init(routine: SavedRoutine? = nil, modelContext: ModelContext) {
        _viewModel = State(initialValue: RoutinePlayerViewModel(routine: routine, modelContext: modelContext))
    }
    
    var body: some View {
        PlayerLayout {
            Group {
                if viewModel.routineData.blocks.isEmpty {
					RoutinePlayerSelectionView()
                } else if !sessionStarted {
                    PreSessionState(
                        viewModel: viewModel,
                        onStartSession: {
                            sessionStarted = true
                            viewModel.startTimer()
                        },
                        onClose: {
                            dismiss()
                        }
                    )
                } else {
                    ActiveSessionState(
                        viewModel: viewModel,
                        onClose: {
                            Task {
                                await viewModel.endSession(saveProgress: false)
                                dismiss()
                     
                            }
                        }
                    )
                }
            }
        }
        .onDisappear {
            if sessionStarted {
                viewModel.cleanup()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                if sessionStarted {
                    logger.info("App backgrounded - timer continues running", category: "Timer")
                }
            case .active:
                if sessionStarted {
                    logger.info("App returned to foreground - timer continues running", category: "Timer")
                }
            @unknown default:
                break
            }
        }
        .alert(LocalizedStringKey("alert.end.session.title"), isPresented: $viewModel.showingEndSessionAlert) {
            Button(LocalizedStringKey("button.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("button.end.session"), role: .destructive) {
                Task {
                    await viewModel.endSession(saveProgress: true)
                    dismiss()
                }
            }
        } message: {
            Text(LocalizedStringKey("alert.end.session.message"))
        }
        .alert(LocalizedStringKey("alert.discard.session.title"), isPresented: $viewModel.showingDiscardSessionAlert) {
            Button(LocalizedStringKey("button.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("button.discard"), role: .destructive) {
                Task {
                    await viewModel.endSession(saveProgress: false)
                    dismiss()
                }
            }
        } message: {
            Text(LocalizedStringKey("alert.discard.session.message"))
        }
        .alert(LocalizedStringKey("alert.finish.session.title"), isPresented: $viewModel.showingFinishAlert) {
            Button(LocalizedStringKey("button.cancel"), role: .cancel) { }
            Button(LocalizedStringKey("button.finish"), role: .destructive) {
                Task {
                    await viewModel.endSession(saveProgress: true)
                    dismiss()
                }
            }
        } message: {
            Text(LocalizedStringKey("alert.finish.session.message"))
        }
    }
}

#Preview {
    // Create a sample routine for preview
    let sampleRoutine = SavedRoutine(
        routine: Routine(
            name: "Morning Meditation",
            icon: "sunrise.fill",
            blocks: [
                RoutineBlock(name: "Breathwork", durationInMinutes: 1, type: .breathwork, blockStartBell: .softBell),
                RoutineBlock(name: "Chanting", durationInMinutes: 1, type: .chanting, blockStartBell: .tibetanBowl),
                RoutineBlock(name: "Silence", durationInMinutes: 1, type: .silence, blockStartBell: .silent)
            ],
            openingBell: .softBell,
            closingBell: .digitalChime
        )
    )
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavedRoutine.self, configurations: config)
    
    return RoutinePlayerView(routine: sampleRoutine, modelContext: container.mainContext)
}
