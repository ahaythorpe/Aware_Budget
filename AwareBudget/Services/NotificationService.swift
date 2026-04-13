import Foundation
import UserNotifications

enum NotificationService {
    private static let morningID  = "awarebudget.morning"
    private static let eveningID  = "awarebudget.evening.nudge"
    private static let noEventsID = "awarebudget.no.events"
    private static let biasHitID  = "awarebudget.bias.hit"

    // MARK: - Permission

    static func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Permission denied — app works without notifications.
        }
    }

    // MARK: - 1. Morning reminder (8am daily)

    static func scheduleMorningReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [morningID])

        let content = UNMutableNotificationContent()
        content.title = "AwareBudget"
        content.body = "One question. 60 seconds. Nudge is waiting."
        content.sound = .default

        var components = DateComponents()
        components.hour = 8
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: morningID, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - 2. Evening nudge (7pm if no check-in today)

    static func scheduleEveningNudge() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [eveningID])

        let content = UNMutableNotificationContent()
        content.title = "AwareBudget"
        content.body = "Nudge noticed."
        content.sound = .default

        var components = DateComponents()
        components.hour = 19
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: eveningID, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - 3. No events in 48h

    static func scheduleNoEventsReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [noEventsID])

        let content = UNMutableNotificationContent()
        content.title = "AwareBudget"
        content.body = "Nudge has no data. That's also information."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: noEventsID, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - 4. Bias hits threshold

    static func scheduleBiasAlert(biasName: String, count: Int) {
        let center = UNUserNotificationCenter.current()
        let id = "\(biasHitID).\(biasName)"
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let content = UNMutableNotificationContent()
        content.title = "AwareBudget"
        content.body = "\(biasName) appeared \(count) times. Nudge has something."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Cancel evening nudge (user checked in)

    static func cancelEveningNudge() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [eveningID])
    }

    // MARK: - Reset no-events timer (user logged an event)

    static func resetNoEventsTimer() {
        scheduleNoEventsReminder()
    }

    // MARK: - Legacy compatibility

    static func scheduleDailyReminder() {
        scheduleMorningReminder()
        scheduleEveningNudge()
    }

    static func cancelIfCheckedIn() {
        cancelEveningNudge()
    }
}
