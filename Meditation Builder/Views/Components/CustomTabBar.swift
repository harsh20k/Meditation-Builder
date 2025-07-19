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
	
	var body: some View {
		HStack(spacing: 0) {
			ForEach(TabSelection.allCases, id: \.self) { tab in
				Button(action: {
					selectedTab = tab
				}) {
					HStack(spacing: 8) {
						Image(systemName: tab.icon)
							.font(.system(size: 20, weight: .medium))
							.foregroundColor(selectedTab == tab ? AppTheme.accentColor : .gray)
					}
					.padding(.horizontal, 12)
					.padding(.vertical, 8)
				}
				.buttonStyle(PlainButtonStyle())
				
				if tab != TabSelection.allCases.last {
					Spacer()
				}
			}
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 8)
		.background(
			RoundedRectangle(cornerRadius: AppTheme.CornerRadius.button)
				.fill(AppTheme.tabBar)
				.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
		)
		.frame(height: 48)
		.padding(.horizontal, 20)
		.padding(.bottom, 0)
			// Apply background color and a slight blur for a softer look
		.background(
			AppTheme.backgroundColor
				.blur(radius: 8)
		)
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
				CustomTabBar(selectedTab: $selectedTab)
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
