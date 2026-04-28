//
//  SessionHistoryView.swift
//  Meditation Builder
//

import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineDataManager) private var dataManager
    @Query(sort: \MeditationSession.sessionStartTime, order: .reverse) private var sessions: [MeditationSession]
    @State private var selectedSession: MeditationSession? = nil
    @State private var showingStatistics = false
    @State private var searchText = ""
    @State private var selectedFilter: SessionFilter = .all

    private var filteredSessions: [MeditationSession] {
        var filtered = sessions
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.routineName.localizedCaseInsensitiveContains(searchText) }
        }
        switch selectedFilter {
        case .all: break
        case .completed:       filtered = filtered.filter { !$0.wasDiscarded }
        case .discarded:       filtered = filtered.filter { $0.wasDiscarded }
        case .fullyCompleted:  filtered = filtered.filter { $0.wasFullyCompleted }
        }
        return filtered
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundColor(AppTheme.accentColor)
                        .font(.system(size: 26, weight: .bold))
                        .accessibilityHidden(true)
                    Text(LocalizedStringKey("session.history.title"))
                        .font(AppTheme.Typography.titleFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Spacer()
                    Button(action: { showingStatistics = true }) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppTheme.accentColor)
                            .frame(width: 36, height: 36)
                            .background(AppTheme.cardColor)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel(Text(LocalizedStringKey("statistics.title")))
                }
                .padding(.horizontal)
                .padding(.top, AppTheme.Spacing.extraLarge)
                .padding(.bottom, AppTheme.Spacing.medium)

                // Search bar
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.lightGrey)
                        .font(.system(size: 15))
                        .accessibilityHidden(true)
                    TextField("", text: $searchText, prompt: Text(LocalizedStringKey("search.routines.placeholder")).foregroundColor(AppTheme.lightGrey))
                        .foregroundColor(AppTheme.offWhiteText)
                        .font(AppTheme.Typography.bodyFont)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button { searchText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.lightGrey)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Clear search")
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .background(AppTheme.searchBar)
                .cornerRadius(AppTheme.CornerRadius.button)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.bottom, AppTheme.Spacing.small)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.Spacing.small) {
                        ForEach(SessionFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.displayName,
                                isSelected: selectedFilter == filter,
                                action: { selectedFilter = filter }
                            )
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                }
                .padding(.bottom, AppTheme.Spacing.medium)

                // Content
                if filteredSessions.isEmpty {
                    HistoryEmptyStateView(isFiltered: !searchText.isEmpty || selectedFilter != .all)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: AppTheme.Spacing.small) {
                            ForEach(filteredSessions) { session in
                            SessionRowView(session: session) {
                                selectedSession = session
                            }
                            .scrollTransition(.animated(.easeInOut)) { content, phase in
                                content.opacity(phase.isIdentity ? 1 : 0.5)
                                    .offset(y: phase.isIdentity ? 0 : 6)
                            }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .sheet(isPresented: $showingStatistics) {
            SessionStatisticsView()
        }
    }
}

// MARK: - Session Row View

struct SessionRowView: View {
    let session: MeditationSession
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: session.routineIcon)
                        .font(.system(size: 20, weight: .light))
                        .foregroundColor(AppTheme.accentColor)
                }
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 3) {
                    Text(session.routineName)
                        .font(AppTheme.Typography.headlineFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    Text(session.getSessionSummary())
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.lightGrey)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(session.sessionDurationFormatted)
                        .font(AppTheme.Typography.captionFont)
                        .foregroundColor(AppTheme.offWhiteText)
                    StatusBadge(session: session)
                }
            }
            .padding(AppTheme.Spacing.medium)
            .background(AppTheme.cardColor)
            .cornerRadius(AppTheme.CornerRadius.medium)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(session.routineName), \(session.sessionDurationFormatted), \(session.wasDiscarded ? "discarded" : session.wasFullyCompleted ? "completed" : "\(session.completionRatePercentage)% complete")")
        .accessibilityHint("Double-tap to view session details")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let session: MeditationSession

    var body: some View {
        Text(statusText)
            .font(AppTheme.Typography.captionFont)
            .padding(.horizontal, AppTheme.Spacing.small)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.18))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }

    private var statusText: String {
        if session.wasDiscarded { return "Discarded" }
        if session.wasFullyCompleted { return "Completed" }
        return "\(session.completionRatePercentage)%"
    }

    private var statusColor: Color {
        if session.wasDiscarded { return .red }
        if session.wasFullyCompleted { return AppTheme.accentColor }
        return .orange
    }
}

// MARK: - Session Detail View

