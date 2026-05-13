import Foundation

/// Picks the next bias to attribute to a Quick log event by rotating
/// through the plausible biases for a given (category × status) combo.
///
/// Why: a fixed "Lunch + impulse → Ego Depletion" mapping makes every
/// lunch event look identical. Rotating across the 4–5 plausible biases
/// (Ego Depletion, Present Bias, Social Proof, Moral Licensing,
/// Mental Accounting) means the same purchase pattern gets probed from
/// multiple behavioural angles over time — building a richer profile
/// and surfacing more of the 16 biases without overwhelming any single
/// review.
///
/// Rotation index is persisted per (category, status) in UserDefaults
/// so it survives app restarts.
///
/// **v2 backlog:** "neglected bias boost" — if a bias hasn't been
/// touched (last_seen) in 14 days and IS in the current shortlist,
/// prioritise it over the rotation pick. Requires async fetch of
/// `bias_progress`, so it lives outside the sync `nextBias` path.
enum BiasRotation {
    /// Status-aware fallback used when category isn't in the curated map
    /// or after the curated list runs out. Order is intentional — first
    /// item is the most diagnostic for the status, last items are the
    /// rarer "long tail" probes.
    static func statusFallback(for status: MoneyEvent.PlannedStatus) -> [String] {
        switch status {
        case .impulse:
            return ["Present Bias", "Ego Depletion", "Bandwagon Effect", "Social Proof", "Loss Aversion", "Framing Effect", "Moral Licensing"]
        case .surprise:
            return ["Availability Heuristic", "Planning Fallacy", "Ostrich Effect", "Loss Aversion", "Framing Effect", "Overconfidence Bias"]
        case .planned:
            return ["Mental Accounting", "Anchoring", "Sunk Cost Fallacy", "Status Quo Bias", "Moral Licensing", "Denomination Effect"]
        }
    }

    /// Cited (category × status) shortlist sourced from `BiasMappings`.
    /// Returns the bias names ordered by confidence (high → medium → low).
    /// Empty for combos without curated citations — caller falls through
    /// to `statusFallback` (status-level construct prior, not a category
    /// claim). This is the swap from "Claude's opinion table" to a
    /// citation-grounded mapping the algorithm can defend.
    static func categoryShortlist(category: String, status: MoneyEvent.PlannedStatus) -> [String] {
        BiasMappings.citedBiases(category: category, status: status)
    }

    /// Merge curated category list with the status fallback, dedup,
    /// preserve order. Always non-empty (status fallback covers it).
    static func shortlist(category: String, status: MoneyEvent.PlannedStatus) -> [String] {
        var seen = Set<String>()
        return (categoryShortlist(category: category, status: status) + statusFallback(for: status))
            .filter { seen.insert($0).inserted }
    }

    // MARK: - Rotation

    /// Returns the next bias in the rotation for this (category, status)
    /// and advances the index. Survives app restarts via UserDefaults.
    static func nextBias(category: String, status: MoneyEvent.PlannedStatus) -> String {
        let list = shortlist(category: category, status: status)
        guard !list.isEmpty else { return "Present Bias" }

        let key = "biasRot_\(category)_\(status.rawValue)"
        let defaults = UserDefaults.standard
        let index = defaults.integer(forKey: key)
        let bias = list[index % list.count]
        defaults.set(index + 1, forKey: key)
        return bias
    }

    /// Same as `nextBias` but without advancing — for previews/UI hints
    /// where you want to *show* what would be picked next without
    /// committing to it (e.g. on the status picker before save).
    static func peekNextBias(category: String, status: MoneyEvent.PlannedStatus) -> String {
        let list = shortlist(category: category, status: status)
        guard !list.isEmpty else { return "Present Bias" }
        let key = "biasRot_\(category)_\(status.rawValue)"
        let index = UserDefaults.standard.integer(forKey: key)
        return list[index % list.count]
    }

    // MARK: - Pair selection (multi-bias)

    /// Reverse lookup: bias name → bias category (e.g. "Loss Aversion" →
    /// "Decision Making"). Built once from `biasCategories` so callers
    /// don't pay an O(n) scan per lookup.
    private static let biasCategoryByName: [String: String] = {
        var map: [String: String] = [:]
        for c in biasCategories {
            for p in c.patterns {
                map[p.name] = c.name
            }
        }
        return map
    }()

    /// True when both bias names belong to the same bias category
    /// (e.g. "Loss Aversion" and "Anchoring" both fall under
    /// "Decision Making"). Used by the save path to drop a secondary
    /// tag that becomes redundant after a boost-driven primary swap.
    static func sameCategory(_ a: String, _ b: String) -> Bool {
        guard let ca = biasCategoryByName[a],
              let cb = biasCategoryByName[b] else { return false }
        return ca == cb
    }

