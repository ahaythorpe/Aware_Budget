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

    /// DEBUG-only — ensures there's a valid Supabase session on every launch.
    /// Uses a persistent per-device test user stored in UserDefaults so saves
    /// and fetches actually have a user_id to associate with. In release
    /// builds the user signs in via the normal flow (OTP / OAuth).
    #if DEBUG
    /// Published DEBUG auth status so views can show a diagnostic banner.
    /// Uses a singleton @Observable so SwiftUI refreshes live as it updates.
    @MainActor static var debugAuthStatus: String {
        get { DebugAuthStatus.shared.status }
        set { DebugAuthStatus.shared.status = newValue }
    }

    func ensureDebugSession() async {
        if let uid = await currentUserId {
            await MainActor.run { Self.debugAuthStatus = "signed in · \(String(uid.uuidString.prefix(8)))" }
            print("[DEBUG AUTH] already signed in: \(uid)")
            return
        }

        let defaults = UserDefaults.standard
        let savedEmail = defaults.string(forKey: "debugEmail")
        let savedPassword = defaults.string(forKey: "debugPassword")

        // Try saved creds.
        if let e = savedEmail, let p = savedPassword {
            do {
                try await client.auth.signIn(email: e, password: p)
                if let uid = await currentUserId {
                    await MainActor.run { Self.debugAuthStatus = "signed in via saved creds · \(String(uid.uuidString.prefix(8)))" }
                    print("[DEBUG AUTH] signed in via saved creds: \(uid)")
                    return
                }
            } catch {
                print("[DEBUG AUTH] saved creds failed: \(error.localizedDescription)")
            }
        }

        // Fresh signup.
        let email = "debug-\(UUID().uuidString.prefix(8))@awarebudget.test"
        let password = "Dbg-\(UUID().uuidString.prefix(12))"
        do {
            try await client.auth.signUp(email: String(email), password: String(password))
            defaults.set(email, forKey: "debugEmail")
            defaults.set(password, forKey: "debugPassword")
            if let uid = await currentUserId {
                await MainActor.run { Self.debugAuthStatus = "signed up · \(String(uid.uuidString.prefix(8)))" }
                print("[DEBUG AUTH] signed up: \(uid)")
            } else {
                await MainActor.run { Self.debugAuthStatus = "signup OK but no session (email confirmation?)" }
                print("[DEBUG AUTH] signup returned but no session — email confirmation likely required in Supabase settings")
            }
        } catch {
            await MainActor.run { Self.debugAuthStatus = "signup FAILED: \(error.localizedDescription)" }
            print("[DEBUG AUTH] signup FAILED: \(error)")
            print("[DEBUG AUTH] Fix: Supabase dashboard -> Authentication -> Providers -> Email -> ENABLE + disable 'Confirm email' for DEBUG.")
        }
    }
    #endif

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

    /// Returns N questions tailored to the user's top-ranked biases.
    /// Picks top-N biases by BFAS + activity score, then for each bias fetches
    /// the least-recently-shown question. Falls back to generic next-question
    /// if a bias has no available question. See PRD v1.2.
    func fetchTailoredQuestions(count: Int = 4) async throws -> [Question] {
        // 1) Rank biases by score
        let progress = try await fetchBiasProgress()
        let topBiases: [String] = progress
            .map { bp -> (String, Int) in
                let score = BiasScoreService.computeScore(
                    biasName: bp.biasName, progress: bp, taggedEvents: 0
                )
                return (bp.biasName, score.score)
            }
            .sorted { $0.1 > $1.1 }
            .prefix(count)
            .map(\.0)

        var picked: [Question] = []
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())

        // 2) For each top bias, pick its least-recently-shown question
        for bias in topBiases {
            let rows: [Question] = try await client.from("question_pool")
                .select()
                .eq("bias_name", value: bias)
                .order("last_shown", ascending: true, nullsFirst: true)
                .limit(1)
                .execute()
                .value
            if let q = rows.first, !picked.contains(where: { $0.id == q.id }) {
                picked.append(q)
                try await client.from("question_pool")
                    .update(["last_shown": today])
                    .eq("id", value: q.id.uuidString)
                    .execute()
            }
        }

        // 3) Fill remaining slots from generic pool
        while picked.count < count {
            do {
                let q = try await fetchNextQuestion()
                if !picked.contains(where: { $0.id == q.id }) {
                    picked.append(q)
                }
            } catch {
                break
            }
        }

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

    /// Saves 16 BFAS baseline answers. YES -> bfas_weight 7, NO -> 2.
    /// Upserts by (user_id, bias_name): updates existing row or inserts new.
    func saveBFASAssessment(answers: [String: Bool]) async throws {
        guard let uid = await currentUserId else { return }

        let existing: [BiasProgress] = try await client.from("user_bias_progress")
            .select()
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        let existingByBias = Dictionary(uniqueKeysWithValues: existing.map { ($0.biasName, $0) })

        for (biasName, yes) in answers {
            let weight = yes ? 7 : 2
            if let row = existingByBias[biasName] {
                try await client.from("user_bias_progress")
                    .update(["bfas_weight": AnyJSON.integer(weight)])
                    .eq("id", value: row.id.uuidString)
                    .execute()
            } else {
                let new = BiasProgress(
                    id: UUID(),
                    userId: uid,
                    biasName: biasName,
                    timesEncountered: 0,
                    timesReflected: 0,
                    firstSeen: nil,
                    lastSeen: nil,
                    createdAt: Date(),
                    bfasWeight: weight
                )
                try await client.from("user_bias_progress")
                    .insert(new)
                    .execute()
            }
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
    var bfasWeight: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case biasName = "bias_name"
        case timesEncountered = "times_encountered"
        case timesReflected = "times_reflected"
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case createdAt = "created_at"
        case bfasWeight = "bfas_weight"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        biasName = try c.decode(String.self, forKey: .biasName)
        timesEncountered = try c.decode(Int.self, forKey: .timesEncountered)
        timesReflected = try c.decode(Int.self, forKey: .timesReflected)
        firstSeen = try c.decodeIfPresent(Date.self, forKey: .firstSeen)
        lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        bfasWeight = try c.decodeIfPresent(Int.self, forKey: .bfasWeight) ?? 0
    }

    init(id: UUID, userId: UUID, biasName: String, timesEncountered: Int, timesReflected: Int, firstSeen: Date?, lastSeen: Date?, createdAt: Date, bfasWeight: Int = 0) {
        self.id = id
        self.userId = userId
        self.biasName = biasName
        self.timesEncountered = timesEncountered
        self.timesReflected = timesReflected
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.createdAt = createdAt
        self.bfasWeight = bfasWeight
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
