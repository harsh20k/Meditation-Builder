//
//  AnimationPlaygroundView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct AnimationPlaygroundView: View {
    @State private var currentBlockIndex: Int = 2
    @State private var totalBlocks: Int = 5
    @State private var inBlockProgress: Double = 0.6
    @State private var blockStartDate: Date = Date()
    
    // Bounce rise animation controls
    @State private var animationDuration: Double = 1.5
    @State private var bounceIntensity: Double = 2.0
    
    // Auto simulation
    @State private var autoLoop: Bool = true
    @State private var loopDelay: Double = 1.0
    @State private var simulationTimer: Timer?
    @State private var isAnimating: Bool = false
    
    private var completedCount: Int {
        currentBlockIndex
    }
    
    private var remainingCount: Int {
        max(0, totalBlocks - currentBlockIndex - 1)
    }
    
    var body: some View {
        ZStack {
            // Black background like timer view
            Color.black.ignoresSafeArea(.all)
            
            VStack(spacing: 20) {
                // Title
                Text("Block Completion Animations")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Main animation area
                ZStack {
                    // Use BlockProgressIndicator with bounce rise animation
//                    BlockProgressIndicator(
//                        currentBlockIndex: currentBlockIndex,
//                        totalBlocks: totalBlocks,
//                        inBlockProgress: inBlockProgress,
//                        blockStartDate: blockStartDate,
//                        enableBreathing: false,
//                        enableBounceRise: true,
//                        bounceRiseDuration: animationDuration,
//                        bounceRiseIntensity: bounceIntensity
//
//                    )
//                    .scaleEffect(1.5) // Make it larger for better visibility
                }
                .frame(height: 250) // Fixed height for animation area
                
                // Controls section - properly scrollable
                ScrollView {
                    VStack(spacing: 16) {
                        // Block controls
                        VStack(spacing: 8) {
                            Text("Block Settings")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            HStack {
                                Text("Current Block:")
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(currentBlockIndex)", value: $currentBlockIndex, in: 0...totalBlocks-1)
                                    .accentColor(.cyan)
                            }
                            
                            HStack {
                                Text("Total Blocks:")
                                    .foregroundColor(.white)
                                Spacer()
                                Stepper("\(totalBlocks)", value: $totalBlocks, in: 3...8)
                                    .accentColor(.cyan)
                            }
                            
                            VStack(spacing: 4) {
                                Text("Progress: \(Int(inBlockProgress * 100))%")
                                    .foregroundColor(.white)
                                HStack {
                                    Text("0%").foregroundColor(.white.opacity(0.6)).font(.caption)
                                    Slider(value: $inBlockProgress, in: 0...1)
                                        .accentColor(.cyan)
                                    Text("100%").foregroundColor(.white.opacity(0.6)).font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Bounce Rise Animation Controls
                        VStack(spacing: 8) {
                            Text("Bounce Rise Animation")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            VStack(spacing: 4) {
                                Text("Animation Duration: \(animationDuration, specifier: "%.1f")s")
                                    .foregroundColor(.white)
                                HStack {
                                    Text("0.5s").foregroundColor(.white.opacity(0.6)).font(.caption)
                                    Slider(value: $animationDuration, in: 0.5...3.0)
                                        .accentColor(.cyan)
                                    Text("3.0s").foregroundColor(.white.opacity(0.6)).font(.caption)
                                }
                            }
                            
                            VStack(spacing: 4) {
                                Text("Bounce Intensity: \(bounceIntensity, specifier: "%.1f")x")
                                    .foregroundColor(.white)
                                HStack {
                                    Text("1.0x").foregroundColor(.white.opacity(0.6)).font(.caption)
                                    Slider(value: $bounceIntensity, in: 1.0...3.0)
                                        .accentColor(.cyan)
                                    Text("3.0x").foregroundColor(.white.opacity(0.6)).font(.caption)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Auto loop control
                        VStack(spacing: 8) {
                            Toggle("Auto Progress Simulation", isOn: $autoLoop)
                                .foregroundColor(.white)
                                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            
                            if autoLoop {
                                VStack(spacing: 4) {
                                    Text("Loop Delay: \(loopDelay, specifier: "%.1f")s")
                                        .foregroundColor(.white.opacity(0.7))
                                    HStack {
                                        Text("0.2s").foregroundColor(.white.opacity(0.6)).font(.caption)
                                        Slider(value: $loopDelay, in: 0.2...3.0)
                                            .accentColor(.cyan.opacity(0.7))
                                        Text("3.0s").foregroundColor(.white.opacity(0.6)).font(.caption)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Manual test buttons
                        VStack(spacing: 12) {
                            Text("Manual Controls")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            HStack(spacing: 12) {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        inBlockProgress = min(inBlockProgress + 0.2, 1.0)
                                    }
                                }) {
                                    Text("Progress +20%")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.cyan)
                                        .cornerRadius(6)
                                }
                                
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        inBlockProgress = max(inBlockProgress - 0.2, 0.0)
                                    }
                                }) {
                                    Text("Progress -20%")
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.cyan.opacity(0.7))
                                        .cornerRadius(6)
                                }
                            }
                            
                            Button(action: {
                                resetProgress()
                            }) {
                                Text("Reset Progress")
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.red.opacity(0.7))
                                    .cornerRadius(6)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Bounce Rise Animation")
                                .foregroundColor(.white)
                                .font(.headline)
                            
                            Text("The bounce rise animation creates a spring-based bouncing effect on the progress indicators as they fill up. Each indicator bounces sequentially as progress moves through them, creating a lively and engaging visual feedback.")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(8)
                        
                        // Spacer for bottom padding
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                }
                .background(Color.clear)
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .onAppear {
            if autoLoop {
                startAutoLoop()
            }
        }
        .onDisappear {
            stopAutoLoop()
        }
        .onChange(of: autoLoop) { _, newValue in
            if newValue {
                startAutoLoop()
            } else {
                stopAutoLoop()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func resetProgress() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentBlockIndex = 0
            inBlockProgress = 0.0
            blockStartDate = Date()
        }
    }
    
    // MARK: - Auto Loop Simulation
    
    private func startAutoLoop() {
        guard autoLoop else { return }
        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            withAnimation(.linear(duration: 0.1)) {
                inBlockProgress += 0.02 // Slow progress increment
                if inBlockProgress >= 1.0 {
                    // Complete current block and move to next
                    if currentBlockIndex < totalBlocks - 1 {
                        currentBlockIndex += 1
                        inBlockProgress = 0.0
                        blockStartDate = Date()
                    } else {
                        // Reset when all blocks are completed
                        DispatchQueue.main.asyncAfter(deadline: .now() + loopDelay) {
                            currentBlockIndex = 0
                            inBlockProgress = 0.0
                            blockStartDate = Date()
                        }
                    }
                }
            }
        }
    }
    
    private func stopAutoLoop() {
        simulationTimer?.invalidate()
        simulationTimer = nil
    }
}

#Preview {
    AnimationPlaygroundView()
} 
