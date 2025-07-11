//
//  CustomTabBar.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct CustomTabBar: View {
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Image(systemName: "music.note")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor)
                    .frame(width: 44, height: 44)
                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "hammer")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
            Image(systemName: "gearshape")
                .font(.system(size: 24, weight: .regular))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .frame(height: 56)
        .background(AppTheme.backgroundColor)
        .ignoresSafeArea(edges: .bottom)
    }
} 