    /// Returns up to two biases for a (category × status) event: the
    /// primary (current rotation pick) and an optional secondary from a
    /// *different* bias category, so the user gets meaningfully
    /// overlapping signals rather than two near-duplicates.
    ///
    /// Bella's algorithm constraint (2026-05-12): max two biases per
    /// spending event, with the second only added when genuine overlap
    /// exists. "Different bias category" is the proxy for genuine
    /// overlap — same-category secondaries (e.g. two Social biases on
    /// one Drinks purchase) get filtered out as redundant.
    ///
    /// Advances the rotation index once (same as `nextBias`) so the
    /// caller doesn't double-advance when both fields are stored.
    static func nextBiasPair(
        category: String,
        status: MoneyEvent.PlannedStatus
    ) -> (primary: String, secondary: String?) {
        let list = shortlist(category: category, status: status)
        guard !list.isEmpty else { return ("Present Bias", nil) }

        let key = "biasRot_\(category)_\(status.rawValue)"
        let defaults = UserDefaults.standard
        let index = defaults.integer(forKey: key)
        let primary = list[index % list.count]
        defaults.set(index + 1, forKey: key)

        let primaryCategory = biasCategoryByName[primary]
        let secondary = list
            .first { name in
                name != primary && biasCategoryByName[name] != primaryCategory
            }

        return (primary, secondary)
    }

    // MARK: - Neglected-bias boost (adaptive threshold)

    /// Default fallback when the user hasn't logged enough to derive
    /// a personal cadence. Used as the lower bound of the adaptive
    /// threshold too (so even very-active loggers keep a minimum
    /// 14-day window between neglect promotions).
    static let neglectedThresholdDays: Int = 14

    /// Compute the user's personal "stale" threshold from their actual
    /// log cadence. Multiplier 5× means: roughly 5 missed log
    /// opportunities before the boost fires.
    ///
    /// Daily logger (gap = 1d):  max(14, min(60,  5)) → 14 days
    /// Weekly logger (gap = 7d): max(14, min(60, 35)) → 35 days
    /// Monthly logger (gap = 30d): max(14, min(60, 150)) → 60 days (capped)
    ///
    /// Bounded [14, 60] so it never gets too aggressive (< 2 weeks)
    /// or too lazy (> 2 months). Pass `medianGapDays = 0` (or call
    /// without progress data) to fall back to the static 14-day default.
    static func adaptiveThreshold(medianGapDays: Int) -> Int {
        guard medianGapDays > 0 else { return neglectedThresholdDays }
        return max(neglectedThresholdDays, min(60, medianGapDays * 5))
    }

    /// Median number of days between consecutive logs for this user.
    /// Returns 0 if there are < 2 events to compute a gap from. Used
    /// to seed `adaptiveThreshold(...)`.
    static func medianLogGapDays(events: [MoneyEvent]) -> Int {
        let dates = events.map(\.date).sorted()
        guard dates.count >= 2 else { return 0 }
        let gaps: [Int] = zip(dates, dates.dropFirst()).compactMap { earlier, later in
            Calendar.current.dateComponents([.day], from: earlier, to: later).day
        }.filter { $0 > 0 }
        guard !gaps.isEmpty else { return 0 }
        let sorted = gaps.sorted()
        return sorted[sorted.count / 2]
    }

    /// Picks a bias for this (category, status), preferring one that
    /// hasn't been seen in `neglectedThresholdDays` days. Returns the
    /// most-stale neglected bias from the shortlist if any qualifies;
    /// otherwise falls back to the standard rotation pick. Always
    /// advances the rotation index either way so cycling continues.
    ///
    /// `progress` is the user's current `bias_progress` rows (from
    /// `SupabaseService.fetchBiasProgress()`). Pass [] to bypass the
    /// boost — useful when offline or before progress has loaded.
    /// Pure peek — does NOT advance the rotation index. Use when the
    /// caller has already advanced (or will advance) the index via
    /// `nextBias` and just wants the boost-adjusted result. Returns
    /// the same `rotatedPick` you pass in if no neglected bias
    /// qualifies for the boost.
    static func boostedPick(
        rotatedPick: String,
        category: String,
        status: MoneyEvent.PlannedStatus,
        progress: [BiasProgress],
        thresholdDays: Int = neglectedThresholdDays
    ) -> String {
        let list = shortlist(category: category, status: status)
        guard !list.isEmpty else { return rotatedPick }

        let cutoff = Date().addingTimeInterval(TimeInterval(-thresholdDays * 24 * 60 * 60))
        let lastSeenByBias: [String: Date] = Dictionary(
            uniqueKeysWithValues: progress.compactMap { p in
                guard let last = p.lastSeen else { return nil }
                return (p.biasName, last)
            }
        )

        // A bias qualifies as neglected if it's in the shortlist AND
        // (never recorded OR last seen before the cutoff). Among
        // qualifying biases, pick the *most* neglected — never-seen
        // first (.distantPast), then oldest lastSeen.
        let candidates: [(bias: String, last: Date)] = list.compactMap { bias in
            let last = lastSeenByBias[bias] ?? .distantPast
            return last <= cutoff ? (bias, last) : nil
        }
        return candidates.min(by: { $0.last < $1.last })?.bias ?? rotatedPick
    }
}
