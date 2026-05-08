import Foundation

/// A single BFAS baseline assessment question — maps 1:1 to one of the 16 biases.
/// User answers YES (trait present) or NO (trait absent). Answer seeds
/// `bias_progress.bfas_weight` (see DESIGN_HANDBOOK §8 + PRD v1.2).
struct BFASQuestion: Identifiable, Equatable {
    let id = UUID()
    let biasName: String
    let emoji: String
    let prompt: String

    /// Canonical BFAS-style baseline. 16 questions, 1 per bias, ordered to
    /// spread cognitive load across the assessment. Prompts adapted from
    /// Pompian (2012) *Behavioral Finance and Wealth Management*.
    static let seed: [BFASQuestion] = [
        .init(biasName: "Present Bias", emoji: "⏱️",
              prompt: "Given a choice between $50 now and $75 in a month, you'd usually take the $50."),
        .init(biasName: "Status Quo Bias", emoji: "🔁",
              prompt: "You stay with subscriptions or accounts because switching feels like effort."),
        .init(biasName: "Anchoring", emoji: "🏷️",
              prompt: "A price feels 'fair' if it's lower than the first price you saw."),
        .init(biasName: "Loss Aversion", emoji: "🛡️",
              prompt: "A $100 loss feels worse than a $100 gain feels good."),
        .init(biasName: "Social Proof", emoji: "👥",
              prompt: "You're more likely to buy something if friends rave about it."),
        .init(biasName: "Moral Licensing", emoji: "🎁",
              prompt: "After a good financial decision, you reward yourself by spending."),
        .init(biasName: "Scarcity Heuristic", emoji: "⚡",
              prompt: "'Only 2 left' or 'sale ends today' pushes you to buy."),
        .init(biasName: "Sunk Cost Fallacy", emoji: "🧾",
              prompt: "You keep paying for things because you've already invested money."),
        .init(biasName: "Ego Depletion", emoji: "🌙",
              prompt: "You spend more when you're tired or mentally drained."),
        .init(biasName: "Mental Accounting", emoji: "📁",
              prompt: "You treat 'bonus' or 'tax refund' money differently to regular income."),
        .init(biasName: "Overconfidence Bias", emoji: "📈",
              prompt: "You believe your future income will cover decisions made today."),
        .init(biasName: "Framing Effect", emoji: "🖼️",
              prompt: "'Save 30%' feels better than 'pay 70%' — even when it's the same deal."),
        .init(biasName: "Availability Heuristic", emoji: "📰",
              prompt: "A single bad purchase memory shapes what you buy next more than data does."),
        .init(biasName: "Ostrich Effect", emoji: "📭",
              prompt: "You avoid checking bank balances when you suspect bad news."),
        .init(biasName: "Planning Fallacy", emoji: "📅",
              prompt: "Big purchases or holidays usually end up costing more than you planned."),
        .init(biasName: "Denomination Effect", emoji: "💳",
              prompt: "You spend more freely with tap-and-go than with cash."),
    ]
}
