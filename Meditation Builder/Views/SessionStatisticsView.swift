//
//  SessionStatisticsView.swift
//  Meditation Builder
//

import SwiftUI
import SwiftData

struct SessionStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineDataManager) private var dataManager
    @Environment(\.dismiss) private var dismiss
    @Query private var sessions: [MeditationSession]
    @State private var statistics: SessionStatistics?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()

                Group {
                    if isLoading {
                        VStack(spacing: AppTheme.Spacing.large) {
                            ProgressView()
                                .tint(AppTheme.accentColor)
                            Text("Loading statistics…")
                                .font(AppTheme.Typography.bodyFont)
                                .foregroundColor(AppTheme.lightGrey)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let stats = statistics {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: AppTheme.Spacing.large) {
                                overviewGrid(stats: stats)
                                recentActivitySection
                                insightsSection(stats: stats)
                            }
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.medium)
                            .padding(.bottom, AppTheme.Spacing.section)
                        }
                    } else {
                        StatisticsEmptyStateView()
                    }
                }
            }
            .navigationTitle(LocalizedStringKey("statistics.title"))
            .navigationBarTitleDisplayMode(.inline)
            .liquidGlassNavigationBar()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button.done")) { dismiss() }
                        .foregroundColor(AppTheme.accentColor)
                        .font(AppTheme.Typography.buttonFont)
                }
            }
        }
        .onAppear { loadStatistics() }
    }

    // MARK: - Overview Grid

    private func overviewGrid(stats: SessionStatistics) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium),
            GridItem(.flexible(), spacing: AppTheme.Spacing.medium)
        ], spacing: AppTheme.Spacing.medium) {
            ThemedStatCard(title: "Total Sessions", value: "\(stats.totalSessions)", icon: "clock.arrow.circlepath")
            ThemedStatCard(title: "Completion Rate", value: "\(stats.completionRatePercentage)%", icon: "checkmark.circle.fill")
            ThemedStatCard(title: "Total Time", value: stats.totalDurationFormatted, icon: "timer")
            ThemedStatCard(title: "Avg Duration", value: stats.averageDurationFormatted, icon: "clock")
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("statistics.recent.activity"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.lightGrey)

            let recent = sessions.filter { !$0.wasDiscarded }
                .sorted { $0.sessionStartTime > $1.sessionStartTime }
                .prefix(5)

            if recent.isEmpty {
                Text(LocalizedStringKey("statistics.no.recent.sessions"))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.lightGrey)
                    .padding(.vertical, AppTheme.Spacing.small)
            } else {
                ForEach(Array(recent), id: \.id) { session in
                    if session.id != recent.first?.id {
                        Divider().background(AppTheme.lightGrey.opacity(0.15))
                    }
                    RecentSessionRow(session: session)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    // MARK: - Insights Section

    private func insightsSection(stats: SessionStatistics) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("statistics.insights"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.lightGrey)

            InsightRow(icon: "target", title: "Most Used", value: getMostUsedRoutine())
            Divider().background(AppTheme.lightGrey.opacity(0.15))
            InsightRow(icon: "calendar", title: "Best Day", value: getBestDay())
            if stats.totalOvershootTimeInSeconds > 0 {
                Divider().background(AppTheme.lightGrey.opacity(0.15))
                InsightRow(icon: "clock.badge.exclamationmark", title: "Total Overshoot", value: stats.totalOvershootTimeFormatted)
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    // MARK: - Helpers

    private func loadStatistics() {
        Task {
            do {
                let stats = try await dataManager.getSessionStatistics()
                await MainActor.run {
                    self.statistics = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
            }
        }
    }

    private func getMostUsedRoutine() -> String {
        let counts = Dictionary(grouping: sessions.filter { !$0.wasDiscarded }, by: { $0.routineName })
            .mapValues { $0.count }
        return counts.max(by: { $0.value < $1.value })?.key ?? "None"
    }

    private func getBestDay() -> String {
        let dayCounts = Dictionary(grouping: sessions.filter { !$0.wasDiscarded }) {
            Calendar.current.component(.weekday, from: $0.sessionStartTime)
        }.mapValues { $0.count }
        guard let best = dayCounts.max(by: { $0.value < $1.value }) else { return "None" }
        return DateFormatter().weekdaySymbols[best.key - 1]
    }
}

// MARK: - Themed Stat Card

struct ThemedStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(AppTheme.accentColor)
                .accessibilityHidden(true)
            Text(value)
                .font(AppTheme.Typography.headlineFontLarge)
                .foregroundColor(AppTheme.offWhiteText)
            Text(title)
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(AppTheme.lightGrey)
                .multilineTextAlignment(.center)
        }
        .padding(AppTheme.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Stat Card (legacy alias kept for compatibility)

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        ThemedStatCard(title: title, value: value, icon: icon)
    }
}

// MARK: - Recent Session Row

struct RecentSessionRow: View {
    let session: MeditationSession

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: session.routineIcon)
                    .font(.system(size: 16, weight: .light))
                    .foregroundColor(AppTheme.accentColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(session.routineName)
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(formatDate(session.sessionStartTime))
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(session.sessionDurationFormatted)
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("component.completion.percentage", comment: ""),
                    session.completionRatePercentage
                ))
                .font(AppTheme.Typography.captionFont)
                .foregroundColor(session.wasFullyCompleted ? AppTheme.accentColor : .orange)
            }
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Insight Row

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppTheme.accentColor)
                .frame(width: 24, height: 24)
                .accessibilityHidden(true)
            Text(title)
                .font(AppTheme.Typography.bodyFont)
                .foregroundColor(AppTheme.lightGrey)
            Spacer()
            Text(value)
                .font(AppTheme.Typography.bodyFont)
                .foregroundColor(AppTheme.offWhiteText)
        }
    }
}

// MARK: - Statistics Empty State

struct StatisticsEmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.cardColor)
                    .frame(width: 80, height: 80)
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(AppTheme.accentColor)
            }
            VStack(spacing: AppTheme.Spacing.small) {
                Text(LocalizedStringKey("statistics.empty.title"))
                    .font(AppTheme.Typography.headlineFontLarge)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(LocalizedStringKey("statistics.empty.message"))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.lightGrey)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.extraLarge)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SessionStatisticsView()
}
