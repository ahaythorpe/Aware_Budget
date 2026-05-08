import Foundation
import UserNotifications
import SwiftUI

/// Catches notification taps and routes them into the app. When the
/// user taps a smart-nudge alert (morning / lunch / evening / chunky),
/// we set `pendingSlot` here. RootTabView observes it and switches to
/// the Log tab; MoneyEventView reads the slot's
/// `highlightedCategories` and visually highlights matching tiles.
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {

    static let shared = NotificationRouter()

    /// Set when a notification is tapped. Cleared by the consumer
    /// (RootTabView / MoneyEventView) once it's been acted on.
    var pendingSlot: NotificationSlot?

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
        if let raw = response.notification.request.content.userInfo["slot"] as? String,
           let slot = NotificationSlot(rawValue: raw) {
            // Hop to main actor for the @Observable mutation.
            Task { @MainActor in
                self.pendingSlot = slot
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
