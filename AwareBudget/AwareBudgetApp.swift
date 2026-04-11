import SwiftUI

@main
struct AwareBudgetApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            RootView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
    }
}

struct RootView: View {
    @Binding var hasCompletedOnboarding: Bool

    var body: some View {
        NavigationStack {
            if hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            }
        }
    }
}
