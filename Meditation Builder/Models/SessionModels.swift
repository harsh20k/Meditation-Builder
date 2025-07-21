//
//  SessionModels.swift
//  Meditation Builder
//
//  Created by harsh on 09/07/25.
//

import Foundation
import SwiftUI
import SwiftData

/**
 * SessionModels.swift
 *
 * This file contains all models related to meditation session tracking,
 * including session records, block records, event-based tracking, and
 * session statistics. It implements both traditional session tracking
 * and the new deferred event-based approach.
 *
 * ## Key Components:
 * - `MeditationSession`: SwiftData model for complete session records
 * - `SessionBlockRecord`: SwiftData model for individual block performance
 * - `SessionEvent`: Event enum for lightweight session state tracking
 * - `SessionRecord`: SwiftData model for deferred event-based saving
 * - `SessionStatistics`: Value type for aggregated session data
 *
 * ## Architecture:
 * The file supports two session tracking approaches:
 * 1. **Traditional**: Direct block-by-block tracking with immediate persistence
 * 2. **Event-based**: Lightweight event recording with deferred reconstruction
 *
 * ## Usage:
 * These models are used in:
 * - Session playback and tracking
 * - Session history and statistics
 * - Performance analytics
 * - Data persistence and retrieval
 */

// MARK: - Session Block Record

/**
 * SwiftData model representing the performance record of an individual block
 * within a meditation session.
 * 
 * This model tracks how a specific block was performed during a session,
 * including timing, completion status, and any deviations from the planned
 * duration. It provides detailed analytics for individual block performance.
 *
 * ## Properties:
 * - `id`: Unique identifier for the block record
 * - `blockId`: Reference to the original block
 * - `blockName`: Human-readable name of the block
 * - `blockType`: Type of meditation technique used
 * - `plannedDurationInMinutes`: Original planned duration
 * - `actualDurationInSeconds`: Actual time spent on the block
 * - `wasSkipped`: Whether the block was skipped entirely
 * - `orderIndex`: Position within the session
 * - `startTime`: When the block actually started
 * - `endTime`: When the block ended (nil if skipped)
 */
@Model
final class SessionBlockRecord: Identifiable {
    /// Unique identifier for the block record
    var id: UUID
    
    /// Reference to the original block
    var blockId: UUID
    
    /// Human-readable name of the block
    var blockName: String
    
    /// Type of meditation technique used
    var blockType: MeditationBlock.BlockType
    
    /// Original planned duration in minutes
    var plannedDurationInMinutes: Int
    
    /// Actual time spent on the block in seconds
    var actualDurationInSeconds: Int
    
    /// Whether the block was skipped entirely
    var wasSkipped: Bool
    
    /// Position within the session
    var orderIndex: Int
    
    /// When the block actually started
    var startTime: Date
    
    /// When the block ended (nil if skipped)
    var endTime: Date?
    
