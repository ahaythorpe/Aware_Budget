import Foundation

/// Static map of which biases commonly co-occur with which. Used by the
/// Education tab's bias chips: when a bias is expanded, the "RELATED"
/// row surfaces 1-3 sibling biases so the user can explore the mental
/// web inline (Pattern A from the fold-up plan).
///
/// Relationships are research-grounded: pairs cited in Kahneman/Tversky,
/// Thaler, Klontz, or BFAS literature as co-occurring or causally linked
/// in spending decisions.
enum BiasRelationships {
    static let related: [String: [String]] = [
        "Loss Aversion":         ["Sunk Cost Fallacy", "Status Quo Bias", "Ostrich Effect"],
        "Anchoring":             ["Overconfidence Bias", "Framing Effect"],
        "Sunk Cost Fallacy":     ["Loss Aversion", "Status Quo Bias"],
        "Overconfidence Bias":   ["Anchoring", "Planning Fallacy"],
        "Ego Depletion":         ["Present Bias", "Moral Licensing"],
        "Availability Heuristic":["Social Proof", "Scarcity Heuristic"],
        "Mental Accounting":     ["Denomination Effect", "Framing Effect", "Moral Licensing"],
        "Denomination Effect":   ["Mental Accounting", "Framing Effect"],
        "Framing Effect":        ["Anchoring", "Mental Accounting"],
        "Present Bias":          ["Planning Fallacy", "Sunk Cost Fallacy"],
        "Planning Fallacy":      ["Overconfidence Bias", "Present Bias"],
        "Social Proof":          ["Scarcity Heuristic", "Availability Heuristic"],
        "Scarcity Heuristic":    ["Social Proof", "Availability Heuristic"],
        "Status Quo Bias":       ["Loss Aversion", "Moral Licensing"],
        "Moral Licensing":       ["Status Quo Bias", "Ego Depletion"],
        "Ostrich Effect":        ["Loss Aversion"],
    ]

    static func relatedBiases(for biasName: String) -> [BiasPattern] {
        let names = related[biasName] ?? []
        return names.compactMap { name in allBiasPatterns.first(where: { $0.name == name }) }
    }
}
