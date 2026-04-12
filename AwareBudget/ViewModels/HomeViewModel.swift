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
        case 80...: return "Looking aligned — keep it up."
        case 50..<80: return "Adjust early — awareness is the lever."
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
        } catch {
            errorMessage = error.localizedDescription
        }
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

    private static func computeWeekDots(from checkIns: [CheckIn]) -> [Bool] {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
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
            .filter { $0.eventType == .surprise }
            .reduce(0.0) { $0 + $1.amount }
        guard month.incomeTarget > 0 else { return 0 }
        let pct = (1 - unplanned / month.incomeTarget) * 100
        return max(0, min(100, pct))
    }
}
