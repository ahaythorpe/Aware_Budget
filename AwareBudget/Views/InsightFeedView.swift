import SwiftUI
import Charts

struct InsightFeedView: View {
    @State private var weekEvents: [MoneyEvent] = []
    @State private var allEvents: [MoneyEvent] = []
    @State private var recentCheckIns: [CheckIn] = []
    @State private var isLoading = false

    private let service = SupabaseService.shared
    private let borderColor = Color(hex: "4CAF50").opacity(0.15)

    var body: some View {
        ZStack {
            Color(hex: "F5F7F5").ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.sectionGap) {
                    weeklyHeroCard
                    unplannedBarChartSection
                    biasFrequencySection
                    donutChartSection
                    nudgeInsightCard
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
        .refreshable { await load() }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            weekEvents = try await service.fetchMoneyEventsThisWeek()
            allEvents = try await service.fetchAllMoneyEvents()
            recentCheckIns = try await service.fetchRecentCheckIns(limit: 60)
        } catch {
            // swallow for now
        }
    }

    // MARK: - 1. Weekly hero card (gradient)

    private var weeklyHeroCard: some View {
        let planned = weekEvents.filter { $0.plannedStatus == .planned }.reduce(0.0) { $0 + $1.amount }
        let unplanned = weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let net = planned - unplanned
        let checkInDays = Set(recentCheckIns.filter { isThisWeek($0.date) }.map { dayOfWeek($0.date) }).count

        return ZStack(alignment: .topTrailing) {
            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 120, height: 120)
                .offset(x: 40, y: -30)
            Circle()
                .fill(Color.white.opacity(0.04))
                .frame(width: 80, height: 80)
                .offset(x: -20, y: 80)

            VStack(alignment: .leading, spacing: 14) {
                Text("THIS WEEK")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(DS.goldText)
                    .tracking(1.2)

                if weekEvents.isEmpty {
                    Text("Start logging to see your impact")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                } else {
                    let sign = net >= 0 ? "+" : ""
                    Text("\(sign)\(formattedAmount(abs(net))) from future you")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Text("\(checkInDays) of 7 days you chose future you")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))

                if !weekEvents.isEmpty {
                    weeklyPills
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.heroGradient)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous))
    }

    private var weeklyPills: some View {
        let total = weekEvents.reduce(0.0) { $0 + $1.amount }
        let unplanned = weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let unplannedPct = total > 0 ? Int((unplanned / total) * 100) : 0
        let topTag = topBehaviourTag(from: weekEvents)
        let streak = consecutiveCheckInDays()

        return HStack(spacing: 8) {
            heroPill(text: "\(unplannedPct)% unplanned")
            if let tag = topTag {
                heroPill(text: tag.label)
            }
            if streak > 0 {
                heroPill(text: "\(streak)d streak")
            }
        }
    }

    private func heroPill(text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.18)))
    }

    // MARK: - 2. Unplanned spend bar chart (6 weeks)

    private var unplannedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Unplanned spend")

            let weeklyData = computeWeeklyUnplanned()

            if weeklyData.isEmpty {
                emptyCard(message: "Log events to see your unplanned spend trend.")
            } else {
                Chart(weeklyData) { item in
                    BarMark(
                        x: .value("Week", item.label),
                        y: .value("Amount", item.amount)
                    )
                    .foregroundStyle(item.improving ? DS.positive : DS.warning)
                    .cornerRadius(4)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(shortAmount(v))
                                    .font(.caption2)
                                    .foregroundStyle(DS.textTertiary)
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - 3. Bias frequency horizontal bars

    private var biasFrequencySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bias frequency")

            let patterns = computeBiasPatterns()

            if patterns.isEmpty {
                emptyCard(message: "Complete check-ins and log events to discover your patterns.")
            } else {
                Chart(patterns) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Bias", item.tag.label)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "1B5E20"), Color(hex: "4CAF50")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(4)
                    .annotation(position: .trailing, alignment: .leading, spacing: 4) {
                        Text("\(item.count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(DS.textSecondary)
                    }
                }
                .frame(height: CGFloat(max(patterns.count, 1)) * 36)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel()
                            .font(.caption)
                            .foregroundStyle(DS.textPrimary)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                )
            }
        }
    }

    // MARK: - 4. Donut chart — planned vs unplanned

    private var donutChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Planned vs unplanned")

            let total = allEvents.reduce(0.0) { $0 + $1.amount }
            let planned = allEvents.filter { $0.plannedStatus == .planned }.reduce(0.0) { $0 + $1.amount }
            let unplanned = total - planned
            let plannedPct = total > 0 ? Int((planned / total) * 100) : 0
            let unplannedPct = total > 0 ? Int((unplanned / total) * 100) : 0

            if allEvents.isEmpty {
                emptyCard(message: "Log events to see your planned vs unplanned ratio.")
            } else {
                let slices: [DonutSlice] = [
                    DonutSlice(label: "Planned", value: planned, color: DS.positive),
                    DonutSlice(label: "Unplanned", value: max(unplanned, 0.01), color: DS.warning),
                ]

                HStack(spacing: 20) {
                    Chart(slices) { slice in
                        SectorMark(
                            angle: .value("Amount", slice.value),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .foregroundStyle(slice.color)
                        .cornerRadius(4)
                    }
                    .frame(width: 120, height: 120)

                    VStack(alignment: .leading, spacing: 10) {
                        donutLegend(color: DS.positive, label: "Planned", pct: plannedPct)
                        donutLegend(color: DS.warning, label: "Unplanned", pct: unplannedPct)
                    }

                    Spacer()
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .fill(DS.cardBg)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                                .stroke(borderColor, lineWidth: 0.5)
                        )
                )
            }
        }
    }

    private func donutLegend(color: Color, label: String, pct: Int) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DS.textPrimary)
                Text("\(pct)%")
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }
        }
    }

    // MARK: - 5. Nudge insight card

    private var nudgeInsightCard: some View {
        let msg = weeklyNudgeMessage()
        return NudgeCardView(message: msg)
    }

    // MARK: - Empty state

    private func emptyCard(message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.title3)
                .foregroundStyle(DS.textTertiary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(DS.textSecondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(borderColor, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Data models

    struct WeeklyUnplanned: Identifiable {
        let id = UUID()
        let label: String
        let amount: Double
        let improving: Bool
    }

    struct BiasPattern: Identifiable {
        let id = UUID()
        let tag: CheckIn.SpendingDriver
        let count: Int
    }

    struct DonutSlice: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
    }

    // MARK: - Computation helpers

    private func computeWeeklyUnplanned() -> [WeeklyUnplanned] {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()

        var results: [WeeklyUnplanned] = []
        var previousAmount: Double = 0

        for weeksAgo in (0..<6).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                  let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)),
                  let sunday = cal.date(byAdding: .day, value: 7, to: monday) else {
                continue
            }
            let weekTotal = allEvents
                .filter { $0.date >= monday && $0.date < sunday && $0.plannedStatus.isUnplanned }
                .reduce(0.0) { $0 + $1.amount }

            let label = weeksAgo == 0 ? "This wk" : "\(weeksAgo)w ago"
            let improving = weekTotal <= previousAmount || weeksAgo == 5
            results.append(WeeklyUnplanned(label: label, amount: weekTotal, improving: improving))
            previousAmount = weekTotal
        }
        return results
    }

    private func computeBiasPatterns() -> [BiasPattern] {
        var counts: [String: Int] = [:]
        for event in allEvents {
            if let tag = event.behaviourTag {
                counts[tag, default: 0] += 1
            }
        }
        for checkIn in recentCheckIns {
            if let driver = checkIn.spendingDriver {
                counts[driver.rawValue, default: 0] += 1
            }
        }
        return counts.compactMap { rawValue, count -> BiasPattern? in
            guard let driver = CheckIn.SpendingDriver(rawValue: rawValue) else { return nil }
            return BiasPattern(tag: driver, count: count)
        }
        .sorted { $0.count > $1.count }
    }

    private func topBehaviourTag(from events: [MoneyEvent]) -> CheckIn.SpendingDriver? {
        let tags = events.compactMap(\.behaviourTag)
        let counts = Dictionary(grouping: tags, by: { $0 }).mapValues(\.count)
        guard let top = counts.max(by: { $0.value < $1.value }) else { return nil }
        return CheckIn.SpendingDriver(rawValue: top.key)
    }

    private func consecutiveCheckInDays() -> Int {
        let cal = Calendar.current
        var streak = 0
        var date = Date()
        let sortedDates = Set(recentCheckIns.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        for checkDate in sortedDates {
            if cal.isDate(checkDate, inSameDayAs: date) {
                streak += 1
                date = cal.date(byAdding: .day, value: -1, to: date) ?? date
            } else {
                break
            }
        }
        return streak
    }

    private func isThisWeek(_ date: Date) -> Bool {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()
        guard let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else { return false }
        return date >= monday && date <= now
    }

    private func dayOfWeek(_ date: Date) -> Int {
        Calendar.current.component(.weekday, from: date)
    }

    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = Locale.current.currency?.identifier ?? "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "\(Int(amount))"
    }

    private func shortAmount(_ value: Double) -> String {
        if value >= 1000 {
            return "\(Int(value / 1000))k"
        }
        return "\(Int(value))"
    }

    private func weeklyNudgeMessage() -> NudgeMessage {
        let total = weekEvents.reduce(0.0) { $0 + $1.amount }
        let unplanned = weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let unplannedPct = total > 0 ? Int((unplanned / total) * 100) : 0

        if weekEvents.isEmpty {
            return .text("No events this week yet. Nudge is patient. Mostly.")
        }

        let patterns = computeBiasPatterns()
        if let top = patterns.first, top.count >= 5 {
            return .withAction(
                "\(top.tag.label) is your dominant pattern at \(top.count) encounters. That's worth understanding.",
                actionLabel: "See your fix",
                action: .openLearnBias(top.tag.label)
            )
        }

        if unplannedPct > 50 {
            return .text("\(unplannedPct)% unplanned this week. Nudge isn't judging, but awareness is the lever.")
        }

        if unplannedPct < 20, !weekEvents.isEmpty {
            return .text("Only \(unplannedPct)% unplanned this week. Future you is winning.")
        }

        return .text("\(weekEvents.count) events logged this week. The data is building. Nudge is watching.")
    }
}

#Preview {
    NavigationStack { InsightFeedView() }
}
