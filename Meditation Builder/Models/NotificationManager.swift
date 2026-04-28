//
//  NotificationManager.swift
//  Meditation Builder
//

import Foundation
import UserNotifications
import Observation

@MainActor
@Observable
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    var reminderEnabled = false {
        didSet {
            if reminderEnabled { scheduleReminder() } else { cancelReminder() }
            UserDefaults.standard.set(reminderEnabled, forKey: Keys.enabled)
        }
    }

    var reminderTime: Date = NotificationManager.defaultReminderTime {
        didSet {
            UserDefaults.standard.set(reminderTime, forKey: Keys.time)
            if reminderEnabled { scheduleReminder() }
        }
    }

    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private static let reminderIdentifier = "meditation-daily-reminder"
    private enum Keys {
        static let enabled = "NotificationManager.enabled"
        static let time = "NotificationManager.time"
    }

    private static var defaultReminderTime: Date {
        Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        loadSettings()
        Task { await refreshAuthorizationStatus() }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            logger.error("Notification authorization error: \(error)", category: "Notifications")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    // MARK: - Scheduling

    func scheduleReminder() {
        Task {
            guard await requestAuthorization() else { return }
            cancelReminder()

            let content = UNMutableNotificationContent()
            content.title = "Time to Meditate"
            content.body = "Your daily meditation practice is waiting."
            content.sound = .default

            var components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: Self.reminderIdentifier,
                content: content,
                trigger: trigger
            )
            do {
                try await UNUserNotificationCenter.current().add(request)
                logger.info("Daily meditation reminder scheduled at \(components.hour ?? 0):\(String(format: "%02d", components.minute ?? 0))", category: "Notifications")
            } catch {
                logger.error("Failed to schedule reminder: \(error)", category: "Notifications")
            }
        }
    }

    func cancelReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
        logger.info("Daily reminder cancelled", category: "Notifications")
    }

    // MARK: - Foreground Handling

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Persistence

    private func loadSettings() {
        reminderEnabled = UserDefaults.standard.bool(forKey: Keys.enabled)
        if let saved = UserDefaults.standard.object(forKey: Keys.time) as? Date {
            reminderTime = saved
        }
    }
}
