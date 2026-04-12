import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showMoneyEvent = false
    @State private var showTargetEditor = false
    @State private var targetInput = ""
    @State private var isLoadingDemo = false
    @State private var showSettings = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
        .sheet(isPresented: $showMoneyEvent, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack { MoneyEventView() }
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
                heroCheckInCard
                streakSection
                statCardsRow
                dailyMissions
                alignmentCard
                logEventButton
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
            selectedTab?.wrappedValue = .checkIn
        case .openLearnBias, .openBiasDetail:
            selectedTab?.wrappedValue = .learn
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

    // MARK: - Hero check-in card (#2E7D32)

    private var heroCheckInCard: some View {
        Button {
            selectedTab?.wrappedValue = .checkIn
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

                if viewModel.isCheckedInToday, let tone = viewModel.todaysCheckIn?.emotionalTone {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(DS.paleGreen)
                        Text("Done for today")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    Text("You showed up. Back tomorrow.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(tone.emoji)
                        Text("Tone \u{00B7} \(tone.label)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
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
                selectedTab?.wrappedValue = .checkIn
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
                missionRow(
                    done: viewModel.hasViewedLearnToday,
                    label: "Learn a bias",
                    hint: "Swipe through Learn"
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
                            .foregroundStyle(Color(hex: "4CAF50"))
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

    // MARK: - Log event

    private var logEventButton: some View {
        Button {
            showMoneyEvent = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Log event")
            }
        }
        .buttonStyle(SecondaryButtonStyle())
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
                    .foregroundStyle(Color(hex: "4CAF50"))
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
