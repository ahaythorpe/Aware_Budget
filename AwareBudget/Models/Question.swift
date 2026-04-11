import Foundation

struct Question: Identifiable, Codable, Hashable {
    let id: UUID
    var question: String
    var whyExplanation: String
    var biasName: String
    var biasCategory: String
    var difficulty: String
    var lastShown: Date?

    enum CodingKeys: String, CodingKey {
        case id, question, difficulty
        case whyExplanation = "why_explanation"
        case biasName = "bias_name"
        case biasCategory = "bias_category"
        case lastShown = "last_shown"
    }
}
