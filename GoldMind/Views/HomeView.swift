import SwiftUI
import UserNotifications

struct HomeView: View {
    var selectedTab: Binding<RootTab>? = nil

    @State private var viewModel = HomeViewModel()
    @State private var showCredibility = false
    @State private var showAlgorithmExplainer = false
    @State private var showSettings = false
    @State private var showDevMenu = false
    @State private var showNudgeHello = false
    @Bindable private var router = NotificationRouter.shared
    @State private var previewOnboarding = false
    @State private var previewBFAS = false
    @State private var showCheckIn = false
    @State private var showFinanceEditor = false
    @State private var showPatternsDetail = false
    @State private var financeIncome: String = ""
    @State private var financeSavings: String = ""
    @State private var financeInvestment: String = ""
    @State private var userArchetype: String? = nil
    @State private var userAvatarUrl: String? = nil
    @State private var showMoneyMindQuiz: Bool = false
    @State private var showNamePrompt: Bool = false
    @State private var expandedCounter: Set<String> = []
    /// Notification authorization state. Drives the "Enable notifications"
    /// banner so users who missed or declined the system prompt have a
    /// visible recovery path (deep-link to iOS Settings). Important for
    /// App Store reviewers — they verify denied-state UX is graceful.
    @State private var notifAuthStatus: UNAuthorizationStatus = .notDetermined
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasCompletedBFAS") private var hasCompletedBFAS = false
    @AppStorage("hasPromptedForName") private var hasPromptedForName: Bool = false

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
            case .weekly:  return "Last week's patterns. Let's revisit."
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

