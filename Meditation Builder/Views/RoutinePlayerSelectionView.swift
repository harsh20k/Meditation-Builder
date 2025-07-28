import SwiftUI
import SwiftData

// PreferenceKey to capture each item's center X position
struct CarouselCellKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct RoutinePlayerSelectionView: View {
    @Bindable var viewModel: RoutinePlayerViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Beads Progress Indicator
                    BeadsView(
                        currentBlockIndex: 0,
                        totalBlocks: 0,
                        inBlockProgress: 0.0,
                        blockStartDate: Date(),
                        isRoutineSelected: false,
                        isPlaying: false
                    )
                    .padding(.top, geometry.safeAreaInsets.top + 60)
                    
                    // Spacer to push carousel to vertical center
                    Spacer()
                    
                    // New Carousel Implementation
                    RoutineCarouselView(
                        routines: viewModel.savedRoutines,
                        onRoutineSelected: { routine in
                            viewModel.selectRoutine(routine)
                        }
                    )
                    .frame(height: 200) // Increased height for better visibility
                    
                    // Spacer for bottom padding
                    Spacer()
                }
            }
        }
    }
}

struct RoutineCarouselView: View {
    let routines: [SavedRoutine]
    let onRoutineSelected: (SavedRoutine) -> Void
    
    @State private var positions: [Int: CGFloat] = [:]
    @State private var currentIndex: Int = 0
    
    private let itemWidth = UIScreen.main.bounds.width * 0.7
    private let spacing: CGFloat = 16
    
    var body: some View {
        VStack(spacing: 24) {
            // Display the currently centered routine name
            if !routines.isEmpty {
                Text(routines[currentIndex].routineName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.offWhiteText)
                    .padding(.top, 4)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing) {
                    ForEach(Array(routines.enumerated()), id: \.element.id) { index, routine in
                        VStack(spacing: 12) {
                            // Icon Circle
                            ZStack {
                                Circle()
                                    .fill(AppTheme.cardColor)
                                    .frame(width: itemWidth * 0.6, height: itemWidth * 0.6)
                                
                                Image(systemName: routine.routineIcon)
                                    .font(.system(size: 32, weight: .ultraLight))
                                    .foregroundColor(AppTheme.accentColor)
                            }
                            
                            // Routine Name
                            Text(routine.routineName)
                                .font(AppTheme.Typography.captionFont)
                                .foregroundColor(AppTheme.offWhiteText)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .frame(width: itemWidth * 0.8)
                        }
                        .frame(width: itemWidth)
                        .scaleEffect(currentIndex == index ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        .onTapGesture {
                            onRoutineSelected(routine)
                        }
                        // Capture each card's center X
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: CarouselCellKey.self,
                                    value: [index: geo.frame(in: .global).midX]
                                )
                            }
                        )
                    }
                }
                .padding(.horizontal, (UIScreen.main.bounds.width - itemWidth) / 2)
            }
            .onPreferenceChange(CarouselCellKey.self) { prefs in
                positions = prefs
                detectCenterItem()
            }
        }
    }
    
    /// Finds which item is nearest the screen center and triggers a light haptic when it changes.
    private func detectCenterItem() {
        let screenCenter = UIScreen.main.bounds.width / 2
        if let nearest = positions.min(by: { abs($0.value - screenCenter) < abs($1.value - screenCenter) }) {
            let newIndex = nearest.key
            if newIndex != currentIndex {
                currentIndex = newIndex
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavedRoutine.self, configurations: config)
    let viewModel = RoutinePlayerViewModel(modelContext: container.mainContext)
    
    return RoutinePlayerSelectionView(viewModel: viewModel)
} 
