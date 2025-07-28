import SwiftUI
import SwiftData

// PreferenceKey to capture each item's center X position
struct CarouselCellKey: PreferenceKey {
    static var defaultValue: [Int: CGFloat] = [:]
    static func reduce(value: inout [Int: CGFloat], nextValue: () -> [Int: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

struct RoutineSelectionCarousel: View {
    let routines: [SavedRoutine]
    let onRoutineSelected: (SavedRoutine) -> Void
    let currentlySelectedRoutine: SavedRoutine?
    
    @State private var positions: [Int: CGFloat] = [:]
    @State private var currentIndex: Int = 0
    @State private var lastSelectedIndex: Int = -1
    @State private var scrollOffset: CGFloat = 0
    @State private var isProgrammaticScroll: Bool = false
    
    private let itemWidth = UIScreen.main.bounds.width * 0.7
    private let spacing: CGFloat = 16
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView(.horizontal, showsIndicators: false) {
                ScrollViewReader { proxy in
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
                            
                            // // Routine Name
                            // Text(routine.routineName)
                            //     .font(AppTheme.Typography.captionFont)
                            //     .foregroundColor(AppTheme.offWhiteText)
                            //     .multilineTextAlignment(.center)
                            //     .lineLimit(2)
                            //     .frame(width: itemWidth * 0.8)
                        }
                        .frame(width: itemWidth)
                        .scaleEffect(currentIndex == index ? 1.0 : 0.8)
                        .animation(.easeInOut(duration: 0.2), value: currentIndex)

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
                .onAppear {
                    // Scroll to the selected routine when the view appears
                    if let selectedRoutine = currentlySelectedRoutine,
                       let selectedIndex = routines.firstIndex(where: { $0.id == selectedRoutine.id }) {
                        isProgrammaticScroll = true
                        proxy.scrollTo(selectedRoutine.id, anchor: .center)
                        // Reset the flag
                        isProgrammaticScroll = false
                    }
                }
            }
            }
            .onPreferenceChange(CarouselCellKey.self) { prefs in
                positions = prefs
                detectCenterItem()
            }
            .onAppear {
                // Find the index of the currently selected routine
                if let selectedRoutine = currentlySelectedRoutine,
                   let selectedIndex = routines.firstIndex(where: { $0.id == selectedRoutine.id }) {
                    // Set carousel to show the currently selected routine
                    currentIndex = selectedIndex
                    lastSelectedIndex = selectedIndex
                } else if !routines.isEmpty && lastSelectedIndex == -1 {
                    // Only auto-select first routine if no routine is currently selected
                    lastSelectedIndex = 0
                    onRoutineSelected(routines[0])
                }
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
                
                // Only provide haptic feedback for user-initiated scrolls
                if !isProgrammaticScroll {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                // Automatically select the centered routine
                if newIndex != lastSelectedIndex && newIndex < routines.count {
                    lastSelectedIndex = newIndex
                    onRoutineSelected(routines[newIndex])
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavedRoutine.self, configurations: config)
    
    let sampleRoutines = [
        SavedRoutine(routine: Routine(name: "Morning Meditation", icon: "sunrise.fill", blocks: [], openingBell: .softBell, closingBell: .digitalChime)),
        SavedRoutine(routine: Routine(name: "Evening Relaxation", icon: "moon.fill", blocks: [], openingBell: .tibetanBowl, closingBell: .softBell)),
        SavedRoutine(routine: Routine(name: "Quick Focus", icon: "brain.head.profile", blocks: [], openingBell: .digitalChime, closingBell: .tibetanBowl))
    ]
    
    return ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        RoutineSelectionCarousel(
            routines: sampleRoutines,
            onRoutineSelected: { routine in
                print("Auto-selected: \(routine.routineName)")
            },
            currentlySelectedRoutine: sampleRoutines.first
        )
    }
} 