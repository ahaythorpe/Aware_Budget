import Foundation

/// Inserts sample data into Supabase so all screens render meaningfully.
/// Triggered by a hidden "Load demo data" button on HomeView.
@MainActor
enum DemoDataService {

    private static let service = SupabaseService.shared

    static func seed() async throws {
        guard let uid = await service.currentUserId else {
            throw NSError(domain: "DemoData", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "Sign in first"])
        }

        let cal = Calendar.current
        let now = Date()

        // MARK: - 7 daily check-ins (last 7 days)

        let tones: [CheckIn.EmotionalTone] = [.calm, .neutral, .anxious, .calm, .neutral, .calm, .calm]
        let drivers: [CheckIn.SpendingDriver?] = [
            .presentBias, nil, .emotional, .social, nil, .convenience, .frictionAvoid
        ]

        for day in 0..<7 {
            let date = cal.date(byAdding: .day, value: -(6 - day), to: now) ?? now
            let checkIn = CheckIn(
                id: UUID(),
                userId: uid,
                date: date,
                questionId: nil,
                response: nil,
                emotionalTone: tones[day],
                spendingDriver: drivers[day],
                streakCount: day + 1,
                alignmentPct: 60 + Double(day) * 4,
                createdAt: date
            )
            try await service.saveCheckIn(checkIn)
        }

        // MARK: - 8 money events (last 2 weeks)

        struct EventSeed {
            let daysAgo: Int
            let amount: Double
            let status: MoneyEvent.PlannedStatus
            let tag: String?
            let note: String?
        }

        let events: [EventSeed] = [
            EventSeed(daysAgo: 1,  amount: 45,   status: .surprise, tag: "present_bias",   note: "Coffee machine deal"),
            EventSeed(daysAgo: 2,  amount: 89,   status: .surprise, tag: "social",         note: "Group dinner"),
            EventSeed(daysAgo: 3,  amount: 22,   status: .impulse,  tag: "emotional",       note: "Late-night order"),
            EventSeed(daysAgo: 5,  amount: 1200, status: .planned,  tag: nil,               note: "Rent"),
            EventSeed(daysAgo: 6,  amount: 78,   status: .planned,  tag: nil,               note: "Weekly groceries"),
            EventSeed(daysAgo: 8,  amount: 32,   status: .planned,  tag: nil,               note: "Transport pass"),
            EventSeed(daysAgo: 10, amount: 350,  status: .planned,  tag: nil,               note: "Freelance payment"),
            EventSeed(daysAgo: 12, amount: 25,   status: .planned,  tag: nil,               note: "Refund"),
        ]

        for e in events {
            let date = cal.date(byAdding: .day, value: -e.daysAgo, to: now) ?? now
            let event = MoneyEvent(
                id: UUID(),
                userId: uid,
                date: date,
                amount: e.amount,
                plannedStatus: e.status,
                behaviourTag: e.tag,
                lifeEvent: nil,
                note: e.note,
                createdAt: date
            )
            try await service.saveMoneyEvent(event)
        }

        // MARK: - 3 bias progress entries

        try await service.updateBiasProgress(biasName: "Anchoring", reflected: true)
        for _ in 0..<6 {
            try await service.updateBiasProgress(biasName: "Anchoring", reflected: false)
        }
        for _ in 0..<4 {
            try await service.updateBiasProgress(biasName: "Loss Aversion", reflected: false)
        }
        for _ in 0..<3 {
            try await service.updateBiasProgress(biasName: "Bandwagon Effect", reflected: false)
        }
    }
}