    /**
     * Initializes a new session block record.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - blockId: Reference to the original block
     *   - blockName: Human-readable name of the block
     *   - blockType: Type of meditation technique used
     *   - plannedDurationInMinutes: Original planned duration
     *   - actualDurationInSeconds: Actual time spent (defaults to 0)
     *   - wasSkipped: Whether the block was skipped (defaults to false)
     *   - orderIndex: Position within the session
     *   - startTime: When the block actually started
     *   - endTime: When the block ended (defaults to nil)
     */
    init(
        id: UUID = UUID(),
        blockId: UUID,
        blockName: String,
        blockType: MeditationBlock.BlockType,
        plannedDurationInMinutes: Int,
        actualDurationInSeconds: Int = 0,
        wasSkipped: Bool = false,
        orderIndex: Int,
        startTime: Date,
        endTime: Date? = nil
    ) {
        self.id = id
        self.blockId = blockId
        self.blockName = blockName
        self.blockType = blockType
        self.plannedDurationInMinutes = plannedDurationInMinutes
        self.actualDurationInSeconds = actualDurationInSeconds
        self.wasSkipped = wasSkipped
        self.orderIndex = orderIndex
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Meditation Session

/**
 * SwiftData model representing a complete meditation session.
 * 
 * This model tracks the overall performance of a meditation session,
 * including timing, completion rates, and detailed block records.
 * It provides comprehensive analytics and user-friendly display methods
 * for session review and statistics.
 *
 * ## Properties:
 * - `id`: Unique identifier for the session
 * - `routineId`: Reference to the routine that was performed
 * - `routineName`: Human-readable name of the routine
 * - `routineIcon`: SF Symbol icon for visual representation
 * - `sessionStartTime`: When the session started
 * - `sessionEndTime`: When the session ended (nil if ongoing)
 * - `totalPlannedDurationInMinutes`: Total planned duration of all blocks
 * - `totalActualDurationInSeconds`: Total actual time spent meditating
 * - `wasCompleted`: Whether the session was completed (not discarded)
 * - `wasDiscarded`: Whether the session was discarded by the user
 * - `completedBlocksCount`: Number of blocks that were completed
 * - `totalBlocksCount`: Total number of blocks in the routine
 * - `overshootTimeInSeconds`: Time spent beyond all blocks completion
 * - `actualMeditationTimeInSeconds`: Time spent actually meditating (excluding pauses)
 * - `blockRecords`: Detailed records for each block (cascade deleted)
 */
@Model
final class MeditationSession: Identifiable {
	
    /// Unique identifier for the session
    /// Unique identifier for the session
    var id: UUID
    
    /// Reference to the routine that was performed
    var routineId: UUID
    
    /// Human-readable name of the routine
    var routineName: String
    
    /// SF Symbol icon for visual representation
    var routineIcon: String
    
    /// When the session started
    var sessionStartTime: Date
    
    /// When the session ended (nil if ongoing)
    var sessionEndTime: Date?
    
    /// Total planned duration of all blocks in minutes
    var totalPlannedDurationInMinutes: Int
    
    /// Total actual time spent meditating in seconds
    var totalActualDurationInSeconds: Int
    
    /// Whether the session was completed (not discarded)
    var wasCompleted: Bool
    
    /// Whether the session was discarded by the user
    var wasDiscarded: Bool
    
    /// Number of blocks that were completed
    var completedBlocksCount: Int
    
    /// Total number of blocks in the routine
    var totalBlocksCount: Int
    
    /// Time spent beyond all blocks completion in seconds
    var overshootTimeInSeconds: Int
    
    /// Time spent actually meditating (excluding paused time) in seconds
    var actualMeditationTimeInSeconds: Int = 0
    
    /// Detailed records for each block (cascade deleted when session is deleted)
    @Relationship(deleteRule: .cascade) var blockRecords: [SessionBlockRecord]
    
    /**
     * Initializes a new meditation session.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - routineId: Reference to the routine that was performed
     *   - routineName: Human-readable name of the routine
     *   - routineIcon: SF Symbol icon for visual representation
     *   - sessionStartTime: When the session started
     *   - sessionEndTime: When the session ended (defaults to nil)
     *   - totalPlannedDurationInMinutes: Total planned duration of all blocks
     *   - totalActualDurationInSeconds: Total actual time spent (defaults to 0)
     *   - wasCompleted: Whether the session was completed (defaults to false)
     *   - wasDiscarded: Whether the session was discarded (defaults to false)
     *   - completedBlocksCount: Number of blocks completed (defaults to 0)
     *   - totalBlocksCount: Total number of blocks in the routine
     *   - overshootTimeInSeconds: Time spent beyond completion (defaults to 0)
     *   - actualMeditationTimeInSeconds: Actual meditation time (defaults to 0)
     *   - blockRecords: Detailed records for each block (defaults to empty array)
     */
    init(
        id: UUID = UUID(),
        routineId: UUID,
        routineName: String,
        routineIcon: String,
        sessionStartTime: Date,
        sessionEndTime: Date? = nil,
        totalPlannedDurationInMinutes: Int,
        totalActualDurationInSeconds: Int = 0,
        wasCompleted: Bool = false,
        wasDiscarded: Bool = false,
        completedBlocksCount: Int = 0,
        totalBlocksCount: Int,
        overshootTimeInSeconds: Int = 0,
        actualMeditationTimeInSeconds: Int = 0,
        blockRecords: [SessionBlockRecord] = []
    ) {
        self.id = id
        self.routineId = routineId
        self.routineName = routineName
        self.routineIcon = routineIcon
        self.sessionStartTime = sessionStartTime
        self.sessionEndTime = sessionEndTime
        self.totalPlannedDurationInMinutes = totalPlannedDurationInMinutes
        self.totalActualDurationInSeconds = totalActualDurationInSeconds
        self.wasCompleted = wasCompleted
        self.wasDiscarded = wasDiscarded
        self.completedBlocksCount = completedBlocksCount
        self.totalBlocksCount = totalBlocksCount
        self.overshootTimeInSeconds = overshootTimeInSeconds
        self.actualMeditationTimeInSeconds = actualMeditationTimeInSeconds
        self.blockRecords = blockRecords
    }
    
    // MARK: - Computed Properties
    
    /**
     * Total session duration in seconds (from start to end).
     * Returns 0 if the session hasn't ended yet.
     */
    var sessionDurationInSeconds: Int {
        guard let endTime = sessionEndTime else { return 0 }
        return Int(endTime.timeIntervalSince(sessionStartTime))
    }
    
    /**
     * Formatted session duration string (MM:SS format).
     * Uses actual meditation time (excluding paused time).
     */
    var sessionDurationFormatted: String {
        let duration = actualMeditationTimeInSeconds
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /**
     * Completion rate as a decimal (0.0 to 1.0).
     * Represents the fraction of blocks that were completed.
     */
    var completionRate: Double {
        guard totalBlocksCount > 0 else { return 0.0 }
        return Double(completedBlocksCount) / Double(totalBlocksCount)
    }
    
    /**
     * Completion rate as a percentage (0 to 100).
     * Represents the percentage of blocks that were completed.
     */
    var completionRatePercentage: Int {
        return Int(completionRate * 100)
    }
    
    /**
     * Whether all blocks in the routine were completed.
     * True if completedBlocksCount equals totalBlocksCount.
     */
    var wasFullyCompleted: Bool {
        return completedBlocksCount == totalBlocksCount
    }
    
    /**
     * Whether the session had overshoot time.
     * True if overshootTimeInSeconds is greater than 0.
     */
    var hasOvershoot: Bool {
        return overshootTimeInSeconds > 0
    }
    
    /**
     * Formatted overshoot time string (MM:SS format).
     * Shows time spent beyond all blocks completion.
     */
    var overshootTimeFormatted: String {
        let minutes = overshootTimeInSeconds / 60
        let seconds = overshootTimeInSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // MARK: - Helper Methods
    
    /**
     * Adds a block record to this session.
     * 
     * The record is added and then sorted by order index to maintain
     * proper chronological order.
     *
     * - Parameter record: The block record to add
     */
    func addBlockRecord(_ record: SessionBlockRecord) {
        blockRecords.append(record)
        blockRecords.sort { $0.orderIndex < $1.orderIndex }
    }
    
    /**
     * Completes the session with final timing and status information.
     * 
     * This method calculates completion metrics, overshoot time, and
     * finalizes the session record. It should be called when the session ends.
     *
     * - Parameters:
     *   - endTime: When the session ended
     *   - wasDiscarded: Whether the session was discarded by the user
     *   - actualMeditationTime: Actual meditation time excluding pauses (optional)
     */
    func completeSession(endTime: Date, wasDiscarded: Bool = false, actualMeditationTime: Int? = nil) {
        self.sessionEndTime = endTime
        self.wasDiscarded = wasDiscarded
        self.wasCompleted = !wasDiscarded
        
        // Use provided actual meditation time or calculate from session duration
        if let actualTime = actualMeditationTime {
            self.actualMeditationTimeInSeconds = actualTime
            self.totalActualDurationInSeconds = actualTime
        } else {
            // Fallback to session duration if no actual time provided
            self.totalActualDurationInSeconds = sessionDurationInSeconds
            self.actualMeditationTimeInSeconds = sessionDurationInSeconds
        }
        
        // Calculate overshoot time based on actual meditation time
        let plannedDurationInSeconds = totalPlannedDurationInMinutes * 60
        self.overshootTimeInSeconds = max(0, self.actualMeditationTimeInSeconds - plannedDurationInSeconds)
        
        // Count completed blocks with improved criteria
        // A block is considered "completed" if:
        // 1. It was not skipped
        // 2. It has an end time
        // 3. It ran for at least 10 seconds OR at least 10% of its planned duration (whichever is smaller)
        self.completedBlocksCount = blockRecords.filter { record in
            guard !record.wasSkipped && record.endTime != nil else { return false }
            
            let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10) // 10 seconds or 10% of planned, whichever is smaller
            return record.actualDurationInSeconds >= minimumDurationForCompletion
        }.count
    }
    
    /**
     * Updates a specific block record with new timing information.
     * 
     * This method is used during session playback to update block records
     * as they complete or are skipped.
     *
     * - Parameters:
     *   - blockId: The ID of the block to update
     *   - actualDuration: Actual duration in seconds
     *   - wasSkipped: Whether the block was skipped
     *   - endTime: When the block ended
     */
    func updateBlockRecord(_ blockId: UUID, actualDuration: Int, wasSkipped: Bool, endTime: Date) {
        if let record = blockRecords.first(where: { $0.blockId == blockId }) {
            print("🔧 DEBUG - updateBlockRecord:")
            print("   Block: \(record.blockName)")
            print("   Actual Duration: \(actualDuration)s")
            print("   Was Skipped: \(wasSkipped)")
            print("   Start Time: \(record.startTime)")
            print("   End Time: \(endTime)")
            print("   Raw Duration: \(Int(endTime.timeIntervalSince(record.startTime)))s")
            
            record.actualDurationInSeconds = actualDuration
            record.wasSkipped = wasSkipped
            record.endTime = endTime
            
            print("   ✅ Record updated - actualDurationInSeconds now: \(record.actualDurationInSeconds)s")
        } else {
            print("⚠️ DEBUG - updateBlockRecord: Block record not found for ID: \(blockId)")
        }
    }
    
    // MARK: - User-Friendly Display Methods
    
    /**
     * Returns a brief summary of the session for display in lists.
     * 
     * Shows the session date and time in a short format.
     *
     * - Returns: Formatted date string for the session
     */
    func getSessionSummary() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        return dateFormatter.string(from: sessionStartTime)
    }
    
    /**
     * Returns a detailed summary of the session for detailed views.
     * 
     * Shows comprehensive information including duration, completion rate,
     * overshoot time, and status.
     *
     * - Returns: Detailed session summary string
     */
    func getDetailedSummary() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        var summary = "Session: \(routineName)\n"
        summary += "Date: \(dateFormatter.string(from: sessionStartTime))\n"
        summary += "Duration: \(sessionDurationFormatted)\n"
        summary += "Completion: \(completedBlocksCount)/\(totalBlocksCount) blocks (\(completionRatePercentage)%)\n"
        
        if hasOvershoot {
            summary += "Overshoot: \(overshootTimeFormatted)\n"
        }
        
        if wasDiscarded {
            summary += "Status: Discarded"
        } else if wasFullyCompleted {
            summary += "Status: Fully completed"
        } else {
            summary += "Status: Partially completed"
        }
        
        return summary
    }
    
    /**
     * Returns a detailed summary of all blocks in the session.
     * 
     * Shows the status and duration of each block, including whether
     * blocks were completed, skipped, or interrupted.
     *
     * - Returns: Detailed block summary string
     */
    func getBlockSummary() -> String {
        var summary = "Block Details:\n"
        
        for record in blockRecords.sorted(by: { $0.orderIndex < $1.orderIndex }) {
            let status: String
            if record.wasSkipped {
                status = "Skipped"
            } else if record.endTime == nil {
                status = "Not Started"
            } else {
                // Use consistent completion criteria
                let minimumDurationForCompletion = min(10, record.plannedDurationInMinutes * 60 / 10)
				
				#if DEBUG
				let isDebugMode = true // Set to true for 5-second blocks, false for normal duration
				#else
				let isDebugMode = false
				#endif
				
				if isDebugMode {
					if record.actualDurationInSeconds >= 10 {
						status = "Completed"
					} else if record.actualDurationInSeconds > 0 {
						status = "Started Only"
					} else {
						status = "Interrupted"
					}
				} else {
					if record.actualDurationInSeconds >= minimumDurationForCompletion {
						status = "Completed"
					} else if record.actualDurationInSeconds > 0 {
						status = "Started Only"
					} else {
						status = "Interrupted"
					}
				}
            }
            
            let actualDuration = record.actualDurationInSeconds
            let minutes = actualDuration / 60
            let seconds = actualDuration % 60
            let durationString = String(format: "%d:%02d", minutes, seconds)
            
            summary += "• \(record.blockName): \(durationString) (\(status))\n"
        }
        
        return summary
    }
}

// MARK: - Event-Based Session Tracking

/**
 * Lightweight event enum for tracking session state changes.
 * 
 * This enum represents the different events that can occur during a
 * meditation session. Events are used in the deferred event-based
 * tracking approach to minimize database writes during playback.
 */
enum SessionEvent: Codable, Equatable {
    /// Session started at the specified time
    case start(Date)
    /// Session paused at the specified time
    case pause(Date)
    /// Session resumed at the specified time
    case resume(Date)
    /// Session finished at the specified time
    case finish(Date)
    
