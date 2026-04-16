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

    /// Hand-curated (category, status) → top biases shortlist.
    /// Mirrors the data previously duplicated across BiasReviewView
    /// and MoneyEventView. Single source of truth lives here.
    static func categoryShortlist(category: String, status: MoneyEvent.PlannedStatus) -> [String] {
        switch (category, status) {
        case ("Coffee", .impulse):        return ["Ego Depletion", "Present Bias", "Status Quo Bias", "Moral Licensing", "Social Proof"]
        case ("Coffee", .planned):        return ["Status Quo Bias", "Mental Accounting", "Anchoring"]
        case ("Coffee", .surprise):       return ["Availability Heuristic", "Ego Depletion"]

        case ("Lunch", .impulse):         return ["Ego Depletion", "Present Bias", "Social Proof", "Moral Licensing", "Mental Accounting"]
        case ("Lunch", .planned):         return ["Mental Accounting", "Status Quo Bias", "Anchoring"]
        case ("Lunch", .surprise):        return ["Availability Heuristic", "Ego Depletion", "Planning Fallacy"]

        case ("Drinks", .impulse):        return ["Social Proof", "Ego Depletion", "Present Bias", "Moral Licensing", "Mental Accounting"]
        case ("Drinks", .planned):        return ["Mental Accounting", "Social Proof", "Anchoring"]
        case ("Drinks", .surprise):       return ["Social Proof", "Availability Heuristic"]

        case ("Eating out", .impulse):    return ["Social Proof", "Present Bias", "Moral Licensing", "Ego Depletion", "Framing Effect"]
        case ("Eating out", .planned):    return ["Mental Accounting", "Anchoring", "Status Quo Bias", "Social Proof"]
        case ("Eating out", .surprise):   return ["Availability Heuristic", "Planning Fallacy"]

        case ("Shopping", .impulse):      return ["Scarcity Heuristic", "Framing Effect", "Social Proof", "Present Bias", "Loss Aversion"]
        case ("Shopping", .planned):      return ["Anchoring", "Sunk Cost Fallacy", "Mental Accounting", "Framing Effect"]
        case ("Shopping", .surprise):     return ["Availability Heuristic", "Loss Aversion", "Planning Fallacy"]

        case ("Clothing", .impulse):      return ["Scarcity Heuristic", "Framing Effect", "Social Proof", "Present Bias", "Moral Licensing"]
        case ("Clothing", .planned):      return ["Anchoring", "Sunk Cost Fallacy", "Mental Accounting"]
        case ("Clothing", .surprise):     return ["Availability Heuristic", "Loss Aversion"]

        case ("Transport", .impulse):     return ["Ego Depletion", "Present Bias", "Status Quo Bias", "Availability Heuristic", "Mental Accounting"]
        case ("Transport", .planned):     return ["Status Quo Bias", "Mental Accounting", "Anchoring"]
        case ("Transport", .surprise):    return ["Availability Heuristic", "Planning Fallacy", "Loss Aversion"]

        case ("Pharmacy", .impulse):      return ["Availability Heuristic", "Loss Aversion", "Present Bias", "Framing Effect"]
        case ("Pharmacy", .planned):      return ["Mental Accounting", "Status Quo Bias", "Anchoring"]
        case ("Pharmacy", .surprise):     return ["Availability Heuristic", "Loss Aversion", "Planning Fallacy", "Ostrich Effect"]

        case ("Subscriptions", .impulse): return ["Framing Effect", "Social Proof", "Scarcity Heuristic", "Present Bias", "Moral Licensing"]
        case ("Subscriptions", .planned): return ["Status Quo Bias", "Sunk Cost Fallacy", "Mental Accounting", "Anchoring", "Overconfidence Bias"]
        case ("Subscriptions", .surprise):return ["Ostrich Effect", "Planning Fallacy", "Status Quo Bias"]

        case ("Entertainment", .impulse): return ["Social Proof", "Present Bias", "Moral Licensing", "Sunk Cost Fallacy", "Scarcity Heuristic"]
        case ("Entertainment", .planned): return ["Mental Accounting", "Anchoring", "Status Quo Bias", "Social Proof"]
        case ("Entertainment", .surprise):return ["Availability Heuristic", "Planning Fallacy"]

        case ("Travel", .impulse):        return ["Present Bias", "Scarcity Heuristic", "Social Proof", "Loss Aversion", "Framing Effect"]
        case ("Travel", .planned):        return ["Anchoring", "Mental Accounting", "Sunk Cost Fallacy", "Overconfidence Bias", "Planning Fallacy"]
        case ("Travel", .surprise):       return ["Planning Fallacy", "Availability Heuristic", "Loss Aversion"]

        case ("Gift", .impulse):          return ["Social Proof", "Loss Aversion", "Scarcity Heuristic", "Framing Effect", "Anchoring"]
        case ("Gift", .planned):          return ["Anchoring", "Social Proof", "Mental Accounting", "Moral Licensing"]
        case ("Gift", .surprise):         return ["Availability Heuristic", "Social Proof", "Loss Aversion"]

        case ("Home", .impulse):          return ["Present Bias", "Framing Effect", "Scarcity Heuristic", "Social Proof"]
        case ("Home", .planned):          return ["Status Quo Bias", "Anchoring", "Sunk Cost Fallacy", "Mental Accounting", "Overconfidence Bias"]
        case ("Home", .surprise):         return ["Planning Fallacy", "Availability Heuristic", "Loss Aversion"]

        case ("Fitness", .impulse):       return ["Moral Licensing", "Social Proof", "Sunk Cost Fallacy", "Scarcity Heuristic"]
        case ("Fitness", .planned):       return ["Overconfidence Bias", "Sunk Cost Fallacy", "Status Quo Bias", "Anchoring"]
        case ("Fitness", .surprise):      return ["Planning Fallacy", "Availability Heuristic"]

        case ("Big purchase", .impulse):  return ["Social Proof", "Scarcity Heuristic", "Framing Effect", "Anchoring", "Loss Aversion"]
        case ("Big purchase", .planned):  return ["Anchoring", "Sunk Cost Fallacy", "Overconfidence Bias", "Planning Fallacy"]
        case ("Big purchase", .surprise): return ["Scarcity Heuristic", "Loss Aversion", "Planning Fallacy"]

        default:                          return []
        }
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
}
