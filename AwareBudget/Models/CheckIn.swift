import Foundation

struct CheckIn: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var questionId: UUID?
    var response: String?
    var emotionalTone: EmotionalTone
    var spendingDriver: SpendingDriver?
    var streakCount: Int
    var alignmentPct: Double
    var createdAt: Date

    // MARK: - Spending drivers ("What drove this decision?")

    enum SpendingDriver: String, Codable, CaseIterable, Identifiable {
        case presentBias    = "present_bias"
        case social         = "social"
        case emotional      = "emotional"
        case convenience    = "convenience"
        case identity       = "identity"
        case frictionAvoid  = "friction_avoid"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .presentBias:   return "Present Bias"
            case .social:        return "Social"
            case .emotional:     return "Reward"
            case .convenience:   return "Convenience"
            case .identity:      return "Identity"
            case .frictionAvoid: return "Friction"
            }
        }

        var shortDescription: String {
            switch self {
            case .presentBias:   return "I want this now"
            case .social:        return "Others are doing it"
            case .emotional:     return "I deserve this"
            case .convenience:   return "This is easier"
            case .identity:      return "This reflects who I am"
            case .frictionAvoid: return "Too hard to change"
            }
        }

        var emoji: String {
            switch self {
            case .presentBias:   return "⚡"
            case .social:        return "👥"
            case .emotional:     return "🎁"
            case .convenience:   return "🛋️"
            case .identity:      return "🪞"
            case .frictionAvoid: return "🔒"
            }
        }
    }

    enum EmotionalTone: String, Codable, CaseIterable, Identifiable {
        case calm, anxious, neutral
        var id: String { rawValue }

        var label: String {
            switch self {
            case .calm: return "Calm"
            case .neutral: return "Neutral"
            case .anxious: return "Anxious"
            }
        }

        var emoji: String {
            switch self {
            case .calm: return "😌"
            case .neutral: return "😐"
            case .anxious: return "😟"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, response
        case userId = "user_id"
        case questionId = "question_id"
        case emotionalTone = "emotional_tone"
        case spendingDriver = "spending_driver"
        case streakCount = "streak_count"
        case alignmentPct = "alignment_pct"
        case createdAt = "created_at"
    }
}
