import SwiftUI

struct HomeView: View {
    var selectedTab: Binding<RootTab>? = nil

    @State private var viewModel = HomeViewModel()
    @State private var showCredibility = false
    @State private var showDevMenu = false
    @State private var previewOnboarding = false
    @State private var previewBFAS = false
    @State private var showCheckIn = false
    @State private var showFinanceEditor = false
    @State private var showPatternsDetail = false
    @State private var financeIncome: String = ""
    @State private var financeSavings: String = ""
    @State private var financeInvestment: String = ""
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

                    Button { showPatternsDetail = true } label: {
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
                                HStack(spacing: 6) {
                                    Text("\(Int(awarenessPercent * 100))%")
                                        .font(.system(size: 26, weight: .black, design: .serif))
                                        .foregroundStyle(DS.goldBase)
                                    Text("🧩")
                                        .font(.system(size: 20))
                                }
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
                    .buttonStyle(.plain)
                    .sheet(isPresented: $showPatternsDetail) {
                        patternsDetailSheet
                    }
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

                // ── YOUR FINANCES ──
                yourFinancesCard
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

    // MARK: - Your Finances card

    // MARK: - Patterns detail sheet

    private var patternsDetailSheet: some View {
        PatternsDetailView(
            patterns: viewModel.dailyPatterns,
            dismiss: { showPatternsDetail = false }
        )
    }

    private func firstSentence(_ text: String) -> String {
        text.split(separator: ".", maxSplits: 1).first
            .map { String($0).trimmingCharacters(in: .whitespaces) + "." } ?? text
    }

    private var yourFinancesCard: some View {
        let income = viewModel.monthlyIncome
        let savings = viewModel.latestSavings
        let investment = viewModel.latestInvestment
        let isEmpty = income == 0 && savings == 0 && investment == 0
        let lastUpdated = viewModel.financeLastUpdated

        let nudgeLine: String = {
            if isEmpty {
                return "Track your income and savings — Nudge connects the dots to your spending patterns."
            }
            if let last = lastUpdated {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                if days > 30 {
                    return "It's been \(days) days since you updated. A quick refresh keeps the picture honest."
                }
            }
            return NudgeVoice.random(NudgeVoice.motto)
        }()

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your finances")

            VStack(alignment: .leading, spacing: 12) {
                if isEmpty {
                    NudgeSaysCard(
                        message: nudgeLine,
                        surface: .gold
                    )
                } else {
                    HStack(spacing: 0) {
                        financeStatItem(label: "INCOME", value: "$\(Int(income))")
                        Spacer()
                        financeStatItem(label: "SAVINGS", value: "$\(Int(savings))")
                        Spacer()
                        financeStatItem(label: "INVESTED", value: "$\(Int(investment))")
                    }

                    NudgeSaysCard(
                        message: nudgeLine,
                        showCoin: false,
                        surface: .paleGreen
                    )
                }

                ResearchFootnote(text: "Voluntary manual entry · no bank connection · Privacy Act only", style: .pill)

                Button {
                    financeIncome = income > 0 ? "\(Int(income))" : ""
                    financeSavings = savings > 0 ? "\(Int(savings))" : ""
                    financeInvestment = investment > 0 ? "\(Int(investment))" : ""
                    showFinanceEditor = true
                } label: {
                    Text(isEmpty ? "Add your numbers →" : "Update numbers →")
                }
                .goldButtonStyle()
            }
            .padding(16)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.goldBase, lineWidth: 2)
            )
            .premiumCardShadow()
        }
        .sheet(isPresented: $showFinanceEditor) {
            financeEditorSheet
        }
    }

    private func financeStatItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(DS.goldBase)
            Text(label)
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .tracking(1.0)
                .foregroundStyle(DS.textTertiary)
        }
    }

    @State private var showFinanceSkipNudge = false

    private var financeEditorSheet: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Your finances")
                        .font(.system(size: 28, weight: .black))
                        .foregroundStyle(.white)
                        .heroTextLegibility()
                        .padding(.top, 20)

                    NudgeSaysCard(
                        message: "This is 100% voluntary. MoneyMind never connects to your bank — you type your own numbers. Under Australian law, that means only the Privacy Act 1988 applies. No financial licence, no CDR, no regulation beyond basic data privacy.",
                        citation: "Privacy Act 1988 (Cth) · no AFSL · no CDR",
                        surface: .dark
                    )

                    VStack(spacing: 14) {
                        financeField(label: "Monthly take-home", text: $financeIncome, emoji: "💰")
                        financeField(label: "Savings balance", text: $financeSavings, emoji: "🏦")
                        financeField(label: "Investment balance", text: $financeInvestment, emoji: "📈")
                    }

                    Button {
                        Task {
                            let inc = Double(financeIncome) ?? 0
                            let sav = Double(financeSavings) ?? 0
                            let inv = Double(financeInvestment) ?? 0
                            try? await SupabaseService.shared.saveMonthlyIncome(inc)
                            try? await SupabaseService.shared.saveBalanceSnapshot(savings: sav, investment: inv)
                            await viewModel.load()
                            showFinanceEditor = false
                        }
                    } label: {
                        Text("Save →")
                    }
                    .goldButtonStyle()
                    .padding(.top, 4)

                    Button {
                        showFinanceSkipNudge = true
                    } label: {
                        Text("Skip for now")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.bottom, 32)
                }
                .padding(.horizontal, 20)
            }

            if showFinanceSkipNudge {
                financeSkipNudge
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showFinanceSkipNudge)
    }

    private var financeSkipNudge: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { showFinanceSkipNudge = false }

            VStack(spacing: 16) {
                NudgeSaysCard(
                    message: "The trend graph only works when it has numbers to compare. Without income and savings, Nudge can't show you how awareness changes your finances. It takes 30 seconds.",
                    citation: "Thaler 1999 · tracking categories = 15–20% more saved",
                    surface: .gold
                )

                Button { showFinanceSkipNudge = false } label: {
                    Text("OK, I'll add them")
                }
                .goldButtonStyle()

                Button {
                    showFinanceSkipNudge = false
                    showFinanceEditor = false
                } label: {
                    Text("Skip anyway")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(DS.warning)
                }
                .padding(.bottom, 8)
            }
            .padding(24)
        }
    }

    private func financeField(label: String, text: Binding<String>, emoji: String) -> some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.system(size: 28))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.textSecondary)
                TextField("$0", text: text)
                    .font(.system(.title3, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                    .keyboardType(.numberPad)
            }
        }
        .padding(14)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(DS.goldBase, lineWidth: 1.5)
        )
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
