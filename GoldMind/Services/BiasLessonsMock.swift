import Foundation

// MARK: - Mock bias lessons
// Used until SupabaseService.fetchAllBiasLessons is wired to the live
// `bias_lessons` table. All 16 biases from PRD v1.1.

enum BiasLessonsMock {
    static let seed: [BiasLesson] = [
        // AVOIDANCE
        BiasLesson(
            id: UUID(),
            biasName: "Ostrich Effect",
            category: "Avoidance",
            shortDescription: "We avoid information that might be bad news, even when knowing would help us.",
            fullExplanation: "The Ostrich Effect describes our tendency to ignore negative financial information. Research by Galai and Sade (2006) showed that investors check portfolios less frequently when markets fall. The irony is that avoidance increases anxiety over time while exposure reduces it.",
            realWorldExample: "You notice your balance is lower than expected so you stop checking your banking app. Three weeks later you are hit with an overdraft fee you could have avoided.",
            howToCounter: "Start small. Just open the app. You don't have to do anything. Just look. Regular low-stakes exposure dulls the stress response. Eventually checking feels normal.",
            emoji: "🫣",
            sortOrder: 1
        ),

        // DECISION MAKING
        BiasLesson(
            id: UUID(),
            biasName: "Loss Aversion",
            category: "Decision Making",
            shortDescription: "Losses feel roughly twice as painful as equivalent gains feel good.",
            fullExplanation: "Kahneman and Tversky's Prospect Theory (1979) showed the pain of losing $50 is psychologically equivalent to the pleasure of gaining ~$100. This asymmetry distorts decisions in both directions.",
            realWorldExample: "You bought shares that have fallen 30%. Selling would lock in the loss, so you hold, telling yourself they will recover, while a better opportunity sits in front of you.",
            howToCounter: "Ask: if I didn't already own this, would I buy it today? If no, loss aversion is driving you. Reframing the decision as a choice between options cuts the emotional charge.",
            emoji: "📉",
            sortOrder: 2
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Anchoring",
            category: "Decision Making",
            shortDescription: "The first number we see sets an invisible reference point for every number after.",
            fullExplanation: "Tversky and Kahneman (1974) showed that arbitrary initial values systematically bias estimates. In retail, the original price anchors your perception so the sale price feels like a bargain, even when the sale price is still above fair value.",
            realWorldExample: "A jacket marked down from $400 to $200 feels like a steal. But you would never have paid $200 for it without the anchor. The discount is doing the selling.",
            howToCounter: "Decide your price before seeing theirs. Write your number down before you browse. If the sale price is above it, walk away.",
            emoji: "⚓",
            sortOrder: 3
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Sunk Cost Fallacy",
            category: "Decision Making",
            shortDescription: "We throw good money after bad because we cannot let go of what we already spent.",
            fullExplanation: "The sunk cost fallacy leads us to continue investing in something because of what we have already put in rather than what we expect to get out. Past costs should be irrelevant to future decisions, but they rarely feel that way.",
            realWorldExample: "You have spent $3,000 renovating a car that keeps breaking down. You spend another $1,500 because otherwise the first $3,000 was wasted. But it was already wasted.",
            howToCounter: "Ask: would I choose this if I were starting from scratch today? If no, the sunk cost is driving the decision. Walk away from past spending. Judge the future on its own terms.",
            emoji: "🧾",
            sortOrder: 4
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Overconfidence Bias",
            category: "Decision Making",
            shortDescription: "We systematically overestimate our knowledge and ability to predict outcomes.",
            fullExplanation: "One of the most robust findings in psychology. In finance it leads to under-diversification, excessive trading, and skipping due diligence because we already know enough. Studies consistently show people rate themselves as above-average investors.",
            realWorldExample: "You are convinced a particular investment will do well based on a trend you noticed. You put in more than you would normally risk. You are right 40% of the time, but your confidence is calibrated for 70%.",
            howToCounter: "Keep a decision journal. Write down your predictions and confidence levels, then check back. Most people discover their confidence significantly outstrips their accuracy.",
            emoji: "📈",
            sortOrder: 5
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Ego Depletion",
            category: "Decision Making",
            shortDescription: "Our willpower is a limited resource that gets spent throughout the day.",
            fullExplanation: "Baumeister's research showed that self-control draws from a finite pool. After a long day of decisions, your ability to resist impulse purchases drops significantly. Evening and late-night shopping exploit this depletion.",
            realWorldExample: "After a stressful workday you browse online and add $200 of things to your cart. In the morning you cannot remember why any of it seemed necessary.",
            howToCounter: "Never make financial decisions when you are tired, hungry, or emotionally drained. Sleep on it. Literally. If it still makes sense tomorrow, it will still be available.",
            emoji: "🌙",
            sortOrder: 6
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Availability Heuristic",
            category: "Decision Making",
            shortDescription: "We judge probability by how easily examples come to mind, not by actual frequency.",
            fullExplanation: "Tversky and Kahneman (1973) showed that vivid, recent, or emotionally charged events feel more likely than they are. A friend's investment win looms larger than the statistical base rate of returns.",
            realWorldExample: "A colleague tells you about doubling their money on a stock. That single vivid story makes you overestimate how likely the same outcome is for you.",
            howToCounter: "Check the base rate before deciding. One person's success story is not data. Ask: how often does this actually work out for people like me?",
            emoji: "📰",
            sortOrder: 7
        ),

        // MONEY PSYCHOLOGY
        BiasLesson(
            id: UUID(),
            biasName: "Mental Accounting",
            category: "Money Psychology",
            shortDescription: "We treat money differently depending on where it came from or what it is for.",
            fullExplanation: "Richard Thaler (Nobel 2017) showed we create psychological buckets for different types of money. Windfall money gets spent more freely even though $100 from a refund buys exactly the same things as $100 from salary.",
            realWorldExample: "You receive a $300 tax refund and immediately spend it on something you would never have justified from salary. The refund felt like free money. It was your money all along.",
            howToCounter: "Before spending any windfall, ask: would I spend this if it came from my salary? If no, that's mental accounting talking. Treat all money as interchangeable. Because it is.",
            emoji: "🧮",
            sortOrder: 8
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Denomination Effect",
            category: "Money Psychology",
            shortDescription: "We spend small denominations more freely than large ones, especially digital.",
            fullExplanation: "Raghubir and Srivastava (2009) showed people spend more when using small bills or digital payments versus large notes. Tap-and-go removes the friction that used to slow spending down.",
            realWorldExample: "A week of small card taps for coffees and snacks. Each one feels trivial. The total quietly adds up to more than you'd ever hand over as a single note.",
            howToCounter: "Check your weekly total, not individual transactions. Set up a weekly push notification showing total tap-and-go spend.",
            emoji: "💳",
            sortOrder: 9
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Framing Effect",
            category: "Money Psychology",
            shortDescription: "The way a choice is presented changes the decision we make, even when the facts are identical.",
            fullExplanation: "Tversky and Kahneman (1981) showed that people make different choices depending on whether outcomes are described as gains or losses. A 20% discount feels different from saving $40, even when the dollar amount is the same.",
            realWorldExample: "A gym charges $15/week or $780/year. The weekly frame feels tiny. The annual frame makes you pause. Same money, different decision.",
            howToCounter: "Restate any deal in absolute dollars, not percentages or per-unit costs. Ask: what is the total I will pay? That cuts through framing.",
            emoji: "🖼️",
            sortOrder: 10
        ),

        // TIME PERCEPTION
        BiasLesson(
            id: UUID(),
            biasName: "Present Bias",
            category: "Time Perception",
            shortDescription: "We consistently overvalue the present at the expense of our future selves.",
            fullExplanation: "Present bias is the tendency to prefer smaller sooner rewards over larger later ones. Behavioural economists call this hyperbolic discounting. We treat our future self like a stranger whose interests matter less.",
            realWorldExample: "You know you should put $200 into savings this month. But a weekend away feels urgent and vivid. Future-you's retirement feels abstract. You go on the trip.",
            howToCounter: "Make your future self vivid. Write them a letter. Name a savings pot after a goal. Use a photo of where you want to go. The less abstract the future, the less steeply we discount it.",
            emoji: "⏰",
            sortOrder: 11
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Planning Fallacy",
            category: "Time Perception",
            shortDescription: "We underestimate time, cost, and risk of future actions while overestimating benefits.",
            fullExplanation: "Kahneman and Tversky (1979) identified our systematic tendency to make optimistic plans. Home renovations, holidays, and projects almost always cost more and take longer than expected.",
            realWorldExample: "You budget $5,000 for a kitchen refresh. The final cost is $8,200. You are genuinely surprised, even though this is the fourth project to overrun.",
            howToCounter: "Add 30% to your first estimate. Use reference class forecasting: look at what similar projects actually cost others, not what you hope yours will cost.",
            emoji: "📋",
            sortOrder: 12
        ),

        // EXTERNAL INFLUENCE
        BiasLesson(
            id: UUID(),
            biasName: "Social Proof",
            category: "External Influence",
            shortDescription: "We use what others do as a shortcut for what we should do.",
            fullExplanation: "Robert Cialdini's term for our tendency to look to others' behaviour when uncertain. In finance this manifests as lifestyle inflation, investment herding, and consumption display. Everyone is performing a version of financial health.",
            realWorldExample: "Your peer group starts buying houses, going on expensive holidays. Even though your financial situation has not changed you start to feel behind and spend to close a gap that may not exist.",
            howToCounter: "Remember that you see the outputs of others' spending (the car, the photos) but not the inputs (the debt, the stress, the trade-offs). The comparison is always incomplete.",
            emoji: "👥",
            sortOrder: 13
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Bandwagon Effect",
            category: "External Influence",
            shortDescription: "Limited availability inflates how much we think something is worth.",
            fullExplanation: "Cialdini (1984) showed that scarcity increases perceived value. 'Only 2 left' and 'sale ends tonight' create urgency that overrides rational evaluation. Real scarcity is rare in consumer markets.",
            realWorldExample: "A flash sale shows a countdown timer and '3 left in stock'. You buy immediately, skipping the research you would normally do. The item is back in stock next week.",
            howToCounter: "Wait 24 hours. Real scarcity rarely expires in an hour. If the item is gone tomorrow, it was not the only one of its kind.",
            emoji: "⏳",
            sortOrder: 14
        ),

        // SELF PERCEPTION
        BiasLesson(
            id: UUID(),
            biasName: "Moral Licensing",
            category: "Self Perception",
            shortDescription: "Past good behaviour gives us unconscious permission to indulge.",
            fullExplanation: "Monin and Miller (2001) showed that people who demonstrate virtuous behaviour in one domain feel licensed to act less virtuously in another. Saving money on groceries licenses a splurge elsewhere.",
            realWorldExample: "You bring lunch to work all week, saving $60. On Friday you buy a $120 pair of shoes, reasoning that you earned it. Net result: -$60.",
            howToCounter: "Decouple rewards from spending entirely. Celebrate good financial behaviour with something free: a walk, a call to a friend, a rest day. The reward should not undo the gain.",
            emoji: "🏅",
            sortOrder: 15
        ),
        BiasLesson(
            id: UUID(),
            biasName: "Status Quo Bias",
            category: "Self Perception",
            shortDescription: "We prefer the current state of affairs and resist change even when change is beneficial.",
            fullExplanation: "Samuelson and Zeckhauser (1988) described the tendency to prefer the existing situation. Driven by loss aversion, regret aversion, and cognitive ease. Costs money every year through insurance auto-renewals and forgotten subscriptions.",
            realWorldExample: "Your home insurance renews automatically at a price that has increased 20% year-on-year. Switching would take 25 minutes and save $200. But switching feels like effort. So you renew.",
            howToCounter: "Schedule a quarterly money review. A short session to check what you're paying and whether anything should change. Making it a habit removes the activation energy.",
            emoji: "🛑",
            sortOrder: 16
        ),
    ]

    /// Category display order for glossary grouping
    static let categoryOrder: [String] = [
        "Avoidance",
        "Decision Making",
        "Money Psychology",
        "Time Perception",
        "External Influence",
        "Self Perception",
    ]
}
