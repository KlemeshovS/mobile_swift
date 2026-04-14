//
//  ScoreSyncManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import Foundation

class ScoreSyncManager {
    static let shared = ScoreSyncManager()
    
    private init() {
        print("🔄 ScoreSyncManager инициализирован, подписка на .drinkDataChanged")
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDataChange),
            name: .drinkDataChanged,
            object: nil
        )
    }
    
    @objc private func handleDataChange() {
        print("📢 Получено уведомление .drinkDataChanged, запускаем отправку счёта")
        sendScore()
    }
    
    func forceSendScore() {
        print("📢 Принудительный вызов отправки счёта")
        sendScore()
    }
    
    private func sendScore() {
        // Проверяем наличие токена через AuthStateManager
        guard AuthStateManager.shared.accessToken != nil else {
            print("⏭️ Пропуск отправки счёта: токен отсутствует")
            return
        }
        
        guard UserDefaults.standard.bool(forKey: "userParticipateInRating") else {
            print("⏭️ Пропуск отправки счёта: пользователь не участвует в рейтинге")
            return
        }
        
        guard let userName = UserDefaults.standard.string(forKey: "userName"), !userName.isEmpty else {
            print("⏭️ Пропуск отправки счёта: имя не задано")
            return
        }
        
        print("📊 Начинаем расчёт прогресса для отправки...")
        let dataManager = DrinkDataManager()
        let daysData = dataManager.loadData() // [String: DrinkLevel]
        let progress = ProgressCalculator.calculate(from: daysData)
        let score = progress.current
        print("📈 Рассчитан текущий прогресс: \(score)")
        
        print("📤 Отправка счёта на сервер: score=\(score)")
        Task {
            do {
                let response = try await UserAPIService.shared.updateMyScore(score: score)
                print("✅ Счёт успешно отправлен: \(response.score) для пользователя \(response.username)")
            } catch UserAPIError.ratingDisabledForScore {
                print("⚠️ Рейтинг отключён для отправки счёта (участие выключено)")
            } catch UserAPIError.authRequiredForRating {
                print("⚠️ Требуется авторизация для рейтинга")
            } catch {
                print("❌ Ошибка отправки счёта: \(error)")
                // Другие ошибки уже обработаны в UserAPIService (включая автообновление токена)
            }
        }
    }
}
