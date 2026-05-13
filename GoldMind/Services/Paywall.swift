import Foundation
import RevenueCat

/// Single source of truth for whether the current user has an active
/// `GoldMind Pro` entitlement. Subscribes to `customerInfoStream` so any
/// purchase, restore, or expiry updates `isPro` without UI having to refetch.
@Observable
@MainActor
final class PaywallStore {
    static let shared = PaywallStore()

    /// Entitlement identifier as configured in the RevenueCat dashboard.
    /// Note: includes a space — `Purchases.shared.entitlements[Self.entitlementID]`
    /// must use this exact string.
    static let entitlementID = "GoldMind Pro"

    var isPro = false

    /// `false` until the first `customerInfo` round-trip completes — gate views
    /// should show a spinner during this window so the paywall doesn't flash
    /// for a paying user on cold start.
    var hasLoaded = false

    /// DEBUG-only lock that prevents `apply(_:)` from overwriting the
    /// forced-pro state with real RevenueCat data. Set by
    /// `forceProForScreenshots()` so screenshot-mode launches don't get
    /// clobbered the moment Purchases finishes its first round-trip.
    private var screenshotBypassLocked = false

    private init() {}

    func start() {
        Task {
            if let info = try? await Purchases.shared.customerInfo() {
                apply(info)
            }
            hasLoaded = true
            for await info in Purchases.shared.customerInfoStream {
                apply(info)
            }
        }
    }

    private func apply(_ info: CustomerInfo) {
        guard !screenshotBypassLocked else { return }
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
    }

    #if DEBUG
    /// DEBUG-only paywall bypass for App Store screenshot capture.
    /// Called from `GoldMindApp.init` when `-ScreenshotMode YES` is
    /// passed as a launch argument or `screenshotMode = true` is set
    /// in UserDefaults. Forces both `isPro` and `hasLoaded` so the
    /// root navigator skips both the paywall and the loading spinner.
    /// Has zero effect on Release builds.
    func forceProForScreenshots() {
        screenshotBypassLocked = true
        isPro = true
        hasLoaded = true
    }
    #endif
}
