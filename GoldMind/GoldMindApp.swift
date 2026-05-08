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
                } else if !hasCompletedBFAS {
                    BFASAssessmentView { answers in
                        Task {
                            try? await SupabaseService.shared.saveBFASAssessment(answers: answers)
                            await MainActor.run { hasCompletedBFAS = true }
                        }
                    }
                } else if !paywall.hasLoaded {
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
                            await scheduleSmartNudgesFromHistory()
                        }
                }
            }
            .task {
                #if DEBUG
                await SupabaseService.shared.ensureDebugSession()
                #endif
                NotificationRouter.install()
                auth.start()
                paywall.start()
                checkingSession = false
            }
        }
    }
}
