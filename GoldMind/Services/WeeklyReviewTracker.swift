import Foundation

/// Tracks whether the Sunday weekly review has been completed for the
/// current ISO week. Stored in UserDefaults as the "YYYY-WW" tag of
/// the most recently completed review.
enum WeeklyReviewTracker {
    private static let key = "weeklyReviewDone"

    /// True iff today is Sunday AND this ISO week has not been marked done.
    static func isDueNow() -> Bool {
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2 // Monday
        let weekday = cal.component(.weekday, from: Date())
        // ISO Sunday == 1 in Gregorian, but Calendar returns 1=Sun...7=Sat
        // regardless of firstWeekday. So 1 means Sunday.
        guard weekday == 1 else { return false }

        let currentTag = weekTag(for: Date())
        let lastDone = UserDefaults.standard.string(forKey: key) ?? ""
        return currentTag != lastDone
    }

    /// Marks this ISO week's review as done.
    static func markDone() {
        UserDefaults.standard.set(weekTag(for: Date()), forKey: key)
    }

    private static func weekTag(for date: Date) -> String {
        let cal = Calendar(identifier: .iso8601)
        let year = cal.component(.yearForWeekOfYear, from: date)
        let week = cal.component(.weekOfYear, from: date)
        return "\(year)-\(week)"
    }
}
