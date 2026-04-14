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
            id: "milestone_4810",
            title: NSLocalizedString("ach_milestone_4810_title", comment: ""),
            description: NSLocalizedString("ach_milestone_4810_desc", comment: ""),
            type: .milestone(target: 4810, isNegative: false),
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
                // Новая разблокировка
                currentAchievements[index].isUnlocked = true
                currentAchievements[index].unlockDate = Date()
                needsSave = true
                print("🎉 Разблокирована ачивка: \(achievement.title)")
            } else if !shouldUnlock && achievement.isUnlocked {
                // Условие больше не выполняется – сбрасываем
                currentAchievements[index].isUnlocked = false
                currentAchievements[index].unlockDate = nil
                needsSave = true
                print("😵 Сброшена ачивка: \(achievement.title)")
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
            
        case .milestone(let target, let isNegative):
            let result = ProgressCalculator.calculate(from: daysData)
            print("🔍 Проверка milestone: target=\(target), isNegative=\(isNegative), max=\(result.max), min=\(result.min)")
            if isNegative {
                return result.min <= -target
            } else {
                return result.max >= target
            }
        }
    }
    
    private func checkSoberStreakAchievement(requiredDays: Int, daysData: [String: DrinkLevel]) -> Bool {
        // Используем StreakHistoryManager для расчета
        let streakManager = StreakHistoryManager.shared
        let historicalMax = streakManager.calculateMaxSoberStreak(daysData: daysData)
        
  //      print("🎯 ПРОВЕРКА ТРЕЗВОЙ АЧИВКИ:")
   //     print("   🏆 Исторический максимум: \(historicalMax) дней")
   //     print("   🎯 Требуется: \(requiredDays) дней")
   //     print("   📊 Результат: \(historicalMax >= requiredDays ? "РАЗБЛОКИРОВАНА" : "НЕДОСТАТОЧНО")")
        
        return historicalMax >= requiredDays
    }

    private func checkDrinkingStreakAchievement(requiredDays: Int, daysData: [String: DrinkLevel]) -> Bool {
        // Используем StreakHistoryManager для расчета
        let streakManager = StreakHistoryManager.shared
        let historicalMax = streakManager.calculateMaxDrinkingStreak(daysData: daysData)
        
  //      print("🎯 ПРОВЕРКА АЛКОГОЛЬНОЙ АЧИВКИ:")
  //      print("   🏆 Исторический максимум: \(historicalMax) дней")
  //      print("   🎯 Требуется: \(requiredDays) дней")
  //      print("   📊 Результат: \(historicalMax >= requiredDays ? "РАЗБЛОКИРОВАНА" : "НЕДОСТАТОЧНО")")
        
        return historicalMax >= requiredDays
    }
    
    private func checkSportAchievement(period: SportPeriod, requiredCount: Int, daysData: [String: DrinkLevel]) -> Bool {
        // 🔥 ИЩЕМ ЛЮБОЙ ПЕРИОД В ИСТОРИИ, а не только от сегодня
        let sportCount = findMaxSportDaysInAnyPeriod(period: period, daysData: daysData)
        
  //      print("🎯 ПРОВЕРКА СПОРТИВНОЙ АЧИВКИ:")
  //      print("   📅 Период: \(period.daysCount) дней")
  //      print("   💪 Максимум спортивных дней в любом периоде: \(sportCount)")
  //      print("   🎯 Требуется: \(requiredCount) дней")
  //      print("   📊 Результат: \(sportCount >= requiredCount ? "РАЗБЛОКИРОВАНА" : "НЕДОСТАТОЧНО")")
        
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
        print("🎯 Проверка новогодней ачивки: \(eventType == .soberNewYear ? "трезвый" : "спортивный")")
        
        let calendar = Calendar.current
        
        // Проверяем все года из данных
        for (dateKey, level) in daysData {
            guard let date = parseDateFromKey(dateKey) else { continue }
            
            let components = calendar.dateComponents([.month, .day], from: date)
            let isDecember31st = components.month == 12 && components.day == 31
            
            if isDecember31st {
                print("📅 Найден 31 декабря: \(dateKey), уровень: \(level.rawValue)")
                
                switch eventType {
                case .soberNewYear:
                    // Для трезвого нового года подходят: .none ИЛИ .sport
                    // Главное - не пил алкоголь
                    if level == .none || level == .sport {
                        print("✅ Найдена дата для ачивки 'трезвый новый год': \(dateKey), уровень: \(level.rawValue)")
                        return true
                    }
                case .sportNewYear:
                    // Для спортивного нового года нужно именно .sport (не little_sport!)
                    if level == .sport || level == .little_sport {
                        print("✅ Найдена дата для ачивки 'спортивный новый год': \(dateKey)")
                        return true
                    }
                }
            }
        }
        
        print("❌ Не найдено подходящих дат для новогодней ачивки: \(eventType)")
        return false
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
