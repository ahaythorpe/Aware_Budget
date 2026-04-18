import SwiftUI

struct CheckInView: View {
    @Environment(\.dismiss) private var dismiss
    var selectedTab: Binding<RootTab>? = nil

    // MARK: - State

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var attemptedCount = 0
    @State private var showWeeklyReview: Bool = false
    @State private var weeklyTopBiases: [HomeViewModel.DailyPattern] = []
    @State private var weeklySpend: Double = 0
    @State private var weeklyEventCount: Int = 0
    @State private var weeklyStreak: Int = 0
    @State private var flashedCitation: String? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var showWhy: Bool = false
    @State private var selectedTone: CheckIn.EmotionalTone? = nil

    @State private var phase: Phase = .questions
    @State private var selectedDriver: CheckIn.SpendingDriver? = nil
    @State private var nudgeCompletionMessage: NudgeMessage?
    @State private var showFollowUp: Bool = false
    @State private var lastAnswerWasYes: Bool = false
    @State private var savedStreak: Int = 0
    @State private var isSaving = false
    @State private var alreadyCheckedIn: CheckIn?
    /// Skip chastise overlay — fires when user taps "Skip" on the
    /// driver-pick step without identifying a driver, OR taps the
    /// toolbar X to abandon the whole check-in. Mirrors the
    /// MoneyEventView skip chastise pattern (consistent UX).
    @State private var showSkipChastise: Bool = false
    /// Tracks WHICH skip path triggered the chastise so "Skip anyway"
    /// does the right thing: X = abandon, driver-pick = save without
    /// driver.
    private enum SkipOrigin { case toolbarX, driverPick }
    @State private var skipOrigin: SkipOrigin = .driverPick
    private var skipChastise: String { NudgeVoice.random(NudgeVoice.skipChastise) }

    private let service = SupabaseService.shared

    private enum Phase {
        case questions, driverPick, done
    }

    // MARK: - Design constants

    private let cardCornerRadius: CGFloat = 28
    private let cardHeight: CGFloat = 380
    private let swipeThreshold: CGFloat = 80
    private let maxRotation: Double = 15

    // Card colours
    private let frontColors: [Color] = [DS.deepGreen, DS.primary, DS.accent]
    private let middleBg = DS.lightGreen
    private let backBg   = DS.mintLight
    private let gold     = DS.goldText

    // MARK: - Body

