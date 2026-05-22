//
//  StreakManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.01.2026.
//

import Foundation

// MARK: - Streak History Manager
class StreakHistoryManager {
    static let shared = StreakHistoryManager()
    private let dataManager = DrinkDataManager()
    
    func saveMaxStreaks(soberMax: Int, drinkingMax: Int) {
    }
    
    func calculateMaxSoberStreak(daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        // Используем startDate = минимальная дата (установка или первый отмеченный день)
        let startDate = PeriodManager.shared.getAchievementStartDate(daysData: daysData)
                
        // Собираем все алкогольные дни
        var alcoholDates: [Date] = []
        for (dateString, level) in daysData {
            let isAlcoholic = (level == .little || level == .medium || level == .heavy ||
                               level == .little_sport || level == .medium_sport || level == .heavy_sport)
            if isAlcoholic {
                let parts = dateString.split(separator: "-").map { String($0) }
                guard parts.count == 3,
                      let year = Int(parts[0]),
                      let month = Int(parts[1]),
                      let day = Int(parts[2]) else { continue }
                var components = DateComponents()
                components.year = year
                components.month = month + 1
                components.day = day
                if let date = calendar.date(from: components) {
                    alcoholDates.append(calendar.startOfDay(for: date))
                }
            }
        }
        alcoholDates.sort()
        
        // Если нет алкогольных дней – все дни от startDate до today трезвые
        if alcoholDates.isEmpty {
            let daysCount = calendar.dateComponents([.day], from: startDate, to: today).day ?? 0
            return max(0, daysCount)
        }
        
        // Идём день за днём от startDate до today
        var currentDate = startDate
        var maxStreak = 0
        var currentStreak = 0
        var alcoholIndex = 0
        
        while currentDate <= today {
            let isAlcoholDay = alcoholIndex < alcoholDates.count && calendar.isDate(currentDate, inSameDayAs: alcoholDates[alcoholIndex])
            
            if isAlcoholDay {
                currentStreak = 0
                alcoholIndex += 1
            } else {
                currentStreak += 1
                if currentStreak > maxStreak {
                    maxStreak = currentStreak
                }
            }
            
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return maxStreak
    }
    
    // Универсальная функция для расчета максимального алкогольного стрика
    func calculateMaxDrinkingStreak(daysData: [String: DrinkLevel]) -> Int {
        
        // 1. КОНВЕРТИРУЕМ СТРОКИ В ДАТЫ
        var dateLevels: [(date: Date, level: DrinkLevel)] = []
        let calendar = Calendar.current
        
        for (dateString, level) in daysData {
            // Проверяем только алкогольные дни
            guard level == .little || level == .medium || level == .heavy || level == .little_sport || level == .medium_sport || level == .heavy_sport else {
                continue
            }
            
            let components = dateString.split(separator: "-").map { String($0) }
            guard components.count == 3,
                  let year = Int(components[0]),
                  let month = Int(components[1]),
                  let day = Int(components[2]) else {
                continue
            }
            
            var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month + 1 // +1 если у вас месяцы 0-индексированные
            dateComponents.day = day
            
            if let date = calendar.date(from: dateComponents) {
                dateLevels.append((date: calendar.startOfDay(for: date), level: level))
            }
        }
        
        // 2. СОРТИРУЕМ ПО ДАТЕ
        dateLevels.sort { $0.date < $1.date }
        
        guard !dateLevels.isEmpty else {
            return 0
        }
        
        // 3. ИЩЕМ САМЫЙ ДЛИННЫЙ ПОСЛЕДОВАТЕЛЬНЫЙ СТРИК
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<dateLevels.count {
            let previousDate = dateLevels[i-1].date
            let currentDate = dateLevels[i].date
            
            // Проверяем, являются ли даты последовательными днями
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(currentDate, inSameDayAs: nextDay) {
                // Даты идут подряд
                currentStreak += 1
                if currentStreak > maxStreak {
                    maxStreak = currentStreak
                }
            } else {
                // Разрыв в последовательности
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    func recalculateMaxStreaksFromData(daysData: [String: DrinkLevel]) {
        
        // Просто логируем текущие максимумы
        let soberMax = calculateMaxSoberStreak(daysData: daysData)
        let drinkingMax = calculateMaxDrinkingStreak(daysData: daysData)

    }
}

// MARK: - Вспомогательные методы для определения текущей очереди
private let queueSpecificKey = DispatchSpecificKey<String>()

extension DispatchQueue {
    static func setupQueueDetection() {
        let streakQueue = DispatchQueue(label: "com.drinkly.streakManager", attributes: .concurrent)
        streakQueue.setSpecific(key: queueSpecificKey, value: "com.drinkly.streakManager")
    }
}
