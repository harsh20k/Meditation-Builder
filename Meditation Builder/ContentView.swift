//
//  ContentView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch colorSchemeRaw {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        MainTabView()
            .preferredColorScheme(preferredColorScheme)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
