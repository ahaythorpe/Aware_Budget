import Foundation
import UserNotifications

/// Time-of-day slots used to deep-link a notification tap into the
/// matching pre-filtered Quick log surface. Stored in the
/// notification's `userInfo["slot"]` and read back by
/// `NotificationRouter` when the user taps the alert.
enum NotificationSlot: String {
    case morning   // ~11am — coffee/breakfast
    case lunch     // ~2pm — lunch
    case evening   // ~7pm — dinner / after work
    case chunky    // 9pm — one-off larger purchases

    /// Categories to pre-highlight on the Log tab when this slot's
    /// notification is tapped. Match cat.name against this list.
    var highlightedCategories: [String] {
        switch self {
        case .morning: return ["Coffee", "Lunch"]
        case .lunch:   return ["Lunch", "Coffee", "Eating out"]
        case .evening: return ["Eating out", "Drinks", "Lunch"]
        case .chunky:  return ["Shopping", "Travel", "Subscriptions", "Big purchase"]
        }
    }
}

enum NotificationService {
    private static let morningID  = "goldmind.morning"
    private static let eveningID  = "goldmind.evening.nudge"
    private static let noEventsID = "goldmind.no.events"
    private static let biasHitID  = "goldmind.bias.hit"

    // Smart time-of-day nudges (F — personalised to user's log hours)
    private static let smartMorningID   = "goldmind.smart.morning"
    private static let smartAfternoonID = "goldmind.smart.afternoon"
    private static let smartEveningID   = "goldmind.smart.evening"
    /// 9pm end-of-day prompt for one-off chunky buys (Shopping, Travel,
    /// Subscriptions, Big purchase) the user might've missed during the
    /// day. Surface-level reminder so the day's data isn't incomplete.
    private static let chunkyBuysID     = "goldmind.chunky.buys"

    // Weekly + monthly review pushes
    private static let weeklyReviewID  = "goldmind.weekly"
    private static let monthlyCheckpointID = "goldmind.monthly"

    /// "Add your numbers" first-week reminder. Fires 48h after install if
    /// the user has not yet entered any finance numbers. Tap routes to
    /// the Home finance editor via NotificationRoute.openFinanceEditor.
    private static let addNumbersReminderID = "goldmind.add.numbers"

    // Meal-anchored copy. Default fire times are 11/14/19, refined by
    // LogTimeAnalytics once the user has 30 days of logs.
    private static let morningBodies = [
        "Coffee or breakfast spend today?",
        "☕ Quick log: anything before work?",
        "Morning purchase to capture?",
    ]
    private static let afternoonBodies = [
        "Lunch happen?",
        "🥗 Midday spend to log?",
        "What did lunch cost?",
    ]
    private static let eveningBodies = [
        "Dinner or after-work spend?",
        "🍽️ Wrap the day's logs?",
        "Anything from the evening to log?",
    ]
    /// End-of-day catch for chunky one-offs the meal slots wouldn't catch.
    private static let chunkyBuysBodies = [
        "Anything chunky today? Shopping, travel, sub renewals, big buys.",
        "💸 One-off purchases worth logging?",
        "Any out-of-pattern spend today?",
    ]

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
        content.title = "GoldMind"
        content.body = "One question. 60 seconds. Nudge is waiting."
        content.sound = .default
        content.userInfo["slot"] = NotificationSlot.morning.rawValue

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
        content.title = "GoldMind"
        content.body = "Nudge noticed."
        content.sound = .default
        content.userInfo["slot"] = NotificationSlot.evening.rawValue

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
        content.title = "GoldMind"
        content.body = "Nudge has no data. That's also information."
        content.sound = .default
        // Default to morning slot so the tap still lands in Quick Log
        // pre-filtered for breakfast / coffee.
        content.userInfo["slot"] = NotificationSlot.morning.rawValue

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
        content.title = "GoldMind"
        content.body = "\(biasName) appeared \(count) times. Nudge has something."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - "Add your numbers" first-week reminder

