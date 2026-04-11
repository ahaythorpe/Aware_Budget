import Foundation

struct MonthlyDecision: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var month: Date
    var decision: String?
    var insight: String?
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, month, decision, insight
        case userId = "user_id"
        case createdAt = "created_at"
    }
}
