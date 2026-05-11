import Foundation

/// Citation-grounded mapping of (category × status) → plausible biases.
///
/// **Why this file exists:** the (category × status) → bias shortlist
/// used to be a hand-curated `switch` returning `[String]`. That made
/// the algorithm look authoritative without any evidence behind which
/// biases we claim are "plausible" for a given purchase context.
///
/// Each row here ties one (category, status, bias) tuple to a published
/// reference. Confidence flags `high` / `medium` / `low` reflect how
/// directly the literature supports the link in *that purchase context*
/// (not how well-established the bias itself is).
///
/// **Confidence definitions:**
/// - `high`   — direct experimental evidence in this purchase domain
///              (e.g. Vohs 2008 measured decision fatigue in midday
///              food choices — that's `high` for Lunch + Impulse).
/// - `medium` — the bias mechanism clearly applies but the literature
///              didn't test the specific category (e.g. Status Quo Bias
///              in Coffee + Impulse — Samuelson & Zeckhauser 1988
///              tested it on insurance defaults; the mechanism extends
///              to habitual coffee runs but isn't directly measured).
/// - `low`    — plausible by inference; flag for review once we have
///              enough confirmation-rate data to validate or retire.
///
/// **Mappings without citations live in `BiasRotation.statusFallback`
/// only** — those are status-level (planned/surprise/impulse) priors
/// grounded in the bias construct itself, not category-specific claims.
enum BiasMappings {
    enum Confidence: String, Codable {
        case high, medium, low
    }

    struct Mapping: Hashable {
        let category: String
        let status: MoneyEvent.PlannedStatus
        let bias: String
        let citation: String
        let confidence: Confidence
    }

