import Foundation

struct BudgetMonth: Identifiable, Codable, Hashable {
    let id: UUID
    var userId: UUID
    var month: Date
    var incomeTarget: Double
    var createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, month
        case userId = "user_id"
        case incomeTarget = "income_target"
        case createdAt = "created_at"
    }
}
