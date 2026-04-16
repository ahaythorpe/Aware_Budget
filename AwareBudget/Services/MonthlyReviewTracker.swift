import Foundation

/// Tracks whether this calendar month's "checkpoint" review has run.
/// Monthly check-in re-asks questions the user previously answered YES to,
/// so we can measure whether their pattern has changed (awareness growth).
///
/// Gating logic (fixes "monthly checkpoint shows on day 1 of install"):
///   - Stores `firstInstallDate` on first call to `isDueNow()`.
///   - Returns true only when ALL of:
///     - This calendar month's marker hasn't been set yet, AND
///     - At least 30 days have passed since first install.
///
/// Without the 30-day gate, a brand-new user sees "Monthly checkpoint"
/// as their first prompt on Home — meaningless because there's nothing
/// to checkpoint. The gate ensures the user has actually had a month's
/// worth of data before being asked to revisit it.
enum MonthlyReviewTracker {
    private static let doneKey = "monthlyCheckpointDone"
    private static let firstInstallKey = "firstInstallDate"

    /// Days the user must have had the app installed before the
    /// monthly checkpoint becomes available. Matches the "monthly"
    /// cadence in the user's mental model.
    static let minDaysSinceInstall: Int = 30

    /// True iff this month's checkpoint hasn't been run AND the user
    /// has had the app long enough to have something to checkpoint.
    static func isDueNow() -> Bool {
        let defaults = UserDefaults.standard
        let now = Date()

        // Self-stamp first-install on the very first call so existing
        // users without a stamp don't get retroactively gated forever.
        if defaults.object(forKey: firstInstallKey) == nil {
            defaults.set(now, forKey: firstInstallKey)
        }
        guard let firstInstall = defaults.object(forKey: firstInstallKey) as? Date else {
            return false
        }
        let daysSinceInstall = Calendar.current
            .dateComponents([.day], from: firstInstall, to: now).day ?? 0
        guard daysSinceInstall >= minDaysSinceInstall else { return false }

        let currentTag = monthTag(for: now)
        let lastDone = defaults.string(forKey: doneKey) ?? ""
        return currentTag != lastDone
    }

    static func markDone() {
        UserDefaults.standard.set(monthTag(for: Date()), forKey: doneKey)
    }

    private static func monthTag(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let year = cal.component(.year, from: date)
        let month = cal.component(.month, from: date)
        return "\(year)-\(month)"
    }
}
