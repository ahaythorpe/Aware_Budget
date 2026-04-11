import Foundation

struct MoneyEvent: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var amount: Double
    var category: String?
    var eventType: EventType
    var note: String?
    var createdAt: Date

    enum EventType: String, Codable, CaseIterable, Identifiable {
        case surprise, win, expected
        var id: String { rawValue }

        var label: String {
            switch self {
            case .surprise: return "Surprise"
            case .win: return "Win"
            case .expected: return "Expected"
            }
        }

        var emoji: String {
            switch self {
            case .surprise: return "⚡"
            case .win: return "🎉"
            case .expected: return "📅"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, amount, category, note
        case userId = "user_id"
        case eventType = "event_type"
        case createdAt = "created_at"
    }
}

enum MoneyCategory: String, CaseIterable, Identifiable {
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case bills = "Bills"
    case income = "Income"
    case health = "Health"
    case entertainment = "Entertainment"
    case other = "Other"

    var id: String { rawValue }
}
