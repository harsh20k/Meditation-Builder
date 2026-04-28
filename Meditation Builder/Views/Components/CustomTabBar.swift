	//
	//  CustomTabBar.swift
	//  Meditation Builder
	//

import SwiftUI

enum TabSelection: Int, CaseIterable {
	case library = 0
	case music = 1
	case timer = 2
	case history = 3
	case settings = 4

	var icon: String {
		switch self {
		case .library:  return "books.vertical.fill"
		case .music:    return "waveform"
		case .timer:    return "timer"
		case .history:  return "clock.arrow.circlepath"
		case .settings: return "gearshape"
		}
	}

	var title: String {
		switch self {
		case .library:  return String(localized: "tab.library")
		case .music:    return String(localized: "tab.sounds")
		case .timer:    return String(localized: "tab.timer")
		case .history:  return String(localized: "tab.history")
		case .settings: return String(localized: "tab.settings")
		}
	}

	var titleKey: LocalizedStringKey {
		switch self {
		case .library:  return LocalizedStringKey("tab.library")
		case .music:    return LocalizedStringKey("tab.sounds")
		case .timer:    return LocalizedStringKey("tab.timer")
		case .history:  return LocalizedStringKey("tab.history")
		case .settings: return LocalizedStringKey("tab.settings")
		}
	}
}

struct CustomTabBar: View {
	@Binding var selectedTab: TabSelection
	@State private var pressedTab: TabSelection?
	var onTabTap: ((TabSelection) -> Void)?

	var body: some View {
		HStack(spacing: 0) {
			ForEach(TabSelection.allCases, id: \.self) { tab in
				Button(action: {
					onTabTap?(tab)
				}) {
					VStack(spacing: 3) {
						Image(systemName: tab.icon)
							.font(.system(size: 18, weight: .medium))
							.foregroundColor(selectedTab == tab ? AppTheme.accentColor : AppTheme.lightGrey)
							.scaleEffect(pressedTab == tab ? 0.88 : 1.0)
							.symbolEffect(.bounce.down, value: selectedTab == tab)
						Text(tab.titleKey)
							.font(.system(size: 10, weight: selectedTab == tab ? .medium : .regular, design: .serif))
							.foregroundColor(selectedTab == tab ? AppTheme.accentColor : AppTheme.lightGrey)
					}
					.frame(maxWidth: .infinity)
					.padding(.top, 8)
					.padding(.bottom, 4)
					.contentShape(Rectangle())
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(pressedTab == tab ? AppTheme.accentColor.opacity(0.1) : Color.clear)
							.animation(.easeInOut(duration: 0.1), value: pressedTab)
					)
				}
				.buttonStyle(PlainButtonStyle())
				.accessibilityLabel(tab.title)
				.accessibilityAddTraits(selectedTab == tab ? [.isButton, .isSelected] : .isButton)
				.simultaneousGesture(
					DragGesture(minimumDistance: 0)
						.onChanged { _ in
							withAnimation(.easeInOut(duration: 0.1)) { pressedTab = tab }
						}
						.onEnded { _ in
							withAnimation(.easeInOut(duration: 0.1)) { pressedTab = nil }
						}
				)
			}
		}
		.padding(.horizontal, 4)
		.background(AppTheme.tabBar)
		.sensoryFeedback(.selection, trigger: selectedTab)
	}
}

#if DEBUG
struct CustomTabBar_Previews: PreviewProvider {
	struct PreviewWrapper: View {
		@State private var selectedTab: TabSelection = .library

		var body: some View {
			VStack {
				Spacer()
				CustomTabBar(
					selectedTab: $selectedTab,
					onTabTap: { tab in selectedTab = tab }
				)
			}
			.background(AppTheme.backgroundColor)
			.previewLayout(.sizeThatFits)
			.padding()
		}
	}

	static var previews: some View {
		Group {
			PreviewWrapper()
				.preferredColorScheme(.dark)
		}
	}
}
#endif
