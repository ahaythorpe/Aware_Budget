import Foundation

// NOTE: Once the Supabase Swift package is added via
// File → Add Package Dependencies → https://github.com/supabase/supabase-swift
// uncomment the `import Supabase` line and the real client wiring below.
// A local in-memory stub is provided so the app builds and runs before the
// package is added.

// import Supabase

@MainActor
final class SupabaseService {
    static let shared = SupabaseService()

    // Public values — safe to ship in the client.
    // Project ref: vdnnoezyogbgtiubamze (region: Asia-Pacific)
    private let supabaseURL = URL(string: "https://vdnnoezyogbgtiubamze.supabase.co")!
    private let supabaseAnonKey = "sb_publishable_lwuCqoY6jpKRwQRJoqZYFQ_CiavSWwH"

    // let client: SupabaseClient

    private init() {
        // self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
    }

    // MARK: - Stub user session

    private(set) var currentUserId: UUID? = UUID(uuidString: "00000000-0000-0000-0000-000000000001")

    // MARK: - Stub data stores (replace with real Supabase queries)

    private var checkIns: [CheckIn] = []
    private var events: [MoneyEvent] = []
    private var budgetMonths: [BudgetMonth] = []
    private var questions: [Question] = QuestionPool.seed

    // MARK: - Auth

    func signUp(email: String, password: String) async throws {
        // TODO: replace with client.auth.signUp(email:password:)
        currentUserId = UUID()
    }

    func signIn(email: String, password: String) async throws {
        // TODO: replace with client.auth.signIn(email:password:)
        currentUserId = UUID()
    }

    func signOut() async throws {
        // TODO: replace with client.auth.signOut()
        currentUserId = nil
    }

    // MARK: - Check-ins

    func saveCheckIn(_ checkIn: CheckIn) async throws {
        checkIns.removeAll { Calendar.current.isDate($0.date, inSameDayAs: checkIn.date) && $0.userId == checkIn.userId }
        checkIns.append(checkIn)
    }

    func fetchTodaysCheckIn() async throws -> CheckIn? {
        guard let uid = currentUserId else { return nil }
        return checkIns.first {
            $0.userId == uid && Calendar.current.isDateInToday($0.date)
        }
    }

    func fetchCheckIn(on date: Date) async throws -> CheckIn? {
        guard let uid = currentUserId else { return nil }
        return checkIns.first {
            $0.userId == uid && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }

    func fetchRecentCheckIns(limit: Int) async throws -> [CheckIn] {
        guard let uid = currentUserId else { return [] }
        return checkIns
            .filter { $0.userId == uid }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Money events

    func saveMoneyEvent(_ event: MoneyEvent) async throws {
        events.append(event)
    }

    func fetchMoneyEvents(forMonth month: Date) async throws -> [MoneyEvent] {
        guard let uid = currentUserId else { return [] }
        let cal = Calendar.current
        return events
            .filter { $0.userId == uid && cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            .sorted { $0.date > $1.date }
    }

    func fetchRecentMoneyEvents(limit: Int) async throws -> [MoneyEvent] {
        guard let uid = currentUserId else { return [] }
        return events
            .filter { $0.userId == uid }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    // MARK: - Questions

    func fetchNextQuestion() async throws -> Question {
        let cal = Calendar.current
        let fourteenDaysAgo = cal.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let candidates = questions.filter { $0.lastShown == nil || $0.lastShown! < fourteenDaysAgo }
        let pool = candidates.isEmpty ? questions : candidates
        let picked = pool.min(by: { ($0.lastShown ?? .distantPast) < ($1.lastShown ?? .distantPast) }) ?? pool[0]

        if let idx = questions.firstIndex(where: { $0.id == picked.id }) {
            questions[idx].lastShown = Date()
        }
        return picked
    }

    // MARK: - Budget months

    func fetchOrCreateBudgetMonth(for date: Date) async throws -> BudgetMonth {
        guard let uid = currentUserId else {
            throw NSError(domain: "SupabaseService", code: 401, userInfo: [NSLocalizedDescriptionKey: "No signed-in user"])
        }
        let cal = Calendar.current
        if let existing = budgetMonths.first(where: {
            $0.userId == uid && cal.isDate($0.month, equalTo: date, toGranularity: .month)
        }) {
            return existing
        }
        let startOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
        let new = BudgetMonth(
            id: UUID(),
            userId: uid,
            month: startOfMonth,
            incomeTarget: 0,
            createdAt: Date()
        )
        budgetMonths.append(new)
        return new
    }

    func updateIncomeTarget(_ amount: Double, for month: Date) async throws {
        guard let uid = currentUserId else { return }
        let cal = Calendar.current
        if let idx = budgetMonths.firstIndex(where: {
            $0.userId == uid && cal.isDate($0.month, equalTo: month, toGranularity: .month)
        }) {
            budgetMonths[idx].incomeTarget = amount
        }
    }
}
