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
        NotificationRouter.install()

        #if DEBUG
        // SCREENSHOT MODE — DEBUG-only paywall bypass for capturing
        // App Store screenshots without a sandbox purchase loop.
        // Activated by adding `-ScreenshotMode YES` to the Xcode
        // scheme's launch arguments (Product → Scheme → Edit Scheme
        // → Run → Arguments). Forces PaywallStore.isPro = true so the
        // root navigator skips the paywall and lands on RootTabView.
        if ProcessInfo.processInfo.arguments.contains("-ScreenshotMode")
            || UserDefaults.standard.bool(forKey: "screenshotMode") {
            PaywallStore.shared.forceProForScreenshots()
        }
        #endif
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
                            // Nothing queues in the OS pending list until
                            // the user actually grants permission. Banner
                            // grant path in HomeView mirrors this flow.
                            let granted = await NotificationService.requestPermission()
                            guard granted else {
                                NotificationService.cancelAll()
                                return
                            }
                            NotificationService.scheduleAll()
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
