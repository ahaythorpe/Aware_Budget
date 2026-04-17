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

    /// Explicit memberwise init — needed because adding the custom
    /// `init(from:)` below suppresses Swift's synthesised one, which
    /// DemoDataService + MoneyEventViewModel rely on.
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

    private static let localDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(userId, forKey: .userId)
        try c.encode(Self.localDateFormatter.string(from: date), forKey: .date)
        try c.encode(amount, forKey: .amount)
        try c.encode(plannedStatus, forKey: .plannedStatus)
        try c.encodeIfPresent(behaviourTag, forKey: .behaviourTag)
        try c.encodeIfPresent(lifeEvent, forKey: .lifeEvent)
        try c.encodeIfPresent(lifeArea, forKey: .lifeArea)
        try c.encodeIfPresent(note, forKey: .note)
        try c.encode(createdAt, forKey: .createdAt)
    }

    /// Per-model tolerant decoder — safety net in case the global
    /// SupabaseClient JSONDecoder isn't actually respected by the
    /// Postgrest Swift SDK (it uses its own internal decoder for
    /// some return paths). Without this, money_events.date as a
    /// bare "2026-04-16" string fails decode silently → Home shows
    /// "0 EVENTS" even when the data is sitting in Supabase. This
    /// regressed when the global decoder was assumed sufficient.
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

    private static let isoParserFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private static let isoParserNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static func decodeFlexibleDate(
        from c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Date {
        // Try Date directly first (works if the global decoder strategy fired).
        if let d = try? c.decode(Date.self, forKey: key) { return d }
        // Fall back to manual string parse covering all formats Postgres
        // emits (DATE, TIMESTAMPTZ with/without fractional seconds, with
        // optional space-T swap).
        let s = try c.decode(String.self, forKey: key)
        if let d = isoParserFrac.date(from: s) { return d }
        if let d = isoParserNoFrac.date(from: s) { return d }
        if let d = dateOnlyParser.date(from: s) { return d }
        let normalized = s.replacingOccurrences(of: " ", with: "T")
        if let d = isoParserFrac.date(from: normalized) { return d }
        if let d = isoParserNoFrac.date(from: normalized) { return d }
        throw DecodingError.dataCorruptedError(
            forKey: key, in: c,
            debugDescription: "MoneyEvent date '\(s)' didn't match any expected format"
        )
    }
}
