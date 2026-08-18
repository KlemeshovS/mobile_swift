//  AppNotificationManager.swift
//  Wobbly

import Foundation
import SwiftUI

enum BetEventKind {
    case challenged  // мне бросили вызов
    case accepted    // мой вызов приняли — "сделка подтверждена"
    case declined    // мой вызов отклонили
    case expired     // мой вызов не приняли вовремя
    case finished    // пари завершилось (естественно или через слив)
}

enum AppNotificationType {
    case achievement(title: String, description: String, achievementDescription: String, imageName: String, isDrinking: Bool)
    case newFollower(username: String, userId: Int, avatarUrl: String?)
    case customMessage(text: String)
    case healthSyncProposal(text: String, onAccept: () -> Void, onDecline: () -> Void)
    case betEvent(kind: BetEventKind, bet: Bet)
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
                achievementDescription: achievement.description,
                imageName: achievement.imageName,
                isDrinking: achievement.isDrinking
            ))
            enqueue(item)
            notifiedIds.insert(achievement.id)
        }

        UserDefaults.standard.set(Array(notifiedIds), forKey: notifiedKey)
    }
    
    // MARK: - Проверка новых событий по пари
    func checkNewBetEvents() async {
        guard AuthStateManager.shared.sessionType == .authenticated else { return }
        let myId = AuthStateManager.shared.userId

        let snapshotKey = "knownBetStates"
        let oldSnapshot = UserDefaults.standard.dictionary(forKey: snapshotKey) as? [String: String] ?? [:]

        let bets = await BetsManager.shared.refresh()

        var newSnapshot: [String: String] = [:]
        for bet in bets {
            newSnapshot["\(bet.id)"] = "\(bet.status.rawValue)|\(bet.resolutionType?.rawValue ?? "")"
        }

        // Первый запуск — просто запоминаем текущее состояние, без уведомлений
        guard !oldSnapshot.isEmpty else {
            UserDefaults.standard.set(newSnapshot, forKey: snapshotKey)
            return
        }

        for bet in bets {
            let oldState = oldSnapshot["\(bet.id)"]

            if oldState == nil {
                // Новое пари, о котором мы ещё не знали
                if bet.status == .pending && bet.opponent.userId == myId {
                    enqueue(AppNotificationItem(type: .betEvent(kind: .challenged, bet: bet)))
                }
                continue
            }

            let oldStatus = oldState?.split(separator: "|", maxSplits: 1).first.map(String.init) ?? ""

            if oldStatus == "pending" && bet.status == .active {
                enqueue(AppNotificationItem(type: .betEvent(kind: .accepted, bet: bet)))
            } else if oldStatus == "pending" && bet.status == .resolved
                        && bet.resolutionType == .declined && bet.challenger.userId == myId {
                enqueue(AppNotificationItem(type: .betEvent(kind: .declined, bet: bet)))
            } else if oldStatus == "pending" && bet.status == .resolved
                        && bet.resolutionType == .expired && bet.challenger.userId == myId {
                enqueue(AppNotificationItem(type: .betEvent(kind: .expired, bet: bet)))
            } else if oldStatus == "active" && bet.status == .resolved {
                enqueue(AppNotificationItem(type: .betEvent(kind: .finished, bet: bet)))
            }
        }

        UserDefaults.standard.set(newSnapshot, forKey: snapshotKey)
    }

    func showCustomMessage(_ text: String) {
        let item = AppNotificationItem(type: .customMessage(text: text))
        enqueue(item)
    }
    
    func showHealthSyncProposal(autoAddedDays: [String], isRussian: Bool, onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) {
        let count = autoAddedDays.count
        let text: String
        if isRussian {
            text = count == 1
                ? "Нашли тренировку в Apple Health — добавить спортивный день?"
                : "Нашли \(count) тренировки в Apple Health — добавить спортивные дни?"
        } else {
            text = count == 1
                ? "Found a workout in Apple Health — mark it as a sport day?"
                : "Found \(count) workouts in Apple Health — mark them as sport days?"
        }
        let item = AppNotificationItem(type: .healthSyncProposal(
            text: text,
            onAccept: onAccept,
            onDecline: onDecline
        ))
        enqueue(item)
    }
    
}
