import Foundation

/// Centralised Nudge voice lines by context. Each `.random()` call picks
/// a fresh line so the same surface doesn't repeat.
/// All lines are dry, warm, research-adjacent, never cheerleader, never shamey.
enum NudgeVoice {

    // MARK: - Skip chastise (pops when user tries to skip a review)
    static let skipChastise: [String] = [
        "Nudge was just getting warm. Patterns you don't look at run the show.",
        "Skipping is logging without learning.",
        "Your blind spots won't flag themselves.",
        "Skip is fine. Next week's 'why did I do that?' is also fine.",
        "Two minutes now. Or twenty minutes next month.",
        "The patterns you ignore still run your money.",
        "Noticing is cheap. Not noticing compounds.",
        "Future-you is waiting with a receipt.",
        "Closing your eyes doesn't close the tab.",
    ]

    // MARK: - Alt-picker chastise (when user taps "No, different reason"
    // — nudge them to pick the real reason slowly, not trigger-happy click)
    static let altPickerChastise: [String] = [
        "Don't just click. The wrong reason gives you the wrong insight.",
        "Fast-clicking through is how blind spots survive. Sit with it.",
        "The real reason is usually the one you'd rather not pick.",
        "Nudge can't read minds. Pick the one that actually fit.",
        "Your future self can tell when you lied here. So can Nudge.",
        "Slow down. The pattern you skip is the one that repeats.",
        "Wrong label now = wrong insight later. Get it right.",
    ]

    // MARK: - Motto lines (Nudge Says cards, session summaries, general rotation)
    static let motto: [String] = [
        "Awareness is interest — it compounds for future-you's savings.",
        "Small awareness. Big difference.",
        "Patterns repeat. Until they don't.",
        "This is how the slow change happens.",
        "Small, frequent, honest. That's the trick.",
        "Every log is a vote for a less surprised future.",
        "Your unexamined habits run a tab.",
        "Small noticed truth beats big forgotten resolution.",
        "The turtle was onto something.",
        "Slow is smooth. Smooth is rich.",
        "Rushing is how we miss it.",
        "Awareness walks. Anxiety runs.",
        "The snail arrives fully noticed.",
        "Small stacks louder than big.",
        "You don't need to run. Just keep walking.",
        "Kahneman called it 'System 1'. You call it Tuesday.",
        "Behavioural finance in practice.",
    ]

    // MARK: - Post-save ("logged." moment)
    static let postSave: [String] = [
        "Logged. One data point richer.",
        "Noticed. Not judged.",
        "Nudge has questions.",
        "Pattern detected.",
        "Another line in your money story.",
        "Your future self just filed this.",
        "Quietly tracking.",
    ]

    // MARK: - Session summary openers
    static let sessionSummary: [String] = [
        "This session: rich in data, short on guilt.",
        "Five seconds of honesty. Weeks of insight.",
        "Look what your week just told you.",
        "Small, frequent, honest. That's the trick.",
        "Patterns repeat. Until they don't.",
    ]

    // MARK: - Weekly review (Sunday)
    static let weeklyReview: [String] = [
        "Your week, without the story.",
        "A week richer in insights.",
        "Seven days, laid bare.",
        "Your week said something. Listen in.",
        "The pattern lives here.",
    ]

    // MARK: - Monthly checkpoint (first check-in of the month)
    static let monthlyCheckpoint: [String] = [
        "Still yes? Still no?",
        "Thirty days of small truths.",
        "A month of quiet data. Let's see.",
        "Checkpoint — not a grade.",
    ]

    // MARK: - Bias-matched motto (smart pairing, see sessionSummary use)
    /// Returns a motto that thematically pairs with the given bias —
    /// used when Nudge is speaking ABOUT a specific pattern so the line
    /// lands instead of feeling random.
    static func mottoFor(bias: String) -> String {
        switch bias {
        case "Present Bias":
            return "Future-you is waiting with a receipt."
        case "Status Quo Bias":
            return "Small stacks louder than big."
        case "Ego Depletion":
            return "Rushing is how we miss it."
        case "Social Proof":
            return "Your unexamined habits run a tab."
        case "Scarcity Heuristic":
            return "Awareness walks. Anxiety runs."
        case "Anchoring":
            return "Kahneman called it 'System 1'. You call it Tuesday."
        case "Moral Licensing":
            return "Small noticed truth beats big forgotten resolution."
        case "Availability Heuristic":
            return "Closing your eyes doesn't close the tab."
        case "Mental Accounting":
            return "Awareness is interest — it compounds for future-you's savings."
        case "Loss Aversion":
            return "The snail arrives fully noticed."
        case "Sunk Cost Fallacy":
            return "Slow is smooth. Smooth is rich."
        case "Overconfidence Bias":
            return "The turtle was onto something."
        case "Framing Effect":
            return "Behavioural finance in practice."
        case "Denomination Effect":
            return "Every log is a vote for a less surprised future."
        case "Planning Fallacy":
            return "You don't need to run. Just keep walking."
        case "Ostrich Effect":
            return "Your blind spots won't flag themselves."
        default:
            return random(motto)
        }
    }

    // MARK: - Random picker helper
    static func random(_ pool: [String]) -> String {
        pool.randomElement() ?? pool.first ?? ""
    }
}
