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
	@Namespace private var selectionNamespace
	var onTabTap: ((TabSelection) -> Void)?

	private let barShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

	var body: some View {
		Group {
			if #available(iOS 26.0, *) {
				liquidGlassBar
			} else {
				legacyGlassBar
			}
		}
		.padding(.horizontal, 20)
		.padding(.top, 4)
		.padding(.bottom, 8)
		.sensoryFeedback(.selection, trigger: selectedTab)
	}

	@available(iOS 26.0, *)
	private var liquidGlassBar: some View {
		GlassEffectContainer(spacing: 4) {
			tabRow
				.padding(6)
		}
		.glassEffect(.clear, in: barShape)
	}

	private var legacyGlassBar: some View {
		tabRow
			.padding(6)
	}

	private var tabRow: some View {
		HStack(spacing: 4) {
			ForEach(TabSelection.allCases, id: \.self) { tab in
				tabButton(for: tab)
			}
		}
	}

	private func tabButton(for tab: TabSelection) -> some View {
		Button {
			onTabTap?(tab)
		} label: {
			VStack(spacing: 3) {
				Image(systemName: tab.icon)
					.font(.system(size: 17, weight: .semibold))
					.scaleEffect(pressedTab == tab ? 0.88 : 1.0)
					.symbolEffect(.bounce.down, value: selectedTab == tab)

				Text(tab.titleKey)
					.font(.system(size: 10, weight: selectedTab == tab ? .semibold : .regular, design: .serif))
					.lineLimit(1)
					.minimumScaleFactor(0.8)
			}
			.foregroundStyle(
				selectedTab == tab ? Color.white : AppTheme.offWhiteText.opacity(0.85)
			)
			.frame(maxWidth: .infinity)
			.padding(.vertical, 10)
			.padding(.horizontal, 2)
			.background {
				if selectedTab == tab {
					selectionPill
				}
			}
			.animation(.bouncy(duration: 0.32), value: selectedTab)
			.contentShape(Rectangle())
		}
		.buttonStyle(.plain)
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

	@ViewBuilder
	private var selectionPill: some View {
		if #available(iOS 26.0, *) {
			Capsule()
				.fill(.clear)
				.glassEffect(.regular.interactive(), in: Capsule())
				.glassEffectID("tabSelection", in: selectionNamespace)
		} else {
			Capsule()
				.fill(Color.white.opacity(0.14))
		}
	}
}

#if DEBUG
struct CustomTabBar_Previews: PreviewProvider {
	struct PreviewWrapper: View {
		@State private var selectedTab: TabSelection = .library

		var body: some View {
			ZStack {
				AppTheme.backgroundColor.ignoresSafeArea()
				VStack {
					Spacer()
					CustomTabBar(
						selectedTab: $selectedTab,
						onTabTap: { tab in selectedTab = tab }
					)
				}
			}
			.preferredColorScheme(.dark)
		}
	}

	static var previews: some View {
		PreviewWrapper()
	}
}
#endif
