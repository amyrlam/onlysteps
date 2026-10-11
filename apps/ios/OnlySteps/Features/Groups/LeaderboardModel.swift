import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class LeaderboardModel {
    let groupID: UUID
    private(set) var entries: [LeaderboardEntry] = []
    private(set) var hasLoaded = false
    var errorMessage: String?

    init(groupID: UUID) {
        self.groupID = groupID
    }

    /// Loads this week's standings (the week is Monday to Sunday in the group's time zone).
    func load() async {
        do {
            entries = try await supabase
                .rpc("group_leaderboard", params: ["gid": groupID.uuidString])
                .execute()
                .value
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
        hasLoaded = true
    }

    /// Uploads fresh steps from Health first, then reloads.
    func refresh() async {
        await StepSync.shared.syncRecentDays()
        await load()
    }
}
