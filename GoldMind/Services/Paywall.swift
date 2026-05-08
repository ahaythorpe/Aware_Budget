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
        isPro = info.entitlements[Self.entitlementID]?.isActive == true
    }
}