struct SessionDetailView: View {
    let session: MeditationSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundColor.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        sessionHeaderCard
                        detailsCard
                        blocksCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.medium)
                    .padding(.vertical, AppTheme.Spacing.medium)
                }
            }
            .navigationTitle(LocalizedStringKey("session.history.details"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(AppTheme.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(LocalizedStringKey("button.done")) { dismiss() }
                        .foregroundColor(AppTheme.accentColor)
                        .font(AppTheme.Typography.buttonFont)
                }
            }
        }
    }

    private var sessionHeaderCard: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: session.routineIcon)
                    .font(.system(size: 26, weight: .light))
                    .foregroundColor(AppTheme.accentColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(session.routineName)
                    .font(AppTheme.Typography.headlineFontLarge)
                    .foregroundColor(AppTheme.offWhiteText)
                StatusBadge(session: session)
            }
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("session.history.details"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.lightGrey)

            ThemedDetailRow(title: "Date", value: formatDate(session.sessionStartTime))
            Divider().background(AppTheme.lightGrey.opacity(0.15))
            ThemedDetailRow(title: "Duration", value: session.sessionDurationFormatted)
            Divider().background(AppTheme.lightGrey.opacity(0.15))
            ThemedDetailRow(title: "Completion", value: "\(session.completedBlocksCount)/\(session.totalBlocksCount) blocks")
            Divider().background(AppTheme.lightGrey.opacity(0.15))
            ThemedDetailRow(title: "Rate", value: "\(session.completionRatePercentage)%")
            if session.hasOvershoot {
                Divider().background(AppTheme.lightGrey.opacity(0.15))
                ThemedDetailRow(title: "Overshoot", value: session.overshootTimeFormatted)
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    private var blocksCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text(LocalizedStringKey("session.history.block.details"))
                .font(AppTheme.Typography.headlineFont)
                .foregroundColor(AppTheme.lightGrey)

            if session.blockRecords.isEmpty {
                Text(LocalizedStringKey("session.history.no.blocks"))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.lightGrey)
                    .italic()
            } else {
                ForEach(session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { record in
                    if record.id != session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }).first?.id {
                        Divider().background(AppTheme.lightGrey.opacity(0.15))
                    }
                    BlockRecordRow(record: record)
                }
            }
        }
        .padding(AppTheme.Spacing.large)
        .background(AppTheme.cardColor)
        .cornerRadius(AppTheme.CornerRadius.large)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Themed Detail Row

struct ThemedDetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
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

// MARK: - Block Record Row

struct BlockRecordRow: View {
    let record: SessionBlockRecord

    private var blockStatus: String {
        if record.wasSkipped { return "Skipped" }
        if record.endTime == nil { return "Not Started" }
        let minDuration = min(10, record.plannedDurationInMinutes * 60 / 10)
        if record.actualDurationInSeconds >= minDuration { return "Completed" }
        if record.actualDurationInSeconds > 0 { return "Started Only" }
        return "Interrupted"
    }

    private var statusColor: Color {
        if record.wasSkipped { return .red }
        if record.endTime == nil { return .orange }
        let minDuration = min(10, record.plannedDurationInMinutes * 60 / 10)
        if record.actualDurationInSeconds >= minDuration { return AppTheme.accentColor }
        if record.actualDurationInSeconds > 0 { return .yellow }
        return .red
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(record.blockName)
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(record.blockType.displayName)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(AppTheme.lightGrey)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(formatDuration(record.actualDurationInSeconds))
                    .font(AppTheme.Typography.bodyFont)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(blockStatus)
                    .font(AppTheme.Typography.captionFont)
                    .foregroundColor(statusColor)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

// MARK: - Detail Row (legacy alias kept for compatibility)

struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        ThemedDetailRow(title: title, value: value)
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.captionFont)
                .padding(.horizontal, AppTheme.Spacing.medium)
                .padding(.vertical, 6)
                .background(isSelected ? AppTheme.accentColor : AppTheme.cardColor)
                .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.lightGrey)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : AppTheme.lightGrey.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel("\(title) filter\(isSelected ? ", selected" : "")")
    }
}

// MARK: - Filter Button (legacy alias)

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        FilterChip(title: title, isSelected: isSelected, action: action)
    }
}

// MARK: - History Empty State

struct HistoryEmptyStateView: View {
    let isFiltered: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.extraLarge) {
            Spacer()
            ZStack {
                Circle()
                    .fill(AppTheme.cardColor)
                    .frame(width: 80, height: 80)
                Image(systemName: isFiltered ? "magnifyingglass" : "clock.arrow.circlepath")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(AppTheme.accentColor)
                    .symbolEffect(.pulse, isActive: !isFiltered)
            }
            VStack(spacing: AppTheme.Spacing.small) {
                Text(LocalizedStringKey(isFiltered ? "empty.no.results" : "session.history.empty.title"))
                    .font(AppTheme.Typography.headlineFontLarge)
                    .foregroundColor(AppTheme.offWhiteText)
                Text(LocalizedStringKey(isFiltered ? "empty.adjust.search.terms" : "session.history.empty.message"))
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

// MARK: - Empty State View (legacy alias)

struct EmptyStateView: View {
    var body: some View {
        HistoryEmptyStateView(isFiltered: false)
    }
}

// MARK: - Session Filter

enum SessionFilter: CaseIterable {
    case all, completed, discarded, fullyCompleted

    var displayName: String {
        switch self {
        case .all:           return String(localized: "filter.all")
        case .completed:     return String(localized: "filter.completed")
        case .discarded:     return String(localized: "filter.discarded")
        case .fullyCompleted: return String(localized: "filter.fully.completed")
        }
    }
}

#Preview {
    SessionHistoryView()
}
