import Foundation
import Supabase

/// Single source of truth for whether a user is signed in. The app gate in
/// `AwareBudgetApp.swift` reads `isAuthenticated` to decide between
/// `SignInView` and the rest of the flow. Mirrors the pattern of
/// `PaywallStore` for consistency.
@Observable
@MainActor
final class AuthStore {
    static let shared = AuthStore()

    var isAuthenticated = false

    /// `false` until the first session check completes. Gate views show a
    /// spinner during this window so the SignInView doesn't flash for a
    /// signed-in user on cold start.
    var hasLoaded = false

    private init() {}

    func start() {
        Task {
            isAuthenticated = await SupabaseService.shared.hasSession()
            hasLoaded = true

            // Re-check on auth state changes (sign-in, sign-out, refresh,
            // token expiry). Supabase emits an event for each transition;
            // recompute by reading the session directly so we stay correct
            // even if the event payload schema shifts.
            for await _ in SupabaseService.shared.client.auth.authStateChanges {
                isAuthenticated = await SupabaseService.shared.hasSession()
            }
        }
    }
}
