import Foundation

/// Static "why this bias fits this personality" copy. Surfaces inside
/// the personality cards on the Education tab as a tap-to-reveal 2nd-
/// level fold-up (Pattern C from the fold-up plan).
///
/// Each entry is a 1-2 sentence rationale linking the surface
/// personality to one of its top biases. Written in Nudge's voice —
/// direct, observational, no "you" lecturing.
enum ArchetypeBiasExplanation {
    /// Keyed by "<ArchetypeRawValue>::<BiasName>"
    static let explanation: [String: String] = [

        // Drifter -> Avoidance
        "Drifter::Ostrich Effect":
            "Looking away is the Drifter's signature move. When the statement looks bad, the inbox stays unopened. The pattern is the avoidance itself, not the underlying number.",

        // Reactor -> Decision Making
        "Reactor::Loss Aversion":
            "The Reactor's fast decisions are often loss-driven. The fear of missing a sale, losing on an investment, or being left behind fuels the rush. Notice the urgency before you commit.",
        "Reactor::Anchoring":
            "Reactors latch onto the first number they see. A 'was $200, now $80' tag locks the brain on $200, not on whether $80 is fair. The anchor stays even after you walk away.",
        "Reactor::Overconfidence Bias":
            "Reactors trust their gut. That's usually fine for small daily picks, but it bites on larger calls (investments, big-ticket buys) where careful comparison would beat instinct.",

        // Bookkeeper -> Money Psychology
        "Bookkeeper::Mental Accounting":
            "The Bookkeeper's mental ledgers are Mental Accounting in action. Treating tax refunds, bonuses, and salary differently feels organised, but the dollar is the same. Watch for 'fun money' framing.",
        "Bookkeeper::Denomination Effect":
            "Splitting a $50 note feels worse than tapping five $10 spends on a card. Bookkeepers feel this acutely. Notice when tap-to-pay erodes the friction that used to be a natural budget.",
        "Bookkeeper::Framing Effect":
            "Bookkeepers organise their money by labels: 'savings', 'spending', 'fun'. That helps until the labels themselves frame what feels OK to spend. Reframe to see the total picture.",

        // Now -> Time Perception
        "Now::Present Bias":
            "Present Bias is The Now's signature pattern. Future rewards feel less real than now-rewards. Even small delays restore proportionality. Sleep on it, see how it feels tomorrow.",
        "Now::Planning Fallacy":
            "The Now underestimates future cost the same way it overweights present reward. The renovation budget, the holiday spend, the side project: all consistently bigger than the plan said.",

        // Bandwagon -> Social
        "Bandwagon::Social Proof":
            "When everyone's buying the ETF, the Bandwagon buys too. The crowd's confidence feels like signal but is usually just confidence. Decouple your decision from the timing of theirs.",
        "Bandwagon::Scarcity Heuristic":
            "'Only 3 left' lands harder on Bandwagons. Scarcity cues exploit the social fear of missing out. Ask: would I want this if it weren't running out?",

        // Autopilot -> Defaults & Habits
        "Autopilot::Status Quo Bias":
            "Autopilots stay in the default super fund, the same insurance, the unread subscription. Status Quo Bias is the keeping, not the choosing. One annual review hour saves years of drift.",
        "Autopilot::Moral Licensing":
            "Doing one good financial thing (saving, budgeting) gives Autopilots unconscious permission to coast. The win licenses the next bad call. Each decision stands on its own.",
    ]

    static func text(forArchetype archetypeRawValue: String, bias biasName: String) -> String? {
        explanation["\(archetypeRawValue)::\(biasName)"]
    }
}
