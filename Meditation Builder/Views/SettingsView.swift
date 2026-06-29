//
//  SettingsView.swift
//  Meditation Builder
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("colorScheme") private var colorSchemeRaw: String = "system"
    @AppStorage("accentColorHex") private var accentColorHex: String = "#5AC8FA"

    @State private var notificationManager = NotificationManager.shared
    @State private var showDeveloperSection = false
    @State private var showExportSheet = false
    @State private var exportedData: Data?
    @State private var showClearDataAlert = false
    @State private var showImportPicker = false

    @Environment(\.modelContext) private var modelContext
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        NavigationStack {
            settingsContent
        }
    }

    private var settingsContent: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 26, weight: .bold))
                        .accessibilityHidden(true)
                    Text(LocalizedStringKey("settings.title"))
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.medium)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.large) {
                        if authManager.canAccessMainApp {
                            accountSection
                        }
                        historySection
                        appearanceSection
                        notificationsSection
                        dataSection
                        aboutSection
                        developerSection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let data = exportedData {
                ShareLink(item: data, preview: SharePreview("sessions.json", image: Image(systemName: "doc.text"))) {
                    Label("Share Sessions", systemImage: "square.and.arrow.up")
                }
            }
        }
        .confirmationDialog("Clear All Data", isPresented: $showClearDataAlert) {
            Button("Clear All Sessions", role: .destructive) { clearAllSessions() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all session history. Routines will not be affected.")
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                sectionHeader(icon: "person.fill", title: String(localized: "settings.account.title"))

                Button {
                    authManager.signOut()
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .medium))
                        Text(LocalizedStringKey("settings.sign.out"))
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

    // MARK: - History Section

    private var historySection: some View {
        SettingsCard {
            NavigationLink {
                SessionHistoryView()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                    Text(LocalizedStringKey("tab.history"))
                        .font(AppTheme.Typography.bodyFont)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.lightGrey)
                }
                .foregroundColor(AppTheme.offWhiteText)
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                sectionHeader(icon: "paintbrush.fill", title: String(localized: "settings.appearance.title"))

                HStack {
                    Text(LocalizedStringKey("settings.color.scheme"))
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                    Picker(String(localized: "settings.color.scheme"), selection: $colorSchemeRaw) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }
                    .pickerStyle(.menu)
                    .tint(AppTheme.accentColor)
                }
            }
        }
    }

    // MARK: - Notifications Section

    private var notificationsSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                sectionHeader(icon: "bell.fill", title: String(localized: "settings.notifications.title"))

                HStack {
                    Text("Enable Daily Reminder")
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { notificationManager.reminderEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if granted { notificationManager.reminderEnabled = true }
                                }
                            } else {
                                notificationManager.reminderEnabled = false
                            }
                        }
                    ))
                    .tint(AppTheme.accentColor)
                    .labelsHidden()
                }

                if notificationManager.reminderEnabled {
                    HStack {
                        Text("Reminder Time")
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.offWhiteText)
                        Spacer()
                        DatePicker(
                            "",
                            selection: $notificationManager.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .tint(AppTheme.accentColor)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                if notificationManager.authorizationStatus == .denied {
                    Label("Notifications are disabled in Settings.", systemImage: "exclamationmark.triangle.fill")
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(.yellow)
                }
            }
                .animation(.easeInOut(duration: 0.2), value: notificationManager.reminderEnabled)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: notificationManager.reminderEnabled)
        }
    }

    // MARK: - Data Section

    private var dataSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                sectionHeader(icon: "externaldrive.fill", title: String(localized: "settings.data.title"))

                settingsRow(icon: "square.and.arrow.up", title: "Export Sessions") {
                    exportSessions()
                }

                Divider().background(AppTheme.lightGrey.opacity(0.3))

                settingsRow(icon: "trash.fill", title: "Clear Session History", isDestructive: true) {
                    showClearDataAlert = true
                }
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                sectionHeader(icon: "info.circle.fill", title: String(localized: "settings.about.title"))

                HStack {
                    Text("Version")
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                    Text(appVersion)
                        .font(AppTheme.Typography.bodyFont)
                        .foregroundColor(AppTheme.lightGrey)
                }

                Divider().background(AppTheme.lightGrey.opacity(0.3))

                Link(destination: URL(string: "https://example.com/privacy")!) {
                    HStack {
                        Text("Privacy Policy")
                            .font(AppTheme.Typography.bodyFont)
                            .foregroundColor(AppTheme.offWhiteText)
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(AppTheme.accentColor)
                            .font(.system(size: 14))
                    }
                }
            }
        }
    }

    // MARK: - Developer Section

    private var developerSection: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDeveloperSection.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(showDeveloperSection ? 90 : 0))
                        .foregroundColor(AppTheme.lightGrey)
                        .font(.system(size: 12, weight: .semibold))
                    Text(LocalizedStringKey("settings.developer.title"))
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.lightGrey)
                    Spacer()
                }
                .padding(.vertical, AppTheme.Spacing.small)
            }
            .buttonStyle(PlainButtonStyle())

            if showDeveloperSection {
                LoggingSettingsView()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentColor)
                .font(.system(size: 18, weight: .medium))
            Text(title)
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.offWhiteText)
            Spacer()
        }
    }

    private func settingsRow(icon: String, title: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(title)
                    .font(AppTheme.Typography.bodyFont)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.lightGrey)
            }
            .foregroundColor(isDestructive ? .red : AppTheme.offWhiteText)
            .padding(.vertical, AppTheme.Spacing.small)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    // MARK: - Data Actions

    private func exportSessions() {
        Task {
            do {
                let sessions = try RoutineDataManager.shared.fetchAllSessions()
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                exportedData = try encoder.encode(sessions.map { SessionExport(from: $0) })
                showExportSheet = true
            } catch {
                logger.error("Failed to export sessions: \(error)", category: "Settings")
            }
        }
    }

    private func clearAllSessions() {
        Task {
            do {
                let sessions = try RoutineDataManager.shared.fetchAllSessions()
                for session in sessions {
                    try RoutineDataManager.shared.deleteSession(session)
                }
                logger.info("Cleared \(sessions.count) sessions", category: "Settings")
            } catch {
                logger.error("Failed to clear sessions: \(error)", category: "Settings")
            }
        }
    }
}

// MARK: - Lightweight Codable export DTO

private struct SessionExport: Codable {
    let id: String
    let routineName: String
    let startTime: Date
    let endTime: Date?
    let durationSeconds: Int
    let wasCompleted: Bool
    let wasDiscarded: Bool
    let completedBlocks: Int
    let totalBlocks: Int

    init(from session: MeditationSession) {
        self.id = session.id.uuidString
        self.routineName = session.routineName
        self.startTime = session.sessionStartTime
        self.endTime = session.sessionEndTime
        self.durationSeconds = session.sessionDurationInSeconds
        self.wasCompleted = session.wasCompleted
        self.wasDiscarded = session.wasDiscarded
        self.completedBlocks = session.completedBlocksCount
        self.totalBlocks = session.totalBlocksCount
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(\.modelContext, try! ModelContainer(
            for: MeditationSession.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ).mainContext)
}