    /**
     * The timestamp when this event occurred.
     */
    var timestamp: Date {
        switch self {
        case .start(let date), .pause(let date), .resume(let date), .finish(let date):
            return date
        }
    }
    
    /**
     * String representation of the event type.
     * Used for debugging and logging purposes.
     */
    var eventType: String {
        switch self {
        case .start: return "start"
        case .pause: return "pause"
        case .resume: return "resume"
        case .finish: return "finish"
        }
    }
}

/**
 * Lightweight session record for deferred event-based saving.
 * 
 * This SwiftData model stores a sequence of session events that can be
 * used to reconstruct detailed session information after the session
 * completes. This approach minimizes database writes during playback
 * and provides more resilient session tracking.
 *
 * ## Properties:
 * - `id`: Unique identifier for the session record
 * - `routineID`: Reference to the routine that was performed
 * - `events`: Sequence of session events
 * - `createdAt`: When the session record was created
 */
@Model
final class SessionRecord: Identifiable {
    /// Unique identifier for the session record
    var id: UUID
    
    /// Reference to the routine that was performed
    var routineID: UUID
    
    /// Sequence of session events
    var events: [SessionEvent]
    
    /// When the session record was created
    var createdAt: Date
    
    /**
     * Initializes a new session record.
     *
     * - Parameters:
     *   - id: Unique identifier (auto-generated if not provided)
     *   - routineID: Reference to the routine that was performed
     *   - events: Sequence of session events (defaults to empty array)
     *   - createdAt: When the session record was created (defaults to current date)
     */
    init(id: UUID = UUID(), routineID: UUID, events: [SessionEvent] = [], createdAt: Date = Date()) {
        self.id = id
        self.routineID = routineID
        self.events = events
        self.createdAt = createdAt
    }
    
