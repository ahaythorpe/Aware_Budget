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
    var daysSinceLastEvent: Int
    var totalBiasesSeen: Int
    var isFirstOpen: Bool
    var completedCheckInToday: Bool
    var unplannedSpendPct: Double   // % of this week's spend that is unplanned
    var weeklyNet: Double           // planned total minus unplanned total this week
    var eventLoggingStreak: Int     // consecutive days with at least one event
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

    // MARK: - Welcome message (top of Home)

    /// Short greeting shown at the top of HomeView. Varies by time of day,
    /// first-open state, streak, and today's activity. No hardcoded fallback —
    /// always returns a brand-safe line.
    static func welcomeMessage(
        hour: Int,
        isFirstOpen: Bool,
        streak: Int,
        checkedInToday: Bool,
        loggedEventToday: Bool
    ) -> String {
        if isFirstOpen {
            return "Hi, I'm Nudge. Ready to understand your money mind?"
        }

        let timeGreeting: String
        switch hour {
        case 0..<12:  timeGreeting = "Good morning"
        case 12..<18: timeGreeting = "Good afternoon"
        default:      timeGreeting = "Good evening"
        }

        switch hour {
        case 0..<12:
            if streak == 0 { return "\(timeGreeting). Let's start seeing your patterns." }
            if streak < 7  { return "\(timeGreeting). Day \(streak) of noticing." }
            return "\(timeGreeting). Habit is forming."

        case 12..<18:
            if !checkedInToday { return "\(timeGreeting). Quick check-in?" }
            return "\(timeGreeting). Nice momentum."

        default:
            if !loggedEventToday { return "\(timeGreeting). Any money moments today?" }
            return "\(timeGreeting). Patterns noticed today."
        }
    }

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

        // 3. No events logged in 2+ days
        if ctx.daysSinceLastEvent >= 2, ctx.completedCheckInToday {
            return .text(
                "Nudge has no data on your week. That's also data."
            )
        }

        // 4. Strong bias pattern linked to spend trend
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

        // 4. High unplanned spend this week
        if ctx.unplannedSpendPct > 50, ctx.weeklyNet < 0 {
            return .withAction(
                "\(Int(ctx.unplannedSpendPct))% of this week's spend was unplanned. Nudge isn't judging, but the pattern is worth seeing.",
                actionLabel: "View trends",
                action: .openTrends
            )
        }

        // 5. Streak milestones
        if let line = streakMilestone(ctx) {
            return .text(line)
        }

        // 6. Anxious tone + rising spend
        if ctx.emotionalToneToday == "anxious",
           ctx.spendTrend == "up" {
            return .withAction(
                "You checked in feeling anxious today. Spending is also up this week. Ego Depletion might explain both.",
                actionLabel: "Show me",
                action: .openLearnBias("Ego Depletion")
            )
        }

        // 7. Anxious tone + high unplanned
        if ctx.emotionalToneToday == "anxious",
           ctx.unplannedSpendPct > 40 {
            return .text(
                "Anxious today and \(Int(ctx.unplannedSpendPct))% unplanned this week. Nudge sees the connection. Awareness is the lever."
            )
        }

        // 8. Strong alignment + active streak
        if ctx.alignmentPct >= 85, ctx.streakDays >= 3 {
            return .text(
                "Alignment at \(Int(ctx.alignmentPct))% and \(ctx.streakDays) days strong. Nudge approves. Quietly."
            )
        }

        // 9. Bias pattern emerging (3 encounters)
        if ctx.topBiasCount == 3, let bias = ctx.topBias {
            return .withAction(
                "\(bias) has appeared 3 times now. That's a pattern, not a coincidence. Worth knowing what to do about it.",
                actionLabel: "See your fix",
                action: .openLearnBias(bias)
            )
        }

        // 10. Checked in today — daily acknowledgement
        if ctx.completedCheckInToday, ctx.streakDays > 0 {
            return .text(
                "Day \(ctx.streakDays). Nudge is here. So are you."
            )
        }

        // 11. Has a streak but hasn't checked in yet today
        if ctx.streakDays > 0 {
            return .withAction(
                "Day \(ctx.streakDays + 1) is waiting. Nudge doesn't beg, but the streak does.",
                actionLabel: "Check in",
                action: .startCheckIn
            )
        }

        // 12. Zero streak — cold start
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

    // MARK: - Money event response (called after saving an event)

    static func moneyEventResponse(
        behaviourTag: String?,
        tagCount: Int,
        lifeEvent: MoneyEvent.LifeEvent?,
        plannedStatus: MoneyEvent.PlannedStatus
    ) -> NudgeMessage {
        // Life event takes priority
        if let life = lifeEvent {
            return .text(
                "That's significant \u{2014} \(life.label.lowercased()). Trends will adjust. One thing: awareness stays the lever."
            )
        }

        // Behaviour tag with pattern. Every line ends with the
        // research cue so the credibility weight matches BFAS framing —
        // each bias claim cites a paper.
        if let tag = behaviourTag {
            let cue = NudgeVoice.researchCueFor(bias: tag)
            if tagCount >= 5 {
                return .withAction(
                    "That's \(tag). \(tagCount)th time. Nudge sees a strong pattern.\n\n\(cue)",
                    actionLabel: "See your fix",
                    action: .openLearnBias(tag)
                )
            }
            if tagCount >= 3 {
                return .withAction(
                    "That's \(tag). \(tagCount)\(ordinalSuffix(tagCount)) time this week.\n\n\(cue)",
                    actionLabel: "Learn more",
                    action: .openLearnBias(tag)
                )
            }
            return .text(
                "That's \(tag). Nudge is keeping count.\n\n\(cue)"
            )
        }

        // Planned with no tag
        if plannedStatus == .planned {
            return .text(
                "Planned. Aware. That's the goal."
            )
        }

        // Unplanned without tag
        return .text(
            "Logged. Awareness is the first step \u{2014} even for the unplanned ones."
        )
    }

    // MARK: - Check-in completion response

    static func checkInResponse(
        streakDays: Int,
        questionsReflected: Int,
        driver: CheckIn.SpendingDriver?,
        emotionalTone: CheckIn.EmotionalTone?
    ) -> NudgeMessage {
        if streakDays == 1 {
            return .text(
                "First one done. Nudge remembers everyone's day one."
            )
        }

        if let driver = driver, let tone = emotionalTone, tone == .anxious {
            return .text(
                "Anxious today and driven by \(driver.label.lowercased()). Nudge sees the connection."
            )
        }

        if streakDays == 7 {
            return .text(
                "Seven days. \(questionsReflected) questions reflected on. Your future self just noticed."
            )
        }

        if streakDays > 0 {
            return .text(
                "Day \(streakDays). \(questionsReflected) reflected on. Nudge is here. So are you."
            )
        }

        return .text(
            "Done. Nudge is keeping score."
        )
    }

    // MARK: - Helpers

    private static func ordinalSuffix(_ n: Int) -> String {
        let ones = n % 10
        let tens = (n / 10) % 10
        if tens == 1 { return "th" }
        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}
