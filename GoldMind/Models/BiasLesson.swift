import Foundation

struct BiasLesson: Identifiable, Codable, Hashable {
    let id: UUID
    var biasName: String
    var displayName: String { biasName.replacingOccurrences(of: "Heuristic", with: "Shortcut") }
    var category: String
    var shortDescription: String
    var fullExplanation: String
    var realWorldExample: String
    var howToCounter: String

    var emoji: String
    var sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, category, emoji
        case biasName = "bias_name"
        case shortDescription = "short_description"
        case fullExplanation = "full_explanation"
        case realWorldExample = "real_world_example"
        case howToCounter = "how_to_counter"
        case sortOrder = "sort_order"
    }
}












