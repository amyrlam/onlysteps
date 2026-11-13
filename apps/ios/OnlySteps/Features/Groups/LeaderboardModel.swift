import Foundation
import Observation
import Supabase

@MainActor
@Observable
final class LeaderboardModel {
    let groupID: UUID
    /// Weeks run Monday to Sunday in the group's time zone.
    let timeZone: TimeZone
    /// 0 is this week, -1 is last week, and so on.
    private(set) var weekOffset = 0
    private(set) var entries: [LeaderboardEntry] = []
    private(set) var hasLoaded = false
    var errorMessage: String?

    init(groupID: UUID, timeZone: String) {
        self.groupID = groupID
        self.timeZone = TimeZone(identifier: timeZone) ?? .current
    }

    /// The Monday that starts the week being shown.
    var weekStart: Date {
        let calendar = StepCalendar(timeZone: timeZone)
        let thisWeek = calendar.weekStart(containing: .now)
        return calendar.calendar.date(byAdding: .day, value: weekOffset * 7, to: thisWeek) ?? thisWeek
    }

    /// Switches to another week; the future is not offered.
    func showWeek(offset: Int) async {
        weekOffset = min(0, offset)
        await load()
    }

    /// Loads the standings for the week being shown.
    func load() async {
        do {
            // Without a week the database uses the current one.
            var params = ["gid": groupID.uuidString]
            if weekOffset != 0 {
                params["week"] = StepCalendar(timeZone: timeZone).dayKey(for: weekStart)
            }
            entries = try await supabase
                .rpc("group_leaderboard", params: params)
                .fetchValue()
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
