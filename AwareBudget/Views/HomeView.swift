import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showCheckIn = false
    @State private var showMoneyEvent = false
    @State private var showTargetEditor = false
    @State private var targetInput = ""

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            content
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .fullScreenCover(isPresented: $showCheckIn, onDismiss: {
            Task { await viewModel.load() }
        }) {
            NavigationStack { CheckInView() }
        }
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
                statsRow
                logEventButton
                recentActivitySection
                monthLink
            }
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .sensoryFeedback(.success, trigger: viewModel.isCheckedInToday)
    }

    // MARK: - Sections

    private var greetingHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.greeting)
                    .font(.title2.weight(.bold))
                Text(viewModel.todayLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            // Settings placeholder — disabled in beta
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(.top, 8)
    }

    private var heroCheckInCard: some View {
        Button {
            showCheckIn = true
        } label: {
            Card {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.isCheckedInToday
                              ? "checkmark.seal.fill"
                              : "sparkles")
                            .foregroundStyle(viewModel.isCheckedInToday ? .green : .blue)
                        Text(viewModel.isCheckedInToday
                             ? "Checked in today"
                             : "Today's check-in")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)
                        Spacer()
                        if !viewModel.isCheckedInToday {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.blue)
                        }
                    }

                    if viewModel.isCheckedInToday, let tone = viewModel.todaysCheckIn?.emotionalTone {
                        Text("You showed up. See you tomorrow.")
                            .font(.title3.weight(.semibold))
                        HStack(spacing: 6) {
                            Text(tone.emoji)
                            Text("Today's tone · \(tone.label)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text(viewModel.nextQuestionTeaser ?? "One question. 60 seconds.")
                            .font(.title3.weight(.semibold))
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Tap to check in")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            streakCard
            alignmentCard
        }
    }

    private var streakCard: some View {
        Card(padding: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Streak")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Text("\(viewModel.streak)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(viewModel.streakMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
            }
        }
    }

    private var alignmentCard: some View {
        Button {
            if !viewModel.isTargetSet {
                targetInput = ""
                showTargetEditor = true
            }
        } label: {
            Card(padding: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .foregroundStyle(.blue)
                        Text("Alignment")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }

                    if viewModel.isTargetSet {
                        Text("\(Int(viewModel.alignmentPct))%")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(viewModel.alignmentColor)
                            .contentTransition(.numericText())
                    } else {
                        Text("Set target")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundStyle(.blue)
                    }

                    Text(viewModel.alignmentReassurance)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                }
            }
        }
        .buttonStyle(.plain)
    }

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

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent activity")

            if viewModel.recentEvents.isEmpty {
                Card(padding: 20) {
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
                }
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
        Card(padding: 14) {
            HStack(spacing: 12) {
                Text(event.eventType.emoji)
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.category ?? event.eventType.label)
                        .font(.subheadline.weight(.medium))
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
    }

    private var monthLink: some View {
        NavigationLink {
            MonthView()
        } label: {
            HStack {
                Text("This month")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { HomeView() }
}
