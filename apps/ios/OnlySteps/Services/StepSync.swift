import Foundation
@preconcurrency import HealthKit
import os
import Supabase

/// Steps for one local calendar day.
struct DayTotal: Sendable {
    let day: Date
    let steps: Int
}

/// Reads step counts from Apple Health and uploads daily totals to Supabase.
///
/// - `activate()` asks for permission (once), starts observing, and syncs.
/// - An `HKObserverQuery` with hourly background delivery wakes the app when
///   new steps are saved, even if it is not running.
/// - The app also calls `syncRecentDays()` whenever it comes to the foreground.
actor StepSync {
    static let shared = StepSync()

    /// How many recent days are re-uploaded on each sync.
    static let syncWindowDays = 14
    /// Matches the `daily_steps.steps` check constraint.
    private static let maxStepsPerDay = 200_000

    private let store = HKHealthStore()
    private let stepType = HKQuantityType(.stepCount)
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OnlySteps", category: "StepSync")
    private var observerQuery: HKObserverQuery?
    private var runningSync: Task<Void, Never>?

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    /// Call after sign-in. Shows the Health permission sheet the first time.
    func activate() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: [stepType])
        } catch {
            logger.error("Health authorization failed: \(error.localizedDescription, privacy: .public)")
            return
        }
        await startObserving()
        await syncRecentDays()
    }

    /// Call at launch (including background launches) so background delivery
    /// has an observer to call. Does nothing until permission was requested once.
    func startObservingIfAuthorized() async {
        guard isAvailable else { return }
        let status = try? await store.statusForAuthorizationRequest(toShare: [], read: [stepType])
        if status == .unnecessary {
            await startObserving()
        }
    }

    /// Uploads the last `syncWindowDays` days. Concurrent calls share one run.
    func syncRecentDays() async {
        if let runningSync {
            await runningSync.value
            return
        }
        let task = Task { await performSync() }
        runningSync = task
        await task.value
        runningSync = nil
    }

    /// Today's steps and this week's total (Monday to today), read locally.
    func localSummary(now: Date = .now) async throws -> (today: Int, week: Int) {
        let days = StepCalendar().daysThisWeek(endingAt: now)
        let totals = try await dailyTotals(for: days, until: now)
        return (totals.last?.steps ?? 0, totals.reduce(0) { $0 + $1.steps })
    }

    // MARK: - Private

    private func startObserving() async {
        guard observerQuery == nil else { return }

        // Explicitly @Sendable: HealthKit calls this on a background queue,
        // so it must not be isolated to this actor.
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { @Sendable _, completionHandler, error in
            let done = ObserverCompletion(completionHandler)
            guard error == nil else {
                done()
                return
            }
            Task {
                await StepSync.shared.syncRecentDays()
                done() // Tell HealthKit we finished, or it backs off future wake-ups.
            }
        }
        observerQuery = query
        store.execute(query)

        do {
            try await store.enableBackgroundDelivery(for: stepType, frequency: .hourly)
        } catch {
            logger.error("Background delivery failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func performSync() async {
        guard isAvailable else { return }
        guard let userID = try? await supabase.auth.session.user.id else { return } // signed out

        let now = Date.now
        let calendar = StepCalendar()
        let days = calendar.recentDayStarts(count: Self.syncWindowDays, endingAt: now)

        do {
            let totals = try await dailyTotals(for: days, until: now)
            let updatedAt = now.ISO8601Format()
            // Days with zero steps are skipped so a device without Health data
            // (or with permission denied) never overwrites real totals.
            let rows = totals.filter { $0.steps > 0 }.map {
                DailyStepsUpsert(
                    userID: userID,
                    day: calendar.dayKey(for: $0.day),
                    steps: min($0.steps, Self.maxStepsPerDay),
                    source: "healthkit",
                    updatedAt: updatedAt
                )
            }
            guard !rows.isEmpty else { return }
            try await supabase
                .from("daily_steps")
                .upsert(rows, onConflict: "user_id,day")
                .execute()
            logger.info("Synced \(rows.count) days of steps")
        } catch {
            logger.error("Step sync failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Sums steps per local day. `days` must be consecutive local midnights.
    private func dailyTotals(for days: [Date], until end: Date) async throws -> [DayTotal] {
        guard let first = days.first else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: first, end: end, options: .strictStartDate)
        let descriptor = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: stepType, predicate: predicate),
            options: .cumulativeSum, // merges iPhone + Apple Watch without double counting
            anchorDate: first,
            intervalComponents: DateComponents(day: 1)
        )
        let collection = try await descriptor.result(for: store)
        return days.map { day in
            let count = collection.statistics(for: day)?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            return DayTotal(day: day, steps: Int(count.rounded()))
        }
    }
}

/// Wraps HealthKit's observer completion handler so it can be called from a Task.
/// HealthKit allows calling it from any thread.
private struct ObserverCompletion: @unchecked Sendable {
    private let handler: () -> Void
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func callAsFunction() { handler() }
}
