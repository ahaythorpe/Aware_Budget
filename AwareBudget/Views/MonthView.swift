import SwiftUI

struct MonthView: View {
    @State private var events: [MoneyEvent] = []
    @State private var alignment: Double = 0
    @State private var incomeTarget: Double = 0
    @State private var isEditingTarget = false
    @State private var targetText: String = ""
    @State private var isLoading = false

    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Date())
    }

    private var alignmentColor: Color {
        switch alignment {
        case 80...: return DS.positive
        case 50..<80: return DS.warning
        default: return DS.warning
        }
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(monthLabel)
                        .font(.title.bold())
                        .foregroundStyle(DS.textPrimary)

                    alignmentCard
                    targetRow
                    unplannedSpendCard
                    topBehaviourCard
                    eventsByStatus
                }
                .padding(DS.hPadding)
            }
        }
        .navigationTitle("This month")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .alert("Income target", isPresented: $isEditingTarget) {
            TextField("Amount", text: $targetText)
            #if !os(macOS)
                .keyboardType(.decimalPad)
            #endif
            Button("Save") {
                Task {
                    let value = Double(targetText.replacingOccurrences(of: ",", with: ".")) ?? 0
                    try? await SupabaseService.shared.updateIncomeTarget(value, for: Date())
                    await load()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Alignment

    private var alignmentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(Int(alignment))%")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(alignmentColor)
                .contentTransition(.numericText())
            Text("aligned this month")
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Target

    private var targetRow: some View {
        Button {
            targetText = String(format: "%.0f", incomeTarget)
            isEditingTarget = true
        } label: {
            HStack {
                Text("Income target")
                    .foregroundStyle(DS.textPrimary)
                Spacer()
                Text(incomeTarget, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                    .foregroundStyle(DS.textSecondary)
                Image(systemName: "chevron.right").foregroundStyle(DS.textTertiary)
            }
            .padding(16)
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

    // MARK: - Unplanned spend ratio

    private var unplannedSpendCard: some View {
        let total = events.reduce(0.0) { $0 + $1.amount }
        let unplanned = events.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let pct = total > 0 ? Int((unplanned / total) * 100) : 0
        let surpriseCount = events.filter { $0.plannedStatus == .surprise }.count
        let impulseCount = events.filter { $0.plannedStatus == .impulse }.count

        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Unplanned spend")

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(pct)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(pct > 40 ? DS.warning : DS.positive)
                Text("of total spend")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
            }

            HStack(spacing: 16) {
                statPill(label: "Surprise", count: surpriseCount, emoji: "\u{26A1}")
                statPill(label: "Impulse", count: impulseCount, emoji: "\u{1F3AF}")
            }
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

    private func statPill(label: String, count: Int, emoji: String) -> some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.caption)
            Text("\(count) \(label.lowercased())")
                .font(.caption.weight(.medium))
                .foregroundStyle(DS.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule().fill(DS.paleGreen)
        )
    }

    // MARK: - Top behaviour

    private var topBehaviourCard: some View {
        let tags = events.compactMap(\.behaviourTag)
        let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
        let top = counts.max(by: { $0.value < $1.value })

        return VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Top behaviour this month")
            if let top = top,
               let driver = CheckIn.SpendingDriver(rawValue: top.key) {
                HStack(spacing: 10) {
                    Text(driver.emoji)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(driver.label)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(DS.textPrimary)
                        Text("\(top.value) events driven by \(driver.label.lowercased())")
                            .font(.caption)
                            .foregroundStyle(DS.textSecondary)
                    }
                }
            } else {
                Text("Log some events to see patterns.")
                    .font(.subheadline)
                    .foregroundStyle(DS.textSecondary)
            }
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

    // MARK: - Events by status

    private var eventsByStatus: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(MoneyEvent.PlannedStatus.allCases) { status in
                let items = events.filter { $0.plannedStatus == status }
                if !items.isEmpty {
                    Text("\(status.emoji) \(status.label)")
                        .font(.headline)
                        .foregroundStyle(DS.textPrimary)
                    ForEach(items) { event in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                if let tag = event.behaviourTag,
                                   let driver = CheckIn.SpendingDriver(rawValue: tag) {
                                    Text(driver.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.textPrimary)
                                } else {
                                    Text(status.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(DS.textPrimary)
                                }
                                Text(event.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(DS.textSecondary)
                            }
                            Spacer()
                            Text(event.amount, format: .currency(code: Locale.current.currency?.identifier ?? "USD"))
                                .fontWeight(.medium)
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
            }
        }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let now = Date()
            let month = try await SupabaseService.shared.fetchOrCreateBudgetMonth(for: now)
            incomeTarget = month.incomeTarget
            events = try await SupabaseService.shared.fetchMoneyEvents(forMonth: now)

            let unplanned = events.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
            if month.incomeTarget > 0 {
                alignment = max(0, min(100, (1 - unplanned / month.incomeTarget) * 100))
            } else {
                alignment = 0
            }
        } catch {
            // swallow — month view is read-only
        }
    }
}
