	//
	//  CustomTabBar.swift
	//  Meditation Builder
	//
	//  Created by harsh  on 09/07/25.
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
		case .library: return "books.vertical.fill"
		case .music: return "music.note"
		case .timer: return "timer"
		case .history: return "clock.arrow.circlepath"
		case .settings: return "gearshape"
		}
	}
	
	var title: String {
		switch self {
		case .library: return String(localized: "tab.library")
		case .music: return String(localized: "tab.music")
		case .timer: return String(localized: "tab.timer")
		case .history: return "History"
		case .settings: return String(localized: "tab.settings")
		}
	}
	
	var titleKey: LocalizedStringKey {
		switch self {
		case .library: return LocalizedStringKey("tab.library")
		case .music: return LocalizedStringKey("tab.music")
		case .timer: return LocalizedStringKey("tab.timer")
		case .history: return LocalizedStringKey("History")
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
					// Call the callback instead of directly setting selectedTab
					onTabTap?(tab)
				}) {
					HStack(spacing: 8) {
						Image(systemName: tab.icon)
							.font(.system(size: 20, weight: .medium))
							.foregroundColor(selectedTab == tab ? AppTheme.accentColor : .gray)
							.scaleEffect(pressedTab == tab ? 0.9 : 1.0)
							.animation(.easeInOut(duration: 0.1), value: pressedTab)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
					.background(
						RoundedRectangle(cornerRadius: 8)
							.fill(pressedTab == tab ? AppTheme.accentColor.opacity(0.2) : Color.clear)
							.animation(.easeInOut(duration: 0.1), value: pressedTab)
					)
				}
				.buttonStyle(PlainButtonStyle())
				.simultaneousGesture(
					DragGesture(minimumDistance: 0)
						.onChanged { _ in
							withAnimation(.easeInOut(duration: 0.1)) {
								pressedTab = tab
							}
						}
						.onEnded { _ in
							withAnimation(.easeInOut(duration: 0.1)) {
								pressedTab = nil
							}
						}
				)
				
				if tab != TabSelection.allCases.last {
					Spacer()
				}
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.background(AppTheme.tabBar)
		.frame(height: 48)
		.ignoresSafeArea(edges: .bottom)
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
					onTabTap: { tab in
						selectedTab = tab
					}
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
				.preferredColorScheme(.light)
			PreviewWrapper()
				.preferredColorScheme(.dark)
		}
	}
}
#endif
