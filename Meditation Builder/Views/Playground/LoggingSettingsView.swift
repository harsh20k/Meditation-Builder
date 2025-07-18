//
//  LoggingSettingsView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import os.log

struct LoggingSettingsView: View {
    @StateObject private var logger = AppLogger.shared
    @State private var showingLogViewer = false
    @State private var showingClearLogsAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.large) {
                    // Header
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 28, weight: .bold))
                        Text("Logging Settings")
                            .font(AppTheme.Typography.titleFont)
                            .foregroundColor(.white)
                        Spacer()
                        
                        // Test button
                        Button("Test") {
                            logger.info("Test log from settings", category: "Test")
                            logger.error("Test error log", category: "Test")
                            logger.debug("Test debug log", category: "Test")
                        }
                        .foregroundColor(.green)
                    }
                    .padding(.horizontal)
                    .padding(.top, AppTheme.Spacing.extraLarge)
                    
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.large) {
                            // Logging Toggle
                            SettingsCard {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                    HStack {
                                        Image(systemName: "toggle.on")
                                            .foregroundColor(AppTheme.accentColor)
                                            .font(.system(size: 20, weight: .medium))
                                        Text("Enable Logging")
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Toggle("", isOn: $logger.isLoggingEnabled)
                                            .onChange(of: logger.isLoggingEnabled) { _, newValue in
                                                logger.info("Logging \(newValue ? "enabled" : "disabled")", category: "Settings")
                                                logger.saveSettings()
                                            }
                                    }
                                    
                                    Text("Enable or disable logging throughout the app")
                                        .font(AppTheme.Typography.bodyFont)
                                        .foregroundColor(AppTheme.lightGrey)
                                }
                            }
                            
                            // Log Level Selection
                            SettingsCard {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                    HStack {
                                        Image(systemName: "slider.horizontal.3")
                                            .foregroundColor(AppTheme.accentColor)
                                            .font(.system(size: 20, weight: .medium))
                                        Text("Log Level")
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    
                                    Text("Select the minimum log level to record")
                                        .font(AppTheme.Typography.bodyFont)
                                        .foregroundColor(AppTheme.lightGrey)
                                    
                                    Picker("Log Level", selection: $logger.currentLogLevel) {
                                        ForEach(AppLogger.LogLevel.allCases, id: \.self) { level in
                                            HStack {
                                                Text(level.emoji)
                                                Text(level.rawValue)
                                            }
                                            .tag(level)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .onChange(of: logger.currentLogLevel) { _, newLevel in
                                        logger.info("Log level changed to: \(newLevel.rawValue)", category: "Settings")
                                        logger.saveSettings()
                                    }
                                }
                            }
                            
                            // Log Actions
                            SettingsCard {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                    HStack {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .foregroundColor(AppTheme.accentColor)
                                            .font(.system(size: 20, weight: .medium))
                                        Text("Log Management")
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    
                                    VStack(spacing: AppTheme.Spacing.small) {
                                        Button(action: { showingLogViewer = true }) {
                                            HStack {
                                                Image(systemName: "eye")
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("View Recent Logs")
                                                    .font(AppTheme.Typography.bodyFont)
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                            .foregroundColor(.white)
                                            .padding(.vertical, AppTheme.Spacing.small)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        
                                        Divider()
                                            .background(AppTheme.lightGrey.opacity(0.3))
                                        
                                        Button(action: { showingClearLogsAlert = true }) {
                                            HStack {
                                                Image(systemName: "trash")
                                                    .font(.system(size: 16, weight: .medium))
                                                Text("Clear All Logs")
                                                    .font(AppTheme.Typography.bodyFont)
                                                Spacer()
                                            }
                                            .foregroundColor(.red)
                                            .padding(.vertical, AppTheme.Spacing.small)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            
                            // Log Info
                            SettingsCard {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(AppTheme.accentColor)
                                            .font(.system(size: 20, weight: .medium))
                                        Text("About Logging")
                                            .font(AppTheme.Typography.headlineFont)
                                            .foregroundColor(.white)
                                        Spacer()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                                        Text("• Logs are stored locally on your device")
                                            .font(AppTheme.Typography.bodyFont)
                                            .foregroundColor(AppTheme.lightGrey)
                                        Text("• Log files are automatically rotated when they reach 5MB")
                                            .font(AppTheme.Typography.bodyFont)
                                            .foregroundColor(AppTheme.lightGrey)
                                        Text("• Only the 10 most recent log files are kept")
                                            .font(AppTheme.Typography.bodyFont)
                                            .foregroundColor(AppTheme.lightGrey)
                                        Text("• Debug logs are only shown in debug builds")
                                            .font(AppTheme.Typography.bodyFont)
                                            .foregroundColor(AppTheme.lightGrey)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, AppTheme.Spacing.extraLarge)
                    }
                }
            }
        }
        .sheet(isPresented: $showingLogViewer) {
            LogViewerView()
        }
        .alert("Clear All Logs", isPresented: $showingClearLogsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                logger.clearAllLogs()
            }
        } message: {
            Text("This will permanently delete all log files. This action cannot be undone.")
        }
    }
}

// MARK: - Settings Card
struct SettingsCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppTheme.Spacing.large)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .fill(AppTheme.cardColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.large)
                    .stroke(Color.white.opacity(AppTheme.Opacity.border), lineWidth: 1)
            )
    }
}

// MARK: - Log Viewer
struct LogViewerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var recentLogs: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                
                VStack {
                    // Log content
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                            ForEach(recentLogs, id: \.self) { logEntry in
                                Text(logEntry)
                                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, AppTheme.Spacing.medium)
                                    .padding(.vertical, AppTheme.Spacing.small)
                                    .background(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .fill(AppTheme.cardColor.opacity(0.5))
                                    )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Recent Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadRecentLogs()
                    }
                    .foregroundColor(AppTheme.accentColor)
                }
            }
        }
        .onAppear {
            loadRecentLogs()
        }
    }
    
    private func loadRecentLogs() {
        recentLogs = logger.getRecentLogs(limit: 100)
    }
}

#Preview {
    LoggingSettingsView()
} 