    /// True when the user has logged nothing and entered no finance numbers.
    /// Drives the empty-state CTA card so a new user gets one clear next
    /// step instead of staring at six zeroes. Becomes false the moment any
    /// data exists.
    private var isEmptyState: Bool {
        viewModel.streak == 0
            && viewModel.recentEvents.isEmpty
            && viewModel.biasesSeenCount == 0
            && viewModel.monthlyIncome == 0
            && viewModel.latestSavings == 0
            && viewModel.latestInvestment == 0
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // ── GREETING (user avatar + name + personality chip) ──
                HStack(alignment: .center, spacing: 14) {
                    // Avatar disc — tap to open Settings (profile + edits).
                    // Uses the same destination as the gear icon so users
                    // who tap either end up in the right place.
                    Button { showSettings = true } label: {
                        AvatarDisc(name: viewModel.firstName, avatarUrl: userAvatarUrl, size: 52)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(viewModel.welcomeMessage)
                            .font(.system(.headline, design: .default, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                        if let arch = userArchetype, !arch.isEmpty {
                            // Personality chip — only shows once the user
                            // has taken the Money Mind Quiz.
                            HStack(spacing: 6) {
                                Text("The \(arch)")
                                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                                    .tracking(0.4)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(DS.heroGradient))
                                Text(viewModel.todayLabel)
                                    .font(.system(.subheadline, weight: .semibold))
                                    .foregroundStyle(DS.goldBase)
                            }
                        } else {
                            Text(viewModel.todayLabel)
                                .font(.system(.body, weight: .semibold))
                                .foregroundStyle(DS.goldBase)
                        }
                    }
                    Spacer(minLength: 8)
                    // Gear -> Settings. Kept as a secondary entry point so
                    // tap targets work for users who don't realise the
                    // avatar is interactive. Dev menu lives behind a
                    // DEBUG-only long-press here.
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18))
                            .foregroundStyle(DS.deepGreen)
                    }
                    .buttonStyle(.plain)
                    #if DEBUG
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.6)
                            .onEnded { _ in showDevMenu = true }
                    )
                    #endif
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
                .premiumCardShadow()
                // Nudge tucked into the bottom-right corner of the greeting
                // card. Tap reveals a rotating welcome line. Sits as a
                // floating chip so it doesn't crowd the main HStack.
                .overlay(alignment: .bottomTrailing) {
                    Button { showNudgeHello = true } label: {
                        // Floating cut-out. Sized 56 (was 40) so Nudge
                        // reads as a peer to the 52pt avatar disc on
                        // the left of the greeting card.
                        Image("nudge")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 56, height: 56)
                    }
                    .buttonStyle(.plain)
                    // Pushes Nudge below the gear icon + slightly into
                    // the card's lower-right margin. y: 8 = nudge sits
                    // 8pt below the card's bottom edge, partly outside
                    // the rounded corner so it reads as floating.
                    .offset(x: -4, y: 8)
                    .popover(isPresented: $showNudgeHello,
                             attachmentAnchor: .point(.top),
                             arrowEdge: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NUDGE SAYS")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(DS.accent)
                            Text(nudgeHelloLine)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DS.textPrimary)
                                .lineSpacing(2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(14)
                        .frame(maxWidth: 260, alignment: .leading)
                        .presentationCompactAdaptation(.popover)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 14)

                // ── NOTIFICATION PERMISSION BANNER ──
                // Shown when status is .denied or .notDetermined. Disappears
                // silently once the user grants. Important: provides the only
                // recovery path for users who already dismissed the system
                // prompt (iOS won't re-ask).
                if notifAuthStatus == .denied || notifAuthStatus == .notDetermined {
                    notificationBanner
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                }

                // ── EMPTY-STATE CTA (first-time, nothing logged yet) ──
                if isEmptyState {
                    emptyStateCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 14)
                }

                // ── STREAK + CIRCLE ──
                HStack(spacing: 12) {
                    // Streak card
                    VStack(spacing: 5) {
                        Text("\(viewModel.streak)")
                            .font(.system(size: 40, weight: .black, design: .serif))
                            .foregroundStyle(DS.goldText)
                        HStack(spacing: 6) {
                            Text("🔥 DAY STREAK")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(.white.opacity(0.9))
                                .shadow(color: DS.deepGreen.opacity(0.7), radius: 2, x: 0, y: 1)
                                .minimumScaleFactor(0.85)
                                .lineLimit(1)
                            InfoPopover(
                                "Days in a row you checked in.",
                                title: "DAY STREAK"
                            )
                        }
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
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Patterns\nidentified")
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundStyle(DS.textSecondary)
                                    InfoPopover(
                                        "16 biases tracked from your tagged spending. Each log moves the count.",
                                        title: "PATTERNS"
                                    )
                                }
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

                // ── MONEY MIND QUIZ TILE (always shown) ──
                // Pre-quiz: invites the user to take it.
                // Post-quiz: shows their personality + a retake affordance.
                moneyMindQuizTile
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

                // ── FUTURE YOU (above the calendar) ──
                futureYouCard
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
                    // 'i' button on YOUR TOP BIASES opens the algorithm
                    // explainer (same content as the Research tab's How
                    // the ranking works section), not the full
                    // credibility sheet.
                    onInfoTap: { showAlgorithmExplainer = true }
                )
                .padding(.horizontal, 18)
                .padding(.bottom, 4)

                ResearchFootnote(text: "BFAS · Behavioural Finance Assessment Score", style: .pill)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 12)

                // ── COUNTERACT YOUR TOP BIASES (tap to expand) ──
                if !topCounterLessons.isEmpty {
                    counteractCard
                        .padding(.horizontal, 18)
                        .padding(.bottom, 12)
                }

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
            await loadArchetype()
            await refreshNotifAuthStatus()
        }
        .refreshable {
            await viewModel.load()
            await loadArchetype()
            await refreshNotifAuthStatus()
        }
        .onChange(of: selectedTab?.wrappedValue) { _, new in
            if new == .home {
                Task {
                    await viewModel.load()
                    await loadArchetype()
                }
            }
        }
        // Notification tap -> openFinanceEditor: route arrives from
        // NotificationRouter, open the finance editor sheet and clear
        // the route so it doesn't re-fire on the next render.
        .onChange(of: router.pendingRoute) { _, route in
            consumePendingRoute(route)
        }
        .task {
            // Cold-launch case: if the tap happened while the app was
            // closed, the router's pendingRoute may already be set before
            // any onChange observer attaches. Consume it on first appear.
            consumePendingRoute(router.pendingRoute)
        }
        .fullScreenCover(isPresented: $showMoneyMindQuiz, onDismiss: {
            Task { await loadArchetype() }
        }) {
            NavigationStack { MoneyMindQuizView() }
        }
        .sheet(isPresented: $showNamePrompt, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NamePromptSheet(onSaved: { _ in
                Task { await viewModel.load() }
            })
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showAlgorithmExplainer) {
            AlgorithmExplainerSheet()
        }
        .sheet(isPresented: $showCredibility) {
            CredibilitySheet()
        }
        .sheet(isPresented: $showSettings, onDismiss: {
            Task {
                await viewModel.load()
                await loadArchetype()
            }
        }) {
            SettingsView(hasCompletedOnboarding: $hasCompletedOnboarding)
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

    // MARK: - Nudge hello (popover from greeting card)

    /// Rotating Nudge welcome line for the avatar-tap popover. Time-of-day
    /// aware + streak-aware so the hello feels alive instead of canned.
    private var nudgeHelloLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = viewModel.firstName
        let nameSnippet = (name.isEmpty || name == "there") ? "there" : name
        let streak = viewModel.streak

        if streak > 0 {
            return "Day \(streak), \(nameSnippet). I'm here when you log."
        }
        switch hour {
        case 0..<12:  return "Morning, \(nameSnippet). Coffee logged yet?"
        case 12..<18: return "Afternoon, \(nameSnippet). One tap when you're ready."
        default:      return "Evening, \(nameSnippet). Last log of the day?"
        }
    }

    // MARK: - Counteract Your Top Biases

    /// Top 3 BiasLessons matching the user's most-triggered biases.
    /// Pairs viewModel.dailyPatterns (ranked) with BiasLessonsMock.seed
    /// (howToCounter strategies). Empty until the user has any signal.
    private var topCounterLessons: [BiasLesson] {
        let topNames = viewModel.dailyPatterns.prefix(3).map(\.biasName)
        return topNames.compactMap { name in
            BiasLessonsMock.seed.first(where: { $0.biasName == name })
        }
    }

    /// Surfaces "how to counteract" strategies for the user's top biases
    /// directly on Home — collapsed by default, tap each row to expand
    /// the full counter-move. Saves a trip to the Research tab for the
    /// most actionable content the user actually needs.
    private var counteractCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.goldBase)
                Text("HOW TO COUNTERACT YOUR TOP BIASES")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(DS.goldBase)
                Spacer()
            }
            VStack(spacing: 8) {
                ForEach(topCounterLessons) { lesson in
                    counteractRow(lesson)
                }
            }
        }
        .padding(14)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.3), lineWidth: 1)
        )
        .premiumCardShadow()
    }

    private func counteractRow(_ lesson: BiasLesson) -> some View {
        let isExpanded = expandedCounter.contains(lesson.biasName)
        return Button {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                if isExpanded { expandedCounter.remove(lesson.biasName) }
                else { expandedCounter.insert(lesson.biasName) }
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(lesson.emoji)
                        .font(.system(size: 18))
                    Text(lesson.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundStyle(DS.goldBase)
                }
                if isExpanded {
                    Text(lesson.howToCounter)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(DS.textPrimary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isExpanded ? DS.paleGreen.opacity(0.4) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Money Mind Quiz tile

    /// Promo card shown on Home until the user has completed the quiz.
    /// Quiet gold/cream tone so it doesn't compete with the green hero
    /// gradient on the check-in card. Disappears once an archetype is
    /// saved to `profiles.archetype`.
    private var moneyMindQuizTile: some View {
        let arch = userArchetype?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasArch = arch?.isEmpty == false
        return Button { showMoneyMindQuiz = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(DS.heroGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(hasArch ? "Your spending personality" : "Money Mind Quiz")
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text(hasArch
                         ? "The \(arch!) · tap to retake"
                         : "Find your spending personality · 2 min")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.goldBase)
            }
            .padding(14)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.goldBase.opacity(0.45), lineWidth: 1)
            )
            .premiumCardShadow()
        }
        .buttonStyle(.plain)
    }

    /// Applies a pending NotificationRoute and clears it on the router
    /// so the same route doesn't fire on the next render. Handles both
    /// the onChange path (foreground tap) and the cold-launch path.
    private func consumePendingRoute(_ route: NotificationRoute?) {
        guard let route else { return }
        switch route {
        case .openFinanceEditor:
            financeIncome = ""
            financeSavings = ""
            financeInvestment = ""
            showFinanceEditor = true
        }
        router.pendingRoute = nil
    }

    private func refreshNotifAuthStatus() async {
        let status = await NotificationService.authorizationStatus()
        await MainActor.run { notifAuthStatus = status }
    }

    // MARK: - Notification permission banner

    private var notificationBanner: some View {
        Button {
            Task {
                if notifAuthStatus == .notDetermined {
                    // First-time grant — kick off scheduling immediately
                    // so the user doesn't have to relaunch for daily
                    // reminders to start working.
                    let granted = await NotificationService.requestPermission()
                    if granted { NotificationService.scheduleAll() }
                } else {
                    NotificationService.openSystemSettings()
                }
                // Re-poll after the user returns so the banner clears
                // when they grant permission.
                let status = await NotificationService.authorizationStatus()
                await MainActor.run { notifAuthStatus = status }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(DS.heroGradient))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Turn on notifications")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text(notifAuthStatus == .denied
                         ? "Currently off. Open Settings to enable."
                         : "Nudge will remind you to log + check in.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.goldBase)
            }
            .padding(12)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func loadArchetype() async {
        let profile = try? await SupabaseService.shared.fetchProfile()
        await MainActor.run {
            userArchetype = profile?.archetype
            userAvatarUrl = profile?.avatarUrl
            // First-launch name prompt: only if we have a profile, the
            // display_name is empty, and we haven't asked yet.
            if let p = profile,
               !hasPromptedForName,
               (p.displayName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
                showNamePrompt = true
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

    /// "Future you" hero — the planned-vs-impulse net of this week's
    /// spending. Surfaces above the calendar so the user sees the
    /// weekly summary before drilling into individual days. Empty
    /// state shows a Nudge note explaining it'll populate after logs.
    private var futureYouCard: some View {
        let planned = viewModel.weekEvents.filter { $0.plannedStatus == .planned }.reduce(0.0) { $0 + $1.amount }
        let unplanned = viewModel.weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let net = planned - unplanned
        let checkInDays = viewModel.weekCheckInDays

        return ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 100, height: 100)
                .offset(x: 30, y: -25)

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("FUTURE YOU")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(DS.goldText)
                    Spacer()
                }

                if viewModel.weekEvents.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image("nudge")
                            .resizable().scaledToFit()
                            .frame(width: 32, height: 32)
                        Text("Log a spend or two and this fills in. You'll see the weekly net of planned versus impulse, and how many days you chose future you.")
                            .font(.system(.subheadline, weight: .medium))
                            .foregroundStyle(.white.opacity(0.92))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                } else {
                    let sign = net >= 0 ? "+" : ""
                    Text("\(sign)$\(Int(abs(net))) from future you")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(.white)
                    Text("\(checkInDays) of 7 days you chose future you")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.heroGradient)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
    }

    private var yourFinancesCard: some View {
        let income = viewModel.monthlyIncome
        let savings = viewModel.latestSavings
        let investment = viewModel.latestInvestment
        let isEmpty = income == 0 && savings == 0 && investment == 0
        let lastUpdated = viewModel.financeLastUpdated

        let nudgeLine: String = {
            if isEmpty {
                return "Track income and savings. Nudge connects them to your spending."
            }
            if let last = lastUpdated {
                let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
                if days > 30 {
                    return "\(days) days since your last update. A refresh keeps the picture honest."
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
                        surface: .whiteShimmer
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
                        surface: .whiteShimmer
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

    /// First-time empty-state card. Two clear actions — set finances or
    /// log first event. Disappears the moment any data exists.
    private var emptyStateCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 4) {
                    Text("NUDGE SAYS")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .tracking(1.6)
                        .foregroundStyle(DS.accent)
                    Text("Two quick things to set up. Then you're tracking.")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(DS.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 10) {
                Button {
                    financeIncome = ""
                    financeSavings = ""
                    financeInvestment = ""
                    showFinanceEditor = true
                } label: {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Add income, savings & investments")
                                .font(.system(.body, weight: .semibold))
                            Text("Takes 30 seconds · manual entry only")
                                .font(.system(size: 11, weight: .medium))
                                .opacity(0.85)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(DS.heroGradient, in: RoundedRectangle(cornerRadius: DS.buttonRadius))
                }
                .buttonStyle(.plain)

                Button {
                    selectedTab?.wrappedValue = .log
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Log your first event")
                            .font(.system(.body, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .foregroundStyle(DS.deepGreen)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.buttonRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.buttonRadius)
                            .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
        )
        .premiumCardShadow()
    }

    private func financeStatItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .black, design: .serif))
                .foregroundStyle(DS.goldBase)
            Text(label)
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.2)
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
                        message: "100% voluntary. GoldMind never connects to your bank. You type your own numbers, so only the Privacy Act 1988 applies. No financial licence, no CDR.",
                        citation: "Privacy Act 1988 (Cth) · no AFSL · no CDR",
                        surface: .whiteShimmer
                    )

                    VStack(spacing: 14) {
                        financeField(label: "Monthly take-home (required)", text: $financeIncome, emoji: "💰")
                        financeField(label: "Savings balance", text: $financeSavings, emoji: "🏦")
                        financeField(label: "Investment balance", text: $financeInvestment, emoji: "📈")
                    }

                    if financeIncome.isEmpty || Double(financeIncome) == 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(DS.warning)
                            Text("Enter your monthly take-home to unlock spending insights")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }

                    Button {
                        Task {
                            let inc = Double(financeIncome) ?? 0
                            let sav = Double(financeSavings) ?? 0
                            let inv = Double(financeInvestment) ?? 0
                            try? await SupabaseService.shared.saveMonthlyIncome(inc)
                            try? await SupabaseService.shared.saveBalanceSnapshot(savings: sav, investment: inv)
                            // User entered numbers -> cancel the pending
                            // 48h "Add your numbers" reminder.
                            if inc > 0 || sav > 0 || inv > 0 {
                                NotificationService.cancelAddNumbersReminder()
                            }
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
                    message: "The trend graph needs numbers to compare. Without income and savings, Nudge can't show how awareness shifts your finances. 30 seconds.",
                    citation: "Thaler 1985 · Mental Accounting",
                    surface: .whiteShimmer
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
                Section("Notifications (DEBUG)") {
                    Button {
                        // Fires the same "Add your numbers" notification in
                        // 10s so we can verify the deep-link route to the
                        // finance editor without waiting 48h.
                        let c = UNMutableNotificationContent()
                        c.title = "GoldMind"
                        c.body = "Two minutes. Add your income and savings so Nudge can see the picture."
                        c.sound = .default
                        c.userInfo["route"] = NotificationRoute.openFinanceEditor.rawValue
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                        let req = UNNotificationRequest(
                            identifier: "goldmind.debug.add.numbers",
                            content: c,
                            trigger: trigger
                        )
                        UNUserNotificationCenter.current().add(req)
                        showDevMenu = false
                    } label: {
                        Label("Fire 'Add numbers' in 10s", systemImage: "bell.badge.fill")
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
