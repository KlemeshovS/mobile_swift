//
//  StatisticsProvider.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 22.02.26.
//

import Foundation

class StatisticsProvider: ObservableObject {
    @Published var progressDays: Int = 0
    private let dayRecords: [String: DayRecord]
    
    // Инициализатор – принимает словарь с записями
    init(dayRecords: [String: DayRecord]) {
        self.dayRecords = dayRecords
    }
    
    // MARK: - Основные методы расчёта
    
    /// Возвращает текущий стрик трезвости (сколько дней подряд без алкоголя на сегодня)
    func currentSoberStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var streak = 0
        var currentDate = today
        
        while true {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            guard let year = components.year, let month = components.month, let day = components.day else {
                break
            }
            
            // Создаём ключ для поиска в dayRecords
            let dayData = DayData(day: day, month: month - 1, year: year)
            let record = dayRecords[dayData.key]
            
            // Проверяем, был ли алкоголь
            if let rec = record, (rec.drinkLevel == .little || rec.drinkLevel == .medium || rec.drinkLevel == .heavy || rec.drinkLevel == .little_sport) {
                // Если нашли алкоголь – стрик прерывается
                break
            } else {
                // Иначе увеличиваем стрик
                streak += 1
                // Переходим ко вчерашнему дню
                guard let prevDate = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = prevDate
            }
        }
        return streak
    }
    
    /// Возвращает статистику за последние N дней: (трезвые дни, дни с алкоголем, спортивные дни)
    func statsForLast(days: Int) -> (soberDays: Int, drinkingDays: Int, sportDays: Int) {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return (0, 0, 0)
        }
        
        var sober = 0
        var drinking = 0
        var sport = 0
        
        var currentDate = startDate
        while currentDate <= endDate {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            if let year = components.year, let month = components.month, let day = components.day {
                let key = DayData(day: day, month: month - 1, year: year).key
                let record = dayRecords[key]
                
                if let rec = record {
                    // Проверяем алкоголь
                    if rec.drinkLevel == .none {
                        sober += 1
                    } else if rec.drinkLevel != .unknown {
                        drinking += 1
                    }
                    // Проверяем спорт
                    if rec.hasSport {
                        sport += 1
                    }
                } else {
                    // День без отметки считаем трезвым (согласно вашему решению)
                    sober += 1
                }
            }
            // Переходим к следующему дню
            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }
        
        return (sober, drinking, sport)
    }
}
