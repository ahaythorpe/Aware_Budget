import SwiftUI

@main
struct AwareBudgetApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false
    @State private var checkingSession = true

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            RootTabView()
                .task {
                    await NotificationService.requestPermission()
                    NotificationService.scheduleMorningReminder()
                    NotificationService.scheduleEveningNudge()
                    NotificationService.scheduleNoEventsReminder()
                }
            #else
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
                        }
                }
            }
            .task {
                if !hasCompletedOnboarding {
                    if await SupabaseService.shared.currentUserId != nil {
                        hasCompletedOnboarding = true
                    }
                }
                checkingSession = false
            }
            #endif
        }
    }
}
