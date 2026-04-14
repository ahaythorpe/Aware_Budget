import Foundation
import SwiftUI

// MARK: - Amount range model

struct AmountRange: Identifiable {
    let label: String
    let midpoint: Double
    var id: String { label }
}

// MARK: - Category definitions

struct SpendCategory: Identifiable {
    let emoji: String
    let name: String
    var id: String { name }
}

let spendCategories: [SpendCategory] = [
    .init(emoji: "☕", name: "Coffee"),
    .init(emoji: "🥗", name: "Lunch"),
    .init(emoji: "🍺", name: "Drinks"),
    .init(emoji: "🛍️", name: "Shopping"),
    .init(emoji: "🚗", name: "Transport"),
    .init(emoji: "🍕", name: "Eating out"),
    .init(emoji: "💊", name: "Pharmacy"),
    .init(emoji: "📱", name: "Subscriptions"),
    .init(emoji: "🎬", name: "Entertainment"),
    .init(emoji: "✈️", name: "Travel"),
    .init(emoji: "👗", name: "Clothing"),
    .init(emoji: "🎁", name: "Gift"),
    .init(emoji: "🏠", name: "Home"),
    .init(emoji: "💪", name: "Fitness"),
    .init(emoji: "💰", name: "Big purchase"),
    .init(emoji: "➕", name: "Other"),
]

let categoryRanges: [String: [AmountRange]] = [
    "Coffee": [
        .init(label: "$4–6", midpoint: 5),
        .init(label: "$6–8", midpoint: 7),
        .init(label: "$8–12", midpoint: 10),
        .init(label: "$12+", midpoint: 15),
    ],
    "Lunch": [
        .init(label: "$12–18", midpoint: 15),
        .init(label: "$18–25", midpoint: 21),
        .init(label: "$25–40", midpoint: 32),
        .init(label: "$40+ special", midpoint: 55),
    ],
    "Drinks": [
        .init(label: "$10–20", midpoint: 15),
        .init(label: "$20–50", midpoint: 35),
        .init(label: "$50–100", midpoint: 75),
        .init(label: "$100+ big night", midpoint: 130),
    ],
    "Shopping": [
        .init(label: "$20–50", midpoint: 35),
        .init(label: "$50–150", midpoint: 100),
        .init(label: "$150–400", midpoint: 275),
        .init(label: "$400+", midpoint: 500),
    ],
    "Transport": [
        .init(label: "$5–15", midpoint: 10),
        .init(label: "$15–40", midpoint: 27),
        .init(label: "$40–100", midpoint: 70),
        .init(label: "$100+", midpoint: 130),
    ],
    "Eating out": [
        .init(label: "$15–25", midpoint: 20),
        .init(label: "$25–40", midpoint: 32),
        .init(label: "$40–60", midpoint: 50),
        .init(label: "$60+", midpoint: 75),
    ],
    "Pharmacy": [
        .init(label: "$10–20", midpoint: 15),
        .init(label: "$20–50", midpoint: 35),
        .init(label: "$50–100", midpoint: 75),
    ],
    "Subscriptions": [
        .init(label: "$5–15", midpoint: 10),
        .init(label: "$15–30", midpoint: 22),
        .init(label: "$30–80", midpoint: 55),
    ],
    "Entertainment": [
        .init(label: "$15–30", midpoint: 22),
        .init(label: "$30–60", midpoint: 45),
        .init(label: "$60–150", midpoint: 105),
        .init(label: "$150+", midpoint: 200),
    ],
    "Travel": [
        .init(label: "$50–200", midpoint: 125),
        .init(label: "$200–500", midpoint: 350),
        .init(label: "$500–2k", midpoint: 1250),
        .init(label: "$2k+", midpoint: 3000),
    ],
    "Clothing": [
        .init(label: "$30–80", midpoint: 55),
        .init(label: "$80–200", midpoint: 140),
        .init(label: "$200–500", midpoint: 350),
        .init(label: "$500+", midpoint: 650),
    ],
    "Gift": [
        .init(label: "$20–50", midpoint: 35),
        .init(label: "$50–150", midpoint: 100),
        .init(label: "$150–400", midpoint: 275),
        .init(label: "$400+", midpoint: 500),
    ],
    "Home": [
        .init(label: "$20–100", midpoint: 60),
        .init(label: "$100–300", midpoint: 200),
        .init(label: "$300–1k", midpoint: 650),
        .init(label: "$1k+", midpoint: 1500),
    ],
    "Fitness": [
        .init(label: "$15–30", midpoint: 22),
        .init(label: "$30–80", midpoint: 55),
        .init(label: "$80–200", midpoint: 140),
    ],
    "Big purchase": [
        .init(label: "$500–2k", midpoint: 1250),
        .init(label: "$2k–10k", midpoint: 6000),
        .init(label: "$10k–30k", midpoint: 20000),
        .init(label: "$30k+", midpoint: 40000),
    ],
    "Other": [
        .init(label: "$5–20", midpoint: 12),
        .init(label: "$20–100", midpoint: 60),
        .init(label: "$100–500", midpoint: 300),
        .init(label: "$500+", midpoint: 750),
    ],
]

