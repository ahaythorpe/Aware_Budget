import Foundation
import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        // Custom JSON decoder that tolerates BOTH ISO8601 timestamps
        // (Postgres TIMESTAMPTZ columns like created_at) AND bare
        // YYYY-MM-DD date strings (Postgres DATE columns like
        // money_events.date and budget_months.month). Without this,
        // every row containing a DATE column failed to decode silently
        // → fetchMoneyEvents returned [] → Home showed "0 EVENTS"
        // even though the rows were sitting in Supabase.
        let decoder = JSONDecoder()
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let isoFormatterNoFrac = ISO8601DateFormatter()
        isoFormatterNoFrac.formatOptions = [.withInternetDateTime]
        let dateOnly = ISO8601DateFormatter()
        dateOnly.formatOptions = [.withFullDate]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let s = try container.decode(String.self)
            if let d = isoFormatter.date(from: s) { return d }
            if let d = isoFormatterNoFrac.date(from: s) { return d }
            if let d = dateOnly.date(from: s) { return d }
            // Postgres timestamp without TZ may also come as
            // "2026-04-16 22:07:41.465+00" — try replacing space with T.
            let normalized = s.replacingOccurrences(of: " ", with: "T")
            if let d = isoFormatter.date(from: normalized) { return d }
            if let d = isoFormatterNoFrac.date(from: normalized) { return d }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Date string '\(s)' didn't match any expected format"
            )
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        client = SupabaseClient(
            supabaseURL: URL(string: "https://vdnnoezyogbgtiubamze.supabase.co")!,
            supabaseKey: "sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH",
            options: SupabaseClientOptions(
                db: SupabaseClientOptions.DatabaseOptions(
                    encoder: encoder,
                    decoder: decoder
                )
            )
        )
    }

    // MARK: - Current user

    var currentUserId: UUID? {
        get async {
            try? await client.auth.session.user.id
        }
    }

    // MARK: - Auth

    /// Sign up with a graceful fallback. If Supabase's hosted email
    /// service is mis-configured (no SMTP) it returns "500: Error
    /// sending confirmation email" — but the user IS created. We try
    /// to sign in immediately afterwards so signup still completes
    /// from the user's perspective. If sign-in also fails, surface a
    /// human-readable message instead of the raw 500.
    func signUp(email: String, password: String) async throws {
        do {
            try await client.auth.signUp(email: email, password: password)
        } catch {
            let msg = error.localizedDescription.lowercased()
            if msg.contains("error sending confirmation email") ||
               msg.contains("email rate limit") ||
               msg.contains("smtp") {
                // The user row was created — try to sign in so the app
                // proceeds even when the dashboard email config is off.
                do {
                    try await client.auth.signIn(email: email, password: password)
                    return
                } catch {
                    throw NSError(
                        domain: "MoneyMind.Auth",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey:
                            "Account created, but email verification is unavailable right now. Try signing in instead."]
                    )
                }
            }
            throw error
        }
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

        // Fresh signup. CRITICAL: persist creds BEFORE the network call —
        // if signUp throws ("Error sending confirmation email" with no
        // SMTP configured), the user row is STILL created in Supabase.
        // Saving the creds first means next launch's saved-creds path
        // can sign in instead of creating yet another orphan user.
        let email = "debug-\(UUID().uuidString.prefix(8))@awarebudget.test"
        let password = "Dbg-\(UUID().uuidString.prefix(12))"
        defaults.set(email, forKey: "debugEmail")
        defaults.set(password, forKey: "debugPassword")
        do {
            try await client.auth.signUp(email: String(email), password: String(password))
            if let uid = await currentUserId {
                await MainActor.run { Self.debugAuthStatus = "signed up · \(String(uid.uuidString.prefix(8)))" }
                print("[DEBUG AUTH] signed up: \(uid)")
            } else {
                // signUp returned but no session — try sign-in fallback.
                do {
                    try await client.auth.signIn(email: String(email), password: String(password))
                    if let uid = await currentUserId {
                        await MainActor.run { Self.debugAuthStatus = "signed up + signed in · \(String(uid.uuidString.prefix(8)))" }
                        print("[DEBUG AUTH] signed up + signed in: \(uid)")
                    }
                } catch {
                    await MainActor.run { Self.debugAuthStatus = "signup OK but sign-in failed (email confirmation?)" }
                    print("[DEBUG AUTH] signup returned but sign-in failed — email confirmation likely required")
                }
            }
        } catch {
            // Signup failed — but the user row may STILL have been created
            // (this happens when SMTP is broken). Try sign-in with the
            // creds we just saved, which works when the row exists.
            print("[DEBUG AUTH] signup threw: \(error.localizedDescription) — trying sign-in")
            do {
                try await client.auth.signIn(email: String(email), password: String(password))
                if let uid = await currentUserId {
                    await MainActor.run { Self.debugAuthStatus = "signup err, signed in · \(String(uid.uuidString.prefix(8)))" }
                    print("[DEBUG AUTH] recovered via sign-in: \(uid)")
                }
            } catch {
                // Both failed — clear the bad creds so next launch tries fresh.
                defaults.removeObject(forKey: "debugEmail")
                defaults.removeObject(forKey: "debugPassword")
                await MainActor.run { Self.debugAuthStatus = "signup + signin FAILED: \(error.localizedDescription)" }
                print("[DEBUG AUTH] signup + sign-in both failed: \(error)")
            }
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

    /// Retag a money event's behaviour_tag. Used when user says "No,
    /// different reason" in the bias review and picks an alternative bias —
    /// the original tag was wrong, so we overwrite it.
    func retagMoneyEvent(id: UUID, newTag: String) async throws {
        struct Patch: Encodable { let behaviour_tag: String }
        try await client.from("money_events")
            .update(Patch(behaviour_tag: newTag))
            .eq("id", value: id.uuidString)
            .execute()
    }

    /// Store the user's free-text reason on a money event (when the alt-picker
    /// "Other — doesn't fit" path is taken and they typed a reason).
    func appendEventNote(id: UUID, note: String) async throws {
        struct Patch: Encodable { let note: String }
        try await client.from("money_events")
            .update(Patch(note: note))
            .eq("id", value: id.uuidString)
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

    // MARK: - Finance tracking (manual entry — no bank API)

    struct MonthlyIncome: Codable, Hashable {
        let monthly_income: Double
    }

    struct BalanceSnapshot: Identifiable, Codable, Hashable {
        let id: UUID
        var savings_balance: Double
        var investment_balance: Double
        var recorded_at: Date
    }

    /// Get the user's stored monthly income. Returns 0 if never set.
    func fetchMonthlyIncome() async throws -> Double {
        guard let uid = await currentUserId else { return 0 }
        let rows: [MonthlyIncome] = try await client.from("user_monthly_income")
            .select("monthly_income")
            .eq("user_id", value: uid.uuidString)
            .limit(1)
            .execute()
            .value
        return rows.first?.monthly_income ?? 0
    }

    /// Upsert the monthly income — set-once, editable any time.
    /// Manual entry only; no bank API. Privacy Act is the only
    /// compliance surface (see docs/ALGORITHM.md §10.5).
    func saveMonthlyIncome(_ amount: Double) async throws {
        guard let uid = await currentUserId else { return }
        struct Row: Encodable {
            let user_id: String
            let monthly_income: Double
        }
        try await client.from("user_monthly_income")
            .upsert(Row(user_id: uid.uuidString, monthly_income: amount),
                    onConflict: "user_id")
            .execute()
    }

    /// Insert OR update today's snapshot. UNIQUE(user_id, recorded_at)
    /// means re-entering on the same day overwrites instead of stacking.
    func saveBalanceSnapshot(savings: Double, investment: Double) async throws {
        guard let uid = await currentUserId else { return }
        struct Row: Encodable {
            let user_id: String
            let savings_balance: Double
            let investment_balance: Double
            let recorded_at: String
        }
        let today = ISO8601DateFormatter.dateOnly.string(from: Date())
        try await client.from("user_balance_snapshots")
            .upsert(Row(
                user_id: uid.uuidString,
                savings_balance: savings,
                investment_balance: investment,
                recorded_at: today
            ), onConflict: "user_id,recorded_at")
            .execute()
    }

    /// Fetch the trend window — used by Insights to plot the
    /// net-worth line. Returns oldest → newest.
    func fetchBalanceSnapshots(monthsBack: Int = 6) async throws -> [BalanceSnapshot] {
        guard let uid = await currentUserId else { return [] }
        let cutoff = Calendar.current.date(byAdding: .month, value: -monthsBack, to: Date())!
        let cutoffStr = ISO8601DateFormatter.dateOnly.string(from: cutoff)
        let rows: [BalanceSnapshot] = try await client.from("user_balance_snapshots")
            .select()
            .eq("user_id", value: uid.uuidString)
            .gte("recorded_at", value: cutoffStr)
            .order("recorded_at", ascending: true)
            .execute()
            .value
        return rows
    }

    // MARK: - Decision lessons (Layer B + C: pre-spend hint + decision helper)

    struct DecisionLesson: Identifiable, Codable, Hashable {
        let id: UUID
        var bias_name: String
        var category: String?
        var planned_status: String?
        var user_note: String?
        var counter_move: String
        var times_surfaced: Int
        var times_useful: Int
        var times_dismissed: Int
        var created_at: Date
        var last_surfaced_at: Date?
    }

    /// Bank a "Yes, that's me" review outcome as a personal decision
    /// lesson. Called from BiasReviewView once the user confirms a bias
    /// AND optionally adds a free-text note. Counter-move is pre-filled
    /// from BiasLessonsMock.howToCounter — user can edit or accept.
    func saveDecisionLesson(
        biasName: String,
        category: String?,
        plannedStatus: String?,
        userNote: String?,
        counterMove: String
    ) async throws {
        guard let uid = await currentUserId else { return }
        struct NewRow: Encodable {
            let user_id: String
            let bias_name: String
            let category: String?
            let planned_status: String?
            let user_note: String?
            let counter_move: String
        }
        let row = NewRow(
            user_id: uid.uuidString,
            bias_name: biasName,
            category: category,
            planned_status: plannedStatus,
            user_note: userNote,
            counter_move: counterMove
        )
        try await client.from("decision_lessons")
            .insert(row)
            .execute()
    }

    /// Fetch lessons relevant to a (category, status) pair. Used by the
    /// pre-spend hint banner (Layer B) and decision helper (Layer C).
    /// Ranks by usefulness rate then recency. Pass nil status to widen.
    func fetchLessons(category: String?, plannedStatus: String?) async throws -> [DecisionLesson] {
        guard let uid = await currentUserId else { return [] }
        var query = client.from("decision_lessons")
            .select()
            .eq("user_id", value: uid.uuidString)
        if let category { query = query.eq("category", value: category) }
        if let plannedStatus { query = query.eq("planned_status", value: plannedStatus) }
        let rows: [DecisionLesson] = try await query
            .order("created_at", ascending: false)
            .limit(10)
            .execute()
            .value
        return rows
    }

    /// Increment `times_surfaced` (called when the hint banner appears)
    /// or `times_useful` / `times_dismissed` per user action. Drives the
    /// usefulness-decay logic that demotes stale lessons.
    enum LessonOutcome { case surfaced, useful, dismissed }

    func recordLessonOutcome(id: UUID, outcome: LessonOutcome) async throws {
        struct Existing: Decodable {
            let times_surfaced: Int
            let times_useful: Int
            let times_dismissed: Int
        }
        let rows: [Existing] = try await client.from("decision_lessons")
            .select("times_surfaced,times_useful,times_dismissed")
            .eq("id", value: id.uuidString)
            .limit(1)
            .execute()
            .value
        guard let row = rows.first else { return }
        var updates: [String: AnyJSON] = [
            "last_surfaced_at": .string(ISO8601DateFormatter().string(from: Date()))
        ]
        switch outcome {
        case .surfaced:  updates["times_surfaced"] = .integer(row.times_surfaced + 1)
        case .useful:    updates["times_useful"] = .integer(row.times_useful + 1)
        case .dismissed: updates["times_dismissed"] = .integer(row.times_dismissed + 1)
        }
        try await client.from("decision_lessons")
            .update(updates)
            .eq("id", value: id.uuidString)
            .execute()
    }

    // MARK: - Bias mapping stats (per-user algorithm self-audit)

    /// Increment the per-(category × status × bias) outcome counter for
    /// the current user. UPSERT via .insert with onConflict to merge.
    /// Silently no-ops when offline so the local UserDefaults fallback
    /// in MappingConfirmationStats keeps working.
    func incrementMappingStat(
        category: String,
        plannedStatus: String,
        biasName: String,
        outcome: String  // "identified" | "not_sure" | "different"
    ) async throws {
        guard let uid = await currentUserId else { return }

        struct Existing: Decodable {
            let id: UUID
            let identified_count: Int
            let not_sure_count: Int
            let different_count: Int
        }

        let rows: [Existing] = try await client.from("bias_mapping_stats")
            .select("id,identified_count,not_sure_count,different_count")
            .eq("user_id", value: uid.uuidString)
            .eq("category", value: category)
            .eq("planned_status", value: plannedStatus)
            .eq("bias_name", value: biasName)
            .limit(1)
            .execute()
            .value

        let nowISO = ISO8601DateFormatter().string(from: Date())

        if let row = rows.first {
            var updates: [String: AnyJSON] = [
                "last_review_at": .string(nowISO),
            ]
            switch outcome {
            case "identified": updates["identified_count"] = .integer(row.identified_count + 1)
            case "not_sure":   updates["not_sure_count"]   = .integer(row.not_sure_count + 1)
            case "different":  updates["different_count"]  = .integer(row.different_count + 1)
            default: return
            }
            try await client.from("bias_mapping_stats")
                .update(updates)
                .eq("id", value: row.id.uuidString)
                .execute()
        } else {
            struct NewRow: Encodable {
                let user_id: String
                let category: String
                let planned_status: String
                let bias_name: String
                let identified_count: Int
                let not_sure_count: Int
                let different_count: Int
                let last_review_at: String
            }
            let new = NewRow(
                user_id: uid.uuidString,
                category: category,
                planned_status: plannedStatus,
                bias_name: biasName,
                identified_count: outcome == "identified" ? 1 : 0,
                not_sure_count:   outcome == "not_sure"   ? 1 : 0,
                different_count:  outcome == "different"  ? 1 : 0,
                last_review_at:   nowISO
            )
            try await client.from("bias_mapping_stats")
                .insert(new)
                .execute()
        }
    }

    /// Pull all of the current user's mapping confirmation stats from
    /// Supabase. Used by AlgorithmExplainerSheet's self-audit panel as
    /// the durable source of truth — UserDefaults is a local cache,
    /// this is the survives-reinstall + cross-device version.
    struct MappingStatRow: Decodable, Hashable {
        let category: String
        let planned_status: String
        let bias_name: String
        let identified_count: Int
        let not_sure_count: Int
        let different_count: Int
    }

    func fetchMappingStats() async throws -> [MappingStatRow] {
        guard let uid = await currentUserId else { return [] }
        let rows: [MappingStatRow] = try await client.from("bias_mapping_stats")
            .select("category,planned_status,bias_name,identified_count,not_sure_count,different_count")
            .eq("user_id", value: uid.uuidString)
            .execute()
            .value
        return rows
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
