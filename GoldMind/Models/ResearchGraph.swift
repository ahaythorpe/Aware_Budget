import Foundation

/// Static lookup tables that drive the Research-tab concept graph.
/// Each of the 16 biases traces to one primary research paper; this
/// table is the bridge between `BiasData.keyRef` (free-text citation
/// label) and a structured paper key that the graph view can render
/// as a node + draw edges to.
///
/// Locked 2026-05-13. If a new bias is added to `BiasData`, add the
/// matching entry here too.
struct PaperCitation: Identifiable, Hashable {
    let key: String      // stable id, e.g. "kahneman_tversky_1979"
    let author: String   // "Kahneman & Tversky"
    let year: String     // "1979"
    let title: String    // "Prospect Theory"

    var id: String { key }
    var label: String { "\(author), \(year)" }
}

enum ResearchGraph {

    /// All 16 primary papers behind GoldMind's bias canon. Derived from
    /// every distinct `BiasData.keyRef`.
    static let papers: [PaperCitation] = [
        .init(key: "galai_sade_2006",
              author: "Galai & Sade",        year: "2006",
              title: "The Ostrich Effect"),
        .init(key: "kahneman_tversky_1979",
              author: "Kahneman & Tversky",  year: "1979",
              title: "Prospect Theory"),
        .init(key: "tversky_kahneman_1974",
              author: "Tversky & Kahneman",  year: "1974",
              title: "Judgment Under Uncertainty"),
        .init(key: "thaler_1980",
              author: "Thaler",              year: "1980",
              title: "Toward a Positive Theory of Consumer Choice"),
        .init(key: "barber_odean_2001",
              author: "Barber & Odean",      year: "2001",
              title: "Boys Will Be Boys: Gender, Overconfidence"),
        .init(key: "baumeister_1998",
              author: "Baumeister et al.",   year: "1998",
              title: "Ego Depletion"),
        .init(key: "tversky_kahneman_1973",
              author: "Tversky & Kahneman",  year: "1973",
              title: "Availability"),
        .init(key: "thaler_1985",
              author: "Thaler",              year: "1985",
              title: "Mental Accounting"),
        .init(key: "raghubir_srivastava_2009",
              author: "Raghubir & Srivastava", year: "2009",
              title: "The Denomination Effect"),
        .init(key: "tversky_kahneman_1981",
              author: "Tversky & Kahneman",  year: "1981",
              title: "The Framing of Decisions"),
        .init(key: "laibson_1997",
              author: "Laibson",             year: "1997",
              title: "Golden Eggs and Hyperbolic Discounting"),
        .init(key: "buehler_1994",
              author: "Buehler, Griffin & Ross", year: "1994",
              title: "The Planning Fallacy"),
        .init(key: "cialdini_2001",
              author: "Cialdini",            year: "2001",
              title: "Influence"),
        .init(key: "banerjee_1992",
              author: "Banerjee",            year: "1992",
              title: "A Simple Model of Herd Behaviour"),
        .init(key: "samuelson_zeckhauser_1988",
              author: "Samuelson & Zeckhauser", year: "1988",
              title: "Status Quo Bias in Decision Making"),
        .init(key: "monin_miller_2001",
              author: "Monin & Miller",      year: "2001",
              title: "Moral Credentials and Moral Licensing"),
    ]

    /// Bias name → primary paper key. Each bias has ONE primary source
    /// for the concept-graph render; broader citations live in
    /// `BiasData.citation`. Derived from `BiasData.keyRef`.
    static let biasToPaper: [String: String] = [
        "Ostrich Effect":          "galai_sade_2006",
        "Loss Aversion":           "kahneman_tversky_1979",
        "Anchoring":               "tversky_kahneman_1974",
        "Sunk Cost Fallacy":       "thaler_1980",
        "Overconfidence Bias":     "barber_odean_2001",
        "Ego Depletion":           "baumeister_1998",
        "Availability Heuristic":  "tversky_kahneman_1973",
        "Mental Accounting":       "thaler_1985",
        "Denomination Effect":     "raghubir_srivastava_2009",
        "Framing Effect":          "tversky_kahneman_1981",
        "Present Bias":            "laibson_1997",
        "Planning Fallacy":        "buehler_1994",
        "Social Proof":            "cialdini_2001",
        "Scarcity Heuristic":      "banerjee_1992",
        "Status Quo Bias":         "samuelson_zeckhauser_1988",
        "Moral Licensing":         "monin_miller_2001",
    ]

    /// Paper key → list of biases that paper underpins. Computed once
    /// from the reverse of `biasToPaper`.
    static let paperToBiases: [String: [String]] = {
        Dictionary(grouping: biasToPaper, by: { $0.value })
            .mapValues { $0.map { $0.key }.sorted() }
    }()

    /// Convenience lookup used by the graph view.
    static func paper(forBias name: String) -> PaperCitation? {
        guard let key = biasToPaper[name] else { return nil }
        return papers.first(where: { $0.key == key })
    }

    static func biases(forPaper key: String) -> [String] {
        paperToBiases[key] ?? []
    }
}
