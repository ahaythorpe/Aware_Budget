import Foundation

struct BiasPattern: Identifiable {
    let id = UUID()
    let name: String
    var displayName: String { name.replacingOccurrences(of: "Heuristic", with: "Shortcut") }
    let oneLiner: String
    let sfSymbol: String
    let iconBg: String
    let iconColor: String
    let nudgeSays: String
    let keyRef: String          // ONE key reference shown on card
    let citation: String        // Full citation for expanded view
    let category: String
    var triggerCount: Int
}

struct BiasCategory {
    let name: String
    let emoji: String
    let patterns: [BiasPattern]
}

// ─────────────────────────────────────────────
// ALL 16 PATTERNS — each with unique SF Symbol,
// unique icon colour, Nudge says, + key reference
// ─────────────────────────────────────────────

let allBiasPatterns: [BiasPattern] = [

    // ── AVOIDANCE ──
    BiasPattern(
        name: "Ostrich Effect",
        oneLiner: "We avoid financial information that feels threatening",
        sfSymbol: "eye.slash.circle",
        iconBg: "#FFF3E0", iconColor: "#E65100",
        nudgeSays: "Opening GoldMind 12 days straight already beats the avoidance pattern. Most people look away. You're looking.",
        keyRef: "Galai & Sade, 2006",
        citation: "Galai, D. & Sade, O. (2006). The Ostrich Effect and the Relationship Between the Liquidity and the Yields of Financial Assets. Journal of Business.",
        category: "Avoidance",
        triggerCount: 2
    ),

    // ── DECISION MAKING ──
    BiasPattern(
        name: "Loss Aversion",
        oneLiner: "Losses feel roughly 2× as painful as equivalent gains",
        sfSymbol: "arrow.down.left.circle",
        iconBg: "#FCE4EC", iconColor: "#C62828",
        nudgeSays: "The pain of losing $50 registers like losing $100. This is why you hold bad investments, avoid reviewing debt, and accept bad deals to avoid the sting of switching.",
        keyRef: "Kahneman & Tversky, 1979",
        citation: "Kahneman, D. & Tversky, A. (1979). Prospect Theory: An Analysis of Decision Under Risk. Econometrica, 47(2), 263–291.",
        category: "Decision Making",
        triggerCount: 3
    ),
    BiasPattern(
        name: "Anchoring",
        oneLiner: "The first number you see becomes your reference point",
        sfSymbol: "tag.fill",
        iconBg: "#E3F2FD", iconColor: "#1565C0",
        nudgeSays: "When a price tag says 'was $200, now $80' your brain anchors to $200 not $80. The question worth asking: would you have paid $80 without the anchor?",
        keyRef: "Tversky & Kahneman, 1974",
        citation: "Tversky, A. & Kahneman, D. (1974). Judgment Under Uncertainty: Heuristics and Biases. Science, 185(4157), 1124–1131.",
        category: "Decision Making",
        triggerCount: 1
    ),
    BiasPattern(
        name: "Sunk Cost Fallacy",
        oneLiner: "We throw good money after bad to justify past spending",
        sfSymbol: "arrow.uturn.backward.circle",
        iconBg: "#F3E5F5", iconColor: "#6A1B9A",
        nudgeSays: "Money already spent is gone. It cannot be recovered by spending more. The only question is: what's the best decision from this point forward?",
        keyRef: "Thaler, 1980",
        citation: "Thaler, R. (1980). Toward a Positive Theory of Consumer Choice. Journal of Economic Behavior & Organization, 1(1), 39–60.",
        category: "Decision Making",
        triggerCount: 0
    ),
    BiasPattern(
        name: "Overconfidence Bias",
        oneLiner: "We systematically overestimate our own financial ability",
        sfSymbol: "star.bubble.fill",
        iconBg: "#FFF8E1", iconColor: "#F57F17",
        nudgeSays: "93% of drivers rate themselves above average. The same effect applies to investing: most people believe they can beat the market. The data disagrees.",
        keyRef: "Barber & Odean, 2001",
        citation: "Barber, B.M. & Odean, T. (2001). Boys Will Be Boys: Gender, Overconfidence, and Common Stock Investment. Quarterly Journal of Economics, 116(1), 261–292.",
        category: "Decision Making",
        triggerCount: 0
    ),
    BiasPattern(
        name: "Ego Depletion",
        oneLiner: "Willpower is a limited daily resource that runs out",
        sfSymbol: "battery.25percent",
        iconBg: "#E8F5E9", iconColor: "#2E7D32",
        nudgeSays: "By Friday evening, after a full week of decisions, your financial willpower is at its lowest ebb. That's when impulse spending consistently peaks.",
        keyRef: "Baumeister et al., 1998",
        citation: "Baumeister, R.F. et al. (1998). Ego Depletion: Is the Active Self a Limited Resource? Journal of Personality and Social Psychology, 74(5), 1252–1265.",
        category: "Decision Making",
        triggerCount: 0
    ),
    BiasPattern(
        name: "Availability Heuristic",
        oneLiner: "We judge probability by what comes to mind most easily",
        sfSymbol: "waveform.badge.magnifyingglass",
        iconBg: "#E0F2F1", iconColor: "#00695C",
        nudgeSays: "You overestimate risks you recently read about and underestimate quiet ongoing ones. Recent financial news shapes your fear more than actual statistics.",
        keyRef: "Tversky & Kahneman, 1973",
        citation: "Tversky, A. & Kahneman, D. (1973). Availability: A Heuristic for Judging Frequency and Probability. Cognitive Psychology, 5(2), 207–232.",
        category: "Decision Making",
        triggerCount: 0
    ),

    // ── MONEY PSYCHOLOGY ──
    BiasPattern(
        name: "Mental Accounting",
        oneLiner: "We treat money differently depending on its source or label",
        sfSymbol: "tray.2.fill",
        iconBg: "#EDE7F6", iconColor: "#4527A0",
        nudgeSays: "Tax refund money and salary money are identical, but tax refunds get spent faster. Nudge helps you see all money as the same resource with the same value.",
        keyRef: "Thaler, 1985",
        citation: "Thaler, R. (1985). Mental Accounting and Consumer Choice. Marketing Science, 4(3), 199–214.",
        category: "Money Psychology",
        triggerCount: 1
    ),
    BiasPattern(
        name: "Denomination Effect",
        oneLiner: "We spend small bills more freely than large ones",
        sfSymbol: "banknote.fill",
        iconBg: "#E8F5E9", iconColor: "#1B5E20",
        nudgeSays: "A $50 note feels harder to break than five $10s. Tap-to-pay removes this friction entirely. Spending accelerates without the psychological 'cost' of handing over cash.",
        keyRef: "Raghubir & Srivastava, 2009",
        citation: "Raghubir, P. & Srivastava, J. (2009). The Denomination Effect. Journal of Consumer Research, 36(4), 701–713.",
        category: "Money Psychology",
        triggerCount: 0
    ),
    BiasPattern(
        name: "Framing Effect",
        oneLiner: "The same choice feels different depending on how it's presented",
        sfSymbol: "rectangle.portrait.on.rectangle.portrait.angled",
        iconBg: "#FFF3E0", iconColor: "#BF360C",
        nudgeSays: "'95% fat free' and '5% fat' are identical. Banks, supermarkets, and salespeople all use framing deliberately. Once you see it, you can't unsee it.",
        keyRef: "Tversky & Kahneman, 1981",
        citation: "Tversky, A. & Kahneman, D. (1981). The Framing of Decisions and the Psychology of Choice. Science, 211(4481), 453–458.",
        category: "Money Psychology",
        triggerCount: 0
    ),

    // ── TIME PERCEPTION ──
    BiasPattern(
        name: "Present Bias",
        oneLiner: "We consistently overvalue now versus the future",
        sfSymbol: "clock.badge.exclamationmark",
        iconBg: "#FCE4EC", iconColor: "#880E4F",
        nudgeSays: "$100 now or $110 next week? Most take $100. But most would wait for the $110 if both options were a year away. Future you deserves the same weight as current you.",
        keyRef: "Laibson, 1997",
        citation: "Laibson, D. (1997). Golden Eggs and Hyperbolic Discounting. Quarterly Journal of Economics, 112(2), 443–478.",
        category: "Time Perception",
        triggerCount: 2
    ),
    BiasPattern(
        name: "Planning Fallacy",
        oneLiner: "We underestimate time, cost and risk of future projects",
        sfSymbol: "calendar.badge.exclamationmark",
        iconBg: "#E3F2FD", iconColor: "#0D47A1",
        nudgeSays: "The Sydney Opera House was budgeted at $7M and cost $102M. Your renovation, holiday or side project estimate probably has the same optimism baked in.",
        keyRef: "Buehler, Griffin & Ross, 1994",
        citation: "Buehler, R., Griffin, D. & Ross, M. (1994). Exploring the 'Planning Fallacy': Why People Underestimate Their Task Completion Times. Journal of Personality and Social Psychology, 67(3), 366–381.",
        category: "Time Perception",
        triggerCount: 0
    ),

    // ── SOCIAL ──
    BiasPattern(
        name: "Social Proof",
        oneLiner: "We measure our wealth relative to others, not our own goals",
        sfSymbol: "person.2.wave.2.fill",
        iconBg: "#F3E5F5", iconColor: "#7B1FA2",
        nudgeSays: "Keeping up with people around you is evolutionarily wired. In tribes, relative status mattered for survival. The Joneses are probably in debt. You're building awareness instead.",
        keyRef: "Cialdini, 2001",
        citation: "Cialdini, R.B. (2001). Influence: Science and Practice (4th ed.). Allyn & Bacon.",
        category: "Social",
        triggerCount: 0
    ),
    BiasPattern(
        name: "Scarcity Heuristic",
        oneLiner: "We follow the crowd even when we privately know better",
        sfSymbol: "figure.walk.motion",
        iconBg: "#E8F5E9", iconColor: "#33691E",
        nudgeSays: "Crypto in 2021. Property in 2006. Everyone piling in is the warning sign, not the green light. The crowd's confidence is a contrary indicator.",
        keyRef: "Banerjee, 1992",
        citation: "Banerjee, A.V. (1992). A Simple Model of Herd Behavior. Quarterly Journal of Economics, 107(3), 797–817.",
        category: "Social",
        triggerCount: 0
    ),

    // ── DEFAULTS & HABITS ──
    BiasPattern(
        name: "Status Quo Bias",
        oneLiner: "The default option wins, even when switching is clearly better",
        sfSymbol: "repeat.circle.fill",
        iconBg: "#FFF8E1", iconColor: "#E65100",
        nudgeSays: "Your default super fund, insurance provider, and subscription plan were all chosen by someone else. Status quo bias keeps you there long after it makes sense.",
        keyRef: "Samuelson & Zeckhauser, 1988",
        citation: "Samuelson, W. & Zeckhauser, R. (1988). Status Quo Bias in Decision Making. Journal of Risk and Uncertainty, 1(1), 7–59.",
        category: "Defaults & Habits",
        triggerCount: 1
    ),
    BiasPattern(
        name: "Moral Licensing",
        oneLiner: "Doing something good gives unconscious permission to be bad",
        sfSymbol: "checkmark.seal.fill",
        iconBg: "#E8EAF6", iconColor: "#283593",
        nudgeSays: "Going to the gym makes you feel like you earned the Uber Eats. One good financial decision can unconsciously license several bad ones that follow it.",
        keyRef: "Monin & Miller, 2001",
        citation: "Monin, B. & Miller, D.T. (2001). Moral Credentials and the Expression of Prejudice. Journal of Personality and Social Psychology, 81(1), 33–43.",
        category: "Defaults & Habits",
        triggerCount: 0
    ),
]

let biasCategories: [BiasCategory] = [
    BiasCategory(name: "Avoidance", emoji: "🙈",
        patterns: allBiasPatterns.filter { $0.category == "Avoidance" }),
    BiasCategory(name: "Decision Making", emoji: "⚖️",
        patterns: allBiasPatterns.filter { $0.category == "Decision Making" }),
    BiasCategory(name: "Money Psychology", emoji: "🧠",
        patterns: allBiasPatterns.filter { $0.category == "Money Psychology" }),
    BiasCategory(name: "Time Perception", emoji: "⏳",
        patterns: allBiasPatterns.filter { $0.category == "Time Perception" }),
    BiasCategory(name: "Social", emoji: "👥",
        patterns: allBiasPatterns.filter { $0.category == "Social" }),
    BiasCategory(name: "Defaults & Habits", emoji: "🔄",
        patterns: allBiasPatterns.filter { $0.category == "Defaults & Habits" }),
]
