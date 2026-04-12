import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showMoneyEvent = false
    @State private var showTargetEditor = false
    @State private var targetInput = ""

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
            selectedTab?.wrappedValue = .month
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
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(DS.textTertiary)
                .accessibilityHidden(true)
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
                        Text("Checked in today")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .textCase(.uppercase)
                            .tracking(0.8)
                    }
                    Text("You showed up. See you tomorrow.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(tone.emoji)
                        Text("Today's tone \u{00B7} \(tone.label)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    Text(viewModel.nextQuestionTeaser ?? "One question. 60 seconds.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Start check-in \u{2192}")
                        .font(.system(size: 13, weight: .bold))
                        .goldButtonStyle()
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.primary)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Streak ring

    private var streakSection: some View {
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

    // MARK: - Log event

    private var logEventButton: some View {
        Button {
            showMoneyEvent = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Log money event")
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
                        Text("Nothing logged yet")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(DS.textPrimary)
                        Text("Tap above to log your first event.")
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