// MARK: - ABS monthly averages (ABS Household Expenditure Survey 2022–23)

let absMonthlyAverage: [String: Int] = [
    "Coffee": 180,
    "Lunch": 380,
    "Drinks": 128,
    "Shopping": 200,
    "Transport": 140,
    "Eating out": 150,
    "Entertainment": 168,
    "Clothing": 152,
    "Fitness": 80,
    "Travel": 200,
    "Home": 300,
    "Pharmacy": 60,
    "Subscriptions": 85,
    "Gift": 80,
]

// MARK: - Auto-suggest bias tag

func suggestedBiasTag(category: String, status: MoneyEvent.PlannedStatus) -> String {
    switch (category, status) {
    case ("Coffee", .impulse):        return "Status Quo Bias"
    case ("Shopping", .surprise):     return "Scarcity Heuristic"
    case ("Shopping", .impulse):      return "Anchoring"
    case ("Drinks", .impulse):        return "Ego Depletion"
    case ("Big purchase", _):         return "Social Proof"
    case ("Eating out", .impulse):      return "Ego Depletion"
    case ("Subscriptions", _):        return "Status Quo Bias"
    default:                          return "Present Bias"
    }
}

// MARK: - ViewModel

@MainActor
@Observable
final class MoneyEventViewModel {
    var selectedCategory: SpendCategory?
    var selectedRange: AmountRange?
    var plannedStatus: MoneyEvent.PlannedStatus?
    var behaviourTag: String?
    var isSaving = false
    var errorMessage: String?
    var didSave = false
    var nudgeResponse: NudgeMessage?
    var biasTimesSeen: Int = 0

    private let service = SupabaseService.shared

    var availableRanges: [AmountRange] {
        guard let cat = selectedCategory else { return [] }
        return categoryRanges[cat.name] ?? []
    }

    var suggestedTag: String? {
        guard let cat = selectedCategory, let status = plannedStatus else { return nil }
        return suggestedBiasTag(category: cat.name, status: status)
    }

    var canSave: Bool {
        selectedCategory != nil && selectedRange != nil && plannedStatus != nil
    }

    func reset() {
        selectedCategory = nil
        selectedRange = nil
        plannedStatus = nil
        behaviourTag = nil
        didSave = false
        nudgeResponse = nil
        errorMessage = nil
        biasTimesSeen = 0
    }

    func onPlannedStatusSet() {
        if let tag = suggestedTag {
            behaviourTag = tag
            Task { await loadBiasCount(tag) }
        }
    }

    func loadBiasCount(_ biasName: String) async {
        do {
            let progress = try await service.fetchBiasProgress()
            biasTimesSeen = progress.first(where: { $0.biasName == biasName })?.timesEncountered ?? 0
        } catch {
            biasTimesSeen = 0
        }
    }

    var nudgeInline: String? {
        guard let tag = behaviourTag else { return nil }
        if biasTimesSeen >= 3 {
            return "You've seen \(tag) \(biasTimesSeen) times now. That's a pattern worth noticing."
        }
        return biasOneLiners[tag] ?? "Nudge is keeping count."
    }

