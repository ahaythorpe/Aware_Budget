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
            return ["Present Bias", "Ego Depletion", "Scarcity Heuristic", "Social Proof", "Loss Aversion", "Framing Effect", "Moral Licensing"]
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

    // MARK: - Neglected-bias boost (14 days)

    /// Days a bias can sit untouched before the boost kicks in.
    static let neglectedThresholdDays: Int = 14

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
        progress: [BiasProgress]
    ) -> String {
        let list = shortlist(category: category, status: status)
        guard !list.isEmpty else { return rotatedPick }

        let cutoff = Date().addingTimeInterval(TimeInterval(-neglectedThresholdDays * 24 * 60 * 60))
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
