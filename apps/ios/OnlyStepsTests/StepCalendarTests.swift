import Foundation
import Testing
@testable import OnlySteps

struct StepCalendarTests {
    let newYork = StepCalendar(timeZone: TimeZone(identifier: "America/New_York")!)
    let utc = StepCalendar(timeZone: TimeZone(identifier: "UTC")!)

    private func date(_ iso: String) throws -> Date {
        try #require(ISO8601DateFormatter().date(from: iso))
    }

    @Test func dayKeyUsesTheCalendarsTimeZone() throws {
        // 23:30 on March 8 in New York is already March 9 in UTC.
        let moment = try date("2026-03-09T03:30:00Z")
        #expect(newYork.dayKey(for: moment) == "2026-03-08")
        #expect(utc.dayKey(for: moment) == "2026-03-09")
    }

    @Test func dayKeyPadsMonthAndDay() throws {
        let moment = try date("2026-01-05T12:00:00Z")
        #expect(utc.dayKey(for: moment) == "2026-01-05")
    }

    @Test func recentDaysAreConsecutiveMidnightsEndingToday() throws {
        // Spans the DST change on March 8, 2026.
        let now = try date("2026-03-10T15:00:00Z")
        let days = newYork.recentDayStarts(count: 14, endingAt: now)

        #expect(days.count == 14)
        #expect(newYork.dayKey(for: days[0]) == "2026-02-25")
        #expect(newYork.dayKey(for: days[13]) == "2026-03-10")
        #expect(Set(days.map(newYork.dayKey)).count == 14)
        for day in days {
            #expect(newYork.calendar.startOfDay(for: day) == day)
        }
    }

    @Test func recentDaysWithZeroCountIsEmpty() throws {
        #expect(utc.recentDayStarts(count: 0, endingAt: .now).isEmpty)
    }

    @Test(arguments: [
        ("2026-10-11T16:00:00Z", "2026-10-05"), // Sunday -> previous Monday
        ("2026-10-12T16:00:00Z", "2026-10-12"), // Monday -> same day
        ("2026-10-14T16:00:00Z", "2026-10-12"), // Wednesday
    ])
    func weekStartsOnMonday(moment: String, expectedMonday: String) throws {
        let start = try newYork.weekStart(containing: date(moment))
        #expect(newYork.dayKey(for: start) == expectedMonday)
    }

    @Test func daysThisWeekRunFromMondayToToday() throws {
        let days = try newYork.daysThisWeek(endingAt: date("2026-10-14T16:00:00Z"))
        #expect(days.map(newYork.dayKey) == ["2026-10-12", "2026-10-13", "2026-10-14"])
    }
}

struct InviteLinkTests {
    @Test func buildsInviteURL() throws {
        let base = try #require(URL(string: "https://onlysteps.app"))
        #expect(InviteLink.url(for: "abc123", base: base).absoluteString == "https://onlysteps.app/join/abc123")
    }

    @Test(arguments: [
        ("https://onlysteps.app/join/abc123", "abc123"),
        ("https://onlysteps.app/join/ABC123/", "abc123"),
        ("onlysteps://join/abc123", "abc123"),
    ])
    func parsesInviteCode(link: String, expected: String) throws {
        let url = try #require(URL(string: link))
        #expect(InviteLink.code(from: url) == expected)
    }

    @Test func ignoresOtherLinks() throws {
        let other = try #require(URL(string: "https://onlysteps.app/groups"))
        let missingCode = try #require(URL(string: "https://onlysteps.app/join"))
        #expect(InviteLink.code(from: other) == nil)
        #expect(InviteLink.code(from: missingCode) == nil)
    }

    @Test func normalizesTypedInput() {
        #expect(InviteLink.normalize("  AbC123 \n") == "abc123")
        #expect(InviteLink.normalize("https://onlysteps.app/join/xyz789") == "xyz789")
    }
}

struct InitialsTests {
    @Test func initials() {
        #expect(Initials.from("Ada Lovelace") == "AL")
        #expect(Initials.from("grace brewster hopper") == "GH")
        #expect(Initials.from("Cher") == "C")
        #expect(Initials.from("   ") == "?")
    }
}
