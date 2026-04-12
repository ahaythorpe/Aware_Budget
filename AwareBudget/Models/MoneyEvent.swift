import Foundation

struct MoneyEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var amount: Double
    var plannedStatus: PlannedStatus
    var behaviourTag: String?
    var lifeEvent: String?
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
        case createdAt = "created_at"
    }
}
