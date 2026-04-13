import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://vdnnoezyogbgtiubamze.supabase.co")!,
            supabaseKey: "sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH"
        )
    }

    // MARK: - Current user

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    // MARK: - Auth

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetUserData() async throws {
        guard let uid = await currentUserId else { return }
        let id = uid.uuidString
        try await client.from("daily_checkins").delete().eq("user_id", value: id).execute()
        try await client.from("money_events").delete().eq("user_id", value: id).execute()
        try await client.from("user_bias_progress").delete().eq("user_id", value: id).execute()
    }

    // MARK: - Check-ins

    func saveCheckIn(_ checkIn: CheckIn) async throws {
        try await client.from("daily_checkins")
            .upsert(checkIn, onConflict: "user_id,date")
            .execute()
    }

    func fetchTodaysCheckIn() async throws -> CheckIn? {
        guard let uid = await currentUserId else { return nil }
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())
        let response: [CheckIn] = try await client.from("daily_checkins")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("date", value: today)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func fetchCheckIn(on date: Date) async throws -> CheckIn? {
        guard let uid = await currentUserId else { return nil }
        let dateStr = ISO8601DateFormatter.dateOnly.string(from: date)
        let response: [CheckIn] = try await client.from("daily_checkins")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("date", value: dateStr)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    func fetchRecentCheckIns(limit: Int) async throws -> [CheckIn] {
        guard let uid = await currentUserId else { return [] }
        let response: [CheckIn] = try await client.from("daily_checkins")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }

    // MARK: - Money events

    func saveMoneyEvent(_ event: MoneyEvent) async throws {
        try await client.from("money_events")
            .insert(event)
            .execute()
    }

    func fetchMoneyEvents(forMonth month: Date) async throws -> [MoneyEvent] {
        guard let uid = await currentUserId else { return [] }
        let cal = Calendar.current
        let start = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let end = cal.date(byAdding: .month, value: 1, to: start)!
        let startStr = ISO8601DateFormatter.dateOnly.string(from: start)
        let endStr = ISO8601DateFormatter.dateOnly.string(from: end)
        let response: [MoneyEvent] = try await client.from("money_events")
            .select()
            .eq("user_id", value: uid.uuidString)
            .gte("date", value: startStr)
            .lt("date", value: endStr)
            .order("date", ascending: false)
            .execute()
            .value
        return response
    }

    func fetchRecentMoneyEvents(limit: Int) async throws -> [MoneyEvent] {
        guard let uid = await currentUserId else { return [] }
        let response: [MoneyEvent] = try await client.from("money_events")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("date", ascending: false)
            .limit(limit)
            .execute()
            .value
        return response
    }

    func fetchMoneyEventsThisWeek() async throws -> [MoneyEvent] {
        guard let uid = await currentUserId else { return [] }
        var cal = Calendar(identifier: .iso8601)
        cal.firstWeekday = 2
        let now = Date()
        guard let monday = cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return []
        }
        let mondayStr = ISO8601DateFormatter.dateOnly.string(from: monday)
        let todayStr = ISO8601DateFormatter.dateOnly.string(from: now)
        let response: [MoneyEvent] = try await client.from("money_events")
            .select()
            .eq("user_id", value: uid.uuidString)
            .gte("date", value: mondayStr)
            .lte("date", value: todayStr)
            .order("date", ascending: false)
            .execute()
            .value
        return response
    }

    func countBehaviourTag(_ tag: String) async throws -> Int {
        guard let uid = await currentUserId else { return 0 }
        let response: [MoneyEvent] = try await client.from("money_events")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("behaviour_tag", value: tag)
            .execute()
            .value
        return response.count
    }

    func fetchAllMoneyEvents() async throws -> [MoneyEvent] {
        guard let uid = await currentUserId else { return [] }
        let response: [MoneyEvent] = try await client.from("money_events")
            .select()
            .eq("user_id", value: uid.uuidString)
            .order("date", ascending: false)
            .execute()
            .value
        return response
    }

    // MARK: - Questions

    func fetchNextQuestion() async throws -> Question {
        let fourteenDaysAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())!
        let dateStr = ISO8601DateFormatter.dateOnly.string(from: fourteenDaysAgo)

        // Try questions not shown in the last 14 days first
        var response: [Question] = try await client.from("question_pool")
            .select()
            .or("last_shown.is.null,last_shown.lt.\(dateStr)")
            .order("last_shown", ascending: true, nullsFirst: true)
            .limit(1)
            .execute()
            .value

        // Fall back to least recently shown
        if response.isEmpty {
            response = try await client.from("question_pool")
                .select()
                .order("last_shown", ascending: true, nullsFirst: true)
                .limit(1)
                .execute()
                .value
        }

        guard let picked = response.first else {
            throw NSError(domain: "SupabaseService", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "No questions available"])
        }

        // Update last_shown
        try await client.from("question_pool")
            .update(["last_shown": ISO8601DateFormatter.dateOnly.string(from: Date())])
            .eq("id", value: picked.id.uuidString)
            .execute()

        return picked
    }

    // MARK: - Budget months

    func fetchOrCreateBudgetMonth(for date: Date) async throws -> BudgetMonth {
        guard let uid = await currentUserId else {
            throw NSError(domain: "SupabaseService", code: 401,
                          userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])
        }
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: date))!
        let monthStr = ISO8601DateFormatter.dateOnly.string(from: startOfMonth)

        // Check for existing
        let existing: [BudgetMonth] = try await client.from("budget_months")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("month", value: monthStr)
            .limit(1)
            .execute()
            .value

        if let found = existing.first { return found }

        // Create new
        let new = BudgetMonth(
            id: UUID(),
            userId: uid,
            month: startOfMonth,
            incomeTarget: 0,
            createdAt: Date()
        )
        try await client.from("budget_months")
            .insert(new)
            .execute()
        return new
    }

    func updateIncomeTarget(_ amount: Double, for month: Date) async throws {
        guard let uid = await currentUserId else { return }
        let cal = Calendar.current
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let monthStr = ISO8601DateFormatter.dateOnly.string(from: startOfMonth)

        try await client.from("budget_months")
            .update(["income_target": amount])
            .eq("user_id", value: uid.uuidString)
            .eq("month", value: monthStr)
            .execute()
    }

    // MARK: - Bias lessons (PRD v1.1)

    func fetchAllBiasLessons() async throws -> [BiasLesson] {
        let response: [BiasLesson] = try await client.from("bias_lessons")
            .select()
            .order("sort_order", ascending: true)
            .execute()
            .value
        return response
    }

    func fetchBiasLesson(biasName: String) async throws -> BiasLesson? {
        let response: [BiasLesson] = try await client.from("bias_lessons")
            .select()
            .eq("bias_name", value: biasName)
            .limit(1)
            .execute()
            .value
        return response.first
    }

    // MARK: - Bias progress (PRD v1.1)

    func fetchBiasProgress() async throws -> [BiasProgress] {
        guard let uid = await currentUserId else { return [] }
        let response: [BiasProgress] = try await client.from("user_bias_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return response
    }

    func updateBiasProgress(biasName: String, reflected: Bool) async throws {
        guard let uid = await currentUserId else { return }
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())

        // Try to fetch existing progress
        let existing: [BiasProgress] = try await client.from("user_bias_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .eq("bias_name", value: biasName)
            .limit(1)
            .execute()
            .value

        if let row = existing.first {
            var updates: [String: AnyJSON] = [
                "times_encountered": .integer(row.timesEncountered + 1),
                "last_seen": .string(today),
            ]
            if reflected {
                updates["times_reflected"] = .integer(row.timesReflected + 1)
            }
            try await client.from("user_bias_progress")
                .update(updates)
                .eq("id", value: row.id.uuidString)
                .execute()
        } else {
            let new = BiasProgress(
                id: UUID(),
                userId: uid,
                biasName: biasName,
                timesEncountered: 1,
                timesReflected: reflected ? 1 : 0,
                firstSeen: Date(),
                lastSeen: Date(),
                createdAt: Date()
            )
            try await client.from("user_bias_progress")
                .insert(new)
                .execute()
        }
    }
}

// MARK: - BiasProgress model

struct BiasProgress: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var biasName: String
    var timesEncountered: Int
    var timesReflected: Int
    var firstSeen: Date?
    var lastSeen: Date?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case biasName = "bias_name"
        case timesEncountered = "times_encountered"
        case timesReflected = "times_reflected"
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case createdAt = "created_at"
    }
}

// MARK: - Date helper

extension ISO8601DateFormatter {
    static let dateOnly: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()
}
