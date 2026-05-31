//
//  HealthKitManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 31.05.26.
//

import HealthKit
import Foundation

class HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()
    private let lastSyncKey = "healthKitLastSyncDate"

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    // MARK: - Запрос разрешения
    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        let workoutType = HKObjectType.workoutType()
        do {
            try await store.requestAuthorization(toShare: [], read: [workoutType])
            UserDefaults.standard.set(true, forKey: "healthKitAuthorizationRequested")
            if UserDefaults.standard.object(forKey: "healthKitSyncEnabled") == nil {
                isSyncEnabled = true
            }
            return true
        } catch {
            print("❌ HealthKit auth error: \(error)")
            return false
        }
    }

    func isAuthorized() -> Bool {
        guard isAvailable else { return false }
        // HealthKit не раскрывает статус чтения — просто проверяем что авторизация запрашивалась
        let key = "healthKitAuthorizationRequested"
        return UserDefaults.standard.bool(forKey: key)
    }

    // MARK: - Читаем тренировки за период
    func fetchWorkoutDays(from startDate: Date, to endDate: Date) async -> Set<String> {
        guard isAvailable else { return [] }

        return await withCheckedContinuation { continuation in
            let workoutType = HKObjectType.workoutType()
            let predicate = HKQuery.predicateForSamples(
                withStart: startDate,
                end: endDate,
                options: .strictStartDate
            )

            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                if let error = error {
                    print("❌ HealthKit query error: \(error)")
                    continuation.resume(returning: [])
                    return
                }

                var days = Set<String>()
                let calendar = Calendar.current

                for sample in samples ?? [] {
                    let comps = calendar.dateComponents([.year, .month, .day], from: sample.startDate)
                    if let y = comps.year, let m = comps.month, let d = comps.day {
                        let key = "\(y)-\(m - 1)-\(d)" // 0-based month
                        days.insert(key)
                    }
                }

                continuation.resume(returning: days)
            }

            store.execute(query)
        }
    }

    // MARK: - Основной метод синхронизации
    func syncWorkoutsToCalendar(daysData: inout [String: DayRecord]) async -> [String] {
        guard isAvailable else { return [] }

        let now = Date()
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -30, to: now)!

        let workoutDays = await fetchWorkoutDays(from: startDate, to: now)
        var autoAddedDays: [String] = []
        let removed = manuallyRemovedDays

        for key in workoutDays {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let y = Int(parts[0]),
                  let m = Int(parts[1]),
                  let d = Int(parts[2]) else { continue }

            var comps = DateComponents()
            comps.year = y; comps.month = m + 1; comps.day = d
            guard let date = calendar.date(from: comps),
                  date <= calendar.startOfDay(for: now) else { continue }

            var record = daysData[key] ?? DayRecord()

            if !record.hasSport && !removed.contains(key) {
                record.hasSport = true
                daysData[key] = record
                autoAddedDays.append(key)
            }
        }

        return autoAddedDays
    }
    
    // Запомнить что пользователь вручную убрал спорт за этот день
    func markDayAsManuallyRemovedSport(_ key: String) {
        var removed = manuallyRemovedDays
        removed.insert(key)
        UserDefaults.standard.set(Array(removed), forKey: "healthKitManuallyRemovedSportDays")
    }

    private var manuallyRemovedDays: Set<String> {
        let arr = UserDefaults.standard.array(forKey: "healthKitManuallyRemovedSportDays") as? [String] ?? []
        return Set(arr)
    }
    
    // MARK: - Дата последней синхронизации
    var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastSyncKey) }
    }
    
    var isSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") }
        set { UserDefaults.standard.set(newValue, forKey: "healthKitSyncEnabled") }
    }
    
}
