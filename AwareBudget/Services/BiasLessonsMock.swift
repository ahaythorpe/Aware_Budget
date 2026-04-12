import Foundation

// MARK: - Mock bias lessons
// Used until SupabaseService.fetchAllBiasLessons is wired to the live
// `bias_lessons` table. One entry per PRD v1.1 category so LearnView
// filter pills all have at least one card.

enum BiasLessonsMock {
    static let seed: [BiasLesson] = [
        BiasLesson(
            id: UUID(),
            biasName: "Ostrich Effect",
            category: "Avoidance",
            shortDescription: "We avoid information that might be bad news — even when knowing would help us.",
            fullExplanation: "The Ostrich Effect describes our tendency to ignore negative financial information. Research by Galai and Sade (2006) showed that investors check portfolios less frequently when markets fall. The irony is that avoidance increases anxiety over time while exposure reduces it.",
            realWorldExample: "You notice your balance is lower than expected so you stop checking your banking app. Three weeks later you are hit with an overdraft fee you could have avoided.",
            howToCounter: "Start with the smallest possible exposure: just open the app. You do not have to do anything — just look. Regular low-stakes exposure reduces the stress response until checking feels normal.",
            emoji: "🫣",
            sortOrder: 1
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Loss Aversion",
            category: "Decision Making",
            shortDescription: "Losses feel roughly twice as painful as equivalent gains feel good.",
            fullExplanation: "Kahneman and Tversky's Prospect Theory (1979) showed the pain of losing £50 is psychologically equivalent to the pleasure of gaining ~£100. This asymmetry distorts decisions in both directions.",
            realWorldExample: "You bought shares that have fallen 30%. Selling would lock in the loss — so you hold, telling yourself they will recover, while a better opportunity sits in front of you.",
            howToCounter: "Ask: if I did not already own this, would I buy it today? If no, loss aversion may be driving the decision. Reframing as choosing between options reduces the emotional charge.",
            emoji: "😨",
            sortOrder: 2
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Mental Accounting",
            category: "Money Psychology",
            shortDescription: "We treat money differently depending on where it came from or what it is for.",
            fullExplanation: "Richard Thaler (Nobel 2017) showed we create psychological buckets for different types of money. Windfall money gets spent more freely even though £100 from a refund buys exactly the same things as £100 from salary.",
            realWorldExample: "You receive a £300 tax refund and immediately spend it on something you would never have justified from salary. The refund felt like free money — but it was your money all along.",
            howToCounter: "Before spending any windfall ask: would I spend this if it came from my salary? If no, that is mental accounting talking. Treat all money as interchangeable, because it is.",
            emoji: "🧮",
            sortOrder: 4
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Present Bias",
            category: "Time Perception",
            shortDescription: "We consistently overvalue the present at the expense of our future selves.",
            fullExplanation: "Present bias is the tendency to prefer smaller sooner rewards over larger later ones. Behavioural economists call this hyperbolic discounting — we treat our future self like a stranger whose interests matter less.",
            realWorldExample: "You know you should put £200 into savings this month. But a weekend away feels urgent and vivid. Future-you's retirement feels abstract. You go on the trip.",
            howToCounter: "Make your future self more vivid — write a letter to them, name a savings pot after a goal, use a photo of somewhere you want to go. The less abstract the future, the less steeply we discount it.",
            emoji: "⏱️",
            sortOrder: 3
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Social Proof",
            category: "External Influence",
            shortDescription: "We use what others do as a shortcut for what we should do.",
            fullExplanation: "Robert Cialdini's term for our tendency to look to others' behaviour when uncertain. In finance this manifests as lifestyle inflation, investment herding, and consumption display. Everyone is performing a version of financial health.",
            realWorldExample: "Your peer group starts buying houses, going on expensive holidays. Even though your financial situation has not changed you start to feel behind and spend to close a gap that may not exist.",
            howToCounter: "Remember that you see the outputs of others' spending (the car, the photos) but not the inputs (the debt, the stress, the trade-offs). The comparison is always incomplete.",
            emoji: "👥",
            sortOrder: 7
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Overconfidence Bias",
            category: "Self Perception",
            shortDescription: "We systematically overestimate our knowledge and ability to predict outcomes.",
            fullExplanation: "One of the most robust findings in psychology. In finance it leads to under-diversification, excessive trading, and skipping due diligence because we already know enough. Studies consistently show people rate themselves as above-average investors.",
            realWorldExample: "You are convinced a particular investment will do well based on a trend you noticed. You put in more than you would normally risk. You are right 40% of the time — but your confidence is calibrated for 70%.",
            howToCounter: "Keep a decision journal. Write down your predictions and confidence levels, then check back. Most people discover their confidence significantly outstrips their accuracy.",
            emoji: "🎯",
            sortOrder: 8
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Status Quo Bias",
            category: "Inertia",
            shortDescription: "We prefer the current state of affairs and resist change even when change is beneficial.",
            fullExplanation: "Samuelson and Zeckhauser (1988) described the tendency to prefer the existing situation. Driven by loss aversion, regret aversion, and cognitive ease. Costs money every year through insurance auto-renewals and forgotten subscriptions.",
            realWorldExample: "Your home insurance renews automatically at a price that has increased 20% year-on-year. Switching would take 25 minutes and save £200. But switching feels like effort. So you renew.",
            howToCounter: "Schedule a quarterly financial MOT — a short session to review what you are paying and whether anything should change. Making inertia-breaking a habit removes the activation energy.",
            emoji: "🛑",
            sortOrder: 9
        )
    ]
}
