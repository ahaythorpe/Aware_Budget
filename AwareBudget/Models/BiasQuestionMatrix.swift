import Foundation

enum BiasQuestionMatrix {
    private static let matrix: [String: [String: String]] = [
        "Ostrich Effect": [
            "Coffee": "Did you avoid checking what this coffee habit costs you weekly?",
            "Subscriptions": "Did you skip reviewing whether this subscription is still worth it?",
            "Shopping": "Did you avoid looking at your total spend before buying?",
            "_default": "Did you avoid information that might have changed this decision?"
        ],
        "Loss Aversion": [
            "Shopping": "Did fear of missing this deal drive the purchase?",
            "Travel": "Did you overpay to avoid the risk of losing the booking?",
            "Subscriptions": "Did you keep this to avoid losing what you've already paid?",
            "_default": "Did the fear of losing outweigh the chance of gaining?"
        ],
        "Anchoring": [
            "Shopping": "Did the original price make the sale price feel like a bargain?",
            "Eating out": "Did the menu's most expensive item make your pick feel reasonable?",
            "Travel": "Did an initial quote set your expectation for the final price?",
            "_default": "Did a reference number shape your sense of what's fair?"
        ],
        "Sunk Cost Fallacy": [
            "Entertainment": "Did you keep watching or attending because you'd already paid?",
            "Subscriptions": "Did 'I've already paid for months' keep you subscribed?",
            "Fitness": "Did past gym fees justify going even when you didn't want to?",
            "_default": "Did past spending pull you into spending more?"
        ],
        "Overconfidence Bias": [
            "Shopping": "Were you sure this was a good deal without actually comparing?",
            "Big purchase": "Did you trust your gut over checking the numbers?",
            "Travel": "Did you assume you'd find a better price without looking?",
            "_default": "Were you more confident about this than the evidence warranted?"
        ],
        "Ego Depletion": [
            "Coffee": "Were you tired or stressed when you bought this coffee?",
            "Eating out": "Did you order more because you were drained after a long day?",
            "Shopping": "Did end-of-day fatigue lower your resistance to buying?",
            "_default": "Were you tired, stressed, or drained when you decided?"
        ],
        "Availability Heuristic": [
            "Coffee": "Did a recent coffee experience make you want this one more?",
            "Shopping": "Did a recent ad or review make this product top of mind?",
            "Eating out": "Did seeing someone else's meal make you want something similar?",
            "_default": "Did a vivid recent memory drive this decision?"
        ],
        "Mental Accounting": [
            "Coffee": "Did this feel like 'small money' that doesn't count?",
            "Shopping": "Did the money's source (bonus, refund, gift) make you spend more freely?",
            "Entertainment": "Did you treat 'fun money' differently than 'real money'?",
            "_default": "Did the money's label make you treat it differently than regular income?"
        ],
        "Denomination Effect": [
            "Coffee": "Did tapping your card make this feel like less than handing over cash?",
            "Shopping": "Did the per-month price hide the real annual cost?",
            "Eating out": "Did splitting the bill make your share feel smaller?",
            "_default": "Did the payment method or framing make the amount feel smaller?"
        ],
        "Framing Effect": [
            "Shopping": "Did 'save 30%' feel more compelling than 'pay $70'?",
            "Eating out": "Did a 'meal deal' frame make you spend more than ordering separately?",
            "Subscriptions": "Did 'only $X per day' hide the yearly total?",
            "_default": "Did how it was presented shape your decision more than the actual price?"
        ],
        "Present Bias": [
            "Coffee": "Did wanting coffee now override your plan to cut back?",
            "Shopping": "Did 'I want this now' beat 'I'll save for later'?",
            "Eating out": "Did today's craving override tomorrow's budget?",
            "_default": "Did you choose now over future you?"
        ],
        "Planning Fallacy": [
            "Shopping": "Did this end up costing more than you expected?",
            "Travel": "Did the total trip cost exceed your original budget?",
            "Big purchase": "Did extras and add-ons push the price beyond plan?",
            "_default": "Did this cost more than you initially expected?"
        ],
        "Social Proof": [
            "Eating out": "Did you choose this place because others recommended it?",
            "Shopping": "Did seeing others buy this make you want one too?",
            "Clothing": "Did trends or influencers shape this purchase?",
            "_default": "Was this influenced by what others are doing or buying?"
        ],
        "Scarcity Heuristic": [
            "Shopping": "Did 'only a few left' or 'limited edition' push you to buy?",
            "Travel": "Did 'last room available' create urgency?",
            "Entertainment": "Did 'selling out fast' make you book sooner?",
            "_default": "Did urgency or limited availability push you to decide faster?"
        ],
        "Moral Licensing": [
            "Coffee": "Did being 'good' recently make this coffee feel earned?",
            "Eating out": "Did a healthy week justify this indulgence?",
            "Shopping": "Did saving money elsewhere feel like permission to splurge here?",
            "_default": "Did recent good behaviour feel like permission to spend more?"
        ],
        "Status Quo Bias": [
            "Coffee": "Did you buy this coffee out of habit rather than a real decision?",
            "Subscriptions": "Did you keep this subscription because switching felt like effort?",
            "Shopping": "Did you pick the same brand without considering alternatives?",
            "_default": "Did you default to this out of habit rather than actively choosing?"
        ],
    ]

    static func question(for bias: String, category: String) -> String {
        if let biasEntry = matrix[bias] {
            if let specific = biasEntry[category] {
                return specific
            }
            return biasEntry["_default"] ?? genericFallback(bias: bias)
        }
        return genericFallback(bias: bias)
    }

    private static func genericFallback(bias: String) -> String {
        "Does \(bias) describe what drove this spend?"
    }
}
