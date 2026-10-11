import Foundation

/// Pure date helpers for step days and weeks. Kept free of HealthKit and
/// networking so it can be unit tested.
///
/// Days are keyed as `yyyy-MM-dd` in the person's own time zone, which is
/// what the `daily_steps.day` column stores. Weeks start on Monday.
struct StepCalendar: Sendable {
    let calendar: Calendar

    init(timeZone: TimeZone = .current) {
        // Always Gregorian, so the key matches Postgres `date` regardless of
        // the calendar chosen in the person's device settings.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        calendar.locale = Locale(identifier: "en_US_POSIX")
        self.calendar = calendar
    }

    /// `yyyy-MM-dd` for the calendar day containing `date`.
    func dayKey(for date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(pad(parts.year ?? 0, 4))-\(pad(parts.month ?? 0, 2))-\(pad(parts.day ?? 0, 2))"
    }

    /// Local midnights for the last `count` days, oldest first, ending with today.
    func recentDayStarts(count: Int, endingAt now: Date) -> [Date] {
        guard count > 0 else { return [] }
        let today = calendar.startOfDay(for: now)
        return (0..<count).reversed().compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }
    }

    /// Local midnight of the Monday that starts the week containing `date`.
    func weekStart(containing date: Date) -> Date {
        let today = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: today) // 1 = Sunday ... 7 = Saturday
        let daysSinceMonday = (weekday + 5) % 7
        return calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) ?? today
    }

    /// Local midnights from this week's Monday through today, oldest first.
    func daysThisWeek(endingAt now: Date) -> [Date] {
        let start = weekStart(containing: now)
        let days = calendar.dateComponents([.day], from: start, to: calendar.startOfDay(for: now)).day ?? 0
        return recentDayStarts(count: days + 1, endingAt: now)
    }

    private func pad(_ value: Int, _ width: Int) -> String {
        let digits = String(value)
        return String(repeating: "0", count: max(0, width - digits.count)) + digits
    }
}