    func save() async {
        guard !isSaving, let uid = await service.currentUserId else { return }
        guard let cat = selectedCategory, let range = selectedRange, let status = plannedStatus else {
            errorMessage = "Complete all fields."
            return
        }
        isSaving = true
        defer { isSaving = false }

        let event = MoneyEvent(
            id: UUID(),
            userId: uid,
            date: Date(),
            amount: range.midpoint,
            plannedStatus: status,
            behaviourTag: behaviourTag,
            lifeEvent: nil,
            lifeArea: cat.name,
            note: nil,
            createdAt: Date()
        )

        do {
            try await service.saveMoneyEvent(event)

            let tagCount: Int
            if let tag = behaviourTag {
                tagCount = try await service.countBehaviourTag(tag)
            } else {
                tagCount = 0
            }

            nudgeResponse = NudgeEngine.moneyEventResponse(
                behaviourTag: behaviourTag,
                tagCount: tagCount,
                lifeEvent: nil,
                plannedStatus: status
            )

            // Reset 48h no-events timer
            NotificationService.resetNoEventsTimer()

            // Bias alert at 5x threshold
            if let tag = behaviourTag, tagCount == 5 {
                NotificationService.scheduleBiasAlert(biasName: tag, count: tagCount)
            }

            didSave = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Driver insights

struct DriverInsight {
    let means: String
    let fix: String
}

let driverInsights: [String: DriverInsight] = [
    "Present Bias": DriverInsight(
        means: "Your brain chose now over future you.",
        fix: "Wait 24hrs on unplanned purchases over $30."
    ),
    "Social Proof": DriverInsight(
        means: "Spending influenced by what others do.",
        fix: "Ask: would I want this if nobody else had it?"
    ),
    "Moral Licensing": DriverInsight(
        means: "Past good behaviour licensed this spend.",
        fix: "Decouple rewards from spending entirely."
    ),
    "Status Quo Bias": DriverInsight(
        means: "The easier path won over the better choice.",
        fix: "Make the better option one tap easier."
    ),
    "Sunk Cost Fallacy": DriverInsight(
        means: "Changing felt harder than continuing.",
        fix: "Ask: would I choose this starting fresh today?"
    ),
    "Anchoring": DriverInsight(
        means: "The original price made this feel like a win.",
        fix: "Decide your price before seeing theirs."
    ),
    "Scarcity Heuristic": DriverInsight(
        means: "Limited availability inflated perceived value.",
        fix: "Wait 24hrs. Real scarcity rarely expires in an hour."
    ),
    "Ego Depletion": DriverInsight(
        means: "Tired brains make expensive decisions.",
        fix: "Sleep on it. Literally."
    ),
    "Loss Aversion": DriverInsight(
        means: "The fear of losing felt twice as heavy.",
        fix: "Reframe: what would you choose starting from zero?"
    ),
    "Mental Accounting": DriverInsight(
        means: "You treated this money differently because of its label.",
        fix: "All dollars are equal. Check the total."
    ),
    "Overconfidence Bias": DriverInsight(
        means: "Confidence outstripped the evidence.",
        fix: "Write down your prediction. Check it later."
    ),
    "Framing Effect": DriverInsight(
        means: "The way it was framed changed your choice.",
        fix: "Restate the deal in absolute dollars, not percentages."
    ),
    "Availability Heuristic": DriverInsight(
        means: "A vivid memory drove this more than data.",
        fix: "Check the base rate before deciding."
    ),
    "Ostrich Effect": DriverInsight(
        means: "You avoided information that might be bad news.",
        fix: "Just open the app. Looking is enough."
    ),
    "Planning Fallacy": DriverInsight(
        means: "It cost more than you expected. As usual.",
        fix: "Add 30% to your first estimate."
    ),
    "Denomination Effect": DriverInsight(
        means: "Small digital payments add up invisibly.",
        fix: "Check your weekly total, not individual taps."
    ),
]

// MARK: - Bias one-liners

private let biasOneLiners: [String: String] = [
    "Present Bias": "We treat future-us like a stranger. Worth noticing.",
    "Status Quo Bias": "Defaults cost real money. Just by existing.",
    "Scarcity Heuristic": "Urgency is almost always manufactured.",
    "Anchoring": "The first number you saw set the frame.",
    "Ego Depletion": "Tired brains make expensive decisions.",
    "Social Proof": "Everyone else is performing too.",
    "Sunk Cost Fallacy": "Past spending shouldn't drive future choices.",
    "Loss Aversion": "The fear of losing feels twice as heavy.",
    "Mental Accounting": "Money is money, regardless of the envelope.",
    "Overconfidence Bias": "Confidence often outstrips accuracy.",
    "Moral Licensing": "Being good doesn't earn a splurge.",
    "Planning Fallacy": "It always costs more than you think.",
    "Framing Effect": "Same number, different frame, different choice.",
    "Denomination Effect": "Small digital payments add up invisibly.",
    "Availability Heuristic": "Vivid stories aren't data.",
    "Ostrich Effect": "Avoidance makes the problem grow.",
]
