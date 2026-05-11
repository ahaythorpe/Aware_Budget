import Foundation

/// The 6 Money Mind Quiz archetypes. Each maps 1:1 to a `BiasCategory` in
/// `BiasData.swift`. The archetype is the SURFACE label; the underlying
/// biases are the DEEP data. Quiz is a fast personalisation entry — NOT a
/// replacement for the BFAS clinical assessment.
///
/// Framework: Klontz Money Scripts (Klontz & Britt, 2011) × Pompian
/// Behavioral Investor Types (2012) × BFAS bias canon. Locked 2026-05-11.
enum Archetype: String, Codable, CaseIterable, Identifiable {
    case drifter   = "Drifter"
    case reactor   = "Reactor"
    case bookkeeper = "Bookkeeper"
    case now       = "Now"
    case bandwagon = "Bandwagon"
    case autopilot = "Autopilot"

    var id: String { rawValue }

    /// Displayed as "The Drifter", "The Now", etc.
    var displayName: String { "The \(rawValue)" }

    var oneLiner: String {
        switch self {
        case .drifter:    "Quietly looks away. Defers money decisions."
        case .reactor:    "Fast decisions, regrets later."
        case .bookkeeper: "Treats different money differently."
        case .now:        "Present beats future, every time."
        case .bandwagon:  "Buys what peers buy."
        case .autopilot:  "Whatever the default is, stays."
        }
    }

    /// Maps to the matching `BiasCategory.name` in `BiasData.swift`.
    var biasCategoryName: String {
        switch self {
        case .drifter:    "Avoidance"
        case .reactor:    "Decision Making"
        case .bookkeeper: "Money Psychology"
        case .now:        "Time Perception"
        case .bandwagon:  "Social"
        case .autopilot:  "Defaults & Habits"
        }
    }

    var sfSymbol: String {
        switch self {
        case .drifter:    "eye.slash.circle.fill"
        case .reactor:    "bolt.fill"
        case .bookkeeper: "tray.2.fill"
        case .now:        "clock.fill"
        case .bandwagon:  "person.2.wave.2.fill"
        case .autopilot:  "repeat.circle.fill"
        }
    }

    var emoji: String {
        switch self {
        case .drifter:    "🙈"
        case .reactor:    "⚡"
        case .bookkeeper: "🧠"
        case .now:        "⏳"
        case .bandwagon:  "👥"
        case .autopilot:  "🔄"
        }
    }

    /// Top 3 bias names from the matching category (already in `BiasData.swift`).
    /// Returned in descending order of canonical importance — kept stable so
    /// the "← You" card and reveal screen render the same set.
    var topBiasNames: [String] {
        switch self {
        case .drifter:    ["Ostrich Effect"]
        case .reactor:    ["Loss Aversion", "Anchoring", "Overconfidence Bias"]
        case .bookkeeper: ["Mental Accounting", "Denomination Effect", "Framing Effect"]
        case .now:        ["Present Bias", "Planning Fallacy"]
        case .bandwagon:  ["Social Proof", "Scarcity Heuristic"]
        case .autopilot:  ["Status Quo Bias", "Moral Licensing"]
        }
    }
}

// MARK: - Scoring

/// One question + its weighted options. `weights` keys = archetype, value =
/// points awarded for choosing that option. One option can map to multiple
/// archetypes per Bella's rule ("one question can map multiple biases").
struct QuizQuestion: Identifiable {
    let id: Int
    let prompt: String
    let options: [QuizOption]
}

struct QuizOption: Identifiable {
    let id: UUID = UUID()
    let label: String
    let weights: [Archetype: Int]
}

