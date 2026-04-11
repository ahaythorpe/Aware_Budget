import Foundation
import SwiftUI

@MainActor
@Observable
final class HomeViewModel {
    var streak: Int = 0
    var alignmentPct: Double = 0
    var todaysCheckIn: CheckIn?
    var recentEvents: [MoneyEvent] = []
    var isLoading = false
    var errorMessage: String?

    private let service = SupabaseService.shared

    var isCheckedInToday: Bool { todaysCheckIn != nil }

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
        switch alignmentPct {
        case 80...: return .green
        case 50..<80: return .orange
        default: return .red
        }
    }

    var alignmentReassurance: String {
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

            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            if let today = todaysCheckIn {
                streak = today.streakCount
                alignmentPct = today.alignmentPct
            } else if let y = try await service.fetchCheckIn(on: yesterday) {
                streak = y.streakCount
                alignmentPct = y.alignmentPct
            } else {
                streak = 0
                alignmentPct = try await computeAlignment()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func computeAlignment() async throws -> Double {
        let now = Date()
        let month = try await service.fetchOrCreateBudgetMonth(for: now)
        let events = try await service.fetchMoneyEvents(forMonth: now)
        let unplanned = events
            .filter { $0.eventType == .surprise }
            .reduce(0.0) { $0 + $1.amount }
        guard month.incomeTarget > 0 else { return 0 }
        let pct = (1 - unplanned / month.incomeTarget) * 100
        return max(0, min(100, pct))
    }
}
