//
//  SessionStatisticsView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData

struct SessionStatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineDataManager) private var dataManager
	@Query private var sessions: [MeditationSession]
    @State private var statistics: SessionStatistics?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        ProgressView("Loading statistics...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let stats = statistics {
                        // Overview cards
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            StatCard(
                                title: "Total Sessions",
                                value: "\(stats.totalSessions)",
                                icon: "clock.arrow.circlepath",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Completion Rate",
                                value: "\(stats.completionRatePercentage)%",
                                icon: "checkmark.circle.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Total Time",
                                value: stats.totalDurationFormatted,
                                icon: "timer",
                                color: .orange
                            )
                            
                            StatCard(
                                title: "Avg Duration",
                                value: stats.averageDurationFormatted,
                                icon: "clock",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                        
                        // Recent activity
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("statistics.recent.activity"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if let recentSessions = getRecentSessions() {
                                ForEach(recentSessions.prefix(5), id: \.id) { session in
                                    RecentSessionRow(session: session)
                                }
                            } else {
                                Text(LocalizedStringKey("statistics.no.recent.sessions"))
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Insights
                        VStack(alignment: .leading, spacing: 16) {
                            Text(LocalizedStringKey("statistics.insights"))
                                .font(.headline)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                InsightRow(
                                    icon: "target",
                                    title: "Most Used Routine",
                                    value: getMostUsedRoutine()
                                )
                                
                                InsightRow(
                                    icon: "calendar",
                                    title: "Best Day",
                                    value: getBestDay()
                                )
                                
                                if stats.totalOvershootTimeInSeconds > 0 {
                                    InsightRow(
                                        icon: "clock.badge.exclamationmark",
                                        title: "Total Overshoot",
                                        value: stats.totalOvershootTimeFormatted
                                    )
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    } else {
                        StatisticsEmptyStateView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle(LocalizedStringKey("statistics.title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    private func loadStatistics() {
        Task {
            do {
                let stats = try await dataManager.getSessionStatistics()
                await MainActor.run {
                    self.statistics = stats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
    
    private func getRecentSessions() -> [MeditationSession]? {
        let completedSessions = sessions.filter { !$0.wasDiscarded }
        return completedSessions.sorted { $0.sessionStartTime > $1.sessionStartTime }
    }
    
    private func getMostUsedRoutine() -> String {
        let completedSessions = sessions.filter { !$0.wasDiscarded }
        let routineCounts = Dictionary(grouping: completedSessions, by: { $0.routineName })
            .mapValues { $0.count }
        
        if let mostUsed = routineCounts.max(by: { $0.value < $1.value }) {
            return mostUsed.key
        }
        return "None"
    }
    
    private func getBestDay() -> String {
        let completedSessions = sessions.filter { !$0.wasDiscarded }
        let dayCounts = Dictionary(grouping: completedSessions) { session in
            Calendar.current.component(.weekday, from: session.sessionStartTime)
        }.mapValues { $0.count }
        
        if let bestDay = dayCounts.max(by: { $0.value < $1.value }) {
            let formatter = DateFormatter()
            formatter.weekdaySymbols[bestDay.key - 1]
            return formatter.weekdaySymbols[bestDay.key - 1]
        }
        return "None"
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Recent Session Row
struct RecentSessionRow: View {
    let session: MeditationSession
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.routineIcon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 32, height: 32)
                .background(Color.accentColor.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(session.routineName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(formatDate(session.sessionStartTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(session.sessionDurationFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(String.localizedStringWithFormat(
                    NSLocalizedString("component.completion.percentage", comment: "Completion percentage"),
                    session.completionRatePercentage
                ))
                    .font(.caption)
                    .foregroundColor(session.wasFullyCompleted ? .green : .orange)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal)
    }
}

// MARK: - Statistics Empty State View
struct StatisticsEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text(LocalizedStringKey("statistics.empty.title"))
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(LocalizedStringKey("statistics.empty.message"))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SessionStatisticsView()
} 
