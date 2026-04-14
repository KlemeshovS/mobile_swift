//
//  Managers.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.01.2026.
//

import SwiftUI
import UIKit

// MARK: - AppInstallManager
class AppInstallManager {
    static let shared = AppInstallManager()
    
    private let userDefaults = UserDefaults.standard
    private let installDateKey = "app_install_date_key"
    
    private init() {
        // Автоматически сохраняем дату при первом создании менеджера
        if userDefaults.object(forKey: installDateKey) == nil {
            userDefaults.set(Date(), forKey: installDateKey)
            print("Дата установки сохранена: \(Date())")
        }
    }
    
    var installDate: Date {
        return userDefaults.object(forKey: installDateKey) as? Date ?? Date()
    }
    
    var installDateStartOfDay: Date {
        Calendar.current.startOfDay(for: installDate)
    }
    
    // Для отладки/тестирования
    func setCustomInstallDate(_ date: Date) {
        userDefaults.set(date, forKey: installDateKey)
    }
    
    func resetToCurrentDate() {
        userDefaults.set(Date(), forKey: installDateKey)
    }
    
    // Дополнительные полезные методы
    func daysSinceInstall() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: installDate, to: Date())
        return max(0, components.day ?? 0)
    }
    
    func isInstalledMoreThan(days: Int) -> Bool {
        return daysSinceInstall() >= days
    }
}

// MARK: - Haptic Manager
class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

// MARK: - Tutorial Manager
class TutorialManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let tutorialShownKey = "tutorialShown"
    
    var isTutorialShown: Bool {
        get { userDefaults.bool(forKey: tutorialShownKey) }
        set { userDefaults.set(newValue, forKey: tutorialShownKey) }
    }
    
    func completeTutorial() {
        isTutorialShown = true
    }
    
    func resetTutorial() {
        isTutorialShown = false
    }
}

// MARK: - Motivation Notification Manager
class MotivationNotificationManager: ObservableObject {
    @Published var showMotivation = false
    @Published var motivationText = ""
    @Published var isPositiveMotivation = false
    
    // Используем UserDefaults только для простых настроек
    private let userDefaults = UserDefaults.standard
    
    private var aiService: AIService?
    private var cachedStatistics: String = ""
    private let defaults = UserDefaults.standard
    
    private let forceDisableAI = true  // поставьте true, чтобы отключить AI
    private var isRussianLanguage: Bool {
        return Locale.current.language.languageCode?.identifier == "ru"
    }
    
    func setupAI(apiKey: String, folderId: String) {
        self.aiService = AIService(apiKey: apiKey, folderId: folderId)
    }
    
    // Новый метод, который принимает статистику и показывает сообщение
    func showMotivationIfNeeded(yesterdayDrinking: Bool, statistics: String, yesterdayLevel: DrinkLevel? = nil) {
            print("🔍 showMotivationIfNeeded вызван, yesterdayDrinking: \(yesterdayDrinking)")

            if yesterdayDrinking {
                // Вчера был алкоголь
                if LanguageManager.shared.currentLanguage == .russian, let aiService = aiService, Reachability.isConnectedToNetwork(), !forceDisableAI {
                    aiService.generateMotivation(statistics: statistics, yesterdayLevel: yesterdayLevel) { [weak self] aiText in
                        DispatchQueue.main.async {
                            if let aiText = aiText, !aiText.isEmpty {
                                self?.motivationText = aiText
                                self?.isPositiveMotivation = true
                                self?.showMotivation = true
                                self?.cacheMessage(aiText)
                            } else {
                                self?.motivationText = MotivationManager.randomDrinkingPhrase()
                                self?.isPositiveMotivation = false
                                self?.showMotivation = true
                            }
                        }
                    }
                } else {
                    motivationText = MotivationManager.randomDrinkingPhrase()
                    isPositiveMotivation = false
                    showMotivation = true
                }
            } else {
                // Вчера трезвый день
                if LanguageManager.shared.currentLanguage == .russian, let aiService = aiService, Reachability.isConnectedToNetwork(), !forceDisableAI {
                    aiService.generateMotivation(statistics: statistics) { [weak self] aiText in
                        DispatchQueue.main.async {
                            if let aiText = aiText, !aiText.isEmpty {
                                self?.motivationText = aiText
                                self?.isPositiveMotivation = true
                                self?.showMotivation = true
                                self?.cacheMessage(aiText)
                            } else {
                                self?.motivationText = MotivationManager.randomSoberPhrase()
                                self?.isPositiveMotivation = true
                                self?.showMotivation = true
                            }
                        }
                    }
                } else {
                    motivationText = MotivationManager.randomSoberPhrase()
                    isPositiveMotivation = true
                    showMotivation = true
                }
            }
        }
    
    private func fallbackToCachedOrRandom() {
        if let cached = getCachedMessage() {
            motivationText = cached
        } else {
            motivationText = MotivationManager.randomSoberPhrase()
        }
        isPositiveMotivation = true
        showMotivation = true
    }
    
    private func cacheMessage(_ message: String) {
        defaults.set(message, forKey: "lastMotivationMessage")
    }
    
    private func getCachedMessage() -> String? {
        return defaults.string(forKey: "lastMotivationMessage")
    }
    
