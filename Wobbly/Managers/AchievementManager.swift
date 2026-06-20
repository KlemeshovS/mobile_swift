//
//  AchievementManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.01.2026.
//

import Foundation

// MARK: - New Achievement Manager
class NewAchievementManager {
    static let shared = NewAchievementManager()
    private let dataManager = DrinkDataManager()
    
    // Все ачивки приложения
    private let allAchievements: [Achievement] = [
        // Ачивки за стрик трезвых дней
        Achievement(
            id: "sober_7",
            title: NSLocalizedString("ach_sober_7_title", comment: ""),
            description: NSLocalizedString("ach_sober_7_desc", comment: ""),
            type: .soberStreak(requiredDays: 7),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_14",
            title: NSLocalizedString("ach_sober_14_title", comment: ""),
            description: NSLocalizedString("ach_sober_14_desc", comment: ""),
            type: .soberStreak(requiredDays: 14),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_21",
            title: NSLocalizedString("ach_sober_21_title", comment: ""),
            description: NSLocalizedString("ach_sober_21_desc", comment: ""),
            type: .soberStreak(requiredDays: 21),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_30",
            title: NSLocalizedString("ach_sober_30_title", comment: ""),
            description: NSLocalizedString("ach_sober_30_desc", comment: ""),
            type: .soberStreak(requiredDays: 30),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_60",
            title: NSLocalizedString("ach_sober_60_title", comment: ""),
            description: NSLocalizedString("ach_sober_60_desc", comment: ""),
            type: .soberStreak(requiredDays: 60),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_90",
            title: NSLocalizedString("ach_sober_90_title", comment: ""),
            description: NSLocalizedString("ach_sober_90_desc", comment: ""),
            type: .soberStreak(requiredDays: 90),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_180",
            title: NSLocalizedString("ach_sober_180_title", comment: ""),
            description: NSLocalizedString("ach_sober_180_desc", comment: ""),
            type: .soberStreak(requiredDays: 180),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_365",
            title: NSLocalizedString("ach_sober_365_title", comment: ""),
            description: NSLocalizedString("ach_sober_365_desc", comment: ""),
            type: .soberStreak(requiredDays: 365),
            isUnlocked: false
        ),
        
        // Ачивки за стрик дней с алкоголем
        Achievement(
            id: "drink_3",
            title: NSLocalizedString("ach_drink_3_title", comment: ""),
            description: NSLocalizedString("ach_drink_3_desc", comment: ""),
            type: .drinkingStreak(requiredDays: 3),
            isUnlocked: false
        ),
        Achievement(
            id: "drink_7",
            title: NSLocalizedString("ach_drink_7_title", comment: ""),
            description: NSLocalizedString("ach_drink_7_desc", comment: ""),
            type: .drinkingStreak(requiredDays: 7),
            isUnlocked: false
        ),
        Achievement(
            id: "drink_14",
            title: NSLocalizedString("ach_drink_14_title", comment: ""),
            description: NSLocalizedString("ach_drink_14_desc", comment: ""),
            type: .drinkingStreak(requiredDays: 14),
            isUnlocked: false
        ),
        Achievement(
            id: "drink_30",
            title: NSLocalizedString("ach_drink_30_title", comment: ""),
            description: NSLocalizedString("ach_drink_30_desc", comment: ""),
            type: .drinkingStreak(requiredDays: 30),
            isUnlocked: false
        ),
        
        // Трезвые дни в году
        Achievement(
            id: "sober_days_year_100",
            title: NSLocalizedString("ach_sober_days_year_100_title", comment: ""),
            description: NSLocalizedString("ach_sober_days_year_100_desc", comment: ""),
            type: .soberDaysInYear(requiredCount: 100),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_days_year_200",
            title: NSLocalizedString("ach_sober_days_year_200_title", comment: ""),
            description: NSLocalizedString("ach_sober_days_year_200_desc", comment: ""),
            type: .soberDaysInYear(requiredCount: 200),
            isUnlocked: false
        ),
        Achievement(
            id: "sober_days_year_300",
            title: NSLocalizedString("ach_sober_days_year_300_title", comment: ""),
            description: NSLocalizedString("ach_sober_days_year_300_desc", comment: ""),
            type: .soberDaysInYear(requiredCount: 300),
            isUnlocked: false
        ),

        // Алкогольные дни в году
        Achievement(
            id: "drink_days_year_100",
            title: NSLocalizedString("ach_drink_days_year_100_title", comment: ""),
            description: NSLocalizedString("ach_drink_days_year_100_desc", comment: ""),
            type: .drinkingDaysInYear(requiredCount: 100),
            isUnlocked: false
        ),
        Achievement(
            id: "drink_days_year_200",
            title: NSLocalizedString("ach_drink_days_year_200_title", comment: ""),
            description: NSLocalizedString("ach_drink_days_year_200_desc", comment: ""),
            type: .drinkingDaysInYear(requiredCount: 200),
            isUnlocked: false
        ),
        Achievement(
            id: "drink_days_year_300",
            title: NSLocalizedString("ach_drink_days_year_300_title", comment: ""),
            description: NSLocalizedString("ach_drink_days_year_300_desc", comment: ""),
            type: .drinkingDaysInYear(requiredCount: 300),
            isUnlocked: false
        ),
        
        // Трезвые месяцы
        Achievement(id: "sober_month_1", title: NSLocalizedString("ach_sober_month_1_title", comment: ""), description: NSLocalizedString("ach_sober_month_1_desc", comment: ""), type: .soberMonth(month: 1), isUnlocked: false),
        Achievement(id: "sober_month_2", title: NSLocalizedString("ach_sober_month_2_title", comment: ""), description: NSLocalizedString("ach_sober_month_2_desc", comment: ""), type: .soberMonth(month: 2), isUnlocked: false),
        Achievement(id: "sober_month_3", title: NSLocalizedString("ach_sober_month_3_title", comment: ""), description: NSLocalizedString("ach_sober_month_3_desc", comment: ""), type: .soberMonth(month: 3), isUnlocked: false),
        Achievement(id: "sober_month_4", title: NSLocalizedString("ach_sober_month_4_title", comment: ""), description: NSLocalizedString("ach_sober_month_4_desc", comment: ""), type: .soberMonth(month: 4), isUnlocked: false),
        Achievement(id: "sober_month_5", title: NSLocalizedString("ach_sober_month_5_title", comment: ""), description: NSLocalizedString("ach_sober_month_5_desc", comment: ""), type: .soberMonth(month: 5), isUnlocked: false),
        Achievement(id: "sober_month_6", title: NSLocalizedString("ach_sober_month_6_title", comment: ""), description: NSLocalizedString("ach_sober_month_6_desc", comment: ""), type: .soberMonth(month: 6), isUnlocked: false),
        Achievement(id: "sober_month_7", title: NSLocalizedString("ach_sober_month_7_title", comment: ""), description: NSLocalizedString("ach_sober_month_7_desc", comment: ""), type: .soberMonth(month: 7), isUnlocked: false),
        Achievement(id: "sober_month_8", title: NSLocalizedString("ach_sober_month_8_title", comment: ""), description: NSLocalizedString("ach_sober_month_8_desc", comment: ""), type: .soberMonth(month: 8), isUnlocked: false),
        Achievement(id: "sober_month_9", title: NSLocalizedString("ach_sober_month_9_title", comment: ""), description: NSLocalizedString("ach_sober_month_9_desc", comment: ""), type: .soberMonth(month: 9), isUnlocked: false),
        Achievement(id: "sober_month_10", title: NSLocalizedString("ach_sober_month_10_title", comment: ""), description: NSLocalizedString("ach_sober_month_10_desc", comment: ""), type: .soberMonth(month: 10), isUnlocked: false),
        Achievement(id: "sober_month_11", title: NSLocalizedString("ach_sober_month_11_title", comment: ""), description: NSLocalizedString("ach_sober_month_11_desc", comment: ""), type: .soberMonth(month: 11), isUnlocked: false),
        Achievement(id: "sober_month_12", title: NSLocalizedString("ach_sober_month_12_title", comment: ""), description: NSLocalizedString("ach_sober_month_12_desc", comment: ""), type: .soberMonth(month: 12), isUnlocked: false),
        
        // Спортивные ачивки
        Achievement(
            id: "sport_8_month",
            title: NSLocalizedString("ach_sport_8_title", comment: ""),
            description: NSLocalizedString("ach_sport_8_desc", comment: ""),
            type: .sportCount(period: .last30Days, requiredCount: 8),
            isUnlocked: false
        ),
        Achievement(
            id: "sport_12_month",
            title: NSLocalizedString("ach_sport_12_title", comment: ""),
            description: NSLocalizedString("ach_sport_12_desc", comment: ""),
            type: .sportCount(period: .last30Days, requiredCount: 12),
            isUnlocked: false
        ),
        Achievement(
            id: "sport_50_half_year",
            title: NSLocalizedString("ach_sport_50_title", comment: ""),
            description: NSLocalizedString("ach_sport_50_desc", comment: ""),
            type: .sportCount(period: .last180Days, requiredCount: 50),
            isUnlocked: false
        ),
        Achievement(
            id: "sport_100_year",
            title: NSLocalizedString("ach_sport_100_title", comment: ""),
            description: NSLocalizedString("ach_sport_100_desc", comment: ""),
            type: .sportCount(period: .last365Days, requiredCount: 100),
            isUnlocked: false
        ),
        
        // Уникальные ачивки
        Achievement(
            id: "sober_new_year",
            title: NSLocalizedString("ach_unique_sober_ny_title", comment: ""),
            description: NSLocalizedString("ach_unique_sober_ny_desc", comment: ""),
            type: .uniqueEvent(eventType: .soberNewYear),
            isUnlocked: false
        ),
        Achievement(
            id: "sport_new_year",
            title: NSLocalizedString("ach_unique_sport_ny_title", comment: ""),
            description: NSLocalizedString("ach_unique_sport_ny_desc", comment: ""),
            type: .uniqueEvent(eventType: .sportNewYear),
            isUnlocked: false
        ),
        
        // Ачивки за накопленные баллы (milestone)
        Achievement(
            id: "milestone_146",
            title: NSLocalizedString("ach_milestone_146_title", comment: ""),
            description: NSLocalizedString("ach_milestone_146_desc", comment: ""),
            type: .milestone(target: 146, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_319",
            title: NSLocalizedString("ach_milestone_319_title", comment: ""),
            description: NSLocalizedString("ach_milestone_319_desc", comment: ""),
            type: .milestone(target: 319, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_443",
            title: NSLocalizedString("ach_milestone_443_title", comment: ""),
            description: NSLocalizedString("ach_milestone_443_desc", comment: ""),
            type: .milestone(target: 443, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_1234",
            title: NSLocalizedString("ach_milestone_1234_title", comment: ""),
            description: NSLocalizedString("ach_milestone_1234_desc", comment: ""),
            type: .milestone(target: 1234, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_1917",
            title: NSLocalizedString("ach_milestone_1917_title", comment: ""),
            description: NSLocalizedString("ach_milestone_1917_desc", comment: ""),
            type: .milestone(target: 1917, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_3491",
            title: NSLocalizedString("ach_milestone_3491_title", comment: ""),
            description: NSLocalizedString("ach_milestone_3491_desc", comment: ""),
            type: .milestone(target: 3491, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_4478",
            title: NSLocalizedString("ach_milestone_4478_title", comment: ""),
            description: NSLocalizedString("ach_milestone_4478_desc", comment: ""),
            type: .milestone(target: 4478, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_4506",
            title: NSLocalizedString("ach_milestone_4506_title", comment: ""),
            description: NSLocalizedString("ach_milestone_4506_desc", comment: ""),
            type: .milestone(target: 4506, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_4810",
            title: NSLocalizedString("ach_milestone_4810_title", comment: ""),
            description: NSLocalizedString("ach_milestone_4810_desc", comment: ""),
            type: .milestone(target: 4810, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_5054",
            title: NSLocalizedString("ach_milestone_5054_title", comment: ""),
            description: NSLocalizedString("ach_milestone_5054_desc", comment: ""),
            type: .milestone(target: 5054, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_5642",
            title: NSLocalizedString("ach_milestone_5642_title", comment: ""),
            description: NSLocalizedString("ach_milestone_5642_desc", comment: ""),
            type: .milestone(target: 5642, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_7010",
            title: NSLocalizedString("ach_milestone_7010_title", comment: ""),
            description: NSLocalizedString("ach_milestone_7010_desc", comment: ""),
            type: .milestone(target: 7010, isNegative: false),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_8848",
            title: NSLocalizedString("ach_milestone_8848_title", comment: ""),
            description: NSLocalizedString("ach_milestone_8848_desc", comment: ""),
            type: .milestone(target: 8848, isNegative: false),
            isUnlocked: false
        ),
        // Отрицательная веха
        Achievement(
            id: "milestone_202_negative",
            title: NSLocalizedString("ach_milestone_202_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_202_negative_desc", comment: ""),
            type: .milestone(target: 202, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_1642_negative",
            title: NSLocalizedString("ach_milestone_1642_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_1642_negative_desc", comment: ""),
            type: .milestone(target: 1642, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_3800_negative",
            title: NSLocalizedString("ach_milestone_3800_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_3800_negative_desc", comment: ""),
            type: .milestone(target: 3800, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_6066_negative",
            title: NSLocalizedString("ach_milestone_6066_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_6066_negative_desc", comment: ""),
            type: .milestone(target: 6066, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_7729_negative",
            title: NSLocalizedString("ach_milestone_7729_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_7729_negative_desc", comment: ""),
            type: .milestone(target: 7729, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_10047_negative",
            title: NSLocalizedString("ach_milestone_10047_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_10047_negative_desc", comment: ""),
            type: .milestone(target: 10047, isNegative: true),
            isUnlocked: false
        ),
        Achievement(
            id: "milestone_11022_negative",
            title: NSLocalizedString("ach_milestone_11022_negative_title", comment: ""),
            description: NSLocalizedString("ach_milestone_11022_negative_desc", comment: ""),
            type: .milestone(target: 11022, isNegative: true),
            isUnlocked: false
        ),

        // Ачивка за отзыв в App Store (ручная разблокировка)
        Achievement(
            id: "left_review",
            title: NSLocalizedString("ach_review_title", comment: ""),
            description: NSLocalizedString("ach_review_desc", comment: ""),
            type: .leftReview,
            isUnlocked: false
        )
    ]
    
    func migrateFromOldData() {
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
            
    private func getProgressExtremes(daysData: [String: DrinkLevel]) -> (max: Int, min: Int) {
        let result = ProgressCalculator.calculate(from: daysData)
        return (result.max, result.min)
    }
    
    // MARK: - Public Methods
    
    // Полный пересчёт ВСЕХ ачивок (разблокировка и сброс)
    func recalculateAllAchievements(daysData: [String: DrinkLevel]) -> [Achievement] {
        var currentAchievements = loadAchievements()
        var needsSave = false
        
        for index in currentAchievements.indices {
            let achievement = currentAchievements[index]
            let shouldUnlock = checkAchievement(achievement, daysData: daysData)
            
            if shouldUnlock && !achievement.isUnlocked {
                currentAchievements[index].isUnlocked = true
                currentAchievements[index].unlockDate = Date()
                needsSave = true
            }
            
            // Пересчитываем счётчик всегда когда ачивка разблокирована
            if shouldUnlock {
                switch achievement.type {
                case .soberDaysInYear, .drinkingDaysInYear:
                    let newCount = countYearsAchieved(type: achievement.type, daysData: daysData)
                    if currentAchievements[index].unlockCount != newCount {
                        currentAchievements[index].unlockCount = newCount
                        needsSave = true
                    }
                case .uniqueEvent:
                    let newCount = countNewYearEvents(type: achievement.type, daysData: daysData)
                    if currentAchievements[index].unlockCount != newCount {
                        currentAchievements[index].unlockCount = newCount
                        needsSave = true
                    }
                case .soberMonth(let month):
                    let newCount = countSoberMonths(month: month, daysData: daysData)
                    if currentAchievements[index].unlockCount != newCount {
                        currentAchievements[index].unlockCount = newCount
                        needsSave = true
                    }
                default:
                    if currentAchievements[index].unlockCount == 0 {
                        currentAchievements[index].unlockCount = 1
                        needsSave = true
                    }
                }
            }
            
            if !shouldUnlock && achievement.isUnlocked {
                // Ачивки с ручной разблокировкой не сбрасываем
                if case .leftReview = achievement.type { continue }
                // Условие больше не выполняется – сбрасываем
                currentAchievements[index].isUnlocked = false
                currentAchievements[index].unlockDate = nil
                currentAchievements[index].unlockCount = 0
                needsSave = true
            }
        }
        
        if needsSave {
            saveAchievements(currentAchievements)
        }
        
        return currentAchievements
    }
    // Оставляем старый метод для обратной совместимости, но он теперь делает полный пересчёт
    func checkAllAchievements(daysData: [String: DrinkLevel]) -> [Achievement] {
        return recalculateAllAchievements(daysData: daysData)
    }
        
    func loadUnlockedAchievements() -> [Achievement] {
        return loadAchievements()
    }
    
    func getAllAchievements() -> [Achievement] {
        return allAchievements
    }
    
    // MARK: - Private Logic
    
    private func countSoberMonths(month: Int, daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        let startYear = calendar.component(.year, from: startDate)
        
        var count = 0
        
        for year in startYear...currentYear {
            // Пропускаем текущий незакончившийся месяц
            if year == currentYear && month >= currentMonth { continue }
            
            // Проверяем что месяц после даты начала
            guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  monthStart >= startDate else { continue }
            
            let hasAlcohol = daysData.contains { dateString, level in
                let parts = dateString.split(separator: "-").map { String($0) }
                guard parts.count == 3,
                      let y = Int(parts[0]),
                      let m = Int(parts[1]) else { return false }
                let isDrinking = (level == .little || level == .medium || level == .heavy ||
                                  level == .little_sport || level == .medium_sport || level == .heavy_sport)
                return y == year && (m + 1) == month && isDrinking
            }
            
            if !hasAlcohol { count += 1 }
        }
        
        return count
    }
    
    private func countNewYearEvents(type: AchievementType, daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        let startYear = calendar.component(.year, from: startDate)
        
        guard case .uniqueEvent(let eventType) = type else { return 0 }
        
        var count = 0
        for year in startYear...currentYear {
            var components = DateComponents()
            components.year = year
            components.month = 12
            components.day = 31
            
            guard let dec31 = calendar.date(from: components),
                  dec31 <= Date(),
                  dec31 >= startDate else { continue }
            
            let dayData = DayData(day: 31, month: 11, year: year)
            let level = daysData[dayData.key] ?? .none
            
            switch eventType {
            case .soberNewYear:
                if level == .none || level == .sport { count += 1 }
            case .sportNewYear:
                if level == .sport || level == .little_sport { count += 1 }
            }
        }
        
        return count
    }
    
    private func countYearsAchieved(type: AchievementType, daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        let startYear = calendar.component(.year, from: startDate)
        
        var count = 0
        
        for year in startYear...currentYear {
            // Собираем данные только за этот год
            let yearData = daysData.filter { key, _ in
                let parts = key.split(separator: "-").map { String($0) }
                guard parts.count == 3, let y = Int(parts[0]) else { return false }
                return y == year
            }
            
            switch type {
            case .soberDaysInYear(let required):
                if checkSoberDaysInYear(requiredCount: required, daysData: daysData, forYear: year) {
                    count += 1
                }
            case .drinkingDaysInYear(let required):
                if checkDrinkingDaysInYear(requiredCount: required, daysData: daysData, forYear: year) {
                    count += 1
                }
            default:
                break
            }
        }
        
        return count
    }
    
    private func checkAchievement(_ achievement: Achievement, daysData: [String: DrinkLevel]) -> Bool {
        switch achievement.type {
        case .soberStreak(let requiredDays):
            return checkSoberStreakAchievement(requiredDays: requiredDays, daysData: daysData)
            
        case .drinkingStreak(let requiredDays):
            return checkDrinkingStreakAchievement(requiredDays: requiredDays, daysData: daysData)
            
        case .sportCount(let period, let requiredCount):
            return checkSportAchievement(period: period, requiredCount: requiredCount, daysData: daysData)
            
        case .uniqueEvent(let eventType):
            return checkUniqueEventAchievement(eventType: eventType, daysData: daysData)
            
        case .soberDaysInYear(let requiredCount):
            return checkSoberDaysInYear(requiredCount: requiredCount, daysData: daysData)

        case .drinkingDaysInYear(let requiredCount):
            return checkDrinkingDaysInYear(requiredCount: requiredCount, daysData: daysData)
            
        case .soberMonth(let month):
            return checkSoberMonth(month: month, daysData: daysData)
            
        case .milestone(let target, let isNegative):
            let result = ProgressCalculator.calculate(from: daysData)
            if isNegative {
                return result.min <= -target
            } else {
                return result.max >= target
            }

        case .leftReview:
            // Разблокируется только вручную через unlockReviewAchievement()
            return false
        }
    }

    // MARK: - Manual unlock

    /// Вызвать после того как пользователь оставил отзыв в App Store.
    @discardableResult
    func unlockReviewAchievement() -> Achievement? {
        var achievements = loadAchievements()
        guard let index = achievements.firstIndex(where: { $0.id == "left_review" }),
              !achievements[index].isUnlocked else { return nil }
        achievements[index].isUnlocked = true
        achievements[index].unlockDate = Date()
        saveAchievements(achievements)
        return achievements[index]
    }
    
    private func checkSoberMonth(month: Int, daysData: [String: DrinkLevel]) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let currentMonth = calendar.component(.month, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)

        // Проверяем все прошедшие года
        let startYear = calendar.component(.year, from: startDate)

        for year in startYear...currentYear {
            // Пропускаем текущий месяц — он ещё не закончился
            if year == currentYear && month >= currentMonth { continue }

            // Проверяем что месяц после даты начала
            guard let monthStart = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
                  monthStart >= startDate else { continue }

            // Проверяем нет ли алкогольных дней в этом месяце
            let hasAlcohol = daysData.contains { dateString, level in
                let parts = dateString.split(separator: "-").map { String($0) }
                guard parts.count == 3,
                      let y = Int(parts[0]),
                      let m = Int(parts[1]) else { return false }

                // Месяц в ключе 0-based, поэтому +1
                let isDrinking = (level == .little || level == .medium || level == .heavy ||
                                  level == .little_sport || level == .medium_sport || level == .heavy_sport)
                return y == year && (m + 1) == month && isDrinking
            }

            if !hasAlcohol { return true }
        }

        return false
    }
    
    private func checkSoberStreakAchievement(requiredDays: Int, daysData: [String: DrinkLevel]) -> Bool {
        // Используем StreakHistoryManager для расчета
        let streakManager = StreakHistoryManager.shared
        let historicalMax = streakManager.calculateMaxSoberStreak(daysData: daysData)
        
        return historicalMax >= requiredDays
    }

    private func checkDrinkingStreakAchievement(requiredDays: Int, daysData: [String: DrinkLevel]) -> Bool {
        // Используем StreakHistoryManager для расчета
        let streakManager = StreakHistoryManager.shared
        let historicalMax = streakManager.calculateMaxDrinkingStreak(daysData: daysData)
        
        return historicalMax >= requiredDays
    }
    
    private func checkSportAchievement(period: SportPeriod, requiredCount: Int, daysData: [String: DrinkLevel]) -> Bool {
        // 🔥 ИЩЕМ ЛЮБОЙ ПЕРИОД В ИСТОРИИ, а не только от сегодня
        let sportCount = findMaxSportDaysInAnyPeriod(period: period, daysData: daysData)
        
        return sportCount >= requiredCount
    }
    
    private func findMaxSportDaysInAnyPeriod(period: SportPeriod, daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        
        // Получаем все спортивные дни
        let sportDays = getSportDays(daysData: daysData)
        guard !sportDays.isEmpty else { return 0 }
        
        var maxSportCount = 0
        
        // Для каждого спортивного дня проверяем период
        for sportDay in sportDays {
            let periodEndDate = sportDay
            guard let periodStartDate = calendar.date(byAdding: .day, value: -period.daysCount, to: periodEndDate) else { continue }
            
            let sportCountInPeriod = countSportDaysInPeriod(start: periodStartDate, end: periodEndDate, daysData: daysData)
            maxSportCount = max(maxSportCount, sportCountInPeriod)
        }
        
        return maxSportCount
    }
    
    private func getSportDays(daysData: [String: DrinkLevel]) -> [Date] {
        var sportDates: [Date] = []
        let calendar = Calendar.current
        
        for (dateKey, level) in daysData {
            // 🔥 КЛЮЧЕВОЕ ИЗМЕНЕНИЕ: Теперь учитываем и little_sport как спортивный день!
            if level == .sport || level == .little_sport || level == .medium_sport || level == .heavy_sport, let date = parseDateFromKey(dateKey) {
                sportDates.append(calendar.startOfDay(for: date))
            }
        }
        
        return sportDates.sorted()
    }
    
    private func countSportDaysInPeriod(start: Date, end: Date, daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        var count = 0
        var currentDate = start
        
        while currentDate <= end {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            guard let day = components.day,
                  let month = components.month,
                  let year = components.year else {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
                continue
            }
            
            let dayData = DayData(day: day, month: month - 1, year: year)
            let level = daysData[dayData.key]
            
            if level == .sport || level == .little_sport || level == .medium_sport || level == .heavy_sport {                count += 1
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return count
    }
    
    private func checkUniqueEventAchievement(eventType: UniqueEvent, daysData: [String: DrinkLevel]) -> Bool {
        switch eventType {
        case .soberNewYear:
            return checkNewYearEvent(daysData: daysData, requiredLevel: .none, eventType: eventType)
        case .sportNewYear:
            return checkNewYearEvent(daysData: daysData, requiredLevel: .sport, eventType: eventType)
        }
    }
    
    // MARK: - Calculation Methods
    
    private func checkSoberNewYear(daysData: [String: DrinkLevel]) -> Bool {
        return checkNewYearEvent(daysData: daysData, requiredLevel: .none, eventType: .soberNewYear)
    }

    private func checkSportNewYear(daysData: [String: DrinkLevel]) -> Bool {
        return checkNewYearEvent(daysData: daysData, requiredLevel: .sport, eventType: .sportNewYear)
    }
    
    private func checkNewYearEvent(daysData: [String: DrinkLevel], requiredLevel: DrinkLevel, eventType: UniqueEvent) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        
        for year in (currentYear - 3)...currentYear {
            var components = DateComponents()
            components.year = year
            components.month = 12
            components.day = 31
            
            guard let dec31 = calendar.date(from: components) else { continue }
            
            // Не проверяем будущие даты
            guard dec31 <= Date() else { continue }
            
            // Не проверяем даты раньше начала использования приложения
            guard dec31 >= startDate else { continue }
            
            let dayData = DayData(day: 31, month: 11, year: year)
            let level = daysData[dayData.key] ?? .none
            
            switch eventType {
            case .soberNewYear:
                let isSober = (level == .none || level == .sport)
                if isSober { return true }
                
            case .sportNewYear:
                let hadSport = (level == .sport || level == .little_sport)
                if hadSport { return true }
            }
        }
        
        return false
    }
    
    private func checkSoberDaysInYear(requiredCount: Int, daysData: [String: DrinkLevel], forYear: Int? = nil) -> Bool {
        let calendar = Calendar.current
        let targetYear = forYear ?? calendar.component(.year, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        
        let startOfYear = calendar.date(from: DateComponents(year: targetYear, month: 1, day: 1))!
        let endOfYear: Date
        if targetYear == calendar.component(.year, from: Date()) {
            endOfYear = calendar.startOfDay(for: Date())
        } else {
            endOfYear = calendar.date(from: DateComponents(year: targetYear, month: 12, day: 31))!
        }
        
        guard endOfYear >= startDate else { return false }
        
        let periodStart = max(startDate, startOfYear)
        let totalDaysPassed = calendar.dateComponents([.day], from: periodStart, to: endOfYear).day ?? 0
        
        var drinkingCount = 0
        for (dateString, level) in daysData {
            let parts = dateString.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  year == targetYear else { continue }
            
            let isDrinking = (level == .little || level == .medium || level == .heavy ||
                              level == .little_sport || level == .medium_sport || level == .heavy_sport)
            if isDrinking { drinkingCount += 1 }
        }
        
        let soberCount = totalDaysPassed - drinkingCount
        return soberCount >= requiredCount
    }

    private func checkDrinkingDaysInYear(requiredCount: Int, daysData: [String: DrinkLevel], forYear: Int? = nil) -> Bool {
        let calendar = Calendar.current
        let targetYear = forYear ?? calendar.component(.year, from: Date())
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
        
        let startOfYear = calendar.date(from: DateComponents(year: targetYear, month: 1, day: 1))!
        guard startOfYear >= startDate || targetYear == calendar.component(.year, from: Date()) else { return false }
        
        var drinkCount = 0
        for (dateString, level) in daysData {
            let parts = dateString.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  year == targetYear else { continue }
            
            let isDrinking = (level == .little || level == .medium || level == .heavy ||
                              level == .little_sport || level == .medium_sport || level == .heavy_sport)
            if isDrinking { drinkCount += 1 }
        }
        
        return drinkCount >= requiredCount
    }
        
    private func loadAchievements() -> [Achievement] {
        let fullData = dataManager.loadFullAppData() // ← Используем новый метод!
        
        // Если еще нет сохраненных ачивок, возвращаем все с дефолтными значениями
        if fullData.achievements.isEmpty {
            return allAchievements
        }
        
        // Обновляем список ачивок, сохраняя статус разблокировки
        var updatedAchievements = allAchievements
        for index in updatedAchievements.indices {
            if let savedAchievement = fullData.achievements.first(where: { $0.id == updatedAchievements[index].id }) {
                updatedAchievements[index].isUnlocked = savedAchievement.isUnlocked
                updatedAchievements[index].unlockDate = savedAchievement.unlockDate
                updatedAchievements[index].unlockCount = savedAchievement.unlockCount
            }
        }
        
        return updatedAchievements
    }

    func saveAchievements(_ achievements: [Achievement]) {
        var fullData = dataManager.loadFullAppData()
        fullData.achievements = achievements
        dataManager.saveFullAppData(fullData)
    }
}
