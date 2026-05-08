import SwiftUI

struct MoneyEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.isPresented) private var isPresented
    @State private var viewModel = MoneyEventViewModel()
    @State private var rangeSheetCategory: SpendCategory? = nil
    @State private var sessionLog: [SessionEntry] = []
    @State private var showSessionSummary: Bool = false
    var selectedTab: Binding<RootTab>? = nil

    struct SessionEntry: Identifiable {
        let id = UUID()
        let eventId: UUID?
        let emoji: String
        let category: String
        let amountLabel: String
        let amount: Double
        let plannedStatus: MoneyEvent.PlannedStatus
        let behaviourTag: String?
    }

    @State private var isBatchSaving: Bool = false
    /// Tracks which range is currently picked in the popup (before status is picked)
    @State private var pendingRange: AmountRange? = nil
    @State private var otherNote: String = ""
    @FocusState private var otherNoteFocused: Bool
    @State private var showAlgoExplainer: Bool = false
    @State private var showBiasReview: Bool = false
    @State private var showSkipAlert: Bool = false
    @State private var lastReviewOutcome: BiasReviewView.ReviewOutcome? = nil
    @State private var saveRewardMessage: String? = nil
    @State private var rewardCoinBounce: Bool = false
    /// Lessons banked from prior reviews for the currently-open category
    /// sheet. Used to show the Layer B pre-spend hint banner.
    @State private var lessonsForCurrentSheet: [SupabaseService.DecisionLesson] = []
    /// Layer C — opt-in decision-helper sheet. Long-press on a category
    /// tile to open. Surfaces 3 banked lessons as a tickable checklist
    /// before the user proceeds to log.
    @State private var helperSheetCategory: SpendCategory? = nil

    /// Rotating dry-wit chastise when user tries to skip review — see NudgeVoice.
    private var skipChastise: String { NudgeVoice.random(NudgeVoice.skipChastise) }

    private var sessionTotal: Double { sessionLog.reduce(0.0) { $0 + $1.amount } }

    private let tileColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if showSessionSummary {
                sessionSummary
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        headerSection
                        if !sessionLog.isEmpty {
                            sessionBanner
                        }
                        categoryGrid
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(DS.warning)
                        }
                    }
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
            }

            if let reward = saveRewardMessage {
                saveRewardOverlay(reward)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .navigationBarHidden(true)
        .toolbar {
            if isPresented {
                ToolbarItem(placement: .cancellationAction) {
                    Button(viewModel.didSave ? "Done" : "Cancel") { dismiss() }
                        .foregroundStyle(DS.textPrimary)
                }
            }
        }
        .sheet(item: $rangeSheetCategory) { cat in
            rangeSheet(for: cat)
                .presentationDetents([.medium, .large])
                .task { await loadLessonsForCategory(cat.name) }
                .onDisappear {
                    pendingRange = nil
                    lessonsForCurrentSheet = []
                }
        }
        .sheet(item: $helperSheetCategory) { cat in
            DecisionHelperSheet(
                category: cat.name,
                plannedStatus: nil,
                onProceed: {
                    // Land on the normal range picker after the helper.
                    rangeSheetCategory = cat
                }
            )
        }
        .sheet(isPresented: $showAlgoExplainer) {
            AlgorithmExplainerSheet()
        }
        .fullScreenCover(isPresented: $showBiasReview) {
            NavigationStack {
                ZStack {
                    BiasReviewView(
                        entries: reviewEntriesFromSessionOnly(),
                        onDone: { outcome in
                            lastReviewOutcome = outcome
                            showBiasReview = false
                            showSessionSummary = true
                        }
                    )
                    .navigationTitle("Review")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Skip") { showSkipAlert = true }
                        }
                    }

                    if showSkipAlert {
                        skipChastiseOverlay
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .zIndex(1)
                    }
                }
                .animation(.spring(response: 0.32, dampingFraction: 0.85), value: showSkipAlert)
            }
        }
    }

    // MARK: - Save reward overlay (Nudge celebration after each Quick log)

    /// Pops down from the top of the screen for ~1.6s with a Nudge coin
    /// and a one-line reward. Reinforces the logging habit — the user
    /// gets a small "Nudge noticed" beat instead of silent saves.
    private func saveRewardOverlay(_ message: String) -> some View {
        VStack {
            HStack(spacing: 12) {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .scaleEffect(rewardCoinBounce ? 1.0 : 0.6)
                    .rotationEffect(.degrees(rewardCoinBounce ? 0 : -18))
                    .animation(.spring(response: 0.35, dampingFraction: 0.55), value: rewardCoinBounce)

                Text(message)
                    .font(.system(.footnote, weight: .bold))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.cardBg, in: Capsule())
            .shimmeringGoldBorder(cornerRadius: 999, lineWidth: 2)
            .premiumCardShadow()
            .padding(.horizontal, 24)
            .padding(.top, 60)

            Spacer()
        }
    }

    // MARK: - Nudge skip chastise overlay (replaces iOS .alert)
    // Same NudgeSaysCard style used everywhere else Nudge speaks.

    private var skipChastiseOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showSkipAlert = false }

            VStack(spacing: 18) {
                Image("nudge")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 56, height: 56)

                VStack(spacing: 8) {
                    Text("NUDGE")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.5)
                        .foregroundStyle(DS.accent)

                    Text("Skipping already?")
                        .font(.system(.title3, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(skipChastise)
                        .font(.system(.subheadline, weight: .medium))
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 4)

                VStack(spacing: 10) {
                    Button {
                        showSkipAlert = false
                    } label: {
                        Text("Keep reviewing")
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(DS.goldForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.nuggetGold, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        showSkipAlert = false
                        showBiasReview = false
                        showSessionSummary = true
                    } label: {
                        Text("Skip anyway")
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(DS.warning)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 22))
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 12)
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick log")
                .font(.system(.largeTitle, weight: .bold))
                .foregroundStyle(DS.textPrimary)
            Text("Tap what you spent on. Log at your own pace — patterns show up over time.")
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            ResearchFootnote(text: "Powered by the BFAS framework · Pompian, 2012", style: .pill)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Saved confirmation (with multi-log session affordance)

    // savedConfirmation removed — multi-log flow handles all save paths
    // via batchSave() + sessionSummary. Single-save path is dead code in
    // the new UX.

    // MARK: - Session banner (saves happen per-tile, this shows progress)

    private var sessionBanner: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet.rectangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.goldBase)
                Text("\(sessionLog.count) logged · $\(Int(sessionTotal))")
                    .font(.system(.subheadline, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Button {
                    sessionLog.removeAll()
                } label: {
                    Text("Hide")
                        .font(.system(.caption, weight: .bold))
                        .foregroundStyle(DS.textTertiary)
                }
                .buttonStyle(.plain)
            }

            Button {
                showBiasReview = true
            } label: {
                Text("Review patterns →")
            }
            .goldButtonStyle()
        }
        .padding(14)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        .premiumCardShadow()
    }

    // MARK: - Session summary (end-of-session screen)

    private var sessionSummary: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Session summary")
                        .font(.system(.largeTitle, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                    Text("\(sessionLog.count) event\(sessionLog.count == 1 ? "" : "s") · $\(Int(sessionTotal)) total")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }

                VStack(spacing: 8) {
                    ForEach(sessionLog) { entry in
                        sessionRow(entry)
                    }
                }

                if let (topName, topCount) = topSessionBiases.first {
                    mostTriggeredPatternCard(name: topName, count: topCount)
                }

                NudgeSaysCard(message: sessionNudgeMessage, surface: .whiteShimmer)

                Button {
                    sessionLog.removeAll()
                    showSessionSummary = false
                    if isPresented { dismiss() } else { selectedTab?.wrappedValue = .home }
                } label: {
                    Text("Back to Home →")
                }
                .goldButtonStyle()
                .padding(.bottom, 24)
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 16)
        }
    }

    /// Full card: most-triggered pattern + why + how to combat.
    /// Gold surface with thick black heading for emphasis.
    private func mostTriggeredPatternCard(name: String, count: Int) -> some View {
        let insight = driverInsights[name]
        let citation: String = allBiasPatterns.first(where: { $0.name == name })?.keyRef ?? ""

        return VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Text("MOST TRIGGERED PATTERN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: "8B6010"))
                Button { showAlgoExplainer = true } label: {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8B6010"))
                }
                .buttonStyle(.plain)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(name)
                    .font(.system(.largeTitle, weight: .black))
                    .foregroundStyle(.black)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                Spacer()
                Text("×\(count)")
                    .font(.system(.title2, weight: .black))
                    .foregroundStyle(DS.goldForeground)
            }

            if let insight {
                Divider().background(DS.goldBase.opacity(0.3))

                VStack(alignment: .leading, spacing: 6) {
                    Text("WHAT THIS MEANS")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DS.deepGreen)
                    Text(insight.means)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("HOW TO COMBAT IT")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(Color(hex: "8B6010"))
                    Text(insight.fix)
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(.black)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if !citation.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "8B6010"))
                    Text(citation)
                        .font(.system(.footnote, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B6010"))
                }
                .padding(.top, 2)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .fill(DS.goldSurfaceBg)
                .shimmerOverlay(duration: 5.5, intensity: 0.22)
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldBase.opacity(0.5), lineWidth: 1)
        )
        .premiumCardShadow()
    }

    private func sessionRow(_ entry: SessionEntry) -> some View {
        HStack(spacing: 12) {
            Text(entry.emoji).font(.system(size: 22))
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.category)
                    .font(.system(.subheadline, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(entry.plannedStatus.emoji) \(entry.plannedStatus.label)")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
            Text(entry.amountLabel)
                .font(.system(.subheadline, weight: .heavy))
                .foregroundStyle(DS.goldBase)
        }
        .padding(12)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    /// Top biases from each entry's actual tagged bias (per-item status drove suggestion).
    private var topSessionBiases: [(String, Int)] {
        let tags = sessionLog.compactMap(\.behaviourTag)
        let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
        return counts.sorted { $0.value > $1.value }.prefix(3).map { ($0.key, $0.value) }
    }

    /// Review = one question per real session event. No padding, no
    /// pool fillers. Each event uses the bias the model rotated to at
    /// save time (BiasRotation), with a sync fallback if behaviourTag
    /// is nil for any reason.
    private func reviewEntriesFromSessionOnly() -> [BiasReviewView.Entry] {
        sessionLog.map { e in
            BiasReviewView.Entry(
                eventId: e.eventId,
                emoji: e.emoji,
                category: e.category,
                amountLabel: e.amountLabel,
                plannedStatus: e.plannedStatus,
                suggestedBias: e.behaviourTag
                    ?? BiasRotation.peekNextBias(category: e.category, status: e.plannedStatus)
            )
        }
    }

    private var sessionNudgeMessage: String {
        if let top = topSessionBiases.first {
            // Pair bias-specific observation with a matched motto.
            return "\(top.0) showed up most this session. \(NudgeVoice.mottoFor(bias: top.0))"
        } else if sessionLog.count >= 3 {
            return "\(NudgeVoice.random(NudgeVoice.sessionSummary))"
        } else {
            return "\(NudgeVoice.random(NudgeVoice.postSave))"
        }
    }

    // MARK: - Category grid (16 gold tiles)

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            LazyVGrid(columns: tileColumns, spacing: 10) {
                ForEach(spendCategories) { cat in
                    categoryTile(cat)
                }
            }
            ResearchFootnote(
                text: "Ranges based on ABS Household Expenditure Survey 2022–23",
                icon: "chart.bar.doc.horizontal"
            )
            .padding(.top, 2)
        }
    }

    private func categoryTile(_ cat: SpendCategory) -> some View {
        let isSelected = viewModel.selectedCategory?.name == cat.name
        // Highlighted = pre-suggested by the slot the user tapped from
        // a notification (e.g. lunchtime nudge → Lunch + Coffee +
        // Eating out get a stronger gold border to draw the eye).
        let isHighlighted = NotificationRouter.shared.pendingSlot?
            .highlightedCategories.contains(cat.name) ?? false
        return Button {
            rangeSheetCategory = cat
            // User acted on the suggestion — clear the deep-link
            // highlight so it doesn't stay loud through the rest of
            // the session.
            NotificationRouter.shared.pendingSlot = nil
        } label: {
            VStack(spacing: 6) {
                Text(cat.emoji)
                    .font(.system(size: 34))
                Text(cat.name)
                    .font(.system(.caption, weight: .heavy))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 104)
            .padding(.vertical, 4)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? DS.goldBase
                            : isHighlighted ? DS.goldBase.opacity(0.7)
                            : DS.accent.opacity(0.15),
                        lineWidth: isSelected ? 2 : isHighlighted ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
        // Long-press = "Help me think this through" — opens the
        // Layer C decision helper checklist before the range picker.
        // Power-user gesture; doesn't disrupt the default tap flow.
        .onLongPressGesture(minimumDuration: 0.5) {
            helperSheetCategory = cat
        }
    }

    // MARK: - Range + status sheet (2-step inline flow per item)

    private func rangeSheet(for cat: SpendCategory) -> some View {
        let ranges = categoryRanges[cat.name] ?? []
        return ScrollView {
            VStack(spacing: 18) {
                VStack(spacing: 4) {
                    Text(cat.emoji).font(.system(size: 40))
                    Text(cat.name)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.textPrimary)
                }
                .padding(.top, 8)

                // Layer B — pre-spend hint banner (Gollwitzer 1999
                // implementation intentions). Surfaces the most
                // relevant past lesson the user banked for this
                // category. Tappable to mark useful or dismiss.
                if !lessonsForCurrentSheet.isEmpty {
                    preSpendHintBanner(lesson: lessonsForCurrentSheet[0])
                }

                if cat.name == "Other" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("WHAT WAS IT?")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(DS.goldBase)
                        TextField("e.g. vet bill, gift, parking fine", text: $otherNote)
                            .font(.system(.subheadline, weight: .semibold))
                            .foregroundStyle(DS.textPrimary)
                            .focused($otherNoteFocused)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 11)
                            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(DS.goldBase.opacity(0.35), lineWidth: 0.8))
                            .submitLabel(.done)
                            .onSubmit { otherNoteFocused = false }
                    }
                    .padding(.horizontal, 20)
                }

                // Step 1 — pick range
                VStack(alignment: .leading, spacing: 8) {
                    Text(pendingRange == nil ? "HOW MUCH?" : "✓ \(pendingRange!.label)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(DS.goldBase)
                        .frame(maxWidth: .infinity, alignment: .center)
                    VStack(spacing: 8) {
                        ForEach(ranges) { range in
                            rangePickButton(range: range)
                        }
                    }
                }
                .padding(.horizontal, 20)

                // Step 2 — pick status (appears after range)
                if pendingRange != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WAS THIS PLANNED?")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(DS.goldBase)
                            .frame(maxWidth: .infinity, alignment: .center)
                        VStack(spacing: 10) {
                            ForEach(MoneyEvent.PlannedStatus.allCases) { status in
                                statusPickButton(cat: cat, status: status)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                if let avg = absMonthlyAverage[cat.name] {
                    ResearchFootnote(text: "Avg $\(avg)/mo · ABS 2022–23", icon: "chart.bar.doc.horizontal")
                        .padding(.top, 6)
                }
            }
            .padding(.bottom, 24)
            .animation(.spring(response: 0.3, dampingFraction: 0.85), value: pendingRange?.label)
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
        .background(DS.cardBg)
    }

    /// Step 1 button — picks range, reveals status buttons (does NOT save yet).
    private func rangePickButton(range: AmountRange) -> some View {
        let isSelected = pendingRange?.label == range.label
        return Button {
            pendingRange = range
        } label: {
            Text(range.label)
                .font(.system(.headline, weight: .bold))
                .foregroundStyle(isSelected ? DS.goldForeground : DS.deepGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(DS.goldSurfaceBg), in: Capsule())
                .overlay(Capsule().stroke(isSelected ? DS.goldBase.opacity(0.5) : DS.goldSurfaceStroke, lineWidth: isSelected ? 1 : 0.5))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }

    /// Step 2 button — picks status, saves immediately, adds to sessionLog, closes popup.
    private func statusPickButton(cat: SpendCategory, status: MoneyEvent.PlannedStatus) -> some View {
        Button {
            guard let range = pendingRange else { return }
            Task { await saveOne(cat: cat, range: range, status: status) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Text(status.emoji).font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.label)
                        .font(.system(.headline, weight: .bold))
                        .foregroundStyle(DS.goldForeground)
                    Text(statusDetail(status))
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundStyle(DS.goldForeground.opacity(0.92))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DS.goldForeground.opacity(0.5))
                    .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(DS.nuggetGold, in: RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(DS.goldBase.opacity(0.4), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .disabled(isBatchSaving)
    }

    private func statusDetail(_ status: MoneyEvent.PlannedStatus) -> String {
        switch status {
        case .planned:  return "I knew this was coming"
        case .surprise: return "Didn't see it coming — external"
        case .impulse:  return "Wanted it in the moment — internal"
        }
    }

    /// Save a single event to Supabase with its status, append to sessionLog, close popup.
    @MainActor
    private func saveOne(cat: SpendCategory, range: AmountRange, status: MoneyEvent.PlannedStatus) async {
        guard !isBatchSaving else { return }
        isBatchSaving = true
        defer { isBatchSaving = false }

        viewModel.selectedCategory = cat
        viewModel.selectedRange = range
        viewModel.plannedStatus = status
        viewModel.customNote = cat.name == "Other" ? otherNote : nil
        viewModel.onPlannedStatusSet()
        await viewModel.save()
        let tag = viewModel.behaviourTag
        let savedEventId = viewModel.lastSavedEventId
        viewModel.reset()

        sessionLog.append(SessionEntry(
            eventId: savedEventId,
            emoji: cat.emoji,
            category: cat.name,
            amountLabel: range.label,
            amount: range.midpoint,
            plannedStatus: status,
            behaviourTag: tag
        ))

        pendingRange = nil
        rangeSheetCategory = nil
        triggerSaveReward()
    }

    // MARK: - Layer B: pre-spend hint (Gollwitzer 1999)

    /// Fetch lessons banked for this category. Pre-loads on sheet open
    /// so the banner is ready when the user lands. Records `surfaced`
    /// for the top lesson so usefulness rate gets a denominator.
    @MainActor
    private func loadLessonsForCategory(_ category: String) async {
        do {
            let lessons = try await SupabaseService.shared
                .fetchLessons(category: category, plannedStatus: nil)
            lessonsForCurrentSheet = lessons
            if let top = lessons.first {
                try? await SupabaseService.shared
                    .recordLessonOutcome(id: top.id, outcome: .surfaced)
            }
        } catch {
            lessonsForCurrentSheet = []
        }
    }

    /// Compact banner above the range picker. "Last time you flagged
    /// X — try this." One tap to mark useful, swipe to dismiss.
    /// Implementation intention cue at the moment of decision.
    private func preSpendHintBanner(lesson: SupabaseService.DecisionLesson) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("LAST TIME · \(lesson.bias_name.uppercased())")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .tracking(1.0)
                    .foregroundStyle(DS.goldBase)
                Text(lesson.counter_move)
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 16) {
                    Button {
                        Task {
                            try? await SupabaseService.shared
                                .recordLessonOutcome(id: lesson.id, outcome: .useful)
                            withAnimation { lessonsForCurrentSheet = [] }
                        }
                    } label: {
                        Text("Helpful")
                            .font(.system(.caption2, weight: .heavy))
                            .foregroundStyle(DS.goldForeground)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(DS.nuggetGold, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    Button {
                        Task {
                            try? await SupabaseService.shared
                                .recordLessonOutcome(id: lesson.id, outcome: .dismissed)
                            withAnimation { lessonsForCurrentSheet = [] }
                        }
                    } label: {
                        Text("Dismiss")
                            .font(.system(.caption2, weight: .semibold))
                            .foregroundStyle(DS.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldSurfaceStroke, lineWidth: 0.75)
        )
    }

    /// Pop a small Nudge celebration after each successful save. Builds
    /// motivation: every 5th log in a session gets the streak-flavoured
    /// line, otherwise rotating postSave wit. Auto-dismisses 1.6s.
    @MainActor
    private func triggerSaveReward() {
        let message = NudgeVoice.random(NudgeVoice.postSave)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.65)) {
            saveRewardMessage = message
            rewardCoinBounce.toggle()
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.35)) {
                    saveRewardMessage = nil
                }
            }
        }
    }

    // (Previous batch-status-at-end flow removed. Each Log popup now
    //  handles range + status for one item and saves inline — see
    //  rangeSheet + statusPickButton + saveOne above.)

    // MARK: - Planned / Surprise / Impulse

    private var plannedStatusPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WAS THIS PLANNED?")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
            VStack(spacing: 12) {
                ForEach(MoneyEvent.PlannedStatus.allCases) { status in
                    plannedPill(status)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func plannedPill(_ status: MoneyEvent.PlannedStatus) -> some View {
        let selected = viewModel.plannedStatus == status
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.plannedStatus = status
                viewModel.onPlannedStatusSet()
            }
        } label: {
            HStack(spacing: 10) {
                Text(status.emoji)
                    .font(.system(size: 20))
                Text(status.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(selected ? DS.goldForeground : DS.goldForeground)
                Spacer()
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DS.goldForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(selected ? AnyShapeStyle(DS.nuggetGold) : AnyShapeStyle(DS.goldSurfaceBg))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(selected ? DS.goldBase.opacity(0.6) : DS.goldSurfaceStroke, lineWidth: selected ? 1.5 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selected)
    }

    // MARK: - Bias tag section

    private var biasTagSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("WHAT'S DRIVING THIS?")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(DS.goldBase)
            ResearchFootnote(text: "BFAS framework · Grable & Joo, 2004")

            if let tag = viewModel.behaviourTag {
                HStack(spacing: 10) {
                    Text(tag)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.goldText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(DS.goldBase.opacity(0.15))
                        )
                        .overlay(
                            Capsule()
                                .stroke(DS.goldBase.opacity(0.4), lineWidth: 1)
                        )

                    if viewModel.suggestedTag == tag {
                        Text("suggested")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(DS.textTertiary)
                    }
                }

                if let inline = viewModel.nudgeInline {
                    NudgeSaysCard(
                        message: inline,
                        surface: .whiteShimmer
                    )
                }

                if let insight = driverInsights[tag] {
                    driverInsightCard(tag: tag, insight: insight)
                        .transition(.move(edge: .top).combined(with: .opacity))

                    ResearchFootnote(text: biasCitation(for: tag))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func driverInsightCard(tag: String, insight: DriverInsight) -> some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DS.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WHAT THIS MEANS")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.accent)
                        .tracking(1)
                    Text(insight.means)
                        .font(.subheadline)
                        .foregroundStyle(DS.textPrimary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("HOW TO BREAK IT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.goldText)
                        .tracking(1)
                    Text(insight.fix)
                        .font(.subheadline)
                        .foregroundStyle(DS.textPrimary)
                }

                Button {
                    selectedTab?.wrappedValue = .insights
                } label: {
                    Text("See your \(tag) pattern \u{2192}")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule().fill(DS.paleGreen)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(14)
        }
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
    }

    // MARK: - Save

    private var saveButton: some View {
        Button {
            Task { await viewModel.save() }
        } label: {
            HStack {
                if viewModel.isSaving {
                    ProgressView().tint(DS.goldForeground)
                } else {
                    Text("Log it")
                        .font(.headline.weight(.bold))
                }
            }
            .goldButtonStyle()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Bias citations

    private func biasCitation(for bias: String) -> String {
        switch bias {
        case "Loss Aversion": return "Kahneman & Tversky, 1979"
        case "Present Bias": return "O'Donoghue & Rabin, 1999"
        case "Anchoring": return "Tversky & Kahneman, 1974"
        case "Overconfidence Bias": return "Barber & Odean, 2001"
        case "Mental Accounting": return "Thaler, 1985"
        case "Status Quo Bias": return "Samuelson & Zeckhauser, 1988"
        case "Ostrich Effect": return "Karlsson et al., 2009"
        case "Sunk Cost Fallacy": return "Arkes & Blumer, 1985"
        case "Ego Depletion": return "Baumeister et al., 1998"
        case "Availability Heuristic": return "Tversky & Kahneman, 1973"
        case "Denomination Effect": return "Raghubir & Srivastava, 2009"
        case "Framing Effect": return "Tversky & Kahneman, 1981"
        case "Planning Fallacy": return "Buehler, Griffin & Ross, 1994"
        case "Scarcity Heuristic": return "Cialdini, 2001"
        case "Moral Licensing": return "Monin & Miller, 2001"
        default: return "Pompian, 2012"
        }
    }

}

#Preview {
    NavigationStack { MoneyEventView() }
}
