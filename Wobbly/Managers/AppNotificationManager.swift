//  AppNotificationManager.swift
//  Wobbly

import Foundation
import SwiftUI

enum AppNotificationType {
    case achievement(title: String, description: String, imageName: String, isDrinking: Bool)
    case newFollower(username: String, userId: Int, avatarUrl: String?)
}

struct AppNotificationItem: Identifiable {
    let id = UUID()
    let type: AppNotificationType
}

class AppNotificationManager: ObservableObject {
    static let shared = AppNotificationManager()

    @Published var currentNotification: AppNotificationItem? = nil
    private var queue: [AppNotificationItem] = []

    private init() {}

    func enqueue(_ item: AppNotificationItem) {
        DispatchQueue.main.async {
            self.queue.append(item)
            if self.currentNotification == nil {
                self.showNext()
            }
        }
    }

    func dismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.currentNotification = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showNext()
            }
        }
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        currentNotification = queue.removeFirst()
    }

    // MARK: - Проверка новых подписчиков
    func checkNewFollowers() async {
        guard AuthStateManager.shared.sessionType == .authenticated else { return }

        let knownKey = "knownFollowerIds"
        // Читаем как [Any] и конвертируем в Int
        let rawIds = UserDefaults.standard.array(forKey: knownKey) ?? []
        let knownIds = Set(rawIds.compactMap { ($0 as? NSNumber)?.intValue ?? ($0 as? Int) })

        do {
            let response = try await UserAPIService.shared.getMyFollowers()
            let currentIds = Set(response.items.map { $0.userId })

            // Сохраняем актуальный список
            UserDefaults.standard.set(Array(currentIds), forKey: knownKey)

            // Первый запуск — просто запоминаем, не показываем
            guard !knownIds.isEmpty else { return }

            // Новые — те кого не было раньше
            let newFollowers = response.items.filter { !knownIds.contains($0.userId) }

            for follower in newFollowers {
                let item = AppNotificationItem(type: .newFollower(
                    username: follower.username,
                    userId: follower.userId,
                    avatarUrl: follower.avatarUrl
                ))
                enqueue(item)
            }
        } catch {
            print("❌ checkNewFollowers error: \(error)")
        }
    }
    
    // MARK: - Проверка новых ачивок
    func checkNewAchievements(daysData: [String: DrinkLevel]) {
        let notifiedKey = "notifiedAchievementIds"
        var notifiedIds = Set(UserDefaults.standard.array(forKey: notifiedKey) as? [String] ?? [])

        let allUnlocked = NewAchievementManager.shared.checkAllAchievements(daysData: daysData)
        let currentUnlockedIds = Set(allUnlocked.filter { $0.isUnlocked }.map { $0.id })

        // Первый запуск — просто запоминаем все текущие ачивки без уведомлений
        if notifiedIds.isEmpty {
            UserDefaults.standard.set(Array(currentUnlockedIds), forKey: notifiedKey)
            return
        }

        // Показываем уведомления только для тех, которых раньше не было
        let newlyUnlocked = allUnlocked.filter { $0.isUnlocked && !notifiedIds.contains($0.id) }

        for achievement in newlyUnlocked {
            let item = AppNotificationItem(type: .achievement(
                title: achievement.title,
                description: achievement.requirementDescription,
                imageName: achievement.imageName,
                isDrinking: achievement.isDrinking
            ))
            enqueue(item)
            notifiedIds.insert(achievement.id)
        }

        UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedKey)
    }
}
