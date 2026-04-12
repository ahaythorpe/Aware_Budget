import SwiftUI

struct InsightFeedView: View {
    @State private var weekEvents: [MoneyEvent] = []
    @State private var allEvents: [MoneyEvent] = []
    @State private var recentCheckIns: [CheckIn] = []
    @State private var isLoading = false

    private let service = SupabaseService.shared

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: DS.sectionGap) {
                    weeklyHeroCard
                    spendingTrendsSection
                    patternsSection
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
            recentCheckIns = try await service.fetchRecentCheckIns(limit: 30)
        } catch {
            // swallow for now
        }
    }

    // MARK: - 1. Weekly hero card

    private var weeklyHeroCard: some View {
        let planned = weekEvents.filter { $0.plannedStatus == .planned }.reduce(0.0) { $0 + $1.amount }
        let unplanned = weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let net = planned - unplanned
        let checkInDays = Set(recentCheckIns.filter { isThisWeek($0.date) }.map { dayOfWeek($0.date) }).count

        return VStack(alignment: .leading, spacing: 14) {
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
                Text("This week: \(sign)\(formattedAmount(abs(net))) from future you")
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
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1B5E20"), Color(hex: "2E7D32"), Color(hex: "4CAF50")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
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
            .background(
                Capsule().fill(.white.opacity(0.18))
            )
    }

    // MARK: - 2. Spending trends (sparkline cards)

    private var spendingTrendsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Spending trends")

            let tagTrends = computeTagTrends()

            if tagTrends.isEmpty {
                emptyCard(message: "Log events with behaviour tags to see trends.")
            } else {
                ForEach(tagTrends, id: \.tag.rawValue) { trend in
                    trendCard(trend)
                }
            }
        }
    }

    private func trendCard(_ trend: TagTrend) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(trend.tag.emoji)
                        .font(.title3)
                    Text(trend.tag.label)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DS.textPrimary)
                }

                directionPill(improving: trend.improving)

                Text("Linked to \(trend.tag.label.lowercased()) bias")
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }

            Spacer()

            SparklineView(
                values: trend.weeklyValues,
                barWidth: 5,
                height: 32,
                improving: trend.improving
            )
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

    private func directionPill(improving: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: improving ? "arrow.down.right" : "arrow.up.right")
                .font(.system(size: 9, weight: .bold))
            Text(improving ? "Improving" : "Watch this")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(improving ? DS.positive : DS.warning)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill((improving ? DS.positive : DS.warning).opacity(0.12))
        )
    }

    // MARK: - 3. Bias patterns (horizontal scroll)

    private var patternsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Your patterns")

            let patterns = computeBiasPatterns()

            if patterns.isEmpty {
                emptyCard(message: "Complete check-ins and log events to discover your patterns.")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(patterns, id: \.tag.rawValue) { pattern in
                            patternCard(pattern)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func patternCard(_ pattern: BiasPattern) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(pattern.tag.emoji)
                .font(.system(size: 32))

            Text(pattern.tag.label)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(DS.textPrimary)

            Text("\(pattern.count) times seen")
                .font(.caption)
                .foregroundStyle(DS.textSecondary)

            strengthPill(pattern.strength)
        }
        .padding(16)
        .frame(width: 150, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                .fill(DS.cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius, style: .continuous)
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    private func strengthPill(_ strength: PatternStrength) -> some View {
        Text(strength.label)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(strength.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(strength.color.opacity(0.12))
            )
    }

    // MARK: - 4. Nudge weekly insight

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
                        .stroke(DS.paleGreen, lineWidth: 0.5)
                )
        )
    }

    // MARK: - Data models

    struct TagTrend {
        let tag: CheckIn.SpendingDriver
        let weeklyValues: [Double]
        let improving: Bool
    }

    struct BiasPattern {
        let tag: CheckIn.SpendingDriver
        let count: Int
        let strength: PatternStrength
    }

    enum PatternStrength {
        case emerging, established, strong

        var label: String {
            switch self {
            case .emerging:    return "Emerging"
            case .established: return "Established"
            case .strong:      return "Strong"
            }
        }

        var color: Color {
            switch self {
            case .emerging:    return DS.textSecondary
            case .established: return DS.warning
            case .strong:      return Color(hex: "D32F2F")
            }
        }

        static func from(count: Int) -> PatternStrength {
            switch count {
            case ..<3:  return .emerging
            case 3..<7: return .established
            default:    return .strong
            }
        }
    }

    // MARK: - Computation helpers

    private func computeTagTrends() -> [TagTrend] {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()

        // Group all events by behaviour tag
        let tagged = allEvents.filter { $0.behaviourTag != nil }
        let byTag = Dictionary(grouping: tagged, by: { $0.behaviourTag! })

        return byTag.compactMap { rawValue, events -> TagTrend? in
            guard let driver = CheckIn.SpendingDriver(rawValue: rawValue) else { return nil }

            // Build 7 weekly buckets (most recent last)
            var weeklyValues: [Double] = []
            for weeksAgo in (0..<7).reversed() {
                guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                      let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)),
                      let sunday = cal.date(byAdding: .day, value: 7, to: monday) else {
                    weeklyValues.append(0)
                    continue
                }
                let weekTotal = events.filter { $0.date >= monday && $0.date < sunday }.reduce(0.0) { $0 + $1.amount }
                weeklyValues.append(weekTotal)
            }

            let recent = weeklyValues.suffix(3).reduce(0, +)
            let earlier = weeklyValues.prefix(4).reduce(0, +)
            let improving = recent <= earlier

            return TagTrend(tag: driver, weeklyValues: weeklyValues, improving: improving)
        }
        .sorted { $0.weeklyValues.last ?? 0 > $1.weeklyValues.last ?? 0 }
    }

    private func computeBiasPatterns() -> [BiasPattern] {
        // Count from both money event tags and check-in drivers
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
            return BiasPattern(tag: driver, count: count, strength: PatternStrength.from(count: count))
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
            return .text(
                "\(unplannedPct)% unplanned this week. Nudge isn't judging, but awareness is the lever."
            )
        }

        if unplannedPct < 20, !weekEvents.isEmpty {
            return .text(
                "Only \(unplannedPct)% unplanned this week. Future you is winning."
            )
        }

        return .text(
            "\(weekEvents.count) events logged this week. The data is building. Nudge is watching."
        )
    }
}

#Preview {
    NavigationStack { InsightFeedView() }
}
