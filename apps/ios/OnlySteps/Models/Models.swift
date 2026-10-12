import Foundation

// Rows and RPC results from Supabase. Column names are snake_case in
// Postgres, so each type maps them explicitly with CodingKeys.

struct Profile: Codable, Identifiable, Sendable {
    let id: UUID
    var displayName: String
    var avatarURL: String?
    var timeZone: String

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case timeZone = "time_zone"
    }
}

struct ProfileUpdate: Encodable, Sendable {
    var displayName: String?
    var timeZone: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case timeZone = "time_zone"
    }
}

/// A competition group. (Not called `Group` to avoid clashing with SwiftUI.Group.)
struct StepGroup: Codable, Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var inviteCode: String
    var timeZone: String

    static let columns = "id, name, invite_code, time_zone"

    enum CodingKeys: String, CodingKey {
        case id, name
        case inviteCode = "invite_code"
        case timeZone = "time_zone"
    }
}

struct NewGroup: Encodable, Sendable {
    let name: String
    let timeZone: String

    enum CodingKeys: String, CodingKey {
        case name
        case timeZone = "time_zone"
    }
}

/// Result row of `group_for_invite(code)`.
struct InvitePreview: Decodable, Sendable {
    let id: UUID
    let name: String
    let memberCount: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case memberCount = "member_count"
    }
}

/// The signed-in user's own `group_removals` row for a group: present when an
/// owner removed them, with any request to rejoin.
struct GroupRemoval: Decodable, Sendable {
    let requestedAt: String?
    let dismissedAt: String?

    static let columns = "requested_at, dismissed_at"

    enum CodingKeys: String, CodingKey {
        case requestedAt = "requested_at"
        case dismissedAt = "dismissed_at"
    }
}

/// Result row of `group_leaderboard(gid, week)`.
struct LeaderboardEntry: Decodable, Identifiable, Sendable {
    let userID: UUID
    let displayName: String
    let avatarURL: String?
    let totalSteps: Int
    let rank: Int

    var id: UUID { userID }

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case totalSteps = "total_steps"
        case rank
    }
}

/// One row written to `daily_steps`.
struct DailyStepsUpsert: Encodable, Sendable {
    let userID: UUID
    let day: String
    let steps: Int
    let source: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case day, steps, source
        case updatedAt = "updated_at"
    }
}
