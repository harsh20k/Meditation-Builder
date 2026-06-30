//
//  CustomTabBar.swift
//  Meditation Builder
//

import SwiftUI

enum TabSelection: Hashable {
	case library
	case community
	case timer
	case settings
	case create

	static let mainTabs: [TabSelection] = [.library, .community, .timer, .settings]

	var icon: String {
		switch self {
		case .library:   return "books.vertical.fill"
		case .community: return "person.3.fill"
		case .timer:     return "timer"
		case .settings:  return "gearshape"
		case .create:    return "plus"
		}
	}

	var title: String {
		switch self {
		case .library:   return String(localized: "tab.library")
		case .community: return String(localized: "tab.community")
		case .timer:     return String(localized: "tab.timer")
		case .settings:  return String(localized: "tab.settings")
		case .create:    return String(localized: "tab.create")
		}
	}

	var titleKey: LocalizedStringKey {
		switch self {
		case .library:   return LocalizedStringKey("tab.library")
		case .community: return LocalizedStringKey("tab.community")
		case .timer:     return LocalizedStringKey("tab.timer")
		case .settings:  return LocalizedStringKey("tab.settings")
		case .create:    return LocalizedStringKey("tab.create")
		}
	}
}

struct CustomTabBar: View {
	@Binding var selectedTab: TabSelection
	@State private var pressedTab: TabSelection?
	@State private var tabTapHapticTrigger = 0
	@Namespace private var selectionNamespace
	var onTabTap: ((TabSelection) -> Void)?
	var onCreateTap: (() -> Void)?

	private let barShape = RoundedRectangle(cornerRadius: 28, style: .continuous)

	var body: some View {
		HStack(alignment: .center, spacing: 10) {
			mainTabSection

			if onCreateTap != nil {
				createAccessoryButton
			}
		}
		.padding(.horizontal, 20)
		.padding(.top, 4)
		.padding(.bottom, 8)
		.sensoryFeedback(.selection, trigger: tabTapHapticTrigger)
	}

	@ViewBuilder
	private var mainTabSection: some View {
		if #available(iOS 26.0, *) {
			GlassEffectContainer(spacing: 4) {
				tabRow
					.padding(6)
			}
			.glassEffect(.clear, in: barShape)
		} else {
			tabRow
				.padding(6)
				.liquidGlassFallback(in: barShape)
		}
	}

	private var tabRow: some View {
		HStack(spacing: 4) {
			ForEach(TabSelection.mainTabs, id: \.self) { tab in
				tabButton(for: tab)
			}
		}
	}

	private func tabButton(for tab: TabSelection) -> some View {
		Button {
			tabTapHapticTrigger += 1
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

	@ViewBuilder
	private var createAccessoryButton: some View {
		if #available(iOS 26.0, *) {
			Button {
				tabTapHapticTrigger += 1
				onCreateTap?()
			} label: {
				Image(systemName: "plus")
					.font(.system(size: 17, weight: .semibold))
					.frame(width: 52, height: 52)
			}
			.buttonStyle(.glassProminent)
			.buttonBorderShape(.circle)
			.controlSize(.small)
			.tint(AppTheme.accentColor)
			.accessibilityLabel("Create new ritual")
		} else {
			AppTheme.floatingActionButton(icon: "plus") {
				tabTapHapticTrigger += 1
				onCreateTap?()
			}
			.accessibilityLabel("Create new ritual")
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