    /**
     * Adds an event to the session record.
     *
     * - Parameter event: The event to add
     */
    func addEvent(_ event: SessionEvent) {
        events.append(event)
    }
    
    /**
     * Gets the session start time from the events.
     * 
     * Returns the timestamp of the first start event, or nil if no start event exists.
     */
    var startTime: Date? {
        events.first { if case .start = $0 { return true }; return false }?.timestamp
    }
    
    /**
     * Gets the session finish time from the events.
     * 
     * Returns the timestamp of the last finish event, or nil if no finish event exists.
     */
    var finishTime: Date? {
        events.last { if case .finish = $0 { return true }; return false }?.timestamp
    }
    
    /**
     * Calculates total actual meditation time (excluding paused intervals).
     * 
     * This method processes the event sequence to determine the total time
     * spent actually meditating, excluding any time spent paused.
     *
     * - Returns: Total meditation time in seconds
     */
    func calculateActualMeditationTime() -> TimeInterval {
        guard let startTime = startTime else { return 0 }
        
        var totalTime: TimeInterval = 0
        var currentSessionStart = startTime
        var isPaused = false
        
        for event in events.dropFirst() { // Skip the first start event
            switch event {
            case .pause(let pauseTime):
                if !isPaused {
                    // Add time from current session start to pause
                    totalTime += pauseTime.timeIntervalSince(currentSessionStart)
                    isPaused = true
                }
            case .resume(let resumeTime):
                if isPaused {
                    // Start a new session segment
                    currentSessionStart = resumeTime
                    isPaused = false
                }
            case .finish(let finishTime):
                if !isPaused {
                    // Add final segment time
                    totalTime += finishTime.timeIntervalSince(currentSessionStart)
                }
                break // Session ended
            case .start:
                // Shouldn't have multiple starts, but handle gracefully
                break
            }
        }
        
        return totalTime
    }
    
