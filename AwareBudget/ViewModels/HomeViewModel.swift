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
    var isLoading = false
    var errorMessage: String?

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

    var todayLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d MMMM"
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
        do {
            todaysCheckIn = try await service.fetchTodaysCheckIn()
            recentEvents = try await service.fetchRecentMoneyEvents(limit: 3)

            let weekHistory = try await service.fetchRecentCheckIns(limit: 14)
            weekDots = Self.computeWeekDots(from: weekHistory)

            let now = Date()
            let month = try await service.fetchOrCreateBudgetMonth(for: now)
            incomeTarget = month.incomeTarget

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
            if let today = todaysCheckIn {
                streak = today.streakCount
                alignmentPct = today.alignmentPct
            } else if let y = try await service.fetchCheckIn(on: yesterday) {
                streak = y.streakCount
                alignmentPct = try await computeAlignment(month: month)
            } else {
                streak = 0
                alignmentPct = try await computeAlignment(month: month)
            }

            if todaysCheckIn == nil {
                let next = try? await service.fetchNextQuestion()
                nextQuestionTeaser = next?.question
                nextBiasName = next?.biasName
            } else {
                nextQuestionTeaser = nil
                nextBiasName = nil
            }

            // Build Nudge context and get message
            let weekEvents = try await service.fetchMoneyEventsThisWeek()
            buildNudge(recentCheckIns: weekHistory, weekEvents: weekEvents)

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

        // Auto-seed demo data on first open when nothing exists
        // Runs outside the main do/catch so auth failures don't block it
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

    private func buildNudge(recentCheckIns: [CheckIn], weekEvents: [MoneyEvent]) {
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
            daysSinceLast = 999
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
            totalBiasesSeen: allBiases.count,
            isFirstOpen: isFirstOpen,
            completedCheckInToday: todaysCheckIn != nil,
            unplannedSpendPct: unplannedPct,
            weeklyNet: weeklyNet
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

    private static func computeWeekDots(from checkIns: [CheckIn]) -> [Bool] {
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
