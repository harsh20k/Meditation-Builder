//
//  SessionHistoryView.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import SwiftUI
import SwiftData

struct SessionHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MeditationSession.sessionStartTime, order: .reverse) private var sessions: [MeditationSession]
    @State private var selectedSession: MeditationSession?
    @State private var showingStatistics = false
    @State private var searchText = ""
    @State private var selectedFilter: SessionFilter = .all
    
    private var dataManager: RoutineDataManager {
        RoutineDataManager(context: modelContext)
    }
    
    private var filteredSessions: [MeditationSession] {
        var filtered = sessions
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { session in
                session.routineName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply status filter
        switch selectedFilter {
        case .all:
            break
        case .completed:
            filtered = filtered.filter { !$0.wasDiscarded }
        case .discarded:
            filtered = filtered.filter { $0.wasDiscarded }
        case .fullyCompleted:
            filtered = filtered.filter { $0.wasFullyCompleted }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Debug info
                VStack {
                    Text("Total Sessions: \(sessions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Filtered Sessions: \(filteredSessions.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Filter and search bar
                VStack(spacing: 12) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search routines...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SessionFilter.allCases, id: \.self) { filter in
                                FilterButton(
                                    title: filter.displayName,
                                    isSelected: selectedFilter == filter,
                                    action: { selectedFilter = filter }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 8)
                .background(Color(.systemBackground))
                
                // Sessions list
                if filteredSessions.isEmpty {
                    EmptyStateView()
                } else {
                    List(filteredSessions, id: \.id) { session in
                        SessionRowView(session: session) {
                            print("👆 Session tapped: \(session.routineName)")
                            selectedSession = session
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Session History")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Refresh") {
                    print("🔄 Manual refresh triggered")
                    // Force a refresh by accessing the sessions
                    let _ = sessions.count
                },
                trailing: Button(action: {
                    showingStatistics = true
                }) {
                    Image(systemName: "chart.bar.fill")
                }
            )
        }
        .sheet(item: $selectedSession) { session in
            SessionDetailView(session: session)
        }
        .sheet(isPresented: $showingStatistics) {
            SessionStatisticsView()
        }
        .onAppear {
            print("📊 SessionHistoryView appeared")
            print("   Total sessions in database: \(sessions.count)")
            print("   Filtered sessions: \(filteredSessions.count)")
            for (index, session) in sessions.enumerated() {
                print("   Session \(index + 1): \(session.routineName) - \(session.sessionDurationFormatted) - \(session.wasDiscarded ? "DISCARDED" : "COMPLETED")")
            }
        }
        .onChange(of: sessions.count) { _, newCount in
            print("📊 Sessions count changed to: \(newCount)")
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSManagedObjectContextDidSave)) { _ in
            print("📊 Database context saved - refreshing sessions")
            // Force refresh of sessions
            Task {
                await MainActor.run {
                    // This will trigger a refresh of the @Query
                }
            }
        }
    }
}

// MARK: - Session Row View
struct SessionRowView: View {
    let session: MeditationSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Routine icon
                Image(systemName: session.routineIcon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 40, height: 40)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                // Session info
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.routineName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(session.getSessionSummary())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text(session.sessionDurationFormatted)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    StatusBadge(session: session)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Status Badge
struct StatusBadge: View {
    let session: MeditationSession
    
    var body: some View {
        Text(statusText)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusText: String {
        if session.wasDiscarded {
            return "Discarded"
        } else if session.wasFullyCompleted {
            return "Completed"
        } else {
            return "\(session.completionRatePercentage)%"
        }
    }
    
    private var statusColor: Color {
        if session.wasDiscarded {
            return .red
        } else if session.wasFullyCompleted {
            return .green
        } else {
            return .orange
        }
    }
}

// MARK: - Session Detail View
struct SessionDetailView: View {
    let session: MeditationSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    private var dataManager: RoutineDataManager {
        RoutineDataManager(context: modelContext)
    }
    
    // Debug computed properties
    private var debugInfo: String {
        """
        Session ID: \(session.id)
        Routine: \(session.routineName)
        Start Time: \(session.sessionStartTime)
        Duration: \(session.sessionDurationFormatted)
        Blocks: \(session.blockRecords.count)
        Completed: \(session.completedBlocksCount)/\(session.totalBlocksCount)
        Discarded: \(session.wasDiscarded)
        """
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Debug info (temporary)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debug Info")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text(debugInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: session.routineIcon)
                                .font(.largeTitle)
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.routineName)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                StatusBadge(session: session)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Session details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Session Details")
                            .font(.headline)
                        
                        DetailRow(title: "Date", value: formatDate(session.sessionStartTime))
                        DetailRow(title: "Duration", value: session.sessionDurationFormatted)
                        DetailRow(title: "Completion", value: "\(session.completedBlocksCount)/\(session.totalBlocksCount) blocks")
                        DetailRow(title: "Completion Rate", value: "\(session.completionRatePercentage)%")
                        
                        if session.hasOvershoot {
                            DetailRow(title: "Overshoot", value: session.overshootTimeFormatted)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Block details
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Block Details")
                            .font(.headline)
                        
                        if session.blockRecords.isEmpty {
                            Text("No block records found")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }), id: \.id) { record in
                                BlockRecordRow(record: record)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Session Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            print("📋 SessionDetailView appeared")
            print("   Session ID: \(session.id)")
            print("   Routine: \(session.routineName)")
            print("   Session Duration: \(session.sessionDurationFormatted)")
            print("   Was Discarded: \(session.wasDiscarded)")
            print("   Completion Rate: \(session.completionRatePercentage)%")
            print("   Total Blocks: \(session.totalBlocksCount) | Completed: \(session.completedBlocksCount)")
            
            print("   Block Details:")
            for record in session.blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let blockStatus: String
                if record.wasSkipped {
                    blockStatus = "SKIPPED"
                } else if record.endTime == nil {
                    blockStatus = "NOT_STARTED"
                } else {
                    // Use the same completion criteria as in MeditationSession
                    let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10) // 10 seconds or 10% of planned, whichever is smaller
                    if record.actualDurationInSeconds >= minimumDurationForCompletion {
                        blockStatus = "COMPLETED"
                    } else if record.actualDurationInSeconds > 0 {
                        blockStatus = "STARTED_ONLY"
                    } else {
                        blockStatus = "INTERRUPTED"
                    }
                }
                
                let blockDuration = String(format: "%d:%02d", record.actualDurationInSeconds / 60, record.actualDurationInSeconds % 60)
                let plannedDuration = String(format: "%d:%02d", record.plannedDurationInMinutes, 0)
                
                print("     \(record.orderIndex + 1). \(record.blockName)")
                print("        Type: \(record.blockType.displayName)")
                print("        Planned: \(plannedDuration) | Actual: \(blockDuration)")
                print("        Status: \(blockStatus)")
                
                if record.endTime != nil {
                    let startTimeFormatted = String(format: "%d:%02d", Int(record.startTime.timeIntervalSince(session.sessionStartTime)) / 60, Int(record.startTime.timeIntervalSince(session.sessionStartTime)) % 60)
                    let endTimeFormatted = String(format: "%d:%02d", Int(record.endTime!.timeIntervalSince(session.sessionStartTime)) / 60, Int(record.endTime!.timeIntervalSince(session.sessionStartTime)) % 60)
                    print("        Start: +\(startTimeFormatted) | End: +\(endTimeFormatted)")
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Block Record Row
struct BlockRecordRow: View {
    let record: SessionBlockRecord
    
    private var blockStatus: String {
        if record.wasSkipped {
            return "Skipped"
        } else if record.endTime == nil {
            return "Not Started"
        } else {
            // Use consistent completion criteria
            let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10)
			
			#if DEBUG
			let isDebugMode = true // Set to true for 5-second blocks, false for normal duration
			#else
			let isDebugMode = false
			#endif
			
			if isDebugMode {
				if record.actualDurationInSeconds >= 5 {
					return "Completed"
				} else if record.actualDurationInSeconds > 0 {
					return "Started Only"
				} else {
					return "Interrupted"
				}
			} else {
				if record.actualDurationInSeconds >= minimumDurationForCompletion {
					return "Completed"
				} else if record.actualDurationInSeconds > 0 {
					return "Started Only"
				} else {
					return "Interrupted"
				}
			}
        }
    }
   
    private var statusColor: Color {
        if record.wasSkipped {
            return .red
        } else if record.endTime == nil {
            return .orange
        } else {
            // Use consistent completion criteria for color
            let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10)
			
			#if DEBUG
			let isDebugMode = true // Set to true for 5-seconds blocks, false for normal duration
			#else
			let isDebugMode = false
			#endif
			
			if isDebugMode {
				if record.actualDurationInSeconds >= 5 {
					return .green  // Completed
				} else if record.actualDurationInSeconds > 0 {
					return .yellow  // Started Only
				} else {
					return .red  // Interrupted
				}
			} else {
				if record.actualDurationInSeconds >= minimumDurationForCompletion {
					return .green  // Completed
				} else if record.actualDurationInSeconds > 0 {
					return .yellow  // Started Only
				} else {
					return .red  // Interrupted
				}
			}
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.blockName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(record.blockType.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(record.actualDurationInSeconds))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(blockStatus)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Filter Button
struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Sessions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Complete your first meditation session to see it here.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Session Filter
enum SessionFilter: CaseIterable {
    case all
    case completed
    case discarded
    case fullyCompleted
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .completed: return "Completed"
        case .discarded: return "Discarded"
        case .fullyCompleted: return "Fully Completed"
        }
    }
}

#Preview {
    SessionHistoryView()
} 