enum MoneyMindQuiz {
    /// The 6 questions, locked 2026-05-11. Order matters for indexing into
    /// the `answers` JSONB array on the DB side.
    static let questions: [QuizQuestion] = [

        // Q1 — Statement day (Drifter / Autopilot)
        QuizQuestion(id: 1, prompt: "Your bank statement arrives. You:", options: [
            QuizOption(label: "Open it that day, check every line",
                       weights: [:]),
            QuizOption(label: "Glance at the balance, close it",
                       weights: [.autopilot: 1]),
            QuizOption(label: "Leave it sitting in the inbox",
                       weights: [.drifter: 2]),
            QuizOption(label: "Have notifications off, never see it",
                       weights: [.drifter: 2, .autopilot: 1]),
        ]),

        // Q2 — The jacket (Reactor / Now) — anchoring + loss aversion
        QuizQuestion(id: 2, prompt: "A jacket is $200. It goes on sale for $80. You:", options: [
            QuizOption(label: "Buy it, that's $120 saved",
                       weights: [.reactor: 2, .now: 1]),
            QuizOption(label: "Buy it but feel uneasy",
                       weights: [.reactor: 1]),
            QuizOption(label: "Skip it, didn't want one yesterday",
                       weights: [:]),
            QuizOption(label: "Wait a week, see if it drops further",
                       weights: [.bookkeeper: 1]),
        ]),

        // Q3 — Tax refund (Bookkeeper)
        QuizQuestion(id: 3, prompt: "A $1,000 tax refund lands in your account. You:", options: [
            QuizOption(label: "Treat it like bonus money, splurge a little",
                       weights: [.bookkeeper: 2, .now: 1]),
            QuizOption(label: "Move it straight to savings, separate from salary",
                       weights: [.bookkeeper: 1]),
            QuizOption(label: "Spend it on something you'd been delaying",
                       weights: [.now: 1]),
            QuizOption(label: "Forget it's there, blends with everything else",
                       weights: [.drifter: 1, .autopilot: 1]),
        ]),

        // Q4 — Now vs later (Now)
        QuizQuestion(id: 4, prompt: "Pick one:", options: [
            QuizOption(label: "$100 today",          weights: [.now: 3]),
            QuizOption(label: "$110 in a week",      weights: [.now: 2]),
            QuizOption(label: "$120 in a month",     weights: [.now: 1]),
            QuizOption(label: "$150 in three months", weights: [:]),
        ]),

        // Q5 — Friendship group (Bandwagon)
        QuizQuestion(id: 5, prompt: "Your friendship group is talking about an ETF everyone's buying. You:", options: [
            QuizOption(label: "Buy in the next day",
                       weights: [.bandwagon: 2, .reactor: 1]),
            QuizOption(label: "Read about it first, then probably buy",
                       weights: [.bandwagon: 1]),
            QuizOption(label: "Stay out, not your thing",
                       weights: [:]),
            QuizOption(label: "Don't even ask what it is",
                       weights: [.drifter: 1]),
        ]),

        // Q6 — Default super fund (Autopilot)
        QuizQuestion(id: 6, prompt: "Your employer puts you in a default super fund. After a year you:", options: [
            QuizOption(label: "Still in the default, haven't checked",
                       weights: [.autopilot: 2, .drifter: 1]),
            QuizOption(label: "Compared fees once, stayed put",
                       weights: [.autopilot: 1]),
            QuizOption(label: "Switched to a different fund",
                       weights: [:]),
            QuizOption(label: "Have no idea which fund you're in",
                       weights: [.drifter: 2, .autopilot: 1]),
        ]),
    ]

    /// Score one answer set. `answers[i]` = chosen option index for `questions[i]`.
    /// Returns (totals, winning archetype). Ties broken by `Archetype.allCases`
    /// order (Drifter > Reactor > Bookkeeper > Now > Bandwagon > Autopilot) —
    /// arbitrary but stable so retakes don't flip on identical inputs.
    static func score(answers: [Int]) -> (scores: [Archetype: Int], winner: Archetype) {
        var totals: [Archetype: Int] = [:]
        Archetype.allCases.forEach { totals[$0] = 0 }

        for (i, optionIdx) in answers.enumerated() where i < questions.count {
            let q = questions[i]
            guard optionIdx >= 0, optionIdx < q.options.count else { continue }
            for (arch, pts) in q.options[optionIdx].weights {
                totals[arch, default: 0] += pts
            }
        }

        let winner = Archetype.allCases.max(by: { (totals[$0] ?? 0) < (totals[$1] ?? 0) })
                    ?? .drifter
        return (totals, winner)
    }
}
