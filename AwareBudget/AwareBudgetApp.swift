import SwiftUI

@main
struct AwareBudgetApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var checkingSession = true

    var body: some Scene {
        WindowGroup {
            Group {
                if checkingSession {
                    ZStack {
                        DS.bg.ignoresSafeArea()
                        ProgressView()
                    }
                } else if hasCompletedOnboarding {
                    RootTabView()
                        .task {
                            await NotificationService.requestPermission()
                            NotificationService.scheduleMorningReminder()
                            NotificationService.scheduleEveningNudge()
                            NotificationService.scheduleNoEventsReminder()
                        }
                } else {
                    OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                }
            }
            .task {
                // Check for existing Supabase session
                if !hasCompletedOnboarding {
                    if await SupabaseService.shared.currentUserId != nil {
                        hasCompletedOnboarding = true
                    }
                }
                checkingSession = false
            }
        }
    }
}
