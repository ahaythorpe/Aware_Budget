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

    // MARK: - Header

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(DS.deepPurple)
                Text(viewModel.todayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    // MARK: - Hero check-in card (#2D1B69)

    private var heroCheckInCard: some View {
        Button {
            selectedTab?.wrappedValue = .checkIn
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 8) {
                    Image(systemName: viewModel.isCheckedInToday ? "checkmark.seal.fill" : "sparkles")
                        .foregroundStyle(viewModel.isCheckedInToday ? Color.green : DS.coral)
                    Text(viewModel.isCheckedInToday ? "Checked in today" : "Today's check-in")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.75))
                        .textCase(.uppercase)
                        .tracking(0.8)
                    Spacer()
                    if !viewModel.isCheckedInToday {
                        Image(systemName: "arrow.right")
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }

                if viewModel.isCheckedInToday, let tone = viewModel.todaysCheckIn?.emotionalTone {
                    Text("You showed up. See you tomorrow.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                    HStack(spacing: 6) {
                        Text(tone.emoji)
                        Text("Today's tone · \(tone.label)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    Text(viewModel.nextQuestionTeaser ?? "One question. 60 seconds.")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Tap to check in")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(DS.deepPurple)
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
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
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
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .foregroundStyle(DS.accent)
                        Text("Alignment")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                    }
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
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
                Spacer()
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                            .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
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
            Text("Recent activity")
                .font(.caption.weight(.bold))
                .foregroundStyle(DS.accent)
                .textCase(.uppercase)
                .tracking(0.9)

            if viewModel.recentEvents.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Nothing logged yet")
                            .font(.subheadline.weight(.medium))
                        Text("Tap above to log your first event.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
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
            Text(event.eventType.emoji)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(DS.bg)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(event.category ?? event.eventType.label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.deepPurple)
                Text(event.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(DS.deepPurple)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
                )
        )
    }
}

#Preview {
    NavigationStack { HomeView() }
}
