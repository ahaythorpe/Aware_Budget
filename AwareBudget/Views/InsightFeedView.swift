import SwiftUI
import Charts

struct InsightFeedView: View {
    var selectedTab: Binding<RootTab>? = nil

    @State private var weekEvents: [MoneyEvent] = []
    @State private var allEvents: [MoneyEvent] = []
    @State private var recentCheckIns: [CheckIn] = []
    @State private var balanceSnapshots: [SupabaseService.BalanceSnapshot] = []
    @State private var awarenessTimestamps: [Date] = []
    /// Selected category to drill into on the expandable trend chart.
    /// nil = overlaid view of top 5 categories. Setting a value
    /// expands that category's line full-screen with daily breakdown.
    @State private var expandedCategory: String? = nil
    @State private var isLoading = false
    @State private var showAboutScore = false

    private let service = SupabaseService.shared
    private let borderColor = DS.accent.opacity(0.15)

    private var hasNoData: Bool {
        allEvents.isEmpty && recentCheckIns.isEmpty && !isLoading
    }

    var body: some View {
        ZStack {
            DS.bg.ignoresSafeArea()

            if hasNoData {
                insightsEmptyState
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        weeklyHeroCard
                        netWorthTrendSection
                        categoryTrendSection
                        biasFrequencySection
                        donutChartSection
                        nudgeInsightCard
                    }
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAboutScore = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(DS.goldBase)
                }
            }
        }
        .sheet(isPresented: $showAboutScore) {
            AboutScoreSheet()
        }
        .task { await load() }
        .refreshable { await load() }
        .onChange(of: selectedTab?.wrappedValue) { _, new in
            if new == .insights { Task { await load() } }
        }
    }

    // MARK: - Full-page empty state

    private var insightsEmptyState: some View {
        VStack(spacing: 22) {
            Spacer()

            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            NudgeSaysCard(
                message: "Your insights appear after you log an event. Start logging now.",
                surface: .gold
            )
            .padding(.horizontal, DS.hPadding)

            // Statement block — gold surface, not a button
            Text("Nudge tracks patterns, not perfection.")
                .font(.system(.headline, weight: .bold))
                .italic()
                .foregroundStyle(DS.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity)
                .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
                )
                .padding(.horizontal, DS.hPadding)

            ResearchFootnote(text: "Patterns assessed via BFAS · Pompian, 2012", style: .pill)

            Button {
                selectedTab?.wrappedValue = .log
            } label: {
                Text("Log your first event")
            }
            .goldButtonStyle()
            .padding(.horizontal, DS.hPadding)
            .padding(.top, 6)

            Spacer()
        }
    }

    // MARK: - Load

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            weekEvents = try await service.fetchMoneyEventsThisWeek()
            allEvents = try await service.fetchAllMoneyEvents()
            recentCheckIns = try await service.fetchRecentCheckIns(limit: 60)
            balanceSnapshots = (try? await service.fetchBalanceSnapshots(monthsBack: 6)) ?? []
            awarenessTimestamps = (try? await service.fetchLessonTimestamps(monthsBack: 6)) ?? []
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
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(DS.goldText)
                    .tracking(1.2)

                if weekEvents.isEmpty {
                    Text("Log events to see your weekly trends")
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
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.18)))
    }

    // MARK: - 1.5 Net worth trend (manual snapshots + bias overlay)

    /// Option B from the design conversation. Plots the user's
    /// manually-entered net worth (savings + investment) as a
    /// gold line over the last 6 months, overlaid with a faint
    /// green band showing how their bias-confirmation rate has
    /// trended over the same window. The story: "as your awareness
    /// grew, your net worth started moving."
    ///
    /// Hidden until the user has at least 2 snapshots — a single
    /// dot doesn't tell a trend. Empty state nudges them to
    /// Settings to enter their first balance.
    private var netWorthTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Net worth trend")
            if balanceSnapshots.count < 2 {
                netWorthEmptyCard
            } else {
                netWorthChart
            }
        }
    }

    private var netWorthEmptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Track your net worth over time.")
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(DS.textPrimary)
            Text("Add your monthly take-home + savings + investment balance in Settings (gear icon on Home). Drop a fresh snapshot weekly. After 2+ snapshots, the trend shows up here — with bias awareness overlaid so you can see how the two move together.")
                .font(.system(.footnote, weight: .medium))
                .foregroundStyle(DS.textSecondary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.accent.opacity(0.15), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private var netWorthChart: some View {
        let netWorth = balanceSnapshots.map { (date: $0.recorded_at, value: $0.savings_balance + $0.investment_balance) }
        let latest = netWorth.last?.value ?? 0
        let maxNet = max(netWorth.map(\.value).max() ?? 1, 1)
        // Cumulative awareness curve — each banked lesson is a moment
        // the user actively identified a bias. Normalised to the same
        // y-range as net worth so the two read on one chart.
        let awareness = cumulativeAwareness(timestamps: awarenessTimestamps, normaliseTo: maxNet)
        let trendInsight = computeTrendInsight(netWorth: netWorth, awareness: awarenessTimestamps)

        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("$\(Int(latest))")
                    .font(.system(size: 28, weight: .black, design: .serif))
                    .foregroundStyle(DS.goldBase)
                Text("net worth today")
                    .font(.system(.caption, weight: .semibold))
                    .foregroundStyle(DS.textSecondary)
                Spacer()
            }
            if let insight = trendInsight {
                trendInsightNudge(insight)
            }
            Chart {
                // Awareness line (faint green, behind)
                ForEach(awareness, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Awareness", point.value),
                        series: .value("Series", "Awareness")
                    )
                    .foregroundStyle(DS.accent.opacity(0.55))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
                }
                // Net worth line (gold, foreground)
                ForEach(netWorth, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Net worth", point.value),
                        series: .value("Series", "Net worth")
                    )
                    .foregroundStyle(DS.matteYellow)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                    AreaMark(
                        x: .value("Date", point.date),
                        y: .value("Net worth", point.value),
                        series: .value("Series", "Net worth")
                    )
                    .foregroundStyle(LinearGradient(
                        colors: [DS.matteYellow.opacity(0.25), DS.matteYellow.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    ))
                    .interpolationMethod(.catmullRom)
                }
            }
            .frame(height: 160)
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
            // Tiny legend for the two series
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Capsule().fill(DS.matteYellow).frame(width: 14, height: 3)
                    Text("Net worth")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
                HStack(spacing: 5) {
                    Capsule().fill(DS.accent.opacity(0.55)).frame(width: 14, height: 3)
                    Text("Awareness moments")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
            }
            ResearchFootnote(
                text: "Manual entry · update weekly in Settings · awareness = lessons banked",
                style: .inline
            )
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        .premiumCardShadow()
    }

    /// Build a cumulative-count awareness series scaled to share the
    /// y-axis with net worth. Each timestamp = +1 to a running total;
    /// the final total is normalised to the chart's max net-worth value
    /// so the curve reads alongside the line without a secondary axis.
    private func cumulativeAwareness(timestamps: [Date], normaliseTo maxValue: Double) -> [(date: Date, value: Double)] {
        guard !timestamps.isEmpty else { return [] }
        let total = Double(timestamps.count)
        guard total > 0 else { return [] }
        let scale = maxValue / total
        return timestamps.enumerated().map { idx, date in
            (date: date, value: Double(idx + 1) * scale)
        }
    }

    /// Compute a celebratory or neutral one-liner about how net worth
    /// and awareness have moved together. Fires when there's enough
    /// data to compare the most recent month vs the prior month.
    private func computeTrendInsight(
        netWorth: [(date: Date, value: Double)],
        awareness: [Date]
    ) -> String? {
        guard let latest = netWorth.last, netWorth.count >= 2 else { return nil }
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        guard let priorAnchor = netWorth.last(where: { $0.date < cutoff }) else { return nil }
        let netDelta = latest.value - priorAnchor.value
        let recentAwareness = awareness.filter { $0 >= cutoff }.count
        let priorAwareness = max(0, awareness.count - recentAwareness)

        if netDelta > 0 && recentAwareness > priorAwareness {
            let pct = Int((netDelta / max(priorAnchor.value, 1)) * 100)
            return "Net worth up \(pct)% this month while you banked \(recentAwareness) new awareness moments. The two move together."
        }
        if netDelta > 0 {
            let pct = Int((netDelta / max(priorAnchor.value, 1)) * 100)
            return "Net worth up \(pct)% this month. Keep noticing — the data is moving in your direction."
        }
        if recentAwareness > priorAwareness {
            return "You banked \(recentAwareness) new lessons this month. Net worth hasn't moved yet — that's normal. Awareness comes first."
        }
        return nil
    }

    private func trendInsightNudge(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image("nudge")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text("NUDGE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(DS.accent)
                Text(message)
                    .font(.system(.footnote, weight: .semibold))
                    .foregroundStyle(DS.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.goldSurfaceBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DS.cardRadius)
                .stroke(DS.goldSurfaceStroke, lineWidth: 0.5)
        )
    }

    // MARK: - 2. Category trend (expandable line graph)

    /// Replaces the old weekly bar chart with a per-category trend
    /// line. Default view: top 5 categories overlaid as muted lines
    /// over the last 6 weeks. Tap a category in the legend to expand
    /// just that line full-width with a richer y-axis. Tap again to
    /// collapse back to the overlay.
    ///
    /// Why: the bar chart only showed total unplanned spend, which
    /// hides which categories drive the spike. The trend graph
    /// answers "where does my money actually trend over time?" — the
    /// foundation question for behavioural awareness.
    private var categoryTrendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Category trend")
            let series = computeCategoryTrend()
            if series.isEmpty {
                emptyCard(message: "Log spend events across a few weeks to see your category trends.")
            } else {
                categoryTrendChart(series: series)
            }
        }
    }

    private struct CategoryTrendPoint: Identifiable {
        let id = UUID()
        let category: String
        let weekStart: Date
        let amount: Double
    }

    /// Build (category × week) totals for the top 5 most-spent
    /// categories over the last 6 weeks. Older weeks bucketed by ISO
    /// week start (Monday).
    private func computeCategoryTrend() -> [CategoryTrendPoint] {
        let cal = Calendar.current
        let now = Date()
        let cutoff = cal.date(byAdding: .day, value: -42, to: now) ?? now
        let recent = allEvents.filter { $0.date >= cutoff }

        // Top 5 categories by total spend in window.
        let totals = recent.reduce(into: [String: Double]()) { acc, e in
            let cat = e.lifeArea ?? "Other"
            acc[cat, default: 0] += e.amount
        }
        let topCategories = totals
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
        let allowed = Set(topCategories)

        // Bucket by week-start.
        var buckets: [String: [Date: Double]] = [:]
        for e in recent {
            let cat = e.lifeArea ?? "Other"
            guard allowed.contains(cat) else { continue }
            var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: e.date)
            comps.weekday = 2 // Monday
            let weekStart = cal.date(from: comps) ?? e.date
            buckets[cat, default: [:]][weekStart, default: 0] += e.amount
        }
        var out: [CategoryTrendPoint] = []
        for cat in topCategories {
            let weeks = buckets[cat] ?? [:]
            for (weekStart, amount) in weeks {
                out.append(CategoryTrendPoint(category: cat, weekStart: weekStart, amount: amount))
            }
        }
        return out.sorted { $0.weekStart < $1.weekStart }
    }

    @ViewBuilder
    private func categoryTrendChart(series: [CategoryTrendPoint]) -> some View {
        let categories = Array(Set(series.map(\.category))).sorted()
        let palette: [Color] = [DS.matteYellow, DS.primary, DS.accent, DS.deepGreen, DS.lightGreen]

        VStack(alignment: .leading, spacing: 10) {
            Chart(series) { point in
                let isExpanded = expandedCategory == nil || expandedCategory == point.category
                LineMark(
                    x: .value("Week", point.weekStart),
                    y: .value("Amount", point.amount),
                    series: .value("Category", point.category)
                )
                .foregroundStyle(by: .value("Category", point.category))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(
                    lineWidth: expandedCategory == point.category ? 3 : 2,
                    lineCap: .round
                ))
                .opacity(isExpanded ? 1.0 : 0.18)
            }
            .chartForegroundStyleScale(domain: categories, range: Array(palette.prefix(categories.count)))
            .chartLegend(.hidden)
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
            // Tappable legend doubles as the expand/collapse control.
            categoryLegend(categories: categories, palette: palette)

            if let expanded = expandedCategory {
                Text("Showing \(expanded) only — tap again to see all.")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(DS.textSecondary)
            } else {
                Text("Tap a category to focus its trend.")
                    .font(.system(.caption, weight: .medium))
                    .foregroundStyle(DS.textTertiary)
            }
        }
        .padding(16)
        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
        .premiumCardShadow()
    }

    private func categoryLegend(categories: [String], palette: [Color]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(categories.enumerated()), id: \.element) { idx, cat in
                let colour = palette[idx % palette.count]
                let isExpanded = expandedCategory == cat
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                            expandedCategory = isExpanded ? nil : cat
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Capsule()
                                .fill(colour)
                                .frame(width: 12, height: 3)
                            Text(cat)
                                .font(.system(.caption2, weight: isExpanded ? .heavy : .semibold))
                                .foregroundStyle(isExpanded ? DS.textPrimary : DS.textSecondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            isExpanded ? AnyShapeStyle(DS.goldSurfaceBg) : AnyShapeStyle(Color.clear),
                            in: Capsule()
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 2b. (Legacy) Unplanned spend bar chart — replaced by categoryTrendSection
    // Kept here for now so existing seed data + screenshots still work.
    // Remove in a follow-up once the new section is verified across users.

    private var unplannedBarChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Unplanned spend")

            let weeklyData = computeWeeklyUnplanned()

            if weeklyData.isEmpty {
                emptyCard(message: "Log a money event to see your patterns.")
            } else {
                Chart(weeklyData) { item in
                    BarMark(
                        x: .value("Week", item.label),
                        y: .value("Amount", item.amount)
                    )
                    // improving = soft green; not-improving = brand gold
                    // (was warning orange — too flashy for this analysis)
                    .foregroundStyle(item.improving ? DS.primary : DS.matteYellow)
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
                emptyCard(message: "Check in and log events to see bias patterns.")
            } else {
                Chart(patterns) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Bias", item.tag.label)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [DS.matteYellow, DS.matteYellow.opacity(0.7)],
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
                emptyCard(message: "Log events to see your planned vs unplanned split.")
            } else {
                let slices: [DonutSlice] = [
                    DonutSlice(label: "Planned", value: planned, color: DS.primary),
                    DonutSlice(label: "Unplanned", value: max(unplanned, 0.01), color: DS.matteYellow),
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
                        donutLegend(color: DS.primary, label: "Planned", pct: plannedPct)
                        donutLegend(color: DS.matteYellow, label: "Unplanned", pct: unplannedPct)
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
            return .text("No events this week yet. The data builds when you do.")
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

        return .text("\(weekEvents.count) events logged this week. The picture is forming.")
    }
}

// MARK: - About your score sheet

private struct AboutScoreSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // THE SCIENCE
                    sectionTitle("THE SCIENCE")
                    Text("Each question surfaces a specific cognitive bias documented in peer-reviewed behavioural economics research.")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)

                    // THE SCORING
                    sectionTitle("THE SCORING")
                    VStack(spacing: 12) {
                        scoreRow(icon: "\u{2726}", label: "Yes answer", detail: "+2 to that bias score")
                        scoreRow(icon: "○", label: "No answer", detail: "-1 (awareness working)")
                        scoreRow(icon: "💰", label: "Tagged spend", detail: "+3 (behaviour evidence)")
                    }

                    // YOUR STAGES
                    sectionTitle("YOUR STAGES")
                    VStack(alignment: .leading, spacing: 10) {
                        stageRow("🔍", "Unseen", "not yet encountered")
                        stageRow("👁", "Noticed", "seen 1\u{2013}2 times")
                        stageRow("🔄", "Emerging", "pattern forming (3\u{2013}5\u{00D7})")
                        stageRow("⚡", "Active", "strong pattern (6\u{00D7}+)")
                        stageRow("📉", "Improving", "last 3 answers were No")
                        stageRow("✅", "Aware", "sustained awareness (3 weeks)")
                    }

                    // IMPORTANT
                    sectionTitle("IMPORTANT")
                    Text("This is not a clinical diagnosis. MoneyMind reflects your own patterns back to you \u{2014} nothing more. For financial advice speak to a qualified financial planner.")
                        .font(.subheadline)
                        .foregroundStyle(DS.textSecondary)

                    Button {
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.system(size: 15, weight: .bold))
                            .goldButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 8)
                }
                .padding(.horizontal, DS.hPadding)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(DS.bg.ignoresSafeArea())
            .navigationTitle("How your score works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DS.accent)
                }
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .heavy))
            .foregroundStyle(DS.accent)
            .tracking(1.5)
    }

    private func scoreRow(icon: String, label: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(DS.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }
            Spacer()
        }
    }

    private func stageRow(_ emoji: String, _ name: String, _ desc: String) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.body)
            Text(name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DS.textPrimary)
            Text("\u{2014} \(desc)")
                .font(.caption)
                .foregroundStyle(DS.textSecondary)
            Spacer()
        }
    }
}

#Preview {
    NavigationStack { InsightFeedView() }
}
