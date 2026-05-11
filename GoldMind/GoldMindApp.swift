import SwiftUI
import RevenueCat
import RevenueCatUI

@main
struct GoldMindApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false
    @State private var checkingSession = true
    @State private var paywall = PaywallStore.shared
    @State private var auth = AuthStore.shared

    init() {
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: "appl_XFOSSZlyhbOaxldNVLKSAZnkJmg")
        // Install the UNUserNotificationCenter delegate synchronously at
        // launch — BEFORE any async work in .task — so the delegate is
        // already in place if iOS cold-launches the app from a notification
        // tap (Apple calls didReceive on launch in that flow). Previously
        // the install happened after `ensureDebugSession()` which could
        // race the OS callback in DEBUG. Required for reliable deep-link
        // routing in all build configs.
        NotificationRouter.install()
    }

    /// Pulls last 30 days of events, computes user's median log hour per
    /// slot, schedules smart nudges at those hours. See F / LogTimeAnalytics.
    private func scheduleSmartNudgesFromHistory() async {
        let events = (try? await SupabaseService.shared.fetchMoneyEvents(forMonth: Date())) ?? []
        let hours = LogTimeAnalytics.medianHours(from: events)
        NotificationService.scheduleSmartNudges(hours: hours)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if checkingSession {
                    ZStack {
                        DS.bg.ignoresSafeArea()
                        ProgressView()
                    }
                } else if !hasCompletedOnboarding {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                } else if !auth.hasLoaded {
                    ZStack {
                        DS.bg.ignoresSafeArea()
                        ProgressView()
                    }
                } else if !auth.isAuthenticated {
                    SignInView()
                } else if !paywall.hasLoaded {
                    // BFAS auto-prompt removed 2026-05-11. Money Mind Quiz
                    // is now the primary entry-level assessment surfaced
                    // from Home + Education. BFAS remains available as an
                    // opt-in deeper assessment via Settings for users who
                    // want the full 16-question clinical version.
                    ZStack {
                        DS.bg.ignoresSafeArea()
                        ProgressView()
                    }
                } else if !paywall.isPro {
                    PaywallView(displayCloseButton: false)
                } else {
                    RootTabView()
                        .task {
                            await NotificationService.requestPermission()
                            NotificationService.scheduleMorningReminder()
                            NotificationService.scheduleEveningNudge()
                            NotificationService.scheduleNoEventsReminder()
                            NotificationService.scheduleWeeklyReview()
                            NotificationService.scheduleMonthlyCheckpoint()
                            NotificationService.scheduleAddNumbersReminder()
                            await scheduleSmartNudgesFromHistory()
                        }
                }
            }
            .task {
                #if DEBUG
                await SupabaseService.shared.ensureDebugSession()
                #endif
                // NotificationRouter.install() moved to init() so it
                // runs synchronously at launch — see comment there.
                auth.start()
                paywall.start()
                checkingSession = false
            }
        }
    }
}
