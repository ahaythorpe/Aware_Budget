import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCredibility = false
    @State private var showDevMenu = false
    @State private var previewOnboarding = false
    @State private var previewBFAS = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false
    let totalPatterns = 16

    var awarenessPercent: Double {
        Double(viewModel.biasesSeenCount) / Double(totalPatterns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── GREETING (Nudge-branded notification) ──
                HStack(alignment: .center, spacing: 14) {
                    Image("nudge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.welcomeMessage)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .lineLimit(2)
                            .minimumScaleFactor(0.85)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.todayLabel)
                            .font(.system(.caption, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                    }
                    Spacer(minLength: 8)
                    Button { showDevMenu = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(DS.deepGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(DS.paleGreen, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.deepGreen, lineWidth: 1)
                )
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)

                // ── STREAK + CIRCLE ──
                HStack(spacing: 12) {
                    // Streak card
                    VStack(spacing: 5) {
                        Text("\(viewModel.streak)")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundColor(DS.goldText)
                        Text("🔥 day streak")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(0.8)
                            .foregroundColor(.white.opacity(0.65))
                            .textCase(.uppercase)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(DS.heroGradient)
                    .cornerRadius(DS.cardRadius)

                    // Awareness circle
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(DS.mintBg, lineWidth: 5)
                            Circle()
                                .trim(from: 0, to: CGFloat(awarenessPercent))
                                .stroke(
                                    LinearGradient(
                                        colors: [DS.primary, DS.accent],
                                        startPoint: .leading, endPoint: .trailing),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.2), value: awarenessPercent)
                            Text("\(viewModel.biasesSeenCount)/\(totalPatterns)")
                                .font(.system(size: 10, weight: .black, design: .serif))
                                .foregroundColor(DS.deepGreen)
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(Int(awarenessPercent * 100))%")
                                .font(.system(size: 22, weight: .black, design: .serif))
                                .foregroundColor(DS.deepGreen)
                            Text("Patterns\nidentified")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color.white)
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(DS.accent.opacity(0.2), lineWidth: 0.5))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── CHECK IN ──
                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's check-in")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.white)
                    Button(action: {}) {
                        Text("Start check-in →")
                    }
                    .goldButtonStyle()
                }
                .padding(14)
                .background(DS.heroGradient)
                .cornerRadius(16)
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── MONTH CALENDAR ──
                MonthCalendarView(eventsByDay: viewModel.monthEventsByDay)
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)

                // ── TOP 4 BIASES ──
                TopBiasesCard(
                    patterns: viewModel.dailyPatterns,
                    totalSeen: viewModel.biasesSeenCount,
                    onInfoTap: { showCredibility = true }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── NUDGE ──
                NudgeSaysCard(
                    message: viewModel.nudgeMessage?.body ?? "Stay aware. Adjust early. No shame."
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .background(DS.bg)
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .sheet(isPresented: $showCredibility) {
            CredibilitySheet()
        }
        .sheet(isPresented: $showDevMenu) {
            devMenu
        }
        .fullScreenCover(isPresented: $previewOnboarding) {
            OnboardingView(hasCompletedOnboarding: .constant(false))
                .overlay(alignment: .topTrailing) {
                    Button("Close") { previewOnboarding = false }
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.35), in: Capsule())
                        .padding(.top, 60)
                        .padding(.trailing, 16)
                }
        }
        .fullScreenCover(isPresented: $previewBFAS) {
            BFASAssessmentView { _ in previewBFAS = false }
                .overlay(alignment: .topTrailing) {
                    Button("Close") { previewBFAS = false }
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(DS.cardBg, in: Capsule())
                        .padding(.top, 60)
                        .padding(.trailing, 16)
                }
        }
    }

    private var devMenu: some View {
        NavigationStack {
            List {
                Section("Preview flows") {
                    Button {
                        showDevMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            previewOnboarding = true
                        }
                    } label: {
                        Label("Preview OnboardingView", systemImage: "rectangle.stack")
                    }
                    Button {
                        showDevMenu = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            previewBFAS = true
                        }
                    } label: {
                        Label("Preview BFAS assessment", systemImage: "list.bullet.clipboard")
                    }
                }
                Section("Reset flags") {
                    Button("Reset onboarding + BFAS", role: .destructive) {
                        hasCompletedOnboarding = false
                        hasCompletedBFAS = false
                        showDevMenu = false
                    }
                    Button("Reset weekly review flag") {
                        UserDefaults.standard.removeObject(forKey: "weeklyReviewDone")
                        showDevMenu = false
                    }
                    Button("Reset demo data seed flag") {
                        UserDefaults.standard.removeObject(forKey: "demoDataSeeded")
                        showDevMenu = false
                    }
                }
                Section("State") {
                    HStack {
                        Text("Onboarding")
                        Spacer()
                        Text(hasCompletedOnboarding ? "Done" : "Pending")
                            .foregroundStyle(DS.textSecondary)
                    }
                    HStack {
                        Text("BFAS assessment")
                        Spacer()
                        Text(hasCompletedBFAS ? "Done" : "Pending")
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                Section {
                    Text("DEBUG builds skip onboarding + BFAS and go straight to Home. Reset flags above, then cold-launch the app from Xcode (⌘R) to preview the gated flows.")
                        .font(.system(.footnote, weight: .regular))
                        .foregroundStyle(DS.textSecondary)
                }
            }
            .navigationTitle("Dev")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showDevMenu = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
