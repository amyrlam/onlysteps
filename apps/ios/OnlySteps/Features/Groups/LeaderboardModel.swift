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
    /// Who has walked the most this month and this year.
    private(set) var records: [StepRecord] = []
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

    /// Totals every member's days since January 1 to find the month's and
    /// the year's leader. Call after `load()`, which supplies the names.
    func loadRecords() async {
        let members = entries
        guard !members.isEmpty else { return }
        let today = StepCalendar(timeZone: timeZone).dayKey(for: .now)
        let year = String(today.prefix(4)), month = String(today.prefix(7))
        do {
            // The API returns at most 1,000 rows at a time.
            var days: [StepDay] = []
            while true {
                let page: [StepDay] = try await supabase
                    .from("daily_steps")
                    .select("user_id, day, steps")
                    .in("user_id", values: members.map(\.userID.uuidString))
                    .gte("day", value: "\(year)-01-01")
                    .order("day")
                    .order("user_id")
                    .range(from: days.count, to: days.count + 999)
                    .fetchValue()
                days += page
                if page.count < 1000 { break }
            }
            func leader(_ title: String, prefix: String) -> StepRecord? {
                var totals: [UUID: Int] = [:]
                for day in days where day.day.hasPrefix(prefix) { totals[day.userID, default: 0] += day.steps }
                guard let top = totals.max(by: { $0.value < $1.value }), top.value > 0,
                      let member = members.first(where: { $0.userID == top.key }) else { return nil }
                return StepRecord(title: title, entry: member, steps: top.value)
            }
            records = [
                leader("Most steps in \(Date.now.formatted(.dateTime.month(.wide)))", prefix: month),
                leader("Most steps in \(year)", prefix: year),
            ].compactMap { $0 }
        } catch {
            print("Loading records failed: \(error)")
        }
    }

    /// Uploads fresh steps from Health first, then reloads.
    func refresh() async {
        await StepSync.shared.syncRecentDays()
        await load()
    }
}

/// One line of the records card.
struct StepRecord: Identifiable {
    let title: String
    let entry: LeaderboardEntry
    let steps: Int

    var id: String { title }
}

/// A row of `daily_steps`.
private struct StepDay: Decodable, Sendable {
    let userID: UUID
    let day: String
    let steps: Int

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case day, steps
    }
}
