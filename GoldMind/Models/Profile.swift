import Foundation

/// User-editable display preferences. One row per auth.users row, primary
/// key = auth.users.id (1:1, ON DELETE CASCADE). Auto-created by the
/// `on_auth_user_created` trigger on the database side, so a profile row
/// always exists for any signed-in user — fetches should never need to
/// handle the "missing row" case in normal operation.
///
/// Backed by `public.profiles` (migration 20260509120000).
struct Profile: Codable, Hashable {
    let id: UUID
    var displayName: String?
    var hideName: Bool
    var hideEmail: Bool
    var archetype: String?
    var topBiases: [String]
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case hideName    = "hide_name"
        case hideEmail   = "hide_email"
        case archetype
        case topBiases   = "top_biases"
        case createdAt   = "created_at"
        case updatedAt   = "updated_at"
    }

    // top_biases is NOT NULL on the DB side (default '{}'), but decode
    // tolerantly so older cached payloads that pre-date the column don't fail.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id           = try c.decode(UUID.self, forKey: .id)
        displayName  = try c.decodeIfPresent(String.self, forKey: .displayName)
        hideName     = try c.decode(Bool.self, forKey: .hideName)
        hideEmail    = try c.decode(Bool.self, forKey: .hideEmail)
        archetype    = try c.decodeIfPresent(String.self, forKey: .archetype)
        topBiases    = (try? c.decode([String].self, forKey: .topBiases)) ?? []
        createdAt    = try c.decode(Date.self, forKey: .createdAt)
        updatedAt    = try c.decode(Date.self, forKey: .updatedAt)
    }
}

/// Subset of `Profile` used for client-driven updates. Server fills
/// `id` and `updated_at` automatically — no need to send them.
struct ProfileUpdate: Codable {
    var displayName: String?
    var hideName: Bool?
    var hideEmail: Bool?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case hideName    = "hide_name"
        case hideEmail   = "hide_email"
    }
}