    /**
     * Gets all pause/resume intervals from the events.
     * 
     * This method extracts all pause and resume pairs from the event sequence,
     * including pauses that never resumed (ending with session finish).
     *
     * - Returns: Array of pause intervals with optional resume times
     */
    func getPauseIntervals() -> [(pause: Date, resume: Date?)] {
        var intervals: [(pause: Date, resume: Date?)] = []
        var currentPause: Date?
        
        for event in events {
            switch event {
            case .pause(let pauseTime):
                currentPause = pauseTime
            case .resume(let resumeTime):
                if let pause = currentPause {
                    intervals.append((pause: pause, resume: resumeTime))
                    currentPause = nil
                }
            case .finish:
                if let pause = currentPause {
                    intervals.append((pause: pause, resume: nil))
                    currentPause = nil
                }
            case .start:
                break
            }
        }
        
        return intervals
    }
}

// MARK: - Session Statistics

/**
 * Value type representing aggregated session statistics.
 * 
 * This struct provides computed statistics across multiple sessions,
 * including total duration, completion rates, and overshoot time.
 * It's used for analytics and progress tracking.
 *
 * ## Properties:
 * - `totalSessions`: Total number of sessions
 * - `totalDurationInSeconds`: Total duration across all sessions
 * - `averageDurationInSeconds`: Average duration per session
 * - `completionRate`: Average completion rate across sessions
 * - `totalOvershootTimeInSeconds`: Total overshoot time across sessions
 */
struct SessionStatistics {
    /// Total number of sessions
    let totalSessions: Int
    
