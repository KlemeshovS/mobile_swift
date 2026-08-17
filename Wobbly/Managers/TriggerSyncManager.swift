//  TriggerSyncManager.swift
//  Wobbly
//
//  Синхронизация дневника триггеров с /me/calendar/triggers.
//  Зеркалит CalendarSyncManager (last-write-wins по одному timestamp'у на весь дневник),
//  но, в отличие от календаря, бэкенд явно возвращает 409 при конфликте — в этом случае
//  локальные данные не перезаписывают серверные вслепую, а подтягиваются свежие с сервера.

import Foundation

class TriggerSyncManager {
    static let shared = TriggerSyncManager()

    private let localUpdatedAtKey = "triggersLocalUpdatedAt"
    private init() {}

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

    private func isoString(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }

    // MARK: - Основная синхронизация
    func sync() async {
        guard AuthStateManager.shared.sessionType == .authenticated else {
            return
        }

        do {
            print("🔄 TriggerSync: запрос данных с сервера...")
            let serverData = try await UserAPIService.shared.getTriggers()
            let serverUpdatedAt = parseServerDate(serverData.updatedAt)
            let localUpdatedAt = self.localUpdatedAt
            print("🔄 TriggerSync: localUpdatedAt=\(String(describing: localUpdatedAt))")

            if localUpdatedAt == nil {
                if !serverData.triggers.isEmpty {
                    await applyServerData(serverData.triggers)
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
                print("📤 TriggerSync: локальные новее (\(local) > \(server)) — отправляем")
                await pushToServer()
            } else if server > local {
                print("📥 TriggerSync: серверные новее (\(server) > \(local)) — берём")
                await applyServerData(serverData.triggers)
            } else {
                print("✅ TriggerSync: данные синхронизированы")
            }

        } catch {
            print("❌ TriggerSync error: \(error)")
        }
    }

    // MARK: - Отправка локальных данных на сервер
    func pushToServer() async {
        let localTriggers = TriggerManager.shared.allTriggers()
        var serverTriggers: [String: [String]] = [:]
        for (dayKey, triggers) in localTriggers {
            serverTriggers[dayKey] = triggers.map { $0.rawValue }
        }

        let clientUpdatedAtString = localUpdatedAt.map { isoString(from: $0) }

        do {
            let response = try await UserAPIService.shared.putTriggers(
                triggers: serverTriggers,
                clientUpdatedAt: clientUpdatedAtString
            )
            print("✅ TriggerSync: отправлено \(serverTriggers.count) записей")
            if let serverDate = parseServerDate(response.updatedAt) {
                UserDefaults.standard.set(serverDate, forKey: localUpdatedAtKey)
                print("✅ TriggerSync: localUpdatedAt обновлён серверным значением")
            }
        } catch UserAPIError.triggersConflict {
            // Сервер уже содержит более новую версию — не перезаписываем её,
            // а подтягиваем актуальные данные оттуда.
            print("⚠️ TriggerSync: конфликт — сервер новее, подтягиваем серверные данные")
            do {
                let serverData = try await UserAPIService.shared.getTriggers()
                await applyServerData(serverData.triggers)
            } catch {
                print("❌ TriggerSync: не удалось получить серверные данные после конфликта: \(error)")
            }
        } catch {
            print("❌ TriggerSync push error: \(error)")
        }
    }

    // MARK: - Применение серверных данных локально
    @MainActor
    private func applyServerData(_ triggers: [String: [String]]) async {
        var localTriggers: [String: [DrinkTrigger]] = [:]
        for (dayKey, rawTriggers) in triggers {
            let parsed = rawTriggers.compactMap { DrinkTrigger(rawValue: $0) }
            if !parsed.isEmpty {
                localTriggers[dayKey] = parsed
            }
        }

        TriggerManager.shared.replaceAll(localTriggers)

        // Обновляем localUpdatedAt
        UserDefaults.standard.set(Date(), forKey: localUpdatedAtKey)

        // Уведомляем UI (те же слушатели, что и у календаря — карточка инсайтов триггеров
        // пересчитывается вместе со статистикой)
        NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
        print("✅ TriggerSync: применено \(localTriggers.count) записей с сервера")
    }
}
