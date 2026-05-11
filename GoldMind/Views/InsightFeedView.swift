import SwiftUI
import Charts

struct InsightFeedView: View {
    var selectedTab: Binding<RootTab>? = nil

    @State private var weekEvents: [MoneyEvent] = []
    @State private var allEvents: [MoneyEvent] = []
    @State private var recentCheckIns: [CheckIn] = []
    @State private var balanceSnapshots: [SupabaseService.BalanceSnapshot] = []
    @State private var awarenessTimestamps: [Date] = []
    @State private var monthlyIncome: Double = 0
    /// Selected category to drill into on the expandable trend chart.
    /// nil = overlaid view of top 5 categories. Setting a value
    /// expands that category's line full-screen with daily breakdown.
    @State private var expandedCategory: String? = nil
    @State private var isLoading = false
    @State private var showAboutScore = false

    private let service = SupabaseService.shared
    private let borderColor = DS.accent.opacity(0.15)

    private var hasNoData: Bool {
        // Keep empty state up through the initial load so blank charts
        // never flash behind the "Log your first event" CTA.
        allEvents.isEmpty && recentCheckIns.isEmpty
    }

    private var monthlySpend30d: Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return allEvents
            .filter { $0.createdAt >= cutoff }
            .reduce(0.0) { $0 + abs($1.amount) }
    }

    var body: some View {
        Group {
            if hasNoData {
                insightsEmptyState
            } else {
                ScrollView {
                    VStack(spacing: DS.sectionGap) {
                        weeklyHeroCard
                        financialOverviewSection
                        highestExpenseCard
                        financialTrendChart
                        wealthSnapshotSection
                        biasTrendChart
                        netWorthTrendSection
                        categoryTrendSection
                        biasFrequencySection
                        donutChartSection
                        nudgeInsightCard

                        // MARK: — Compound Growth Card
                        CompoundGrowthCard(monthlySpend: monthlySpend30d)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, DS.hPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            }
        }
        .background(DS.bg.ignoresSafeArea())
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
                surface: .whiteShimmer
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
        weekEvents = (try? await service.fetchMoneyEventsThisWeek()) ?? []
        allEvents = (try? await service.fetchAllMoneyEvents()) ?? []
        recentCheckIns = (try? await service.fetchRecentCheckIns(limit: 60)) ?? []
        balanceSnapshots = (try? await service.fetchBalanceSnapshots(monthsBack: 6)) ?? []
        awarenessTimestamps = (try? await service.fetchLessonTimestamps(monthsBack: 6)) ?? []
        monthlyIncome = (try? await service.fetchMonthlyIncome()) ?? 0
        print("[Insights] loaded: \(allEvents.count) events, income=\(monthlyIncome), snapshots=\(balanceSnapshots.count)")
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
                HStack(spacing: 6) {
                    Text("THIS WEEK")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.goldText)
                        .tracking(1.2)
                    InfoPopover(
                        "A rolling 7-day view of your logged events and check-ins. Resets each Monday.",
                        title: "THIS WEEK"
                    )
                    Spacer()
                }

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

    // MARK: - 1.3 Financial Overview (income, spending, savings, bias impact)

    @State private var showIncomePopup = false

    private var financialOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Financial overview")

            let totalExpenses = allEvents
                .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
                .reduce(0.0) { $0 + $1.amount }
            let impulseTotal = allEvents
                .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) && $0.plannedStatus == .impulse }
                .reduce(0.0) { $0 + $1.amount }
            let plannedTotal = allEvents
                .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) && $0.plannedStatus == .planned }
                .reduce(0.0) { $0 + $1.amount }
            let savings = monthlyIncome > 0 ? max(monthlyIncome - totalExpenses, 0) : 0
            let latestSnapshot = balanceSnapshots.last

            VStack(alignment: .leading, spacing: 16) {
                financeOverviewRow(emoji: "💰", label: "Income", value: monthlyIncome, note: monthlyIncome > 0 ? nil : "Not set. Update on Home.")
                financeOverviewRow(emoji: "🛒", label: "Spent this month", value: totalExpenses, note: "\(allEvents.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count) events")
                financeOverviewRow(emoji: "⚡", label: "Impulse spending", value: impulseTotal, note: totalExpenses > 0 ? "\(Int((impulseTotal / totalExpenses) * 100))% of total" : nil)
                financeOverviewRow(emoji: "📋", label: "Planned spending", value: plannedTotal, note: nil)
                if monthlyIncome > 0 {
                    financeOverviewRow(emoji: "💎", label: "Estimated savings", value: savings, note: "\(Int((savings / monthlyIncome) * 100))% of income")
                }
                if let snap = latestSnapshot {
                    financeOverviewRow(emoji: "🏦", label: "Savings balance", value: snap.savings_balance, note: nil)
                    financeOverviewRow(emoji: "📈", label: "Invested", value: snap.investment_balance, note: nil)
                }

                Divider()

                biasSpendingBreakdown(expenses: totalExpenses)

                ResearchFootnote(text: "Voluntary manual entry · Privacy Act 1988 only", style: .inline)
            }
            .padding(16)
            .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DS.cardRadius)
                    .stroke(DS.goldBase, lineWidth: 2)
            )
            .premiumCardShadow()
        }
    }

    private func financeOverviewRow(emoji: String, label: String, value: Double, note: String?) -> some View {
        HStack(spacing: 10) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 26)
            Text(label)
                .font(.system(.subheadline, weight: .medium))
                .foregroundStyle(DS.textPrimary)
            Spacer()
            VStack(alignment: .trailing, spacing: 1) {
                Text("$\(Int(value))")
                    .font(.system(size: 15, weight: .bold, design: .serif))
                    .foregroundStyle(DS.goldBase)
                if let note {
                    Text(note)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(DS.textTertiary)
                }
            }
        }
    }

    @ViewBuilder
    private func biasSpendingBreakdown(expenses: Double) -> some View {
        let taggedEvents = allEvents.filter {
            Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) && $0.behaviourTag != nil
        }
        let biasSpend = Dictionary(grouping: taggedEvents, by: { $0.behaviourTag! })
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
        let emojiLookup = Dictionary(uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.emoji) })

        if !biasSpend.isEmpty {
            HStack(spacing: 6) {
                Text("SPENDING BY BIAS")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.6)
                    .foregroundStyle(DS.goldBase)
                InfoPopover(
                    "Each tagged spend is grouped by the bias driving it. The dollar amounts show how much each pattern is costing you this month.",
                    title: "SPENDING BY BIAS"
                )
                Spacer()
            }

            ForEach(biasSpend.prefix(5), id: \.key) { bias, amount in
                HStack(spacing: 8) {
                    Text(emojiLookup[bias] ?? "🧠")
                        .font(.system(size: 14))
                    Text(bias)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    Text("$\(Int(amount))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(DS.goldBase)
                    if expenses > 0 {
                        Text("\(Int((amount / expenses) * 100))%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DS.accent, in: Capsule())
                    }
                }
            }

            NudgeSaysCard(
                message: "Each dollar is tagged with the bias driving the spend. This is behavioural finance in action. Awareness precedes change.",
                citation: "Kahneman 2011 · Thaler & Sunstein 2008",
                surface: .whiteShimmer
            )
        }
    }

    // MARK: - Highest Expense card

    private var highestExpenseCard: some View {
        let monthEvents = allEvents.filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
        let highest = monthEvents.max(by: { $0.amount < $1.amount })
        let emojiLookup = Dictionary(uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.emoji) })
        let counterLookup = Dictionary(uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.howToCounter) })

        return Group {
            if let top = highest {
                VStack(alignment: .leading, spacing: 10) {
                    SectionHeader(title: "Biggest spend this month")

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(emojiLookup[top.behaviourTag ?? ""] ?? "💸")
                                .font(.system(size: 28))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("$\(Int(top.amount))")
                                    .font(.system(size: 24, weight: .black, design: .serif))
                                    .foregroundStyle(DS.goldBase)
                                Text(top.lifeArea ?? "Uncategorised")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DS.textPrimary)
                            }
                            Spacer()
                            Text(top.plannedStatus.rawValue.capitalized)
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(top.plannedStatus == .planned ? DS.accent : DS.warning, in: Capsule())
                        }

                        if let bias = top.behaviourTag {
                            Text("Driven by \(bias)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(DS.textSecondary)
                            if let counter = counterLookup[bias] {
                                HStack(spacing: 4) {
                                    Image(systemName: "lightbulb.fill")
                                        .font(.caption2)
                                        .foregroundStyle(DS.goldBase)
                                    Text(counter.split(separator: ".").first.map { String($0) + "." } ?? counter)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(DS.accent)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                    .padding(14)
                    .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.cardRadius)
                            .stroke(DS.goldBase, lineWidth: 2)
                    )
                    .premiumCardShadow()
                }
            }
        }
    }

    // MARK: - Financial Trend chart (income vs expenses vs savings over months)

    private struct MonthlyFinance: Identifiable {
        let id = UUID()
        let month: String
        let date: Date
        let income: Double
        let expenses: Double
        let savings: Double
    }

    // MARK: - Wealth Snapshot (savings + investment lines)

    @State private var wealthRange: WealthRange = .threeMonths
    @State private var netWorthRange: WealthRange = .threeMonths
    enum WealthRange: String, CaseIterable { case threeMonths = "3M", sixMonths = "6M", all = "All" }

    private var wealthSnapshotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Wealth snapshot")

            if balanceSnapshots.count < 2 {
                NudgeSaysCard(
                    message: "Log your balances monthly in Your Finances to see your wealth story here.",
                    citation: "Manual snapshots only · no bank connection",
                    surface: .whiteShimmer
                )
            } else {
                let filtered = filteredSnapshots()
                let savingsPoints = filtered.map { $0.savings_balance }
                let investPoints = filtered.map { $0.investment_balance }
                let allValues = savingsPoints + investPoints
                let floor = (allValues.min() ?? 0) * 0.9
                let ceiling = Swift.max((allValues.max() ?? 10) * 1.1, floor + 10)
                let domain = floor...ceiling

                VStack(alignment: .leading, spacing: 10) {
                    Picker("Range", selection: $wealthRange) {
                        ForEach(WealthRange.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)

                    let monthFmt: DateFormatter = {
                        let f = DateFormatter()
                        f.dateFormat = "MMM yy"
                        return f
                    }()

                    Chart {
                        ForEach(filtered, id: \.id) { snap in
                            LineMark(
                                x: .value("Date", snap.recorded_at),
                                y: .value("Savings", snap.savings_balance),
                                series: .value("Type", "Savings")
                            )
                            .foregroundStyle(DS.accent)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            PointMark(
                                x: .value("Date", snap.recorded_at),
                                y: .value("Savings", snap.savings_balance)
                            )
                            .foregroundStyle(DS.accent)
                            .symbolSize(25)

                            LineMark(
                                x: .value("Date", snap.recorded_at),
                                y: .value("Investments", snap.investment_balance),
                                series: .value("Type", "Investments")
                            )
                            .foregroundStyle(DS.goldBase)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            PointMark(
                                x: .value("Date", snap.recorded_at),
                                y: .value("Investments", snap.investment_balance)
                            )
                            .foregroundStyle(DS.goldBase)
                            .symbolSize(25)
                        }
                    }
                    .chartYScale(domain: domain)
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(ChartScaling.dollarLabel(v))
                                        .font(.caption2)
                                        .foregroundStyle(DS.textTertiary)
                                }
                            }
                        }
                    }
                    .animation(.easeInOut, value: wealthRange)

                    HStack(spacing: 14) {
                        legendDot(color: DS.accent, label: "Savings")
                        legendDot(color: DS.goldBase, label: "Investments")
                    }

                    NudgeSaysCard(
                        message: "Manual snapshots only. No bank connection. Your numbers, your story.",
                        showCoin: false,
                        surface: .whiteShimmer
                    )
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldBase, lineWidth: 2)
                )
                .premiumCardShadow()
            }
        }
    }

    private func filteredSnapshots() -> [SupabaseService.BalanceSnapshot] {
        let cal = Calendar.current
        let now = Date()
        switch wealthRange {
        case .threeMonths:
            let cutoff = cal.date(byAdding: .month, value: -3, to: now) ?? now
            return balanceSnapshots.filter { $0.recorded_at >= cutoff }
        case .sixMonths:
            let cutoff = cal.date(byAdding: .month, value: -6, to: now) ?? now
            return balanceSnapshots.filter { $0.recorded_at >= cutoff }
        case .all:
            return balanceSnapshots
        }
    }

    // MARK: - Monthly Trend chart

    private var financialTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Monthly trend")

            let data = computeMonthlyFinance()
            if data.isEmpty {
                emptyCard(message: "Log events over multiple months to see your financial trend.")
            } else {
                let finValues = data.flatMap { [$0.income, $0.expenses, $0.savings] }
                VStack(alignment: .leading, spacing: 10) {
                    Chart {
                        ForEach(data) { item in
                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.income),
                                width: .ratio(0.25)
                            )
                            .foregroundStyle(DS.goldBase)
                            .position(by: .value("Type", "Income"))

                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.expenses),
                                width: .ratio(0.25)
                            )
                            .foregroundStyle(DS.matteYellow)
                            .position(by: .value("Type", "Expenses"))

                            BarMark(
                                x: .value("Month", item.month),
                                y: .value("Amount", item.savings),
                                width: .ratio(0.25)
                            )
                            .foregroundStyle(DS.accent)
                            .position(by: .value("Type", "Savings"))
                        }
                    }
                    .chartYScale(domain: ChartScaling.yDomain(for: finValues))
                    .frame(height: 180)
                    .chartYAxis {
                        AxisMarks(values: .stride(by: ChartScaling.yStride(for: finValues))) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(ChartScaling.dollarLabel(v)).font(.caption2).foregroundStyle(DS.textTertiary)
                                }
                            }
                        }
                    }

                    HStack(spacing: 14) {
                        legendDot(color: DS.goldBase, label: "Income")
                        legendDot(color: DS.matteYellow, label: "Expenses")
                        legendDot(color: DS.accent, label: "Savings")
                    }

                    if data.count < 2 {
                        NudgeSaysCard(
                            message: "This is your first month. As months pass, bars appear side by side showing how your spending and savings trend over time.",
                            surface: .whiteShimmer
                        )
                    }
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldBase, lineWidth: 2)
                )
                .premiumCardShadow()
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption2.weight(.semibold)).foregroundStyle(DS.textSecondary)
        }
    }

    private func computeMonthlyFinance() -> [MonthlyFinance] {
        let cal = Calendar.current
        let now = Date()
        let f = DateFormatter()
        f.dateFormat = "MMM"

        var results: [MonthlyFinance] = []
        for monthsAgo in (0..<6).reversed() {
            guard let monthDate = cal.date(byAdding: .month, value: -monthsAgo, to: now) else { continue }
            let monthEvents = allEvents.filter { cal.isDate($0.date, equalTo: monthDate, toGranularity: .month) }
            let expenses = monthEvents.reduce(0.0) { $0 + $1.amount }
            guard expenses > 0 || monthsAgo == 0 else { continue }
            let savings = max(monthlyIncome - expenses, 0)
            results.append(MonthlyFinance(
                month: f.string(from: monthDate),
                date: monthDate,
                income: monthlyIncome,
                expenses: expenses,
                savings: savings
            ))
        }
        return results
    }

    // MARK: - Bias Trend chart (spending per bias over weeks)

    private struct BiasWeekPoint: Identifiable {
        let id = UUID()
        let bias: String
        let weekLabel: String
        let amount: Double
    }

    private var biasTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bias spending trend")

            let data = computeBiasTrend()
            if data.isEmpty {
                emptyCard(message: "Log events across multiple weeks to see how bias-tagged spending changes.")
            } else {
                let biases = Array(Set(data.map(\.bias))).sorted()
                let palette: [Color] = [DS.goldBase, DS.matteYellow, DS.accent, DS.deepGreen, DS.lightGreen]
                let weekCount = Set(data.map(\.weekLabel)).count

                let biasValues = data.map(\.amount)
                VStack(alignment: .leading, spacing: 10) {
                    Chart(data) { point in
                        if weekCount > 1 {
                            LineMark(
                                x: .value("Week", point.weekLabel),
                                y: .value("Amount", point.amount),
                                series: .value("Bias", point.bias)
                            )
                            .foregroundStyle(by: .value("Bias", point.bias))
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        }

                        BarMark(
                            x: .value("Bias", point.bias),
                            y: .value("Amount", point.amount)
                        )
                        .foregroundStyle(by: .value("Bias", point.bias))
                        .cornerRadius(6)
                    }
                    .chartForegroundStyleScale(domain: biases, range: Array(palette.prefix(biases.count)))
                    .chartYScale(domain: ChartScaling.yDomain(for: biasValues))
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(values: .stride(by: ChartScaling.yStride(for: biasValues))) { value in
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(ChartScaling.dollarLabel(v)).font(.caption2).foregroundStyle(DS.textTertiary)
                                }
                            }
                        }
                    }
                    .chartLegend(.visible)

                    NudgeSaysCard(
                        message: weekCount > 1
                            ? "Watch your bias lines trend down as awareness kicks in. Falling lines = awareness working."
                            : "This shows spending per bias this week. As you log over more weeks, this becomes a trend line showing how awareness changes your spending.",
                        citation: "Debiasing · Fischhoff 1982 · Larrick 2004",
                        surface: .whiteShimmer
                    )
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DS.cardRadius)
                        .stroke(DS.goldBase, lineWidth: 2)
                )
                .premiumCardShadow()
            }
        }
    }

    private func computeBiasTrend() -> [BiasWeekPoint] {
        let cal = Calendar.current
        let now = Date()
        let tagged = allEvents.filter { $0.behaviourTag != nil }
        guard !tagged.isEmpty else { return [] }

        let topBiases = Dictionary(grouping: tagged, by: { $0.behaviourTag! })
            .mapValues { $0.reduce(0.0) { $0 + $1.amount } }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map(\.key)
        let allowed = Set(topBiases)

        var results: [BiasWeekPoint] = []
        for weeksAgo in (0..<6).reversed() {
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: now),
                  let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)),
                  let sunday = cal.date(byAdding: .day, value: 7, to: monday) else { continue }

            let weekEvents = tagged.filter { $0.date >= monday && $0.date < sunday && allowed.contains($0.behaviourTag!) }
            let label = weeksAgo == 0 ? "This wk" : "\(weeksAgo)w ago"

            let biasAmounts = Dictionary(grouping: weekEvents, by: { $0.behaviourTag! })
                .mapValues { $0.reduce(0.0) { $0 + $1.amount } }

            for bias in topBiases {
                if let amount = biasAmounts[bias], amount > 0 {
                    results.append(BiasWeekPoint(bias: bias, weekLabel: label, amount: amount))
                }
            }
        }
        return results
    }

    private var incomeVsSpendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Income vs spending")

            if monthlyIncome <= 0 {
                emptyCard(message: "Enter your monthly income on the Home screen (Your Finances card) to unlock this breakdown.")
            } else {
                let totalExpenses = allEvents
                    .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) }
                    .reduce(0.0) { $0 + $1.amount }
                let savings = max(monthlyIncome - totalExpenses, 0)
                let savingsRate = monthlyIncome > 0 ? Int((savings / monthlyIncome) * 100) : 0
                let impulseTotal = allEvents
                    .filter { Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .month) && $0.plannedStatus == .impulse }
                    .reduce(0.0) { $0 + $1.amount }
                let impulsePct = totalExpenses > 0 ? Int((impulseTotal / totalExpenses) * 100) : 0

                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("$\(Int(savings))")
                                .font(.system(size: 28, weight: .black, design: .serif))
                                .foregroundStyle(DS.goldBase)
                            Text("estimated savings")
                                .font(.system(.caption, weight: .semibold))
                                .foregroundStyle(DS.textSecondary)
                        }
                        Spacer()
                        Button { showIncomePopup = true } label: {
                            Image(systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundStyle(DS.goldBase)
                        }
                    }

                    HStack(spacing: 0) {
                        let incomeFrac = monthlyIncome > 0 ? min(1, monthlyIncome / max(monthlyIncome, totalExpenses)) : 0.5
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.accent)
                            .frame(width: max(4, CGFloat(incomeFrac) * (UIScreen.main.bounds.width - 64)), height: 8)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(DS.matteYellow)
                            .frame(height: 8)
                    }
                    .clipShape(Capsule())

                    HStack(spacing: 16) {
                        HStack(spacing: 5) {
                            Circle().fill(DS.accent).frame(width: 8, height: 8)
                            Text("Income $\(Int(monthlyIncome))")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(DS.textSecondary)
                        }
                        HStack(spacing: 5) {
                            Circle().fill(DS.matteYellow).frame(width: 8, height: 8)
                            Text("Spent $\(Int(totalExpenses))")
                                .font(.system(.caption2, weight: .semibold))
                                .foregroundStyle(DS.textSecondary)
                        }
                        Spacer()
                        Text("\(savingsRate)% saved")
                            .font(.system(.caption2, weight: .bold))
                            .foregroundStyle(savingsRate >= 20 ? DS.accent : DS.warning)
                    }

                    if impulsePct > 0 {
                        NudgeSaysCard(
                            message: "\(impulsePct)% of this month's spending was impulse. That's $\(Int(impulseTotal)) your future self didn't plan for.",
                            citation: "Impulse spending correlates with present bias · O'Donoghue & Rabin 1999",
                            surface: .whiteShimmer
                        )
                    }
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
                .premiumCardShadow()
            }
        }
        .sheet(isPresented: $showIncomePopup) {
            incomeMethodPopup
                .presentationDetents([.medium])
        }
    }

    private var incomeMethodPopup: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NudgeSaysCard(
                        message: "Your expenses are calculated automatically from your logged events. Savings = income minus expenses. No bank connection needed.",
                        citation: "Manual entry keeps you outside CDR/AFSL regulation · Privacy Act 1988 only",
                        surface: .whiteShimmer
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("HOW IT WORKS")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(DS.accent)

                        calculationRow(icon: "dollarsign.circle", label: "Income", detail: "You enter monthly take-home in Settings")
                        calculationRow(icon: "cart", label: "Expenses", detail: "Auto-summed from your logged events")
                        calculationRow(icon: "leaf", label: "Savings", detail: "Income − Expenses (derived)")
                    }

                    ResearchFootnote(text: "Thaler's Mental Accounting (1985): categorising spending changes how we value it.", style: .inline)
                }
                .padding(20)
            }
            .background(DS.bg)
            .navigationTitle("How this works")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showIncomePopup = false }
                        .foregroundStyle(DS.goldBase)
                }
            }
        }
    }

    private func calculationRow(icon: String, label: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(DS.accent)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(DS.textPrimary)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(DS.textSecondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - 1.4 Bias Impact Analysis

    @State private var showBiasImpactPopup = false

    private var biasImpactSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Bias impact")

            let impacts = computeBiasImpacts()
            if impacts.isEmpty {
                emptyCard(message: "Tag events with biases to see how awareness changes your spending.")
            } else {
                VStack(spacing: 10) {
                    ForEach(impacts, id: \.bias) { impact in
                        HStack(spacing: 12) {
                            Text(impact.emoji)
                                .font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(impact.bias)
                                    .font(.system(.subheadline, weight: .bold))
                                    .foregroundStyle(DS.textPrimary)
                                Text(impact.insight)
                                    .font(.system(.caption, weight: .medium))
                                    .foregroundStyle(impact.improving ? DS.accent : DS.textSecondary)
                            }
                            Spacer()
                            if impact.improving {
                                Image(systemName: "arrow.down.right")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(DS.accent)
                            }
                        }
                        .padding(12)
                        .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.smallCardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.smallCardRadius)
                                .stroke(impact.improving ? DS.accent.opacity(0.3) : DS.accent.opacity(0.1), lineWidth: 0.5)
                        )
                    }

                    Button { showBiasImpactPopup = true } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "book.closed")
                            Text("How this is calculated")
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(DS.goldBase)
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .background(DS.cardBg, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shimmeringGoldBorder(cornerRadius: DS.cardRadius)
                .premiumCardShadow()
            }
        }
        .sheet(isPresented: $showBiasImpactPopup) {
            biasImpactMethodPopup
                .presentationDetents([.medium])
        }
    }

    private var biasImpactMethodPopup: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NudgeSaysCard(
                        message: "After you identify a bias, Nudge tracks whether your spending pattern shifts. This is the core of behavioural finance. Awareness precedes change.",
                        citation: "Kahneman 2011 · Thaler & Sunstein 2008",
                        surface: .whiteShimmer
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("THE METHOD")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(DS.accent)

                        calculationRow(icon: "1.circle", label: "Before", detail: "Average weekly spend tagged with this bias before you confirmed it in a check-in")
                        calculationRow(icon: "2.circle", label: "After", detail: "Average weekly spend since confirmation")
                        calculationRow(icon: "arrow.triangle.2.circlepath", label: "Impact", detail: "% change. Positive = spending dropped.")
                    }

                    ResearchFootnote(text: "Debiasing through awareness · Fischhoff 1982 · Larrick 2004", style: .inline)
                }
                .padding(20)
            }
            .background(DS.bg)
            .navigationTitle("Bias impact method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showBiasImpactPopup = false }
                        .foregroundStyle(DS.goldBase)
                }
            }
        }
    }

    struct BiasImpact {
        let bias: String
        let emoji: String
        let insight: String
        let improving: Bool
    }

    private func computeBiasImpacts() -> [BiasImpact] {
        let emojiLookup = Dictionary(uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.emoji) })
        let taggedEvents = allEvents.filter { $0.behaviourTag != nil }
        guard !taggedEvents.isEmpty else { return [] }

        let biases = Set(taggedEvents.compactMap(\.behaviourTag))
        let cal = Calendar.current
        var results: [BiasImpact] = []

        for bias in biases {
            let events = taggedEvents.filter { $0.behaviourTag == bias }.sorted { $0.date < $1.date }
            guard events.count >= 2 else { continue }

            let midpoint = events.count / 2
            let firstHalf = events.prefix(midpoint)
            let secondHalf = events.suffix(from: midpoint)

            let firstDays = max(1, (cal.dateComponents([.day], from: firstHalf.first!.date, to: firstHalf.last!.date).day ?? 0) + 1)
            let secondDays = max(1, (cal.dateComponents([.day], from: secondHalf.first!.date, to: secondHalf.last!.date).day ?? 0) + 1)

            let firstRate = firstHalf.reduce(0.0) { $0 + $1.amount } / Double(firstDays) * 7
            let secondRate = secondHalf.reduce(0.0) { $0 + $1.amount } / Double(secondDays) * 7

            let change = firstRate > 0 ? ((secondRate - firstRate) / firstRate) * 100 : 0
            let improving = change < -5
            let emoji = emojiLookup[bias] ?? "🧠"

            let insight: String
            if improving {
                insight = "Down \(abs(Int(change)))% per week since awareness"
            } else if change > 5 {
                insight = "Up \(Int(change))%. Pattern still active."
            } else {
                insight = "Holding steady"
            }

            results.append(BiasImpact(bias: bias, emoji: emoji, insight: insight, improving: improving))
        }

        return results.sorted { $0.improving && !$1.improving }
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
            if balanceSnapshots.count < 3 {
                netWorthEmptyCard
            } else {
                netWorthChart
            }
        }
    }

    private var netWorthEmptyCard: some View {
        let snapsSoFar = balanceSnapshots.count
        let leadCopy: String = {
            switch snapsSoFar {
            case 0: return "Track your net worth over time."
            case 1: return "You've started. One more snapshot and the trend appears."
            default: return "Almost there. Log one more snapshot to see your trend."
            }
        }()
        return VStack(alignment: .leading, spacing: 8) {
            Text(leadCopy)
                .font(.system(.subheadline, weight: .bold))
                .foregroundStyle(DS.textPrimary)
            Text("Add your monthly take-home, savings, and investment balance in Settings (gear icon on Home). Drop a fresh snapshot weekly. After 3+ snapshots, the trend shows up here with bias awareness overlaid so you can see how the two move together.")
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
        let cutoff: Date? = {
            let cal = Calendar.current
            switch netWorthRange {
            case .threeMonths: return cal.date(byAdding: .month, value: -3, to: Date())
            case .sixMonths:   return cal.date(byAdding: .month, value: -6, to: Date())
            case .all:         return nil
            }
        }()
        let allNetWorth = balanceSnapshots.map { (date: $0.recorded_at, value: $0.savings_balance + $0.investment_balance) }
        let netWorth = cutoff.map { c in allNetWorth.filter { $0.date >= c } } ?? allNetWorth
        let filteredAwareness = cutoff.map { c in awarenessTimestamps.filter { $0 >= c } } ?? awarenessTimestamps
        let latest = allNetWorth.last?.value ?? 0
        let nwOnly = netWorth.map(\.value)
        let nwMin = nwOnly.min() ?? 0
        let nwMax = nwOnly.max() ?? 1
        let isFlat = (nwMax - nwMin) < 1
        // Each awareness timestamp becomes a green dot on the gold line
        // at that date — same x-axis, y-value interpolated from the
        // adjacent net-worth snapshots. No scale-mixing.
        let awarenessMarkers = filteredAwareness.compactMap { ts -> (date: Date, value: Double)? in
            guard let v = interpolatedNetWorth(at: ts, in: netWorth) else { return nil }
            return (date: ts, value: v)
        }
        let yDomain: ClosedRange<Double> = isFlat
            ? (nwMax * 0.9)...(nwMax * 1.1 + 1)
            : (nwMin * 0.95)...(nwMax * 1.05)
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
            Picker("Range", selection: $netWorthRange) {
                ForEach(WealthRange.allCases, id: \.self) { r in
                    Text(r.rawValue).tag(r)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 4)
            if let insight = trendInsight {
                trendInsightNudge(insight)
            }
            Chart {
                // Net worth line (gold) + snapshot dots
                ForEach(netWorth, id: \.date) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Net worth", point.value),
                        series: .value("Series", "Net worth")
                    )
                    .foregroundStyle(DS.matteYellow)
                    .interpolationMethod(.linear)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Net worth", point.value)
                    )
                    .foregroundStyle(DS.matteYellow)
                    .symbolSize(30)

                    if !isFlat {
                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Net worth", point.value),
                            series: .value("Series", "Net worth")
                        )
                        .foregroundStyle(LinearGradient(
                            colors: [DS.matteYellow.opacity(0.25), DS.matteYellow.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        .interpolationMethod(.linear)
                    }
                }
                // Awareness moments — green dots on the gold line at the
                // date the user identified a bias. Same axis, real story.
                ForEach(awarenessMarkers, id: \.date) { marker in
                    PointMark(
                        x: .value("Date", marker.date),
                        y: .value("Net worth", marker.value)
                    )
                    .foregroundStyle(DS.accent)
                    .symbolSize(60)
                    .symbol(.circle)
                }
            }
            .chartYScale(domain: yDomain)
            .frame(height: 160)
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(ChartScaling.dollarLabel(v))
                                .font(.caption2)
                                .foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel().font(.caption2).foregroundStyle(DS.textTertiary)
                }
            }
            .animation(.easeInOut, value: netWorthRange)
            // Tiny legend: gold line for net worth, green dot per awareness moment
            HStack(spacing: 14) {
                HStack(spacing: 5) {
                    Capsule().fill(DS.matteYellow).frame(width: 14, height: 3)
                    Text("Net worth")
                        .font(.system(.caption2, weight: .semibold))
                        .foregroundStyle(DS.textSecondary)
                }
                HStack(spacing: 5) {
                    Circle().fill(DS.accent).frame(width: 8, height: 8)
                    Text("Awareness moment")
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

    /// Linear-interpolate the net-worth value at an arbitrary date so
    /// awareness markers can sit ON the gold line. Clamps to the
    /// nearest snapshot before the first / after the last entry.
    private func interpolatedNetWorth(at date: Date, in series: [(date: Date, value: Double)]) -> Double? {
        guard !series.isEmpty else { return nil }
        let sorted = series.sorted { $0.date < $1.date }
        if date <= sorted.first!.date { return sorted.first!.value }
        if date >= sorted.last!.date { return sorted.last!.value }
        guard let nextIdx = sorted.firstIndex(where: { $0.date > date }), nextIdx > 0 else {
            return sorted.last!.value
        }
        let before = sorted[nextIdx - 1]
        let after = sorted[nextIdx]
        let span = after.date.timeIntervalSince(before.date)
        guard span > 0 else { return before.value }
        let t = date.timeIntervalSince(before.date) / span
        return before.value + (after.value - before.value) * t
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
            return "Net worth up \(pct)% this month. Keep noticing. The data is moving in your direction."
        }
        if recentAwareness > priorAwareness {
            return "You banked \(recentAwareness) new lessons this month. Net worth hasn't moved yet. That's normal. Awareness comes first."
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
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .tracking(1.6)
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
        let palette: [Color] = [DS.goldBase, DS.matteYellow, DS.accent, DS.deepGreen, DS.lightGreen]
        let weekCount = Set(series.map(\.weekStart)).count
        let catValues: [Double] = {
            if let focused = expandedCategory {
                return series.filter { $0.category == focused }.map(\.amount)
            }
            return series.map(\.amount)
        }()

        VStack(alignment: .leading, spacing: 10) {
            Chart(series) { point in
                let isExpanded = expandedCategory == nil || expandedCategory == point.category
                if weekCount > 1 {
                    LineMark(
                        x: .value("Week", point.weekStart),
                        y: .value("Amount", point.amount),
                        series: .value("Category", point.category)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: expandedCategory == point.category ? 3 : 2, lineCap: .round))
                    .opacity(isExpanded ? 1.0 : 0.18)

                    PointMark(
                        x: .value("Week", point.weekStart),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .opacity(isExpanded ? 1.0 : 0.18)
                } else {
                    BarMark(
                        x: .value("Category", point.category),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(by: .value("Category", point.category))
                    .cornerRadius(6)
                    .opacity(isExpanded ? 1.0 : 0.18)
                }
            }
            .chartForegroundStyleScale(domain: categories, range: Array(palette.prefix(categories.count)))
            .chartYScale(domain: ChartScaling.yDomain(for: catValues))
            .chartLegend(.hidden)
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(values: .stride(by: ChartScaling.yStride(for: catValues))) { value in
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text(ChartScaling.dollarLabel(v))
                                .font(.caption2)
                                .foregroundStyle(DS.textTertiary)
                        }
                    }
                }
            }
            .animation(.easeInOut, value: expandedCategory)
            categoryLegend(categories: categories, palette: palette)

            NudgeSaysCard(
                message: weekCount > 1
                    ? "Tap a category to focus its trend."
                    : "This shows spending per category this week. Lines appear as you log across more weeks.",
                showCoin: false,
                surface: .whiteShimmer
            )
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
                let freqValues = patterns.map { Double($0.count) }
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
                .chartXScale(domain: ChartScaling.yDomain(for: freqValues))
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
                    DonutSlice(label: "Planned", value: planned, color: DS.goldBase),
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
                        donutLegend(color: DS.goldBase, label: "Planned", pct: plannedPct)
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
                VStack(alignment: .leading, spacing: 20) {
                    // THE SCIENCE
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("THE SCIENCE")
                        Text("Each question surfaces a specific cognitive bias documented in peer-reviewed behavioural economics research.")
                            .font(.subheadline)
                            .foregroundStyle(DS.textSecondary)
                    }

                    sheetDivider

                    // THE SCORING
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("THE SCORING")
                        VStack(spacing: 12) {
                            scoreRow(icon: "\u{2726}", label: "Yes answer", detail: "+2 to that bias score")
                            scoreRow(icon: "○", label: "No answer", detail: "-1 (awareness working)")
                            scoreRow(icon: "💰", label: "Tagged spend", detail: "+3 (behaviour evidence)")
                        }
                    }

                    sheetDivider

                    // YOUR STAGES
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("YOUR STAGES")
                        VStack(alignment: .leading, spacing: 10) {
                            stageRow("🔍", "Unseen", "not yet encountered")
                            stageRow("👁", "Noticed", "seen 1\u{2013}2 times")
                            stageRow("🔄", "Emerging", "pattern forming (3\u{2013}5\u{00D7})")
                            stageRow("⚡", "Active", "strong pattern (6\u{00D7}+)")
                            stageRow("📉", "Improving", "last 3 answers were No")
                            stageRow("✅", "Aware", "sustained awareness (3 weeks)")
                        }
                    }

                    sheetDivider

                    // IMPORTANT
                    VStack(alignment: .leading, spacing: 10) {
                        sectionTitle("IMPORTANT")
                        Text("This is not a clinical diagnosis. GoldMind reflects your own patterns back to you \u{2014} nothing more. For financial advice speak to a qualified financial planner.")
                            .font(.subheadline)
                            .foregroundStyle(DS.textSecondary)
                    }

                    Button {
                        dismiss()
                    } label: {
                        Text("Got it")
                            .font(.system(size: 15, weight: .bold))
                            .goldButtonStyle()
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 12)
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
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(DS.accent)
            .tracking(1.2)
    }

    private var sheetDivider: some View {
        Divider()
            .background(DS.accent.opacity(0.15))
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
