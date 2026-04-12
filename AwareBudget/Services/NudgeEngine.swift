import Foundation

// MARK: - Nudge intelligence — pure Swift, no API, no costs

struct NudgeContext {
    var streakDays: Int
    var topBias: String?
    var topBiasCount: Int
    var alignmentPct: Double
    var topSpendCategory: String?
    var spendTrend: String?        // "up" "down" "stable"
    var emotionalToneToday: String?
    var daysSinceLastCheckin: Int
    var totalBiasesSeen: Int
    var isFirstOpen: Bool
    var completedCheckInToday: Bool
}

enum NudgeAction: Equatable {
    case startCheckIn
    case openLearnBias(String)
    case openBiasDetail(String)
    case openTrends
}

enum NudgeMessage: Equatable {
    case text(String)
    case withAction(String, actionLabel: String, action: NudgeAction)

    var body: String {
        switch self {
        case .text(let s): return s
        case .withAction(let s, _, _): return s
        }
    }
}

enum NudgeEngine {

    // MARK: - Main decision tree (priority ordered)

    static func message(for ctx: NudgeContext) -> NudgeMessage {

        // 1. First ever open
        if ctx.isFirstOpen {
            return .withAction(
                "I'm Nudge. A gold coin who has seen some things. Ready to understand your money mind?",
                actionLabel: "Let's go",
                action: .startCheckIn
            )
        }

        // 2. Missed 2+ days
        if ctx.daysSinceLastCheckin >= 2 {
            return .withAction(
                "You were gone \(ctx.daysSinceLastCheckin) days. Nudge noticed. No lecture \u{2014} your streak starts fresh today.",
                actionLabel: "Check in now",
                action: .startCheckIn
            )
        }

        // 3. Strong bias pattern linked to spend trend
        if ctx.topBiasCount >= 5,
           let bias = ctx.topBias,
           let category = ctx.topSpendCategory,
           ctx.spendTrend == "up" {
            return .withAction(
                "\(category) spending is up. You've hit \(bias) \(ctx.topBiasCount) times. Nudge thinks these are connected.",
                actionLabel: "See why",
                action: .openLearnBias(bias)
            )
        }

        // 4. Streak milestones
        if let line = streakMilestone(ctx) {
            return .text(line)
        }

        // 5. Anxious tone + rising spend
        if ctx.emotionalToneToday == "anxious",
           ctx.spendTrend == "up" {
            return .withAction(
                "You checked in feeling anxious today. Spending is also up this week. Ego Depletion might explain both.",
                actionLabel: "Show me",
                action: .openLearnBias("Ego Depletion")
            )
        }

        // 6. Strong alignment + active streak
        if ctx.alignmentPct >= 85, ctx.streakDays >= 3 {
            return .text(
                "Alignment at \(Int(ctx.alignmentPct))% and \(ctx.streakDays) days strong. Nudge approves. Quietly."
            )
        }

        // 7. Bias pattern emerging (3 encounters)
        if ctx.topBiasCount == 3, let bias = ctx.topBias {
            return .withAction(
                "\(bias) has appeared 3 times now. That's a pattern, not a coincidence. Worth knowing what to do about it.",
                actionLabel: "See your fix",
                action: .openLearnBias(bias)
            )
        }

        // 8. Checked in today — daily acknowledgement
        if ctx.completedCheckInToday, ctx.streakDays > 0 {
            return .text(
                "Day \(ctx.streakDays). Nudge is here. So are you."
            )
        }

        // 9. Has a streak but hasn't checked in yet today
        if ctx.streakDays > 0 {
            return .withAction(
                "Day \(ctx.streakDays + 1) is waiting. Nudge doesn't beg, but the streak does.",
                actionLabel: "Check in",
                action: .startCheckIn
            )
        }

        // 10. Zero streak — cold start
        return .withAction(
            "Nothing tracked yet. Nudge has questions. Starting with: how aware are you, really?",
            actionLabel: "Find out",
            action: .startCheckIn
        )
    }

    // MARK: - Streak milestone copy

    private static func streakMilestone(_ ctx: NudgeContext) -> String? {
        let milestones: [Int: String] = [
            7:   "Seven days. Your future self just noticed.",
            14:  "Two weeks straight. That's a habit forming. Nudge is moderately impressed.",
            30:  "30 days. You've encountered \(ctx.totalBiasesSeen) biases. You can't unsee them now.",
            60:  "60 days of awareness. Most people quit at day 3. You're not most people.",
            100: "100 days. Nudge is going to need a moment.",
        ]
        return milestones[ctx.streakDays]
    }
}
