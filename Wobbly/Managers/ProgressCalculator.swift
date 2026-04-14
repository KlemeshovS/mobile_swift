//
//  ProgressCalculator.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 06.03.26.
//
import Foundation

struct ProgressResult {
    let current: Int      // прогресс на сегодня
    let max: Int          // исторический максимум
    let min: Int          // исторический минимум
}

struct ProgressCalculator {
    static func calculate(from daysData: [String: DrinkLevel]) -> ProgressResult {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Находим первую дату с отметкой (аналогично findFirstMarkedDate)
        guard let firstMarkedDate = findFirstMarkedDate(daysData: daysData) else {
            return ProgressResult(current: 0, max: 0, min: 0)
        }
        
        var startDate = firstMarkedDate
        if let daysAgo = calendar.dateComponents([.day], from: startDate, to: today).day,
           daysAgo > 3650 {
            startDate = calendar.date(byAdding: .day, value: -3650, to: today)!
        }
        
        var currentProgress = 0
        var maxProgress = 0
        var minProgress = 0
        var consecutiveDrinkDays = 0
        var consecutiveSoberDays = 0
        
        var date = startDate
        while date <= today {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let year = components.year,
                  let month = components.month,
                  let day = components.day else {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }
            
            let monthZeroBased = month - 1
            let key = "\(year)-\(monthZeroBased)-\(day)"
            let level = daysData[key] ?? .none  // по умолчанию .none, т.к. дни без отметки считаются трезвыми
            
            // Логика расчёта
            switch level {
                        case .none:
                            let weeks = consecutiveSoberDays / 7
                            let bonus = bonusCoefficient(for: weeks)
                            currentProgress += Int(ceil(5.0 * bonus))
                            consecutiveDrinkDays = 0
                            consecutiveSoberDays += 1
                            
                        case .sport:
                            let weeks = consecutiveSoberDays / 7
                            let bonus = bonusCoefficient(for: weeks)
                            currentProgress += Int(ceil(20.0 * bonus))
                            consecutiveDrinkDays = 0
                            consecutiveSoberDays += 1
                            
                        case .little:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 5, consecutiveDays: consecutiveDrinkDays)
                            currentProgress -= penalty
                            
                        case .little_sport:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 5, consecutiveDays: consecutiveDrinkDays)
                            currentProgress = currentProgress - penalty + 20
                            
                        case .medium:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 20, consecutiveDays: consecutiveDrinkDays)
                            currentProgress -= penalty
                            
                        case .heavy:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 35, consecutiveDays: consecutiveDrinkDays)
                            currentProgress -= penalty
                
                        case .medium_sport:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 20, consecutiveDays: consecutiveDrinkDays)
                            currentProgress = currentProgress - penalty + 5 //почти обнуляем спорт
                        case .heavy_sport:
                            consecutiveDrinkDays += 1
                            consecutiveSoberDays = 0
                            let penalty = calculatePenalty(base: 35, consecutiveDays: consecutiveDrinkDays)
                            currentProgress = currentProgress - penalty + 0 //обнуляем спорт
                            
                        case .unknown:
                            break
                        }
            
            maxProgress = max(maxProgress, currentProgress)
            minProgress = min(minProgress, currentProgress)
            
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return ProgressResult(current: currentProgress, max: maxProgress, min: minProgress)
    }
    
    private static func findFirstMarkedDate(daysData: [String: DrinkLevel]) -> Date? {
        let calendar = Calendar.current
        var earliestDate: Date? = nil
        
        for (key, level) in daysData {
            if level == .unknown || level == .none {
                continue
            }
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  let day = Int(parts[2]) else { continue }
            
            var components = DateComponents()
            components.year = year
            components.month = month + 1
            components.day = day
            
            if let date = calendar.date(from: components) {
                if earliestDate == nil || date < earliestDate! {
                    earliestDate = date
                }
            }
        }
        return earliestDate
    }
    
    private static func bonusCoefficient(for weeks: Int) -> Double {
        switch weeks {
        case 0: return 1.0
        case 1: return 1.2
        case 2: return 1.5
        case 3: return 1.75
        default: return 2.0
        }
    }
    
    private static func calculatePenalty(base: Int, consecutiveDays: Int) -> Int {
        let coefficient: Double
        switch consecutiveDays {
        case 1: coefficient = 1.0
        case 2: coefficient = 1.5
        case 3: coefficient = 2.5
        case 4: coefficient = 3.5
        default: coefficient = 3.0
        }
        return Int(ceil(Double(base) * coefficient))
    }
}
