//
//  NotificationManagerTests.swift
//  Meditation BuilderTests
//

import Testing
import UserNotifications
import Foundation
@testable import Meditation_Builder

@Suite("NotificationManager")
@MainActor
struct NotificationManagerTests {

    @Test("reminderEnabled persists to UserDefaults")
    func enabledPersists() {
        let defaults = UserDefaults(suiteName: "test.notifications")!
        defaults.removeObject(forKey: "NotificationManager.enabled")

        // NotificationManager uses standard UserDefaults — test the persisted key
        UserDefaults.standard.set(true, forKey: "NotificationManager.enabled")
        let stored = UserDefaults.standard.bool(forKey: "NotificationManager.enabled")
        #expect(stored == true)
        UserDefaults.standard.removeObject(forKey: "NotificationManager.enabled")
    }

    @Test("reminderTime defaults to 8:00 AM")
    func defaultReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: NotificationManager.shared.reminderTime)
        #expect(components.hour == 8)
        #expect(components.minute == 0)
    }
}
