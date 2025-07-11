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
        case .library: return "Library"
        case .music: return "Music"
        case .timer: return "Timer"
        case .tools: return "Tools"
        case .settings: return "Settings"
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