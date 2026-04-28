//
//  Logger.swift
//  Meditation Builder
//
//  Created by harsh  on 09/07/25.
//

import Foundation
import os.log
import OSLog
import Observation

/// Centralized logging utility for the Meditation Builder app
/// Provides multiple log levels, file persistence, and rotation capabilities
@MainActor
@Observable
class AppLogger {
    static let shared = AppLogger()
    
    // MARK: - Log Levels
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
    
    // MARK: - Properties
    private let osLog: OSLog
    private let fileManager = FileManager.default
    private let logDirectory: URL
    private let maxLogFileSize: Int64 = 5 * 1024 * 1024 // 5MB
    private let maxLogFiles = 10
    private let dateFormatter: DateFormatter
    
    var isLoggingEnabled = true
    var currentLogLevel: LogLevel = .info
    
    // MARK: - Initialization
    private init() {
        self.osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.meditationbuilder", category: "App")
        
        // Create log directory
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.logDirectory = documentsPath.appendingPathComponent("Logs")
        
        do {
            try fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create log directory: \(error)")
        }
        
        // Configure date formatter
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        self.dateFormatter.timeZone = TimeZone.current
        
        // Load settings
        loadSettings()
        
        // Debug prints to verify initialization
        print("AppLogger: Initialization started")
        print("AppLogger: isLoggingEnabled = \(isLoggingEnabled)")
        print("AppLogger: currentLogLevel = \(currentLogLevel.rawValue)")
        
        // Log app startup
        log(.info, "AppLogger initialized", category: "System")
        
        print("AppLogger: Initialization completed")
    }
    
    // MARK: - Public Logging Methods
    
    /// Log a message with the specified level and category
    func log(_ level: LogLevel, _ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        guard isLoggingEnabled && level >= currentLogLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(level.emoji) [\(timestamp)] [\(level.rawValue)] [\(category)] [\(fileName):\(line)] \(function): \(message)"
        
        // Log to system
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        
        // Log to file
        writeToFile(logMessage)
        
        #if DEBUG
        // Print to console in debug builds
        print(logMessage)
        #endif
    }
    
    /// Convenience methods for different log levels
    func debug(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, category: category, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, category: category, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, category: category, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "General", file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, category: category, file: file, function: function, line: line)
    }
    
    /// Log an error with additional context
    func error(_ error: Error, context: String = "", category: String = "Error", file: String = #file, function: String = #function, line: Int = #line) {
        let message = "\(context.isEmpty ? "" : "\(context): ")\(error.localizedDescription)"
        log(.error, message, category: category, file: file, function: function, line: line)
    }
    
    // MARK: - File Management
    
    private func writeToFile(_ message: String) {
        let logFile = getCurrentLogFile()
        let logEntry = message + "\n"
        
        do {
            if fileManager.fileExists(atPath: logFile.path) {
                // Check file size and rotate if needed
                let attributes = try fileManager.attributesOfItem(atPath: logFile.path)
                let fileSize = attributes[.size] as? Int64 ?? 0
                
                if fileSize > maxLogFileSize {
                    rotateLogFiles()
                }
            }
            
            // Append to file
            if let data = logEntry.data(using: .utf8) {
                if fileManager.fileExists(atPath: logFile.path) {
                    let fileHandle = try FileHandle(forWritingTo: logFile)
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                } else {
                    try data.write(to: logFile)
                }
            }
        } catch {
            print("Failed to write to log file: \(error)")
        }
    }
    
    private func getCurrentLogFile() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return logDirectory.appendingPathComponent("meditation-builder-\(dateString).log")
    }
    
    private func rotateLogFiles() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        let currentLogFile = getCurrentLogFile()
        let rotatedLogFile = logDirectory.appendingPathComponent("meditation-builder-\(timestamp).log")
        
        do {
            try fileManager.moveItem(at: currentLogFile, to: rotatedLogFile)
            cleanupOldLogFiles()
        } catch {
            print("Failed to rotate log file: \(error)")
        }
    }
    
    private func cleanupOldLogFiles() {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "log" }
                .sorted { file1, file2 in
                    let date1 = try file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1 > date2
                }
            
            // Keep only the most recent files
            if logFiles.count > maxLogFiles {
                for file in logFiles[maxLogFiles...] {
                    try fileManager.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to cleanup old log files: \(error)")
        }
    }
    
    // MARK: - Settings Management
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Check if this is the first launch (no key exists)
        if defaults.object(forKey: "AppLogger.isLoggingEnabled") == nil {
            // First launch - enable logging by default
            isLoggingEnabled = true
            currentLogLevel = .info
            saveSettings()
        } else {
            // Load saved settings
            isLoggingEnabled = defaults.bool(forKey: "AppLogger.isLoggingEnabled")
            if let levelString = defaults.string(forKey: "AppLogger.currentLogLevel"),
               let level = LogLevel(rawValue: levelString) {
                currentLogLevel = level
            }
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isLoggingEnabled, forKey: "AppLogger.isLoggingEnabled")
        defaults.set(currentLogLevel.rawValue, forKey: "AppLogger.currentLogLevel")
    }
    
    // MARK: - Log Retrieval
    
    /// Get recent log entries for debugging
    func getRecentLogs(limit: Int = 100) -> [String] {
        let logFile = getCurrentLogFile()
        
        do {
            let content = try String(contentsOf: logFile, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            return Array(lines.suffix(limit))
        } catch {
            return []
        }
    }
    
    /// Get all log files
    func getAllLogFiles() -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "log" }
                .sorted { file1, file2 in
                    let date1 = try file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    /// Clear all log files
    func clearAllLogs() {
        do {
            let logFiles = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: nil)
                .filter { $0.pathExtension == "log" }
            
            for file in logFiles {
                try fileManager.removeItem(at: file)
            }
            
            log(.info, "All log files cleared", category: "System")
        } catch {
            log(.error, "Failed to clear log files: \(error)", category: "System")
        }
    }
}

// MARK: - Convenience Extensions

extension AppLogger.LogLevel: Comparable {
    static func < (lhs: AppLogger.LogLevel, rhs: AppLogger.LogLevel) -> Bool {
        let order: [AppLogger.LogLevel] = [.debug, .info, .warning, .error, .critical]
        guard let lhsIndex = order.firstIndex(of: lhs),
              let rhsIndex = order.firstIndex(of: rhs) else {
            return false
        }
        return lhsIndex < rhsIndex
    }
}

// MARK: - Global Logger Access

/// Global logger instance for easy access
let logger = AppLogger.shared

// MARK: - Crashlytics Integration (Optional)

#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics

extension AppLogger {
    /// Send logs to Crashlytics for post-mortem analysis
    func sendToCrashlytics() {
        let recentLogs = getRecentLogs(limit: 50)
        let logString = recentLogs.joined(separator: "\n")
        
        Crashlytics.crashlytics().setCustomValue(logString, forKey: "recent_logs")
        Crashlytics.crashlytics().log("Recent app logs: \(logString)")
    }
}
#endif 