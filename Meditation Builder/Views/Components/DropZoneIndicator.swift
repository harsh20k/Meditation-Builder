//
//  DropZoneIndicator.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI

struct DropZoneIndicator: View {
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // Left line
            Rectangle()
                .fill(AppTheme.accentColor)
                .frame(width: 2, height: 20)
                .cornerRadius(1)
            
            // Center dot
            Circle()
                .fill(AppTheme.accentColor)
                .frame(width: 8, height: 8)
                .padding(.horizontal, 8)
            
            // Right line
            Rectangle()
                .fill(AppTheme.accentColor)
                .frame(width: 2, height: 20)
                .cornerRadius(1)
        }
        .opacity(isActive ? 1.0 : 0.0)
        .scaleEffect(isActive ? 1.0 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

#Preview("DropZoneIndicator") {
    ZStack {
        AppTheme.backgroundColor.ignoresSafeArea()
        
        VStack(spacing: 20) {
            DropZoneIndicator(isActive: true)
            DropZoneIndicator(isActive: false)
        }
    }
} 