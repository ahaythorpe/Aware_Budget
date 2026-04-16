import SwiftUI

@main
struct AwareBudgetApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false
    @State private var checkingSession = true

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
                } else if !hasCompletedBFAS {
                    BFASAssessmentView { answers in
                        Task {
                            try? await SupabaseService.shared.saveBFASAssessment(answers: answers)
                            await MainActor.run { hasCompletedBFAS = true }
                        }
                    }
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
                checkingSession = false
            }
        }
    }
}
