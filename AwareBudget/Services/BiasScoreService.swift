import Foundation

// MARK: - Mastery stages

enum MasteryStage: String, CaseIterable {
    case unseen = "Unseen"
    case noticed = "Noticed"
    case emerging = "Emerging"
    case active = "Active"
    case improving = "Improving"
    case aware = "Aware"
}

// MARK: - Trend

enum BiasTrend: String {
    case worsening = "↑ Watch this"
    case stable = "→ Stable"
    case improving = "↓ Improving"
}

// MARK: - Bias score

struct BiasScore {
    var biasName: String
    var score: Int
    var recentAnswers: [Bool]
    var linkedSpend: Double
    var masteryStage: MasteryStage
    var trend: BiasTrend
}

// MARK: - Scoring service

enum BiasScoreService {

    // Scoring weights
    static let yesWeight = 2
    static let noWeight = -1
    static let taggedWeight = 3

    static func calculateStage(score: Int, recentAnswers: [Bool]) -> MasteryStage {
        // Check for aware: 3+ weeks of NO (21+ recent answers all false)
        let lastThreeWeeks = recentAnswers.suffix(21)
        if lastThreeWeeks.count >= 21 && !lastThreeWeeks.contains(true) {
            return .aware
        }

        // Check for improving: last 3 answers were NO
        let lastThree = recentAnswers.suffix(3)
        if lastThree.count >= 3 && !lastThree.contains(true) {
            return .improving
        }

        let yesCount = recentAnswers.filter { $0 }.count

        switch yesCount {
        case 0:     return .unseen
        case 1...2: return .noticed
        case 3...5: return .emerging
        default:    return .active
        }
    }

    static func calculateTrend(recentAnswers: [Bool]) -> BiasTrend {
        guard recentAnswers.count >= 4 else { return .stable }

        let half = recentAnswers.count / 2
        let firstHalf = recentAnswers.prefix(half)
        let secondHalf = recentAnswers.suffix(half)

        let firstYes = firstHalf.filter { $0 }.count
        let secondYes = secondHalf.filter { $0 }.count

        if secondYes < firstYes { return .improving }
        if secondYes > firstYes { return .worsening }
        return .stable
    }

    static func weeklyNet(events: [MoneyEvent]) -> Double {
        let planned = events
            .filter { $0.plannedStatus == .planned }
            .reduce(0.0) { $0 + $1.amount }
        let unplanned = events
            .filter { $0.plannedStatus != .planned }
            .reduce(0.0) { $0 + $1.amount }
        return planned - unplanned
    }

    static func computeScore(
        biasName: String,
        progress: BiasProgress?,
        taggedEvents: Int
    ) -> BiasScore {
        let timesEncountered = progress?.timesEncountered ?? 0
        let timesReflected = progress?.timesReflected ?? 0

        // Build recent answers from encounter/reflected ratio
        var recentAnswers: [Bool] = []
        let yesCount = max(0, timesEncountered - timesReflected)
        let noCount = timesReflected
        for _ in 0..<yesCount { recentAnswers.append(true) }
        for _ in 0..<noCount { recentAnswers.append(false) }

        let bfasWeight = progress?.bfasWeight ?? 0
        let score = (yesCount * yesWeight)
            + (noCount * noWeight)
            + (taggedEvents * taggedWeight)
            + bfasWeight

        let stage = calculateStage(score: score, recentAnswers: recentAnswers)
        let trend = calculateTrend(recentAnswers: recentAnswers)

        return BiasScore(
            biasName: biasName,
            score: score,
            recentAnswers: recentAnswers,
            linkedSpend: Double(taggedEvents),
            masteryStage: stage,
            trend: trend
        )
    }
}
