import Foundation
import UserNotifications
import SwiftUI

/// Non-slot notification routes. Each value is the `userInfo["route"]`
/// payload key set on the scheduled notification. Add new routes here +
/// teach a view to react via `NotificationRouter.shared.pendingRoute`.
enum NotificationRoute: String {
    /// Open the Home tab's finance editor sheet (income/savings/investment).
    /// Used by the "Add your numbers" first-week reminder so a tap from
    /// the lock screen lands on the same UI as the Home empty-state CTA.
    case openFinanceEditor = "finance_editor"

    /// Switch to the Insights tab. Used by the weekly review push (Sunday
    /// 10am) and the monthly checkpoint push (1st of month 10am) — both
    /// are "look at the data" prompts, not "log new data" prompts, so
    /// they should land on Insights rather than the Log/Quick-log surface.
    case openInsights = "insights"
}

/// Catches notification taps and routes them into the app. When the
/// user taps a smart-nudge alert (morning / lunch / evening / chunky),
/// we set `pendingSlot` here. RootTabView observes it and switches to
/// the Log tab; MoneyEventView reads the slot's
/// `highlightedCategories` and visually highlights matching tiles.
///
/// Some notifications open Home flows instead of the Log tab — those
/// set `pendingRoute` (currently only `.openFinanceEditor`). Existing
/// slot-based routing is unchanged; the route is additive.
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationRouter()

    /// Set when a notification is tapped. Cleared by the consumer
    /// (RootTabView / MoneyEventView) once it's been acted on.
    var pendingSlot: NotificationSlot?

    /// Non-slot routes that target Home flows. HomeView observes and
    /// clears once handled. Kept separate from `pendingSlot` so the
    /// existing Log-tab routing logic stays untouched.
    var pendingRoute: NotificationRoute?

    /// Wire as the system-wide notification delegate. Call once at
    /// app launch from `GoldMindApp.task`.
    static func install() {
        UNUserNotificationCenter.current().delegate = shared
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Called when the user taps a notification. Reads the
    /// `userInfo["slot"]` payload set by NotificationService and
    /// stashes it for the UI to consume.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let info = response.notification.request.content.userInfo
        if let raw = info["slot"] as? String,
           let slot = NotificationSlot(rawValue: raw) {
            // Hop to main actor for the @Observable mutation.
            Task { @MainActor in
                self.pendingSlot = slot
            }
        }
        if let raw = info["route"] as? String,
           let route = NotificationRoute(rawValue: raw) {
            Task { @MainActor in
                self.pendingRoute = route
            }
        }
        completionHandler()
    }

    /// Show the alert in-app too if the user is foregrounded.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
