import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showTargetEditor = false
    @State private var targetInput = ""
    @State private var isLoadingDemo = false
    @State private var showSettings = false
    @State private var showCheckIn = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("uvpDismissed") private var uvpDismissed = false

    var selectedTab: Binding<RootTab>? = nil

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $showCheckIn, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack { CheckInView() }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
        .alert("Monthly income target", isPresented: $showTargetEditor) {
            TextField("Amount", text: $targetInput)
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
            Button("Save") {
                let value = Double(targetInput.replacingOccurrences(of: ",", with: ".")) ?? 0
                Task { await viewModel.saveTarget(value) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Used to calculate your alignment % each month. You can change this any time.")
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: DS.sectionGap) {
                greetingHeader
                demoDataLink
                if let msg = viewModel.nudgeMessage {
                    NudgeCardView(
                        message: msg,
                        onAction: { action in
                            handleNudgeAction(action)
                        },
                        onDismiss: {
                            withAnimation(.easeOut(duration: 0.25)) {
                                viewModel.dismissNudge()
                            }
                        }
                    )
                }
                if !uvpDismissed { uvpCard }
                patternAlerts
                heroCheckInCard
                patternsToWatchSection
                streakSection
                statCardsRow
                dailyMissions
                alignmentCard
                recentActivitySection
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
    }

    private func handleNudgeAction(_ action: NudgeAction) {
        switch action {
        case .startCheckIn:
            showCheckIn = true
        case .openLearnBias, .openBiasDetail:
            selectedTab?.wrappedValue = .library
        case .openTrends:
            selectedTab?.wrappedValue = .insights
        }
    }

    // MARK: - Header

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text(viewModel.todayLabel)
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.title3)
                    .foregroundStyle(DS.textTertiary)
            }
            .accessibilityLabel("Settings")
        }
        .padding(.top, 8)
    }

    // MARK: - UVP card

    private var uvpCard: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(DS.accent)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text("Most apps track what you spent.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DS.textPrimary)
                Text("AwareBudget tracks why.")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(DS.darkGreen)
                Text("Budgets fail from shame not data \u{00B7} Kahneman, 1979")
                    .font(.system(size: 9))
                    .italic()
                    .foregroundStyle(DS.textTertiary)
            }
            .padding(14)

            Spacer()

            Button {
                withAnimation { uvpDismissed = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(DS.textTertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Pattern alerts

    private var patternAlerts: some View {
        ForEach(viewModel.patternAlerts) { alert in
            Button {
                selectedTab?.wrappedValue = .insights
            } label: {
                HStack(spacing: 12) {
                    Text(alert.emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(alert.biasName) — \(alert.count) times")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(DS.textPrimary)
                        Text(alert.trend)
                            .font(.caption)
                            .foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(DS.textTertiary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(DS.accent.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Hero check-in card (#2E7D32)

    private var heroCheckInCard: some View {
        Button {
            showCheckIn = true
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                if !viewModel.isCheckedInToday, let bias = viewModel.nextBiasName {
                    Text(bias.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(DS.goldText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(DS.goldBase.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(DS.goldText.opacity(0.4), lineWidth: 0.5)
                                )
                        )
                }

                if viewModel.isCheckedInToday {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(DS.goldText)
                        Text("Checked in \u{00B7} Day \(viewModel.streak)")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(.white)
                    }
                    if let tone = viewModel.todaysCheckIn?.emotionalTone {
                        HStack(spacing: 6) {
                            Text(tone.emoji)
                            Text("Tone \u{00B7} \(tone.label)")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                } else {
                    Text(viewModel.nextQuestionTeaser ?? "Today's check-in")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start check-in")
                        .font(.system(size: 13, weight: .bold))
                        .goldButtonStyle()
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.heroGradient)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Patterns to watch today

    private var patternsToWatchSection: some View {
        Group {
            if !viewModel.dailyPatterns.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Patterns to watch today")
                    Text("Rotates daily based on your data")
                        .font(.caption)
                        .foregroundStyle(DS.textSecondary)

                    VStack(spacing: 8) {
                        ForEach(viewModel.dailyPatterns) { pattern in
                            Button {
                                selectedTab?.wrappedValue = .library
                            } label: {
                                HStack(spacing: 12) {
                                    Text(pattern.emoji)
                                        .font(.title2)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(pattern.biasName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(DS.textPrimary)
                                        Text(pattern.oneLiner)
                                            .font(.caption)
                                            .foregroundStyle(DS.textSecondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    Text(pattern.stage.rawValue)
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundStyle(stageForeground(pattern.stage))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            Capsule()
                                                .fill(stageBackground(pattern.stage))
                                        )
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                        .fill(DS.cardBg)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                                .stroke(DS.paleGreen, lineWidth: 0.5)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("New patterns tested daily to build your awareness")
                        .font(.system(size: 9))
                        .italic()
                        .foregroundStyle(DS.textTertiary)
                }
            }
        }
    }

    private func stageForeground(_ stage: MasteryStage) -> Color {
        switch stage {
        case .active: return DS.stageActive
        case .emerging: return DS.stageEmerging
        case .improving: return DS.primary
        default: return DS.textSecondary
        }
    }

    private func stageBackground(_ stage: MasteryStage) -> Color {
        switch stage {
        case .active: return DS.stageActive.opacity(0.1)
        case .emerging: return DS.stageEmerging.opacity(0.1)
        case .improving: return DS.primary.opacity(0.1)
        default: return DS.paleGreen
        }
    }

    // MARK: - Streak ring (or welcome empty state)

    private var streakSection: some View {
        Group {
            if viewModel.streak == 0 && !viewModel.isCheckedInToday {
                welcomeEmptyState
            } else {
                VStack(spacing: 4) {
                    StreakRingView(streak: viewModel.streak, weekDots: viewModel.weekDots)
                        .padding(.vertical, 20)
                    Text(viewModel.streakMessage)
                        .font(.footnote)
                        .foregroundStyle(DS.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(DS.paleGreen, lineWidth: 0.5)
                        )
                )
            }
        }
    }

    private var welcomeEmptyState: some View {
        VStack(spacing: 20) {
            NudgeAvatar(size: 120)

            VStack(spacing: 8) {
                Text("Hi, I'm Nudge")
                    .font(.title.weight(.bold))
                    .foregroundStyle(DS.textPrimary)

                Text("Ready to understand your money mind?")
                    .font(.title3)
                    .foregroundStyle(DS.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                showCheckIn = true
            } label: {
                HStack {
                    Spacer()
                    Text("Start your first check-in")
                        .font(.headline.weight(.bold))
                    Spacer()
                }
                .goldButtonStyle()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.hPadding)
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Stat cards row

    private var statCardsRow: some View {
        HStack(spacing: 10) {
            statCard(
                label: "ALIGNMENT",
                value: viewModel.isTargetSet ? "\(Int(viewModel.alignmentPct))%" : "—",
                color: viewModel.alignmentColor
            )
            statCard(
                label: "BIASES SEEN",
                value: "\(viewModel.biasesSeenCount)",
                color: DS.goldText,
                useGold: true
            )
            statCard(
                label: "THIS WEEK",
                value: viewModel.weekSpendTrend,
                color: DS.textPrimary
            )
        }
    }

    private func statCard(label: String, value: String, color: Color, useGold: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(DS.textTertiary)
                .tracking(0.8)
            if useGold {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(DS.goldText)
            } else {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Daily missions

    private var dailyMissions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Daily missions")
            VStack(spacing: 6) {
                missionRow(
                    done: viewModel.isCheckedInToday,
                    label: "Daily check-in",
                    hint: "Keep the streak"
                )
                missionRow(
                    done: viewModel.hasLoggedEventToday,
                    label: "Log a money event",
                    hint: "Track what happened"
                )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                            .stroke(DS.paleGreen, lineWidth: 0.5)
                    )
            )
        }
    }

    private func missionRow(done: Bool, label: String, hint: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(done ? DS.accent : DS.textTertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(done ? DS.textSecondary : DS.textPrimary)
                    .strikethrough(done)
                Text(hint)
                    .font(.caption)
                    .foregroundStyle(DS.textTertiary)
            }
            Spacer()
        }
    }

    // MARK: - Alignment card

    private var alignmentCard: some View {
        Button {
            if !viewModel.isTargetSet {
                targetInput = ""
                showTargetEditor = true
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: "Alignment")
                    if viewModel.isTargetSet {
                        Text("\(Int(viewModel.alignmentPct))%")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.alignmentColor)
                            .contentTransition(.numericText())
                    } else {
                        Text("Set target")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(DS.accent)
                    }
                    Text(viewModel.alignmentReassurance)
                        .font(.caption)
                        .foregroundStyle(DS.textSecondary)
                        .lineLimit(2, reservesSpace: true)
                }
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                            .stroke(DS.paleGreen, lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent activity")

            if viewModel.recentEvents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.title3)
                        .foregroundStyle(DS.textTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No events logged yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DS.textPrimary)
                        Text("Tap below to log your first event.")
                            .font(.caption)
                            .foregroundStyle(DS.textSecondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(DS.paleGreen, lineWidth: 0.5)
                        )
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.recentEvents) { event in
                        eventRow(event)
                    }
                }
            }
        }
    }

    // MARK: - Demo data (hidden dev link)

    private var demoDataLink: some View {
        Button {
            guard !isLoadingDemo else { return }
            isLoadingDemo = true
            Task {
                do {
                    try await DemoDataService.seed()
                    await viewModel.load()
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
                isLoadingDemo = false
            }
        } label: {
            if isLoadingDemo {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("Load demo data \u{2192}")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DS.accent)
            }
        }
        .buttonStyle(.plain)
    }

    private func eventRow(_ event: MoneyEvent) -> some View {
        HStack(spacing: 12) {
            Text(event.plannedStatus.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(DS.paleGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.plannedStatus.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.textPrimary)
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
            Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(DS.textPrimary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    NavigationStack { HomeView() }
}
