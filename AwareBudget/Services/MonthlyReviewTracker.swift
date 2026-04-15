import Foundation

/// Tracks whether this calendar month's "checkpoint" review has run.
/// Monthly check-in re-asks questions the user previously answered YES to,
/// so we can measure whether their pattern has changed (awareness growth).
enum MonthlyReviewTracker {
    private static let key = "monthlyCheckpointDone"

    /// True iff the user hasn't done this calendar month's checkpoint yet.
    static func isDueNow() -> Bool {
        let currentTag = monthTag(for: Date())
        let lastDone = UserDefaults.standard.string(forKey: key) ?? ""
        return currentTag != lastDone
    }

    static func markDone() {
        UserDefaults.standard.set(monthTag(for: Date()), forKey: key)
    }

    private static func monthTag(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return "\(year)-\(month)"
    }
}