    var body: some View {
        ZStack {
            if alreadyCheckedIn != nil || phase == .done {
                Color.clear
            } else {
                DS.bg.ignoresSafeArea()
            }

            VStack(spacing: 16) {
                if let existing = alreadyCheckedIn {
                    alreadyDoneView(existing)
                } else if showWeeklyReview {
                    WeeklyReviewSummary(
                        topBiases: weeklyTopBiases,
                        weekSpend: weeklySpend,
                        eventCount: weeklyEventCount,
                        streak: weeklyStreak,
                        onContinue: {
                            WeeklyReviewTracker.markDone()
                            withAnimation { showWeeklyReview = false }
                        }
                    )
                } else {
                    progressDots
                        .padding(.horizontal, DS.hPadding)
                        .padding(.top, 8)

                    Spacer(minLength: 0)

                    switch phase {
                    case .questions:
                        if questions.isEmpty {
                            ProgressView()
                        } else {
                            VStack(spacing: 12) {
                                cardStack
                                Text("70% abandon budgeting apps within 30 days. Awareness drives change.")
                                    .font(.caption2)
                                    .foregroundStyle(DS.textTertiary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DS.hPadding)
                            }
                        }
                    case .driverPick:
                        driverPickView
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    case .done:
                        completionView
                            .transition(.opacity)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .navigationTitle("Daily check-in")
        .navigationBarTitleDisplayMode(.inline)
        .overlay {
            // Top-level chastise overlay so it shows from EITHER the
            // questions screen (toolbar X tap) or the driver-pick
            // (Skip button). Was previously only attached to the
            // driver-pick subview.
            if showSkipChastise {
                skipChastiseOverlay
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.85), value: showSkipChastise)
        .toolbar {
            if alreadyCheckedIn != nil || phase == .done {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if let selectedTab { selectedTab.wrappedValue = .home } else { dismiss() }
                    } label: {
                        Text("Done")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(alreadyCheckedIn != nil || phase == .done ? DS.goldBase : .white)
                    }
                }
            }
            if selectedTab == nil && alreadyCheckedIn == nil && phase != .done {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        skipOrigin = .toolbarX
                        showSkipChastise = true
                    } label: {
                        Image(systemName: "xmark")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.textSecondary)
                            .padding(8)
                            .background(DS.paleGreen)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .task {
            // Check if already completed today
            if let existing = try? await service.fetchTodaysCheckIn() {
                alreadyCheckedIn = existing
                return
            }
            if questions.isEmpty {
                await loadQuestions()
            }
        }
    }

    // MARK: - Progress dots

    private var progressDots: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ForEach(0..<max(questions.count, 1), id: \.self) { i in
                    Circle()
                        .fill(i < attemptedCount ? DS.accent : DS.textTertiary.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeOut(duration: 0.2), value: attemptedCount)
                }
            }
            if let flashedCitation {
                HStack(spacing: 5) {
                    Image(systemName: "book.closed.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(DS.goldBase)
                    Text(flashedCitation)
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(Color(hex: "8B6010"))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: "FFF8E1"), in: Capsule())
                .overlay(Capsule().stroke(DS.goldBase.opacity(0.25), lineWidth: 0.5))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if !questions.isEmpty {
                Text("Q\(min(attemptedCount + 1, questions.count)) of \(questions.count) · from BFAS assessment")
                    .font(.system(.caption2, weight: .semibold))
                    .foregroundStyle(DS.textTertiary)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: flashedCitation)
    }

    // MARK: - Card stack (2 back cards visible)

    private var cardStack: some View {
        ZStack {
            // Back card (3rd)
            if currentIndex + 2 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(backBg)
                    .frame(height: cardHeight)
                    .scaleEffect(0.92)
                    .offset(y: 24)
            }
            // Middle card (2nd)
            if currentIndex + 1 < questions.count {
                RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                    .fill(middleBg)
                    .frame(height: cardHeight)
                    .scaleEffect(0.96)
                    .offset(y: 12)
            }
            // Front card with YES/NO overlays
            ZStack {
                frontCard
                yesNoOverlays
            }
            .offset(dragOffset)
            .rotationEffect(.degrees(Double(dragOffset.width) / 20))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        let horizontal = value.translation.width
                        if horizontal > swipeThreshold {
                            swipeYes()
                        } else if horizontal < -swipeThreshold {
                            swipeNo()
                        } else {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardHeight + 30)
        .padding(.horizontal, DS.hPadding)
    }

    // MARK: - YES / NO overlays during drag

    private var yesNoOverlays: some View {
        ZStack {
            // YES overlay (right swipe)
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(DS.accent.opacity(0.85))
                .overlay(
                    Text("YES")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(-15))
                )
                .opacity(max(0, Double(dragOffset.width) / 120))

            // NO overlay (left swipe)
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(DS.warning.opacity(0.85))
                .overlay(
                    Text("NO")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(15))
                )
                .opacity(max(0, Double(-dragOffset.width) / 120))
        }
        .frame(height: cardHeight)
        .allowsHitTesting(false)
    }

    // MARK: - Front card

