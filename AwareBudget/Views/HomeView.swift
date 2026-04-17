import SwiftUI

struct HomeView: View {
    var selectedTab: Binding<RootTab>? = nil

    @State private var viewModel = HomeViewModel()
    @State private var showCredibility = false
    @State private var showDevMenu = false
    @State private var previewOnboarding = false
    @State private var previewBFAS = false
    @State private var showCheckIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false

    private enum CheckInMode {
        case daily, weekly, monthly
        var title: String {
            switch self {
            case .daily:   return "Today's check-in"
            case .weekly:  return "Sunday review"
            case .monthly: return "Monthly checkpoint"
            }
        }
        var subtitle: String {
            switch self {
            case .daily:   return "5 quick swipes · 30 sec"
            case .weekly:  return "Last week's patterns — let's revisit"
            case .monthly: return "Re-checking the biases you flagged"
            }
        }
        var cta: String {
            switch self {
            case .daily:   return "Start check-in →"
            case .weekly:  return "Start weekly review →"
            case .monthly: return "Start monthly checkpoint →"
            }
        }
    }

    private var checkInMode: CheckInMode {
        if MonthlyReviewTracker.isDueNow() { return .monthly }
        if WeeklyReviewTracker.isDueNow() { return .weekly }
        return .daily
    }
    let totalPatterns = 16

    var awarenessPercent: Double {
        Double(viewModel.biasesSeenCount) / Double(totalPatterns)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                #if DEBUG
                debugAuthBanner
                #endif

                // ── GREETING (white card on metallic green bg) ──
                HStack(alignment: .center, spacing: 14) {
                    Image("nudge")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.welcomeMessage)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(viewModel.todayLabel)
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(DS.goldBase)
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
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
                .premiumCardShadow()
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)

                // ── STREAK + CIRCLE ──
                HStack(spacing: 12) {
                    // Streak card
                    VStack(spacing: 5) {
                        Text("\(viewModel.streak)")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundStyle(DS.nuggetGold)
                            .shimmerOverlay(duration: 5.0, intensity: 0.14)
                        Text("🔥 DAY STREAK")
                            .font(.system(size: 10, weight: .heavy, design: .rounded))
                            .tracking(1.0)
                            .foregroundStyle(.white.opacity(0.9))
                            .shadow(color: DS.deepGreen.opacity(0.7), radius: 2, x: 0, y: 1)
                            .minimumScaleFactor(0.85)
                            .lineLimit(1)
                            .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(DS.heroGradient, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius)
                            .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
                    )
                    .premiumCardShadow()

                    // Awareness circle (white card)
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .stroke(DS.mintBg, lineWidth: 5)
                            Circle()
                                .trim(from: 0, to: CGFloat(awarenessPercent))
                                .stroke(DS.goldBase, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 1.2), value: awarenessPercent)
                            Text("\(viewModel.biasesSeenCount)/\(totalPatterns)")
                                .font(.system(size: 10, weight: .black, design: .serif))
                                .foregroundStyle(DS.goldBase)
                        }
                        .frame(width: 54, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(Int(awarenessPercent * 100))%")
                                .font(.system(size: 26, weight: .black, design: .serif))
                                .foregroundStyle(DS.goldBase)
                            Text("Patterns\nidentified")
                                .font(.system(.subheadline, weight: .semibold))
                                .foregroundStyle(DS.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius)
                            .stroke(DS.goldBase, lineWidth: 2)
                    )
                    .premiumCardShadow()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 12)

                // ── CHECK IN (morphs daily / weekly / monthly) ──
                VStack(alignment: .leading, spacing: 10) {
                    Text(checkInMode.title)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: DS.deepGreen.opacity(0.7), radius: 3, x: 0, y: 1)
                    Text(checkInMode.subtitle)
                        .font(.system(.caption, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .shadow(color: DS.deepGreen.opacity(0.5), radius: 2, x: 0, y: 1)
                    Button {
                        showCheckIn = true
                    } label: {
                        Text(checkInMode.cta)
                    }
                    .goldButtonStyle()
                    .padding(.top, 2)
                }
                .padding(14)
                .background(DS.heroGradient, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
                )
                .premiumCardShadow()
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
                .padding(.bottom, 4)

                ResearchFootnote(text: "BFAS · Behavioural Finance Assessment Score", style: .pill)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)

                // ── NUDGE (white card with shimmering gold border — signature) ──
                NudgeSaysCard(
                    message: homeNudgeMessage,
                    surface: .whiteShimmer
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 12)
            }
        }
        .background(DS.bg.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: selectedTab?.wrappedValue) { _, new in
            if new == .home { Task { await viewModel.load() } }
        }
        .sheet(isPresented: $showCredibility) {
            CredibilitySheet()
        }
        .sheet(isPresented: $showDevMenu) {
            devMenu
        }
        .fullScreenCover(isPresented: $showCheckIn, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack {
                CheckInView(selectedTab: selectedTab)
            }
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

    #if DEBUG
    private var debugAuthBanner: some View {
        DebugAuthBanner()
    }
    #endif

    /// Nudge Says body for Home bottom. Combines the engine-generated
    /// contextual message (if any) with a bias-matched motto when a top
    /// pattern is known. Falls back to a rotating motto otherwise.
    private var homeNudgeMessage: String {
        if let engineMsg = viewModel.nudgeMessage?.body {
            // Engine is already context-aware (streak / time / first-open).
            return engineMsg
        }
        if let topBias = viewModel.dailyPatterns.first?.biasName {
            return "\(topBias) is showing up. \(NudgeVoice.mottoFor(bias: topBias))"
        }
        return NudgeVoice.random(NudgeVoice.motto)
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