    /// Total duration across all sessions in seconds
    let totalDurationInSeconds: Int
    
    /// Average duration per session in seconds
    let averageDurationInSeconds: Int
    
    /// Average completion rate across sessions (0.0 to 1.0)
    let completionRate: Double
    
    /// Total overshoot time across sessions in seconds
    let totalOvershootTimeInSeconds: Int
    
    /**
     * Formatted total duration string (MM:SS format).
     */
    var totalDurationFormatted: String {
        let minutes = totalDurationInSeconds / 60
        let seconds = totalDurationInSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /**
     * Formatted average duration string (MM:SS format).
     */
    var averageDurationFormatted: String {
        let minutes = averageDurationInSeconds / 60
        let seconds = averageDurationInSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    /**
     * Completion rate as a percentage (0 to 100).
     */
    var completionRatePercentage: Int {
        return Int(completionRate * 100)
    }
    
    /**
     * Formatted total overshoot time string (MM:SS format).
     */
    var totalOvershootTimeFormatted: String {
        let minutes = totalOvershootTimeInSeconds / 60
        let seconds = totalOvershootTimeInSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 

/**
 * RoutinePlayerViewModel
 *
 * ViewModel for the RoutinePlayerView in the Meditation Builder app.
 *
 * ## Responsibilities:
 * - Manages the state and business logic for playing a meditation routine.
 * - Handles timer operations, block transitions, pause/resume, and session completion.
 * - Tracks session events using an event-based approach for robust analytics and persistence.
 * - Exposes computed properties for the current block, progress, and routine completion status.
 * - Coordinates with RoutineDataManager for data persistence and session saving.
 *
 * ## MVVM Role:
 * - Acts as the "ViewModel" in the MVVM architecture, separating UI concerns from business logic.
 * - Provides observable state and actions for the RoutinePlayerView to bind to.
 * - Ensures all SwiftData and UI-related operations are performed on the main actor for thread safety.
 *
 * ## Usage:
 * - Instantiated by RoutinePlayerView with a SavedRoutine and ModelContext.
 * - The view binds to its published properties and invokes its methods for user actions (play, pause, finish, etc).
 * - Handles all logic for progressing through routine blocks, pausing, and session event tracking.
 */
@MainActor
@Observable
class RoutinePlayerViewModel {
    // MARK: - Properties
    /// The routine being played (persistent model)
    private let routine: SavedRoutine
    /// The SwiftData model context for persistence
    private let modelContext: ModelContext
    /// Data manager for routine/session persistence
    private let dataManager: RoutineDataManager
    /// Whether debug mode is enabled (short block durations)
    private let isDebugMode: Bool
    
    // MARK: - Published State
    /// Index of the current block in the routine
    var currentBlockIndex = 0
    /// Timestamp when the routine started
    var routineStartDate = Date()
    /// Timestamp when the current block started
    var blockStartDate = Date()
    /// Whether the routine is currently paused
    var isPaused = false
    /// Timestamp when the routine was paused (if paused)
    var pausedDate: Date?
    /// Total time spent paused during the routine (seconds)
    var totalPausedTime: TimeInterval = 0
    /// Time spent paused during the current block (seconds)
    var blockPausedTime: TimeInterval = 0
    /// Actual meditation time at the moment of pausing (seconds)
    var actualMeditationTimeAtPause: Int = 0
    /// Whether to show the end session alert
    var showingEndSessionAlert = false
    /// Whether to show the discard session alert
    var showingDiscardSessionAlert = false
    /// Whether to show the finish session alert
    var showingFinishAlert = false
    /// The current time (updated by timer)
    var currentTime = Date()
    
    // Session tracking
    /// Event-based session record for analytics and persistence
    private var sessionRecord: SessionRecord?
    
    // MARK: - Computed Properties
    /// The full routine data (decoded from SavedRoutine)
    var routineData: Routine {
        routine.getRoutine()
    }
    /// The current block being played, or nil if complete
    var currentBlock: RoutineBlock? {
        guard currentBlockIndex < routineData.blocks.count else { return nil }
        return routineData.blocks[currentBlockIndex]
    }
    /// The next block in the routine, or nil if at the end
    var nextBlock: RoutineBlock? {
        let nextIndex = currentBlockIndex + 1
        guard nextIndex < routineData.blocks.count else { return nil }
        return routineData.blocks[nextIndex]
    }
    /// Total number of blocks in the routine
    var totalBlocks: Int {
        routineData.blocks.count
    }
    /// Elapsed time since routine start, excluding paused time (seconds)
    var elapsedTime: Int {
        guard !isPaused else {
            let elapsedBeforePause = pausedDate?.timeIntervalSince(routineStartDate) ?? 0
            return max(0, Int(elapsedBeforePause))
        }
        let elapsed = currentTime.timeIntervalSince(routineStartDate) - totalPausedTime
        return max(0, Int(elapsed))
    }
    /// Progress (0.0-1.0) through the current block
    var inBlockProgress: Double {
        guard let block = currentBlock else { return 0.0 }
        let blockDuration: Double = isDebugMode ? 5.0 : Double(block.durationInMinutes * 60)
        let elapsed: TimeInterval
        if isPaused {
            elapsed = (pausedDate?.timeIntervalSince(blockStartDate) ?? 0) - blockPausedTime
        } else {
            elapsed = currentTime.timeIntervalSince(blockStartDate) - blockPausedTime
        }
        return min(1.0, max(0.0, elapsed / blockDuration))
    }
    /// Whether the routine is complete (all blocks finished)
    var isRoutineComplete: Bool {
        currentBlockIndex >= routineData.blocks.count
    }
    
    // MARK: - Initialization
    /**
     * Initialize the view model with a routine and model context.
     * - Parameters:
     *   - routine: The SavedRoutine to play
     *   - modelContext: The SwiftData context for persistence
     */
    init(routine: SavedRoutine, modelContext: ModelContext) {
        self.routine = routine
        self.modelContext = modelContext
        self.dataManager = RoutineDataManager(context: modelContext)
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
    }
    
    // MARK: - Timer Functions
    /// Start the routine timer and session tracking
    func startTimer() {
        logger.info("Starting timer for routine: \(routine.routineName)", category: "Timer")
        routineStartDate = Date()
        currentTime = Date()
        sessionRecord = SessionRecord(routineID: routine.id)
        sessionRecord?.addEvent(.start(routineStartDate))
        guard currentBlockIndex < routineData.blocks.count else {
            logger.info("Timer completed - no more blocks", category: "Timer")
            return
        }
        startCurrentBlock()
    }
    /// Start the current block (reset block timer)
    private func startCurrentBlock() {
        let block = routineData.blocks[currentBlockIndex]
        blockStartDate = Date()
        currentTime = Date()
        blockPausedTime = 0
        logger.info("Starting block: \(block.name)", category: "Timer")
    }
    /// Toggle pause/resume for the routine
    func togglePause() {
        isPaused.toggle()
        if isPaused {
            pausedDate = Date()
            actualMeditationTimeAtPause = Int(pausedDate!.timeIntervalSince(routineStartDate) - totalPausedTime)
            sessionRecord?.addEvent(.pause(pausedDate!))
            logger.info("Timer paused", category: "Timer")
        } else {
            if let pauseStart = pausedDate {
                let resumeTime = Date()
                let pauseDuration = resumeTime.timeIntervalSince(pauseStart)
                guard pauseDuration > 0 && pauseDuration < 86400 else {
                    logger.warning("Invalid pause duration: \(pauseDuration)s - resetting pause state", category: "Timer")
                    pausedDate = nil
                    return
                }
                totalPausedTime += pauseDuration
                blockPausedTime += pauseDuration
                pausedDate = nil
                sessionRecord?.addEvent(.resume(resumeTime))
                logger.info("Timer resumed", category: "Timer")
            } else {
                logger.warning("Resume called but no pause start time recorded", category: "Timer")
            }
        }
    }
    /// Move to the next block in the routine
    func moveToNextBlock() {
        logger.info("Block completed: \(currentBlock?.name ?? "Unknown")", category: "Timer")
        currentBlockIndex += 1
        if currentBlockIndex >= routineData.blocks.count {
            logger.info("Routine completed: \(routine.routineName) - Timer continues", category: "Timer")
        } else {
            startCurrentBlock()
            let nextBlock = routineData.blocks[currentBlockIndex]
            logger.info("Starting next block: \(nextBlock.name)", category: "Timer")
        }
    }
    /// Format a time interval (seconds) as MM:SS string
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
    // MARK: - Session Management
    /**
     * End the session, optionally saving progress.
     * - Parameter saveProgress: Whether to save the session or discard it
     */
    func endSession(saveProgress: Bool) async {
        logger.info("Session \(saveProgress ? "ended" : "discarded") for routine: \(routine.routineName)", category: "Timer")
        let finishTime = Date()
        sessionRecord?.addEvent(.finish(finishTime))
        if let sessionRecord = sessionRecord {
            do {
                try await dataManager.completeSession(using: sessionRecord, routine: routine, wasDiscarded: !saveProgress)
                logger.info("Session \(saveProgress ? "saved" : "discarded") successfully", category: "Session")
            } catch {
                logger.error("Failed to complete session: \(error)", category: "Session")
            }
        }
        cleanup()
    }
    /// Clean up resources and timers (called on view disappear)
    func cleanup() {
        logger.info("Cleaning up timer resources", category: "Timer")
    }
    /// Update the current time (called by timer)
    func updateCurrentTime(_ newTime: Date) {
        currentTime = newTime
        if !isRoutineComplete && inBlockProgress >= 1.0 && !isPaused {
            moveToNextBlock()
        }
    }
} 