    /// Schedules a one-shot reminder 48h after install nudging the user
    /// to add their income/savings/investment numbers. Tap deep-links to
    /// the Home finance editor (NotificationRoute.openFinanceEditor).
    /// Idempotent — calling it again replaces the pending request.
    static func scheduleAddNumbersReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [addNumbersReminderID])

        let content = UNMutableNotificationContent()
        content.title = "GoldMind"
        content.body = "Two minutes. Add your income and savings so Nudge can see the picture."
        content.sound = .default
        content.userInfo["route"] = NotificationRoute.openFinanceEditor.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 48 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: addNumbersReminderID, content: content, trigger: trigger)
        center.add(request)
    }

    /// Cancel the pending "add your numbers" reminder once the user
    /// has actually entered numbers — call from finance save path.
    static func cancelAddNumbersReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [addNumbersReminderID])
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

    // MARK: - Smart time-of-day nudges (F)

    /// Schedule 3 daily pushes at the user's median logging hours.
    /// Copy rotates per slot. Falls back to 11/14/19 defaults if
    /// history is thin. See LogTimeAnalytics.
    static func scheduleSmartNudges(hours: LogTimeAnalytics.SlotHours) {
        scheduleSmart(id: smartMorningID, hour: hours.morning, bodies: morningBodies, slot: .morning)
        scheduleSmart(id: smartAfternoonID, hour: hours.afternoon, bodies: afternoonBodies, slot: .lunch)
        scheduleSmart(id: smartEveningID, hour: hours.evening, bodies: eveningBodies, slot: .evening)
        scheduleChunkyBuysReminder()
    }

    // MARK: - End-of-day chunky-buys reminder (9pm daily)

    /// Catches one-off larger purchases (Shopping, Travel, Subscriptions,
    /// Big purchase) that wouldn't naturally come up during the meal-slot
    /// nudges. Fires at 9pm so the user can sweep the day before sleep.
    static func scheduleChunkyBuysReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [chunkyBuysID])

        let body = chunkyBuysBodies.randomElement() ?? chunkyBuysBodies[0]
        let content = UNMutableNotificationContent()
        content.title = "GoldMind"
        content.body = body
        content.sound = .default
        content.userInfo["slot"] = NotificationSlot.chunky.rawValue

        var components = DateComponents()
        components.hour = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: chunkyBuysID, content: content, trigger: trigger)
        center.add(request)
    }

    private static func scheduleSmart(id: String, hour: Int, bodies: [String], slot: NotificationSlot? = nil) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let body = bodies.randomElement() ?? bodies[0]
        let content = UNMutableNotificationContent()
        content.title = "GoldMind"
        content.body = body
        content.sound = .default
        if let slot {
            content.userInfo["slot"] = slot.rawValue
        }

        var components = DateComponents()
        components.hour = hour
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Weekly review push (Sunday 10am)

    static func scheduleWeeklyReview() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [weeklyReviewID])

        let content = UNMutableNotificationContent()
        content.title = "GoldMind"
        content.body = ["Your week, without the story.",
                        "A week richer in insights.",
                        "Seven days, laid bare.",
                        "Sunday review is ready."].randomElement() ?? "Weekly review ready."
        content.sound = .default

        var components = DateComponents()
        components.weekday = 1  // Sunday
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: weeklyReviewID, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Monthly checkpoint push (1st of each month 10am)

    static func scheduleMonthlyCheckpoint() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [monthlyCheckpointID])

        let content = UNMutableNotificationContent()
        content.title = "GoldMind"
        content.body = ["A month in. Let's see what moved.",
                        "Thirty days of small truths.",
                        "Still yes? Still no?",
                        "Monthly checkpoint — not a grade."].randomElement() ?? "Monthly checkpoint."
        content.sound = .default

        var components = DateComponents()
        components.day = 1      // 1st of month
        components.hour = 10
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: monthlyCheckpointID, content: content, trigger: trigger)
        center.add(request)
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