    /// All cited (category × status × bias) rows. Rotation uses the
    /// order here as a starting prior — when confirmation-rate data
    /// arrives (Wave 2), low-confirmation rows get re-weighted.
    static let all: [Mapping] = [

        // MARK: Coffee
        .init(category: "Coffee", status: .impulse, bias: "Ego Depletion",
              citation: "Baumeister 1998 · Vohs 2008 (decision fatigue → quick reward purchases)",
              confidence: .high),
        .init(category: "Coffee", status: .impulse, bias: "Present Bias",
              citation: "O'Donoghue & Rabin 1999 (hyperbolic discounting → small immediate rewards)",
              confidence: .high),
        .init(category: "Coffee", status: .impulse, bias: "Status Quo Bias",
              citation: "Samuelson & Zeckhauser 1988 (habit defaults → daily-purchase routines)",
              confidence: .medium),
        .init(category: "Coffee", status: .planned, bias: "Status Quo Bias",
              citation: "Samuelson & Zeckhauser 1988 (planned routine purchases sustain by default)",
              confidence: .high),
        .init(category: "Coffee", status: .planned, bias: "Mental Accounting",
              citation: "Thaler 1985 (categorisation of recurring discretionary spend)",
              confidence: .medium),

        // MARK: Lunch
        .init(category: "Lunch", status: .impulse, bias: "Ego Depletion",
              citation: "Vohs et al. 2008 (midday decision fatigue → impulsive food choices)",
              confidence: .high),
        .init(category: "Lunch", status: .impulse, bias: "Social Proof",
              citation: "Cialdini 2001 (peer eating contexts shift food choice)",
              confidence: .medium),
        .init(category: "Lunch", status: .impulse, bias: "Mental Accounting",
              citation: "Thaler 1985 (\"lunch budget\" framing as separate pool)",
              confidence: .medium),
        .init(category: "Lunch", status: .planned, bias: "Mental Accounting",
              citation: "Thaler 1985 (planned lunch as fixed budget category)",
              confidence: .high),

        // MARK: Drinks
        .init(category: "Drinks", status: .impulse, bias: "Social Proof",
              citation: "Cialdini 2001 · Berger & Heath 2007 (peer drinking norms)",
              confidence: .high),
        .init(category: "Drinks", status: .impulse, bias: "Ego Depletion",
              citation: "Baumeister 1998 (end-of-day willpower depletion → 'one drink' becomes more)",
              confidence: .medium),

        // MARK: Eating out
        .init(category: "Eating out", status: .impulse, bias: "Social Proof",
              citation: "Cialdini 2001 (group dining → ordering escalation, splitting bills hides cost)",
              confidence: .high),
        .init(category: "Eating out", status: .planned, bias: "Mental Accounting",
              citation: "Thaler 1985 (special-occasion budget framing)",
              confidence: .medium),

        // MARK: Shopping
        .init(category: "Shopping", status: .impulse, bias: "Scarcity Heuristic",
              citation: "Cialdini 2001 ('only a few left', 'limited time' as scarcity cues)",
              confidence: .high),
        .init(category: "Shopping", status: .impulse, bias: "Framing Effect",
              citation: "Tversky & Kahneman 1981 ('save 30%' vs 'pay 70%' framing)",
              confidence: .high),
        .init(category: "Shopping", status: .impulse, bias: "Loss Aversion",
              citation: "Kahneman & Tversky 1979 (fear of missing the deal exceeds gain from skipping)",
              confidence: .high),
        .init(category: "Shopping", status: .planned, bias: "Anchoring",
              citation: "Tversky & Kahneman 1974 (RRP/list price as reference for perceived value)",
              confidence: .high),
        .init(category: "Shopping", status: .planned, bias: "Sunk Cost Fallacy",
              citation: "Thaler 1980 ('already in basket' continuing past planned spend)",
              confidence: .medium),

        // MARK: Clothing
        .init(category: "Clothing", status: .impulse, bias: "Scarcity Heuristic",
              citation: "Cialdini 2001 (size availability scarcity, drop releases)",
              confidence: .high),
        .init(category: "Clothing", status: .impulse, bias: "Social Proof",
              citation: "Berger & Heath 2007 (signalling via apparel choice)",
              confidence: .medium),
        .init(category: "Clothing", status: .planned, bias: "Anchoring",
              citation: "Tversky & Kahneman 1974 (original price as reference for sale comparison)",
              confidence: .high),

        // MARK: Transport
        .init(category: "Transport", status: .impulse, bias: "Ego Depletion",
              citation: "Baumeister 1998 (tired-brain → ride-share over public transport)",
              confidence: .high),
        .init(category: "Transport", status: .impulse, bias: "Present Bias",
              citation: "O'Donoghue & Rabin 1999 (immediate convenience over future cost)",
              confidence: .high),
        .init(category: "Transport", status: .planned, bias: "Status Quo Bias",
              citation: "Samuelson & Zeckhauser 1988 (commute defaults rarely revisited)",
              confidence: .high),

        // MARK: Subscriptions
        .init(category: "Subscriptions", status: .planned, bias: "Status Quo Bias",
              citation: "Samuelson & Zeckhauser 1988 (default-subscription persistence: the textbook case)",
              confidence: .high),
        .init(category: "Subscriptions", status: .planned, bias: "Sunk Cost Fallacy",
              citation: "Thaler 1980 ('I've paid for it so I should use it' justifying renewal)",
              confidence: .high),
        .init(category: "Subscriptions", status: .planned, bias: "Denomination Effect",
              citation: "Raghubir & Srivastava 2009 (\"$X/month\" framing vs annual total)",
              confidence: .high),
        .init(category: "Subscriptions", status: .impulse, bias: "Framing Effect",
              citation: "Tversky & Kahneman 1981 (free-trial framing minimises perceived future cost)",
              confidence: .high),

        // MARK: Travel
        .init(category: "Travel", status: .planned, bias: "Anchoring",
              citation: "Tversky & Kahneman 1974 (initial flight/hotel quote anchors all subsequent comparisons)",
              confidence: .high),
        .init(category: "Travel", status: .planned, bias: "Planning Fallacy",
              citation: "Buehler, Griffin & Ross 1994 (trip costs systematically underestimated 30%+)",
              confidence: .high),
        .init(category: "Travel", status: .planned, bias: "Sunk Cost Fallacy",
              citation: "Thaler 1980 (non-refundable bookings drive 'might as well go' even when ill-advised)",
              confidence: .high),
        .init(category: "Travel", status: .impulse, bias: "Present Bias",
              citation: "O'Donoghue & Rabin 1999 (last-minute trip booking = immediate-reward bias)",
              confidence: .medium),
        .init(category: "Travel", status: .impulse, bias: "Scarcity Heuristic",
              citation: "Cialdini 2001 ('only 2 seats left at this price' booking pressure)",
              confidence: .high),

        // MARK: Gift
        .init(category: "Gift", status: .impulse, bias: "Social Proof",
              citation: "Cialdini 2001 (gift norms within social groups)",
              confidence: .medium),
        .init(category: "Gift", status: .planned, bias: "Anchoring",
              citation: "Tversky & Kahneman 1974 ('appropriate' gift price anchored by occasion category)",
              confidence: .medium),

        // MARK: Home
        .init(category: "Home", status: .planned, bias: "Status Quo Bias",
              citation: "Samuelson & Zeckhauser 1988 (utilities/services rarely re-shopped)",
              confidence: .high),
        .init(category: "Home", status: .planned, bias: "Sunk Cost Fallacy",
              citation: "Thaler 1980 (renovation/repair escalation past planned scope)",
              confidence: .medium),

        // MARK: Fitness
        .init(category: "Fitness", status: .planned, bias: "Sunk Cost Fallacy",
              citation: "Thaler 1980 (gym membership justifies continued spend)",
              confidence: .high),
        .init(category: "Fitness", status: .planned, bias: "Overconfidence Bias",
              citation: "Della Vigna & Malmendier 2006 (gym usage forecasting 70% above actual)",
              confidence: .high),

        // MARK: Big purchase
        .init(category: "Big purchase", status: .planned, bias: "Anchoring",
              citation: "Tversky & Kahneman 1974 (sticker price anchors negotiation)",
              confidence: .high),
        .init(category: "Big purchase", status: .planned, bias: "Planning Fallacy",
              citation: "Buehler/Griffin/Ross 1994 (large project cost overruns)",
              confidence: .high),
        .init(category: "Big purchase", status: .impulse, bias: "Scarcity Heuristic",
              citation: "Cialdini 2001 (limited-quantity / closing-soon framing)",
              confidence: .medium),

        // MARK: Pharmacy
        .init(category: "Pharmacy", status: .surprise, bias: "Availability Heuristic",
              citation: "Tversky & Kahneman 1973 (recent symptom = recent medication purchase)",
              confidence: .high),
        .init(category: "Pharmacy", status: .surprise, bias: "Loss Aversion",
              citation: "Kahneman & Tversky 1979 (avoiding worse health outcome > price sensitivity)",
              confidence: .medium),
    ]

    /// Lookup helper: cited biases in priority order (high → medium → low).
    /// Returns empty for any (category, status) combo without curated rows
    /// — caller falls through to BiasRotation.statusFallback (which is the
    /// status-construct prior, not a category claim).
    static func citedBiases(category: String, status: MoneyEvent.PlannedStatus) -> [String] {
        all.filter { $0.category == category && $0.status == status }
           .sorted { lhs, rhs in
               // high before medium before low
               let order: [Confidence: Int] = [.high: 0, .medium: 1, .low: 2]
               return (order[lhs.confidence] ?? 99) < (order[rhs.confidence] ?? 99)
           }
           .map(\.bias)
    }

    /// Returns the citation string for a (category, status, bias) tuple,
    /// or nil if it's a status-fallback (uncategorised) pick. Used by the
    /// algorithm explainer surface to show users *why* this bias was
    /// proposed for their purchase.
    static func citation(category: String, status: MoneyEvent.PlannedStatus, bias: String) -> String? {
        all.first { $0.category == category && $0.status == status && $0.bias == bias }?.citation
    }
}
