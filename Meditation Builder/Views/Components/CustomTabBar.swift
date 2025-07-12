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
    case tools = 3
    case settings = 4
    
    var icon: String {
        switch self {
        case .library: return "books.vertical.fill"
        case .music: return "music.note"
        case .timer: return "timer"
        case .tools: return "hammer"
        case .settings: return "gearshape"
        }
    }
    
    var title: String {
        switch self {
        case .library: return String(localized: "tab.library")
        case .music: return String(localized: "tab.music")
        case .timer: return String(localized: "tab.timer")
        case .tools: return String(localized: "tab.tools")
        case .settings: return String(localized: "tab.settings")
        }
    }
    
    var titleKey: LocalizedStringKey {
        switch self {
        case .library: return LocalizedStringKey("tab.library")
        case .music: return LocalizedStringKey("tab.music")
        case .timer: return LocalizedStringKey("tab.timer")
        case .tools: return LocalizedStringKey("tab.tools")
        case .settings: return LocalizedStringKey("tab.settings")
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: TabSelection
    
    var body: some View {
        HStack {
            ForEach(TabSelection.allCases, id: \.self) { tab in
                Spacer()
                
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        if tab == .timer {
                            // Special styling for the timer tab (center tab)
                            ZStack {
                                Circle()
                                    .fill(selectedTab == tab ? AppTheme.accentColor : AppTheme.accentColor)
                                    .frame(width: 44, height: 44)
                                Image(systemName: tab.icon)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        } else {
                            Image(systemName: tab.icon)
                                .font(.system(size: 24, weight: .regular))
                                .foregroundColor(selectedTab == tab ? AppTheme.accentColor : .white.opacity(0.7))
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
            }
        }
        .frame(height: 56)
        .background(AppTheme.backgroundColor)
        .ignoresSafeArea(edges: .bottom)
    }
} 