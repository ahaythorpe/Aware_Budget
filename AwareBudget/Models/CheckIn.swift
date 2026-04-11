import Foundation

struct CheckIn: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var date: Date
    var questionId: UUID?
    var response: String?
    var emotionalTone: EmotionalTone
    var streakCount: Int
    var alignmentPct: Double
    var createdAt: Date

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
            case .calm: return "🌿"
            case .neutral: return "😌"
            case .anxious: return "😣"
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, date, response
        case userId = "user_id"
        case questionId = "question_id"
        case emotionalTone = "emotional_tone"
        case streakCount = "streak_count"
        case alignmentPct = "alignment_pct"
        case createdAt = "created_at"
    }
}
