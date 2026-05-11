import Foundation
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    var streak: Int = 0
    var alignmentPct: Double = 0
    var incomeTarget: Double = 0
    var todaysCheckIn: CheckIn?
    var recentEvents: [MoneyEvent] = []
    var nextQuestionTeaser: String?
    var nextBiasName: String?
    var weekDots: [Bool] = Array(repeating: false, count: 7)
    var nudgeMessage: NudgeMessage?
    var biasesSeenCount: Int = 0
    var weekSpendTrend: String = "—"
    var weekSpendTrendUp: Bool? = nil
    var hasLoggedEventToday: Bool = false
    var hasViewedLearnToday: Bool = false
    var eventLoggingStreak: Int = 0
    var patternAlerts: [PatternAlert] = []
    var dailyPatterns: [DailyPattern] = []
    var monthlyIncome: Double = 0
    var latestSavings: Double = 0
    var latestInvestment: Double = 0
    var financeLastUpdated: Date?
    var firstName: String = "there"
    var isLoading = false
    var errorMessage: String?

    struct PatternAlert: Identifiable {
        let id = UUID()
        let emoji: String
        let biasName: String
        let count: Int
        let trend: String
    }

    struct DailyPattern: Identifiable {
        let id = UUID()
        let emoji: String
        let biasName: String
        let oneLiner: String
        let stage: MasteryStage
        let score: Int
    }

    // Monthly calendar — events grouped by day-of-month string (ISO date-only)
    var monthEventsByDay: [String: [MoneyEvent]] = [:]

    private let service = SupabaseService.shared

    var isCheckedInToday: Bool { todaysCheckIn != nil }
    var isTargetSet: Bool { incomeTarget > 0 }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12: return "Good morning"
        case 12..<18: return "Good afternoon"
        default: return "Good evening"
        }
    }

    /// Nudge's contextual welcome line for the top of Home.
    /// Varies by time of day, first-open, streak, today's activity.
    var welcomeMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let isFirstOpen = !UserDefaults.standard.bool(forKey: "hasSeenNudge")
        return NudgeEngine.welcomeMessage(
            hour: hour,
            isFirstOpen: isFirstOpen,
            streak: streak,
            checkedInToday: todaysCheckIn != nil,
            loggedEventToday: hasLoggedEventToday,
            firstName: firstName
        )
    }

    var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEE · d MMMM"
        return f.string(from: Date())
    }

    var streakMessage: String {
        switch streak {
        case 0: return "Start your streak today"
        case 1...6: return "Keep showing up"
        case 7...13: return "One week strong"
        case 14...29: return "You're building a habit"
        default: return "Awareness mastery"
        }
    }

    var alignmentColor: Color {
        guard isTargetSet else { return DS.textSecondary }
        switch alignmentPct {
        case 80...: return DS.positive
        case 50..<80: return DS.warning
        default: return DS.warning
        }
    }

    var alignmentReassurance: String {
        guard isTargetSet else { return "Set a target to start tracking." }
        switch alignmentPct {
        case 80...: return "Looking aligned \u{2014} keep it up."
        case 50..<80: return "Adjust early \u{2014} awareness is the lever."
        default: return "Awareness is the first step."
        }
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }

        firstName = await service.fetchFirstName()

        do {
            todaysCheckIn = try await service.fetchTodaysCheckIn()
            recentEvents = try await service.fetchRecentMoneyEvents(limit: 3)

            let weekHistory = try await service.fetchRecentCheckIns(limit: 14)
            weekDots = Self.computeWeekDots(from: weekHistory)

            let now = Date()
            let month = try await service.fetchOrCreateBudgetMonth(for: now)
            incomeTarget = month.incomeTarget

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
            var checkInStreak = 0
            if let today = todaysCheckIn {
                checkInStreak = today.streakCount
                alignmentPct = today.alignmentPct
            } else if let y = try await service.fetchCheckIn(on: yesterday) {
                checkInStreak = y.streakCount
                alignmentPct = try await computeAlignment(month: month)
            } else {
                alignmentPct = try await computeAlignment(month: month)
            }
            streak = checkInStreak

            if todaysCheckIn == nil {
                let next = try? await service.fetchNextQuestion()
                nextQuestionTeaser = next?.question
                nextBiasName = next?.biasName
            } else {
                nextQuestionTeaser = nil
                nextBiasName = nil
            }

            // Biases seen count + pattern alerts
            let biasProgress = try await service.fetchBiasProgress()

            // Count money-event behaviour tags (each logged event with a
            // suggested bias now contributes to the bias ranking too).
            let monthEventsForTags = try await service.fetchMoneyEvents(forMonth: Date())
            let eventTagCounts: [String: Int] = monthEventsForTags
                .compactMap(\.behaviourTag)
                .reduce(into: [:]) { counts, tag in counts[tag, default: 0] += 1 }

            // Biases are "seen" if either bias_progress.times_encountered > 0
            // OR they have >=1 tagged money event this month.
            let taggedBiasNames = Set(eventTagCounts.keys)
            let progressBiasNames = Set(biasProgress.filter { $0.timesEncountered > 0 }.map(\.biasName))
            biasesSeenCount = taggedBiasNames.union(progressBiasNames).count

            let emojiLookup = Dictionary(
                uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.emoji) }
            )
            patternAlerts = biasProgress
                .filter { $0.timesEncountered >= 3 }
                .sorted { $0.timesEncountered > $1.timesEncountered }
                .prefix(3)
                .map { bp in
                    let score = BiasScoreService.computeScore(
                        biasName: bp.biasName, progress: bp, taggedEvents: eventTagCounts[bp.biasName] ?? 0
                    )
                    let trendLabel: String
                    switch score.trend {
                    case .improving: trendLabel = "improving"
                    case .worsening: trendLabel = "watch this"
                    case .stable: trendLabel = "stable"
                    }
                    return PatternAlert(
                        emoji: emojiLookup[bp.biasName] ?? "🧠",
                        biasName: bp.biasName,
                        count: bp.timesEncountered,
                        trend: trendLabel
                    )
                }

            // Daily patterns to watch (top 5 by score DESC)
            let descLookup = Dictionary(
                uniqueKeysWithValues: BiasLessonsMock.seed.map { ($0.biasName, $0.shortDescription) }
            )
            // Merge bias_progress rows with event-tag-only biases for full ranking.
            var mergedBiases: [String: BiasProgress?] = [:]
            for bp in biasProgress { mergedBiases[bp.biasName] = bp }
            for tagName in taggedBiasNames where mergedBiases[tagName] == nil {
                mergedBiases[tagName] = nil // event-tag-only bias, no progress row yet
            }

            dailyPatterns = mergedBiases
                .filter { ($0.value?.timesEncountered ?? 0) > 0 || (eventTagCounts[$0.key] ?? 0) > 0 }
                .compactMap { (biasName, bp) -> (DailyPattern, Int)? in
                    let score = BiasScoreService.computeScore(
                        biasName: biasName, progress: bp, taggedEvents: eventTagCounts[biasName] ?? 0
                    )
                    let oneLiner = descLookup[biasName] ?? ""
                    return (DailyPattern(
                        emoji: emojiLookup[biasName] ?? "🧠",
                        biasName: biasName,
                        oneLiner: oneLiner,
                        stage: score.masteryStage,
                        score: score.score
                    ), score.score)
                }
                .sorted { $0.1 > $1.1 }
                .prefix(5)
                .map(\.0)

            // Week spend trend
            let weekEvents = try await service.fetchMoneyEventsThisWeek()
            let weekTotal = weekEvents.reduce(0.0) { $0 + $1.amount }
            if weekTotal > 0 {
                weekSpendTrend = "$\(Int(weekTotal))"
                weekSpendTrendUp = true
            } else {
                weekSpendTrend = "$0"
                weekSpendTrendUp = nil
            }

            // Event logging streak (consecutive days with events)
            let allEvents = try await service.fetchMoneyEvents(forMonth: Date())

            // Today's events + days since last event (use allEvents — proven reliable)
            let fmt = DateFormatter.localDateOnly
            let todayStr = fmt.string(from: Date())
            let allSorted = allEvents.sorted { $0.date > $1.date }
            hasLoggedEventToday = allSorted.contains { fmt.string(from: $0.date) == todayStr }

            let daysSinceLastEvent: Int
            if hasLoggedEventToday {
                daysSinceLastEvent = 0
            } else if let latestEvent = allSorted.first {
                daysSinceLastEvent = max(0, Calendar.current.dateComponents([.day], from: latestEvent.date, to: Date()).day ?? 0)
            } else {
                daysSinceLastEvent = 0
            }
            monthEventsByDay = Dictionary(grouping: allEvents, by: {
                fmt.string(from: $0.date)
            })
            let eventDates = Set(allEvents.map { fmt.string(from: $0.date) })
            var eStreak = 0
            var checkDate = Date()
            if !eventDates.contains(fmt.string(from: checkDate)) {
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            }
            while eventDates.contains(fmt.string(from: checkDate)) {
                eStreak += 1
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            }
            eventLoggingStreak = eStreak
            streak = max(streak, eventLoggingStreak)

            // Finance data
            monthlyIncome = (try? await service.fetchMonthlyIncome()) ?? 0
            let snapshots = (try? await service.fetchBalanceSnapshots(monthsBack: 1)) ?? []
            if let latest = snapshots.last {
                latestSavings = latest.savings_balance
                latestInvestment = latest.investment_balance
                financeLastUpdated = latest.recorded_at
            }

            // Build Nudge context and get message
            buildNudge(recentCheckIns: weekHistory, weekEvents: weekEvents, daysSinceLastEvent: daysSinceLastEvent)

            // Fallback: always show something if Nudge is nil
            if nudgeMessage == nil {
                nudgeMessage = .text("Nothing tracked yet. Nudge has questions.")
            }
        } catch {
            errorMessage = error.localizedDescription
            if nudgeMessage == nil {
                nudgeMessage = .text("Nothing tracked yet. Nudge has questions.")
            }
        }

        // Auto-seed demo data on first open when nothing exists.
        // DEBUG-only: TestFlight + App Store builds must show a truly empty
        // state for new users (no ghost streak, no phantom "patterns
        // identified" inflation from leftover user_bias_progress rows).
        // Removing the #if DEBUG gate is enough to revert.
        #if DEBUG
        if streak == 0 && recentEvents.isEmpty && !UserDefaults.standard.bool(forKey: "demoDataSeeded") {
            if await service.currentUserId != nil {
                UserDefaults.standard.set(true, forKey: "demoDataSeeded")
                do {
                    try await DemoDataService.seed()
                    await load()
                } catch {
                    // Seed failed — continue without demo data
                }
            }
        }
        #endif
    }

    func dismissNudge() {
        NudgeDismissStore.dismiss()
        nudgeMessage = nil
    }

    func saveTarget(_ amount: Double) async {
        guard amount > 0 else { return }
        do {
            try await service.updateIncomeTarget(amount, for: Date())
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Nudge

    private func buildNudge(recentCheckIns: [CheckIn], weekEvents: [MoneyEvent], daysSinceLastEvent: Int = 0) {
        guard !NudgeDismissStore.isDismissed else {
            nudgeMessage = nil
            return
        }

        let isFirstOpen = !UserDefaults.standard.bool(forKey: "hasSeenNudge")

        // Days since last check-in
        let daysSinceLast: Int
        if todaysCheckIn != nil {
            daysSinceLast = 0
        } else if let latest = recentCheckIns.sorted(by: { $0.date > $1.date }).first {
            daysSinceLast = max(0, Calendar.current.dateComponents([.day], from: latest.date, to: Date()).day ?? 0)
        } else {
            daysSinceLast = 0
        }

        // Top behaviour tag from money events (more meaningful than check-in drivers)
        let eventTags = weekEvents.compactMap(\.behaviourTag)
        let tagCounts = Dictionary(grouping: eventTags, by: { $0 }).mapValues(\.count)
        let topTag = tagCounts.max(by: { $0.value < $1.value })
        let topBiasLabel = topTag?.key

        // Fallback to check-in drivers if no money event tags
        let checkInDrivers = recentCheckIns.compactMap { $0.spendingDriver }
        let driverCounts = Dictionary(grouping: checkInDrivers, by: { $0 }).mapValues(\.count)
        let topDriver = driverCounts.max(by: { $0.value < $1.value })

        let finalTopBias = topBiasLabel ?? topDriver?.key.label
        let finalTopCount = topTag?.value ?? topDriver?.value ?? 0

        // Unplanned spend % this week
        let weekTotal = weekEvents.reduce(0.0) { $0 + $1.amount }
        let weekUnplanned = weekEvents.filter { $0.plannedStatus.isUnplanned }.reduce(0.0) { $0 + $1.amount }
        let unplannedPct = weekTotal > 0 ? (weekUnplanned / weekTotal) * 100 : 0

        // Weekly net: planned minus unplanned
        let plannedTotal = weekEvents.filter { $0.plannedStatus == .planned }.reduce(0.0) { $0 + $1.amount }
        let weeklyNet = plannedTotal - weekUnplanned

        // Spend trend: compare unplanned this week vs total
        let spendTrend: String? = unplannedPct > 50 ? "up" : (unplannedPct < 20 ? "down" : nil)

        // Total distinct biases seen (from both check-in drivers and event tags)
        let allBiases = Set(checkInDrivers.map(\.rawValue)).union(Set(eventTags))

        let ctx = NudgeContext(
            streakDays: streak,
            topBias: finalTopBias,
            topBiasCount: finalTopCount,
            alignmentPct: alignmentPct,
            topSpendCategory: finalTopBias,
            spendTrend: spendTrend,
            emotionalToneToday: todaysCheckIn?.emotionalTone.rawValue,
            daysSinceLastCheckin: daysSinceLast,
            daysSinceLastEvent: daysSinceLastEvent,
            totalBiasesSeen: allBiases.count,
            isFirstOpen: isFirstOpen,
            completedCheckInToday: todaysCheckIn != nil,
            unplannedSpendPct: unplannedPct,
            weeklyNet: weeklyNet,
            eventLoggingStreak: eventLoggingStreak
        )

        let msg = NudgeEngine.message(for: ctx)

        if false && NudgeDedup.isDuplicate(msg) {
            nudgeMessage = nil
        } else {
            NudgeDedup.record(msg)
            nudgeMessage = msg
        }

        if isFirstOpen {
            
            UserDefaults.standard.set(true, forKey: "hasSeenNudge")
        }
    }

    // MARK: - Helpers

    static func computeWeekDots(from checkIns: [CheckIn]) -> [Bool] {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()
        guard let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return Array(repeating: false, count: 7)
        }
        return (0..<7).map { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: monday) else { return false }
            return checkIns.contains { cal.isDate($0.date, inSameDayAs: day) }
        }
    }

    private func computeAlignment(month: BudgetMonth) async throws -> Double {
        let events = try await service.fetchMoneyEvents(forMonth: month.month)
        let unplanned = events
            .filter { $0.plannedStatus.isUnplanned }
            .reduce(0.0) { $0 + $1.amount }
        guard month.incomeTarget > 0 else { return 0 }
        let pct = (1 - unplanned / month.incomeTarget) * 100
        return max(0, min(100, pct))
    }
}