    private var frontCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous)
                .fill(DS.heroGradient)
                .frame(height: cardHeight)

            if currentIndex < questions.count {
                frontContent(for: questions[currentIndex])
                    .padding(24)
            }
        }
        .frame(height: cardHeight)
    }

    private func frontContent(for q: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(q.question)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .heroTextLegibility()
                .padding(.bottom, 2)

            Text(q.biasName)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
            + Text(" · Pompian 2012")
                .font(.system(.caption, weight: .regular))
                .foregroundStyle(.white.opacity(0.4))

            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showWhy.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: showWhy ? "chevron.down" : "chevron.right")
                        .font(.caption2.weight(.bold))
                    Text("Why this matters")
                        .font(.footnote.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(DS.goldText)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            if showWhy {
                NudgeSaysCard(
                    message: q.whyExplanation,
                    citation: NudgeVoice.researchCueFor(bias: q.biasName),
                    surface: .dark
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                Button { swipeYes() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.headline.weight(.bold))
                        Text("Yes")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(DS.matteYellowForeground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DS.matteYellow, in: Capsule())
                }
                .buttonStyle(.plain)

                Button { swipeNo() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark")
                            .font(.headline.weight(.bold))
                        Text("No")
                    }
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(DS.danger, in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Follow-up card (shown when YES + question has follow-up)

    private var followUpCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Follow up")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                if currentIndex > 0, currentIndex - 1 < questions.count {
                    Text("You said yes to: \"\(questions[currentIndex - 1].question)\"")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showFollowUp = false
                }
            } label: {
                Text("Continue")
                    .font(.system(size: 13, weight: .bold))
                    .goldButtonStyle()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Driver pick

    private var driverPickView: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 22) {
                    Text("What drove this?")
                        .font(.system(size: 24, weight: .black))
                        .foregroundStyle(.white)
                        .heroTextLegibility()

                    Text("No wrong answers. Just noticing.")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))

                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(CheckIn.SpendingDriver.allCases) { driver in
                            driverPill(driver)
                        }
                    }

                    Button {
                        guard !isSaving else { return }
                        if selectedDriver == nil {
                            skipOrigin = .driverPick
                            showSkipChastise = true
                        } else {
                            Task { await saveCheckIn() }
                        }
                    } label: {
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        } else {
                            Text(selectedDriver != nil ? "Continue →" : "Skip for now")
                        }
                    }
                    .goldButtonStyle()
                    .padding(.top, 8)
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        // Top-level body has the overlay now — see line ~110.
    }

    /// Same Apple-style modal as MoneyEventView's skip overlay.
    /// Single white card · Nudge coin · NUDGE label · title +
    /// rotating chastise · gold "Pick a driver" · warning-red
    /// "Skip anyway".
    private var skipChastiseOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { showSkipChastise = false }

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

                    Text("Skipping the why?")
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
                        showSkipChastise = false
                    } label: {
                        Text("Pick a driver")
                            .font(.system(.headline, weight: .bold))
                            .foregroundStyle(DS.goldForeground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(DS.nuggetGold, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button {
                        showSkipChastise = false
                        // Different behaviour by origin:
                        // - toolbarX → abandon entire check-in
                        // - driverPick → save what's been answered
                        switch skipOrigin {
                        case .toolbarX:    dismiss()
                        case .driverPick:  Task { await saveCheckIn() }
                        }
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

    private func driverPill(_ driver: CheckIn.SpendingDriver) -> some View {
        let isSelected = selectedDriver == driver
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDriver = isSelected ? nil : driver
            }
        } label: {
            VStack(spacing: 6) {
                Text(driver.emoji)
                    .font(.system(size: 24))
                Text(driver.shortDescription)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isSelected ? DS.goldBase : DS.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(driver.label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(isSelected ? DS.goldBase.opacity(0.7) : DS.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shimmeringGoldBorder(cornerRadius: 14, lineWidth: isSelected ? 3 : 1.5)
            .shadow(color: isSelected ? DS.goldBase.opacity(0.3) : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Completion

    private var completionView: some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                NudgeAvatar(size: 80)
                    .sensoryFeedback(.success, trigger: phase == .done)

                VStack(spacing: 8) {
                    Text("Day \(savedStreak)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(DS.goldText)

                    Text("\(attemptedCount) question\(attemptedCount == 1 ? "" : "s") reflected on")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))

                    if let driver = selectedDriver {
                        Text("\(driver.emoji) \(driver.shortDescription)")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(DS.goldText)
                            .padding(.top, 4)
                    }
                }

                if let nudge = nudgeCompletionMessage {
                    NudgeCardView(message: nudge)
                        .padding(.horizontal, DS.hPadding)
                }

                Spacer()

                Button {
                    if let selectedTab {
                        selectedTab.wrappedValue = .home
                    } else {
                        dismiss()
                    }
                } label: {
                    Text("Done →")
                }
                .goldButtonStyle()
                .padding(.horizontal, DS.hPadding)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Already checked in today

    private func alreadyDoneView(_ checkIn: CheckIn) -> some View {
        ZStack {
            DS.heroGradient
                .shimmerOverlay(duration: 4.5, intensity: 0.22)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                NudgeAvatar(size: 72)

                VStack(spacing: 8) {
                    Text("You checked in today.")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .heroTextLegibility()

                    Text("Day \(checkIn.streakCount)")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(DS.goldText)

                    Text("Come back tomorrow")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 4)
                }

                Spacer()

                Button {
                    if let selectedTab {
                        selectedTab.wrappedValue = .home
                    } else {
                        dismiss()
                    }
                } label: {
                    Text("Done →")
                }
                .goldButtonStyle()
                .padding(.horizontal, DS.hPadding)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Load questions from Supabase (fallback to local mock)

    private func loadQuestions() async {
        // Sunday weekly review — once per ISO week
        if WeeklyReviewTracker.isDueNow() {
            await loadWeeklyReviewData()
            showWeeklyReview = true
        }

        // Monthly checkpoint takes priority over daily — re-asks
        // previously YES-answered questions to measure change.
        if MonthlyReviewTracker.isDueNow() {
            if let checkpoint = await checkpointQuestions(count: 4), !checkpoint.isEmpty {
                questions = checkpoint
                MonthlyReviewTracker.markDone()
                return
            }
        }

        do {
            let fetched = try await service.fetchTailoredQuestions(count: 4)
            if fetched.isEmpty {
                questions = await tailoredSeedQuestions(count: 4)
            } else {
                questions = fetched
            }
        } catch {
            questions = await tailoredSeedQuestions(count: 4)
        }
    }

    /// Checkpoint: pick 4 questions targeting biases the user previously
    /// answered YES to (times_encountered > 0) and hasn't yet fully
    /// reflected on. Gives a "how do you feel now?" moment once a month.
    private func checkpointQuestions(count: Int) async -> [Question]? {
        guard let progress = try? await service.fetchBiasProgress() else { return nil }
        let unresolvedBiases = progress
            .filter { $0.timesEncountered > $0.timesReflected && $0.timesEncountered > 0 }
            .sorted { ($0.timesEncountered - $0.timesReflected) > ($1.timesEncountered - $1.timesReflected) }
            .map(\.biasName)

        guard !unresolvedBiases.isEmpty else { return nil }

        var picked: [Question] = []
        for biasName in unresolvedBiases {
            if let q = QuestionPool.seed.first(where: { $0.biasName == biasName }) {
                picked.append(q)
                if picked.count >= count { break }
            }
        }
        return picked.isEmpty ? nil : picked
    }

    /// Fallback when Supabase `question_pool` is empty. Ranks local seed
    /// by top biases (from bias_progress + money-event tags) so the user
    /// still gets tailored questions without hitting the DB.
    private func tailoredSeedQuestions(count: Int) async -> [Question] {
        guard let progress = try? await service.fetchBiasProgress() else {
            return Array(QuestionPool.seed.shuffled().prefix(count))
        }
        let events = (try? await service.fetchMoneyEvents(forMonth: Date())) ?? []
        let eventTagCounts: [String: Int] = events
            .compactMap(\.behaviourTag)
            .reduce(into: [:]) { $0[$1, default: 0] += 1 }

        // Rank every bias by score.
        let rankedBiases = progress.map { bp -> (String, Int) in
            let score = BiasScoreService.computeScore(
                biasName: bp.biasName, progress: bp, taggedEvents: eventTagCounts[bp.biasName] ?? 0
            )
            return (bp.biasName, score.score)
        }
        .sorted { $0.1 > $1.1 }
        .map(\.0)

        // For each top bias, find a seed question targeting it. Fill with
        // shuffled remainder if not enough matches.
        var picked: [Question] = []
        for biasName in rankedBiases {
            if let q = QuestionPool.seed.first(where: { $0.biasName == biasName && !picked.contains(where: { $0.id == $0.id }) }) {
                picked.append(q)
                if picked.count >= count { break }
            }
        }
        if picked.count < count {
            let fill = QuestionPool.seed
                .filter { q in !picked.contains(where: { $0.id == q.id }) }
                .shuffled()
                .prefix(count - picked.count)
            picked.append(contentsOf: fill)
        }
        return Array(picked.prefix(count))
    }

    private func loadWeeklyReviewData() async {
        do {
            let events = try await service.fetchMoneyEventsThisWeek()
            weeklySpend = events.reduce(0.0) { $0 + $1.amount }
            weeklyEventCount = events.count

            let today = try? await service.fetchTodaysCheckIn()
            weeklyStreak = today?.streakCount ?? 0

            let progress = try await service.fetchBiasProgress()
            let emojiLookup = Dictionary(
                uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.emoji) }
            )
            weeklyTopBiases = progress
                .filter { $0.timesEncountered > 0 }
                .compactMap { bp -> (HomeViewModel.DailyPattern, Int)? in
                    let score = BiasScoreService.computeScore(
                        biasName: bp.biasName, progress: bp, taggedEvents: 0
                    )
                    return (HomeViewModel.DailyPattern(
                        emoji: emojiLookup[bp.biasName] ?? "🧠",
                        biasName: bp.biasName,
                        oneLiner: "",
                        stage: score.masteryStage,
                        score: score.score
                    ), score.score)
                }
                .sorted { $0.1 > $1.1 }
                .prefix(3)
                .map(\.0)
        } catch {
            weeklyTopBiases = []
        }
    }

    // MARK: - Save check-in to Supabase

    private func saveCheckIn() async {
        isSaving = true
        defer { isSaving = false }

        guard let uid = await service.currentUserId else { return }

        // Compute streak
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let yesterdayCheckIn = try? await service.fetchCheckIn(on: yesterday)
        let streak = (yesterdayCheckIn?.streakCount ?? 0) + 1

        // Compute alignment
        let now = Date()
        let month = try? await service.fetchOrCreateBudgetMonth(for: now)
        let events = try? await service.fetchMoneyEvents(forMonth: now)
        let unplanned = (events ?? [])
            .filter { $0.plannedStatus.isUnplanned }
            .reduce(0.0) { $0 + $1.amount }
        let target = month?.incomeTarget ?? 0
        let alignment = target > 0 ? max(0, min(100, (1 - unplanned / target) * 100)) : 0

        let checkIn = CheckIn(
            id: UUID(),
            userId: uid,
            date: Date(),
            questionId: questions.first?.id,
            response: nil,
            emotionalTone: .neutral,
            spendingDriver: selectedDriver,
            streakCount: streak,
            alignmentPct: alignment,
            createdAt: Date()
        )

        do {
            try await service.saveCheckIn(checkIn)
        } catch {
            // Continue to completion even if save fails
        }

        savedStreak = streak

        nudgeCompletionMessage = NudgeEngine.checkInResponse(
            streakDays: streak,
            questionsReflected: attemptedCount,
            driver: selectedDriver,
            emotionalTone: nil
        )

        withAnimation(.easeInOut(duration: 0.3)) {
            phase = .done
        }
        NotificationService.scheduleDailyReminder()
    }

    // MARK: - Swipe actions

    private func swipeYes() {
        lastAnswerWasYes = true
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: 600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func swipeNo() {
        lastAnswerWasYes = false
        withAnimation(.easeOut(duration: 0.3)) {
            dragOffset = CGSize(width: -600, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            advance()
        }
    }

    private func advance() {
        // Flash the citation for the question just answered
        if currentIndex < questions.count {
            let biasName = questions[currentIndex].biasName
            if let citation = allBiasPatterns.first(where: { $0.name == biasName })?.keyRef {
                flashedCitation = citation
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                    if flashedCitation == citation {
                        flashedCitation = nil
                    }
                }
            }
        }
        attemptedCount += 1
        currentIndex += 1
        showWhy = false
        selectedTone = nil
        dragOffset = .zero
        if currentIndex >= questions.count {
            withAnimation(.easeInOut(duration: 0.3)) {
                phase = .driverPick
            }
        }
    }
}

#Preview {
    NavigationStack { CheckInView() }
}
