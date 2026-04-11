import Foundation
import UserNotifications

enum NotificationService {
    private static let dailyIdentifier = "awarebudget.daily.reminder"

    static func requestPermission() async {
        do {
            _ = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            // Permission denied or error — silently ignore; the app works without notifications.
        }
    }

    static func scheduleDailyReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "AwareBudget check-in"
        let bodies = [
            "60 seconds. That's all it takes.",
            "How's your awareness today?",
            "Your streak is waiting."
        ]
        content.body = bodies.randomElement() ?? bodies[0]
        content.sound = .default

        var components = DateComponents()
        components.hour = 20
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyIdentifier, content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelIfCheckedIn() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyIdentifier])
    }
}