    func shouldShowMotivationToday() -> Bool {
        let lastDateString = userDefaults.string(forKey: "lastMotivationDate") ?? ""
        let currentDateString = getCurrentDateString()
        return lastDateString != currentDateString
    }
    
//    func showMotivationIfNeeded(yesterdayDrinking: Bool) {
//        guard shouldShowMotivationToday() else { return }
//
//        motivationText = MotivationManager.getMotivationPhrase(forYesterday: yesterdayDrinking)
//        isPositiveMotivation = !yesterdayDrinking
//        showMotivation = true
//
//        userDefaults.set(getCurrentDateString(), forKey: "lastMotivationDate")
//    }
    
    func shouldShowMotivation() -> Bool {
        let notificationsEnabled = userDefaults.bool(forKey: "motivationNotificationsEnabled")
        return notificationsEnabled && shouldShowMotivationToday()
    }
    
    // Методы для управления настройками уведомлений
    func setMotivationNotificationsEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "motivationNotificationsEnabled")
    }
    
    func areMotivationNotificationsEnabled() -> Bool {
        return userDefaults.bool(forKey: "motivationNotificationsEnabled")
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Motivation Manager
struct MotivationManager {
    // Ключи для алкогольных фраз
        static let drinkingPhraseKeys = [
            "motivation_drinking_1",
            "motivation_drinking_2",
            "motivation_drinking_3",
            "motivation_drinking_4",
            "motivation_drinking_5",
            "motivation_drinking_6",
            "motivation_drinking_7",
            "motivation_drinking_8",
            "motivation_drinking_9",
            "motivation_drinking_10",
            "motivation_drinking_11",
            "motivation_drinking_12",
            "motivation_drinking_13",
            "motivation_drinking_14",
            "motivation_drinking_15",
            "motivation_drinking_16",
            "motivation_drinking_17"
        ]
    
    // Ключи для трезвых фраз
        static let soberPhraseKeys = [
            "motivation_sober_1",
            "motivation_sober_2",
            "motivation_sober_3",
            "motivation_sober_4",
            "motivation_sober_5",
            "motivation_sober_6",
            "motivation_sober_7",
            "motivation_sober_8",
            "motivation_sober_9",
            "motivation_sober_10",
            "motivation_sober_11",
            "motivation_sober_12",
            "motivation_sober_13",
            "motivation_sober_14",
            "motivation_sober_15"
        ]
    
    // Ключи для milestone-сообщений
    static let recoveryMilestoneKeys: [Int: String] = [
        1: "motivation_recovery_1",
        3: "motivation_recovery_3",
        7: "motivation_recovery_7",
        14: "motivation_recovery_14",
        30: "motivation_recovery_30",
        60: "motivation_recovery_60",
        90: "motivation_recovery_90",
        180: "motivation_recovery_180",
        365: "motivation_recovery_365"
    ]
    
    static func randomDrinkingPhrase() -> String {
            let key = drinkingPhraseKeys.randomElement() ?? "motivation_drinking_1"
            return NSLocalizedString(key, comment: "")
        }
        
        static func randomSoberPhrase() -> String {
            let key = soberPhraseKeys.randomElement() ?? "motivation_sober_1"
            return NSLocalizedString(key, comment: "")
        }
        
        static func getMotivationPhrase(forYesterday drinking: Bool) -> String {
            return drinking ? randomDrinkingPhrase() : randomSoberPhrase()
        }
        
        static func isRecoveryMilestoneDay(_ soberDays: Int) -> Bool {
            return recoveryMilestoneKeys.keys.contains(soberDays)
        }
        
        static func getRecoveryPhrase(forSoberDays soberDays: Int) -> String? {
            guard let key = recoveryMilestoneKeys[soberDays] else { return nil }
            return NSLocalizedString(key, comment: "")
        }
}

// MARK: - Period Manager
class PeriodManager {
    static let shared = PeriodManager()
    private let userDefaults = UserDefaults.standard
    private let firstInstallDateKey = "firstInstallDate"
    
    var firstInstallDate: Date {
        get {
            if let savedDate = userDefaults.object(forKey: firstInstallDateKey) as? Date {
                return savedDate
            }
            let newDate = Date()
            userDefaults.set(newDate, forKey: firstInstallDateKey)
            return newDate
        }
    }
    
    private func parseDateFromKey(_ dateKey: String) -> Date? {
        let components = dateKey.split(separator: "-").map { String($0) }
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return nil
        }
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1  // т.к. у нас месяцы 0-based
        dateComponents.day = day
        
        let calendar = Calendar.current
        return calendar.date(from: dateComponents)
    }
    
    func getAchievementStartDate(daysData: [String: DrinkLevel]) -> Date {
        let installDate = firstInstallDate
        
        // Ищем самую раннюю дату в данных
        var earliestDataDate = Date.distantFuture
        for dateKey in daysData.keys {
            if let date = parseDateFromKey(dateKey) {
                earliestDataDate = min(earliestDataDate, date)
            }
        }
        
        // Если есть исторические данные - используем их дату
        // Если нет данных - используем дату установки
        let startDate = earliestDataDate != Date.distantFuture ? earliestDataDate : installDate
        
        return startDate
    }
    
    func isValidPeriodForStats(startDate: Date, endDate: Date) -> Bool {
        return startDate >= firstInstallDate
    }
    
    func getValidPeriod(startDate: Date, endDate: Date) -> (start: Date, end: Date) {
        let actualStart = max(startDate, firstInstallDate)
        return (actualStart, endDate)
    }
}
