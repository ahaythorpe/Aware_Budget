import Foundation

/// Tracks per-mapping (category × status × bias) outcomes from the
/// post-session bias review:
///   - "Yes, that's me"        → yesCount
///   - "Not sure"              → notSureCount
///   - "No, different reason"  → differentCount
///
/// **Why this file exists:** the algorithm proposes a bias, the user
/// confirms or rejects. The confirmation rate is the honesty check on
/// the mapping — if "Ego Depletion on Coffee+Impulse" lands at 75%
/// confirmation after 100 samples, the mapping is good. If it sits at
/// 25%, the mapping is wrong and needs revising.
///
/// **Storage:** local UserDefaults (one Codable dictionary keyed by
/// "category|status|bias"). Pragmatic v1 — promotes to a Supabase
/// `bias_mapping_stats` table once we have a migration window. Local
/// loss on app reinstall is acceptable for now since these are
/// algorithm-tuning signals, not user data.
///
/// **Threshold for action:** mappings with confirmation_rate < 0.30
/// after sampleSize ≥ 20 are flagged as "low-confirmation" — surfaced
/// in the algo explainer so future tuning passes can retire/refine.
enum MappingConfirmationStats {
    private static let key = "biasMappingConfirmationStats.v1"

    struct MappingKey: Hashable, Codable {
        let category: String
        let status: String   // raw value of MoneyEvent.PlannedStatus
        let bias: String

        var storageKey: String { "\(category)|\(status)|\(bias)" }
    }

    struct Stats: Codable, Hashable {
        var yesCount: Int = 0
        var notSureCount: Int = 0
        var differentCount: Int = 0

        var sampleSize: Int { yesCount + notSureCount + differentCount }
        var confirmationRate: Double {
            guard sampleSize > 0 else { return 0 }
            return Double(yesCount) / Double(sampleSize)
        }
    }

    enum Outcome { case yes, notSure, different }

    /// Record a single review outcome for a (category, status, bias)
    /// mapping. Idempotent in the sense that calling it once per
    /// review is correct — duplicate-call guards live at the call
    /// site (BiasReviewView records once per `record(entry:choice:)`).
    static func record(
        category: String,
        status: MoneyEvent.PlannedStatus,
        bias: String,
        outcome: Outcome
    ) {
        var all = loadAll()
        let key = MappingKey(category: category, status: status.rawValue, bias: bias)
        var stats = all[key.storageKey] ?? Stats()
        switch outcome {
        case .yes:       stats.yesCount += 1
        case .notSure:   stats.notSureCount += 1
        case .different: stats.differentCount += 1
        }
        all[key.storageKey] = stats
        save(all)

        let questionKey = "\(bias)_\(category)"
        recordQuestionKey(questionKey, outcome: outcome)

        // Push to Supabase fire-and-forget — survives reinstall AND
        // enables cross-user aggregation for the research deliverable.
        // Migration: 20260416180000_add_bias_mapping_stats.sql
        let outcomeStr: String = {
            switch outcome {
            case .yes:       return "identified"
            case .notSure:   return "not_sure"
            case .different: return "different"
            }
        }()
        Task {
            try? await SupabaseService.shared.incrementMappingStat(
                category: category,
                plannedStatus: status.rawValue,
                biasName: bias,
                outcome: outcomeStr
            )
        }
    }

    static func stats(category: String, status: MoneyEvent.PlannedStatus, bias: String) -> Stats {
        let key = MappingKey(category: category, status: status.rawValue, bias: bias)
        return loadAll()[key.storageKey] ?? Stats()
    }

    /// Async hydrate the local cache from Supabase. Fire-and-forget
    /// from any view that wants the freshest stats — e.g.
    /// AlgorithmExplainerSheet.task. Silently skipped if offline or
    /// no session.
    static func refreshFromRemote() async {
        do {
            let rows = try await SupabaseService.shared.fetchMappingStats()
            var merged = loadAll()
            for row in rows {
                let key = MappingKey(category: row.category, status: row.planned_status, bias: row.bias_name)
                merged[key.storageKey] = Stats(
                    yesCount: row.identified_count,
                    notSureCount: row.not_sure_count,
                    differentCount: row.different_count
                )
            }
            save(merged)
        } catch {
            // Offline / RLS / no session — local cache remains as-is.
        }
    }

    /// All mappings flagged as low-confirmation (rate < 0.30 with
    /// sample ≥ 20). Returned sorted by sample size desc — biggest
    /// evidence base first.
    static func lowConfirmationMappings(threshold: Double = 0.30, minSamples: Int = 20)
    -> [(key: MappingKey, stats: Stats)] {
        let all = loadAll()
        var flagged: [(MappingKey, Stats)] = []
        for (storageKey, stats) in all {
            guard stats.sampleSize >= minSamples,
                  stats.confirmationRate < threshold else { continue }
            let parts = storageKey.split(separator: "|").map(String.init)
            guard parts.count == 3 else { continue }
            let key = MappingKey(category: parts[0], status: parts[1], bias: parts[2])
            flagged.append((key, stats))
        }
        return flagged.sorted { $0.1.sampleSize > $1.1.sampleSize }
    }

    // MARK: - Storage

    private static func loadAll() -> [String: Stats] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: Stats].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func save(_ all: [String: Stats]) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Per-question tracking

    private static let questionKey = "biasQuestionConfirmation.v1"

    static func recordQuestionKey(_ qKey: String, outcome: Outcome) {
        var all = loadQuestionStats()
        var stats = all[qKey] ?? Stats()
        switch outcome {
        case .yes:       stats.yesCount += 1
        case .notSure:   stats.notSureCount += 1
        case .different: stats.differentCount += 1
        }
        all[qKey] = stats
        saveQuestionStats(all)
    }

    static func questionStats(for qKey: String) -> Stats {
        loadQuestionStats()[qKey] ?? Stats()
    }

    static func lowConfirmationQuestions(threshold: Double = 0.30, minSamples: Int = 20)
    -> [(questionKey: String, stats: Stats)] {
        loadQuestionStats()
            .filter { $0.value.sampleSize >= minSamples && $0.value.confirmationRate < threshold }
            .map { (questionKey: $0.key, stats: $0.value) }
            .sorted { $0.stats.sampleSize > $1.stats.sampleSize }
    }

    private static func loadQuestionStats() -> [String: Stats] {
        guard let data = UserDefaults.standard.data(forKey: questionKey),
              let decoded = try? JSONDecoder().decode([String: Stats].self, from: data)
        else { return [:] }
        return decoded
    }

    private static func saveQuestionStats(_ all: [String: Stats]) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        UserDefaults.standard.set(data, forKey: questionKey)
    }
}
