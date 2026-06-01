//
//  WorkoutData.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 01.06.26.
//

import Foundation

struct WorkoutData: Codable {
    let activityName: String
    let durationSeconds: Double
    let distanceMeters: Double?
    let calories: Double?

    var durationFormatted: String {
        let h = Int(durationSeconds) / 3600
        let m = (Int(durationSeconds) % 3600) / 60
        let s = Int(durationSeconds) % 60
        let minStr = NSLocalizedString("workout_min", comment: "")
        let secStr = NSLocalizedString("workout_sec", comment: "")
        if h > 0 {
            let hourStr = NSLocalizedString("workout_hour", comment: "")
            return String(format: "%d \(hourStr) %02d \(minStr)", h, m)
        } else {
            return String(format: "%d \(minStr) %02d \(secStr)", m, s)
        }
    }

    var distanceFormatted: String? {
        guard let d = distanceMeters, d > 0 else { return nil }
        if d >= 1000 {
            return String(format: "%.1f \(NSLocalizedString("workout_km", comment: ""))", d / 1000)
        } else {
            return String(format: "%.0f \(NSLocalizedString("workout_m", comment: ""))", d)
        }
    }

    var caloriesFormatted: String? {
        guard let c = calories, c > 0 else { return nil }
        return String(format: "%.0f \(NSLocalizedString("workout_kcal", comment: ""))", c)
    }
}

// MARK: - Локальное хранилище тренировок
class WorkoutDataStorage {
    static let shared = WorkoutDataStorage()
    private let key = "localWorkoutData"

    func save(_ workout: WorkoutData, for dayKey: String) {
        var all = loadAll()
        all[dayKey] = workout
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func load(for dayKey: String) -> WorkoutData? {
        return loadAll()[dayKey]
    }

    func loadAll() -> [String: WorkoutData] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: WorkoutData].self, from: data)
        else { return [:] }
        return decoded
    }
    func delete(for dayKey: String) {
        var all = loadAll()
        all.removeValue(forKey: dayKey)
        if let encoded = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
}
