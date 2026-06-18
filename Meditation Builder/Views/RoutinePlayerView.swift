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
    let title: String
    let onClose: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Close button - positioned at top right
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .foregroundColor(AppTheme.offWhiteText)
                        .font(.system(size: 20, weight: .medium))
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Close session")
                .position(x: geometry.size.width - 44, y: geometry.safeAreaInsets.top + 60)
                
                // Title - positioned at top center
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .foregroundColor(AppTheme.offWhiteText)
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
    let sessionStarted: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Large elapsed timer with TimelineView for efficiency
            if sessionStarted {
                TimelineView(.periodic(from: viewModel.routineStartDate, by: 1.0)) { context in
                    Text(viewModel.formatTime(viewModel.elapsedTime))
					.font(.system(size: 72, weight: .light, design: .default))
                        .foregroundColor(AppTheme.offWhiteText)
                        .monospacedDigit()
                        .accessibilityLabel("Elapsed time: \(viewModel.formatTime(viewModel.elapsedTime))")
                        .onChange(of: context.date) { _, newDate in
                            viewModel.updateCurrentTime(newDate)
                        }
                }
            } else {
                // Static display when session hasn't started
                Text(viewModel.formatTime(0))
					.font(.system(size: 72, weight: .light, design: .default))
                    .foregroundColor(.gray)
                    .monospacedDigit()
            }
            
            // Current block indicator or completion message
            if sessionStarted {
				if viewModel.isRoutineComplete {
					Text(LocalizedStringKey("routine.complete"))
						.font(.system(size: 17, weight: .regular, design: .default))
						.foregroundColor(AppTheme.offWhiteText.opacity(0.8))
						.lineLimit(2)
						.multilineTextAlignment(.center)
				} else if let current = viewModel.currentBlock {
					HStack(spacing: 0) {
						Text(current.name)
							.font(.system(size: 17, weight: .regular, design: .default))
							.foregroundColor(AppTheme.offWhiteText)
						
						if let next = viewModel.nextBlock {
							Text(" → ")
								.font(.system(size: 17, weight: .regular, design: .default))
								.foregroundColor(AppTheme.offWhiteText.opacity(0.6))
							
							Text(next.name)
								.font(.system(size: 17, weight: .regular, design: .default))
								.foregroundColor(AppTheme.offWhiteText.opacity(0.6))
						}
					}
					.lineLimit(2)
					.multilineTextAlignment(.center)
				}
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Player Controls View
struct PlayerControlsView: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    let onStartSession: (() -> Void)?
    
    init(viewModel: RoutinePlayerViewModel, onStartSession: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onStartSession = onStartSession
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Play/Pause button - always in the same position
                Button(action: {
                    if let onStartSession = onStartSession {
                        onStartSession()
                    } else {
                        viewModel.togglePause()
                    }
                }) {
                    let isPlay = onStartSession != nil || viewModel.isPaused
                    Image(systemName: isPlay ? "play.fill" : "pause.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(AppTheme.offWhiteText)
                        .frame(width: 88, height: 88)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(onStartSession != nil ? "Start session" : (viewModel.isPaused ? "Resume session" : "Pause session"))
                .accessibilityAddTraits(.isButton)
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

// MARK: - Breathing Light Background

struct BreathingLightView: View {
    let isPaused: Bool
    let routineIcon: String
    @State private var breatheScale: CGFloat = 1.0
    @State private var breatheOpacity: Double = 0.04
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Mesh gradient — soft organic breathing background
            MeshGradient(
                    width: 3,
                    height: 3,
                    points: meshPoints,
                    colors: meshColors
                )
                .ignoresSafeArea()
                .opacity(isPaused ? 0.3 : 0.55)
                .animation(.easeInOut(duration: 0.8), value: isPaused)

                // Faint routine icon watermark
                Image(systemName: routineIcon)
                    .font(.system(size: 200, weight: .ultraLight))
                    .foregroundColor(Color(red: 0.302, green: 0.714, blue: 0.675).opacity(0.04))
                    .scaleEffect(breatheScale)

                // Breathing glow ring
                if !reduceMotion {
                    Circle()
                        .stroke(Color(red: 0.302, green: 0.714, blue: 0.675).opacity(breatheOpacity), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(breatheScale * 1.3)
                    Circle()
                        .stroke(Color(red: 0.302, green: 0.714, blue: 0.675).opacity(breatheOpacity * 0.5), lineWidth: 1)
                        .frame(width: 220, height: 220)
                        .scaleEffect(breatheScale * 1.7)
                }
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                breatheScale = 1.1
                breatheOpacity = 0.12
            }
        }
        .onChange(of: isPaused) { _, paused in
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: paused ? 2.0 : 5.0).repeatForever(autoreverses: true)) {
                breatheScale = paused ? 1.03 : 1.1
                breatheOpacity = paused ? 0.05 : 0.12
            }
        }
    }

    private var meshPoints: [SIMD2<Float>] {
        [
            [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
            [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
            [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
        ]
    }

    private var meshColors: [Color] {
        let teal = Color(red: 0.15, green: 0.25, blue: 0.25)
        let deep = Color(red: 0.06, green: 0.08, blue: 0.08)
        return [
            deep, deep, deep,
            deep, teal, deep,
            deep, deep, deep
        ]
    }
}

// MARK: - State-Specific Views

struct PreSessionState: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    let onStartSession: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
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
			
            ZStack {
                // Player Header
                PlayerHeaderView(
                    title: viewModel.routineData.name,
                    onClose: onClose
                )
                
                // Pre-session content

				ZStack {
					// Show carousel if any routines are available
					if viewModel.savedRoutines.count >= 1 {
					// Routine selection carousel
						RoutineSelectionCarousel(
							routines: viewModel.savedRoutines,
							onRoutineSelected: { routine in
								viewModel.selectRoutine(routine)
							},
							currentlySelectedRoutine: viewModel.currentRoutine
						)
						.frame(height: 150)
					}
				}
				.position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 220)

				
				                // Timer Display - positioned at center
                TimerDisplayView(viewModel: viewModel, sessionStarted: false)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
				
				// Player Controls - positioned at center for pre-session
				PlayerControlsView(viewModel: viewModel, onStartSession: onStartSession)
					.position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
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
                // Breathing ambient background
                BreathingLightView(
                    isPaused: viewModel.isPaused,
                    routineIcon: viewModel.routineData.icon
                )

                // Player Header
                PlayerHeaderView(
                    title: viewModel.routineData.name,
                    onClose: onClose
                )
                
                // Timer Display - positioned at center
                TimerDisplayView(viewModel: viewModel, sessionStarted: true)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Player Controls - positioned at bottom
                PlayerControlsView(viewModel: viewModel, onStartSession: nil)
                
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
                if !sessionStarted {
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
        .sensoryFeedback(.impact(flexibility: .soft), trigger: viewModel.isPaused)
        .sensoryFeedback(.success, trigger: viewModel.isRoutineComplete)
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: viewModel.currentBlockIndex)
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
