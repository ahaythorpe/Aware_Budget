import Foundation

struct MoneyEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var amount: Double
    var plannedStatus: PlannedStatus
    var behaviourTag: String?
    var lifeEvent: String?
    var lifeArea: String?
    var note: String?
    var createdAt: Date

    // MARK: - Planned status (replaces old category system)

    enum PlannedStatus: String, Codable, CaseIterable, Identifiable {
        case planned, surprise, impulse
        var id: String { rawValue }

        var label: String {
            switch self {
            case .planned:  return "Planned"
            case .surprise: return "Surprise"
            case .impulse:  return "Impulse"
            }
        }

        var emoji: String {
            switch self {
            case .planned:  return "\u{2713}"
            case .surprise: return "\u{26A1}"
            case .impulse:  return "\u{1F3AF}"
            }
        }

        var isUnplanned: Bool {
            self != .planned
        }
    }

    // MARK: - Life events (shown when amount > 200)

    enum LifeEvent: String, Codable, CaseIterable, Identifiable {
        case jobChange      = "job_change"
        case unexpectedBill = "unexpected_bill"
        case medical        = "medical"
        case windfall       = "windfall"
        case otherBig       = "other_big"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .jobChange:      return "Job/income change"
            case .unexpectedBill: return "Unexpected bill"
            case .medical:        return "Medical"
            case .windfall:       return "Windfall"
            case .otherBig:       return "Other big event"
            }
        }
    }

    // MARK: - Size bucket (derived, not stored)

    enum SizeBucket {
        case small, medium, large

        var label: String {
            switch self {
            case .small:  return "Small"
            case .medium: return "Medium"
            case .large:  return "Large"
            }
        }
    }

    var sizeBucket: SizeBucket {
        switch amount {
        case ..<50:    return .small
        case 50..<200: return .medium
        default:       return .large
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, amount, note
        case userId = "user_id"
        case plannedStatus = "planned_status"
        case behaviourTag = "behaviour_tag"
        case lifeEvent = "life_event"
        case lifeArea = "life_area"
        case createdAt = "created_at"
    }

    /// Explicit memberwise init — restored because the custom
    /// `init(from:)` below suppresses Swift's synthesised one.
    /// Callers (DemoDataService, MoneyEventViewModel) need this.
    init(
        id: UUID,
        userId: UUID,
        date: Date,
        amount: Double,
        plannedStatus: PlannedStatus,
        behaviourTag: String? = nil,
        lifeEvent: String? = nil,
        lifeArea: String? = nil,
        note: String? = nil,
        createdAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.amount = amount
        self.plannedStatus = plannedStatus
        self.behaviourTag = behaviourTag
        self.lifeEvent = lifeEvent
        self.lifeArea = lifeArea
        self.note = note
        self.createdAt = createdAt
    }

    /// Tolerant decoder. Supabase returns the `date` column as a bare
    /// "2026-04-16" string (DATE type, no time component), but the
    /// default Codable Date decoder expects a full ISO8601 timestamp.
    /// Without this, every fetchMoneyEvents returns [] silently and
    /// Home/Insights look empty even though events save correctly.
    /// We try ISO8601-with-time first (covers `created_at`) then fall
    /// back to date-only parsing (covers `date`).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        userId = try c.decode(UUID.self, forKey: .userId)
        date = try MoneyEvent.decodeFlexibleDate(from: c, key: .date)
        amount = try c.decode(Double.self, forKey: .amount)
        plannedStatus = try c.decode(PlannedStatus.self, forKey: .plannedStatus)
        behaviourTag = try c.decodeIfPresent(String.self, forKey: .behaviourTag)
        lifeEvent = try c.decodeIfPresent(String.self, forKey: .lifeEvent)
        lifeArea = try c.decodeIfPresent(String.self, forKey: .lifeArea)
        note = try c.decodeIfPresent(String.self, forKey: .note)
        createdAt = try MoneyEvent.decodeFlexibleDate(from: c, key: .createdAt)
    }

    private static let dateOnlyParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static func decodeFlexibleDate(
        from c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Date {
        // Try Date directly (works for ISO8601 timestamp via default).
        if let d = try? c.decode(Date.self, forKey: key) { return d }
        // Fall back to a "YYYY-MM-DD" string — Supabase DATE columns.
        let s = try c.decode(String.self, forKey: key)
        if let d = dateOnlyParser.date(from: s) { return d }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: c,
            debugDescription: "MoneyEvent date '\(s)' isn't ISO8601 or YYYY-MM-DD"
        )
    }
}
