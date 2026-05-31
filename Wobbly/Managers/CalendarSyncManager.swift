//  CalendarSyncManager.swift
//  Wobbly

import Foundation

class CalendarSyncManager {
    static let shared = CalendarSyncManager()

    private let localUpdatedAtKey = "calendarLocalUpdatedAt"
    private init() {}

    // MARK: - Конвертация DrinkLevel <-> Int
    private func drinkLevelToInt(_ level: DrinkLevel) -> Int {
        switch level {
        case .none: return 0
        case .little: return 1
        case .medium: return 2
        case .heavy: return 3
        case .sport: return 4
        case .little_sport: return 5
        case .medium_sport: return 6
        case .heavy_sport: return 7
        case .unknown: return 0
        }
    }

    private func intToDrinkLevel(_ value: Int) -> DrinkLevel {
        switch value {
        case 1: return .little
        case 2: return .medium
        case 3: return .heavy
        case 4: return .sport
        case 5: return .little_sport
        case 6: return .medium_sport
        case 7: return .heavy_sport
        default: return .none
        }
    }

    // MARK: - Сохраняем время последнего локального изменения
    func markLocalUpdated() {
        UserDefaults.standard.set(Date(), forKey: localUpdatedAtKey)
    }

    private var localUpdatedAt: Date? {
        UserDefaults.standard.object(forKey: localUpdatedAtKey) as? Date
    }

    private func parseServerDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }

    // MARK: - Основная синхронизация
    func sync() async {
        guard AuthStateManager.shared.sessionType == .authenticated else {
            return
        }

        do {
            print("🔄 CalendarSync: запрос данных с сервера...")
            let serverData = try await UserAPIService.shared.getCalendar()
            let serverUpdatedAt = parseServerDate(serverData.updatedAt)
            let localUpdatedAt = self.localUpdatedAt
            print("🔄 CalendarSync: localUpdatedAt=\(String(describing: localUpdatedAt))")

            if localUpdatedAt == nil {
                if !serverData.days.isEmpty {
                    await applyServerData(serverData.days)
                } else {
                    await pushToServer()
                }
                return
            }

            guard let local = localUpdatedAt, let server = serverUpdatedAt else {
                await pushToServer()
                return
            }

            if local > server {
                print("📤 CalendarSync: локальные новее (\(local) > \(server)) — отправляем")
                await pushToServer()
            } else if server > local {
                print("📥 CalendarSync: серверные новее (\(server) > \(local)) — берём")
                await applyServerData(serverData.days)
            } else {
                print("✅ CalendarSync: данные синхронизированы")
            }

        } catch {
            print("❌ CalendarSync error: \(error)")
        }
    }
    
    // MARK: - Отправка локальных данных на сервер
    func pushToServer() async {
        let dataManager = DrinkDataManager()
        let localData = dataManager.loadData()

        var serverDays: [String: Int] = [:]
        for (key, level) in localData {
            let intValue = drinkLevelToInt(level)
            if intValue != 0 {
                serverDays[key] = intValue
            }
        }

        do {
            let response = try await UserAPIService.shared.putCalendar(days: serverDays)
            print("✅ CalendarSync: отправлено \(serverDays.count) записей")
            // Обновляем localUpdatedAt серверным значением
            if let serverDate = parseServerDate(response.updatedAt) {
                UserDefaults.standard.set(serverDate, forKey: localUpdatedAtKey)
                print("✅ CalendarSync: localUpdatedAt обновлён серверным значением")
            }
        } catch {
            print("❌ CalendarSync push error: \(error)")
        }
        // Обновляем данные для виджета
        DrinkDataManager().syncDataForWidget()
    }

    // MARK: - Применение серверных данных локально
    @MainActor
    private func applyServerData(_ days: [String: Int]) async {
        var legacyData: [String: DrinkLevel] = [:]
        for (key, value) in days {
            let level = intToDrinkLevel(value)
            if level != .none {
                legacyData[key] = level
            }
        }

        let dataManager = DrinkDataManager()
        dataManager.saveData(legacyData)

        // Обновляем localUpdatedAt
        UserDefaults.standard.set(Date(), forKey: localUpdatedAtKey)

        // Уведомляем UI
        NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
        print("✅ CalendarSync: применено \(legacyData.count) записей с сервера")
        
        DrinkDataManager().syncDataForWidget()
    }
}
