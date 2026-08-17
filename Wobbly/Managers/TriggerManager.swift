//
//  TriggerManager.swift
//  Wobbly
//
//  Дневник триггеров — почему выпил в конкретный день.
//  Хранится локально (UserDefaults), отдельно от основного DrinkDataManager/FullAppData,
//  чтобы не зависеть от лоссового round-trip через DrinkLevel в синке/экспорте/восстановлении.
//  Синхронизация между устройствами — через TriggerSyncManager.
//

import Foundation

final class TriggerManager {
    static let shared = TriggerManager()

    private let userDefaults = UserDefaults.standard
    private let storageKey = "dayTriggers"

    private var cache: [String: [DrinkTrigger]]

    private init() {
        cache = TriggerManager.load(from: userDefaults, key: storageKey)
    }

    private static func load(from defaults: UserDefaults, key: String) -> [String: [DrinkTrigger]] {
        guard let data = defaults.data(forKey: key),
              let raw = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            return [:]
        }
        var result: [String: [DrinkTrigger]] = [:]
        for (dayKey, rawTriggers) in raw {
            let triggers = rawTriggers.compactMap { DrinkTrigger(rawValue: $0) }
            if !triggers.isEmpty {
                result[dayKey] = triggers
            }
        }
        return result
    }

    private func persist() {
        let raw: [String: [String]] = cache.mapValues { $0.map { $0.rawValue } }
        guard let data = try? JSONEncoder().encode(raw) else { return }
        userDefaults.set(data, forKey: storageKey)
    }

    /// Триггеры для конкретного дня (ключ в формате "год-месяц(0-based)-день", как в daysData)
    func triggers(for dayKey: String) -> [DrinkTrigger] {
        cache[dayKey] ?? []
    }

    /// Заменяет набор триггеров для дня. Пустой массив удаляет запись.
    func setTriggers(_ triggers: [DrinkTrigger], for dayKey: String) {
        if triggers.isEmpty {
            cache.removeValue(forKey: dayKey)
        } else {
            cache[dayKey] = triggers
        }
        persist()
    }

    /// Все сохранённые триггеры по дням — для подсчёта инсайтов в статистике.
    func allTriggers() -> [String: [DrinkTrigger]] {
        cache
    }

    /// Полностью заменяет локальный кэш (используется при применении серверных данных при синхронизации).
    func replaceAll(_ newTriggers: [String: [DrinkTrigger]]) {
        cache = newTriggers
        persist()
    }
}
