//
//  ReviewManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 06.03.26.
//

import Foundation

final class ReviewManager: ObservableObject {
    static let shared = ReviewManager()
    
    private let defaults = UserDefaults.standard
    
    private let hasRatedKey = "review_has_rated"
    private let statsOpenCountKey = "review_stats_open_count"
    private let lastPromptDateKey = "review_last_prompt_date"
    
    // Настройки периодичности (для продакшена)
    private let minOpensBeforePrompt = 1
    private let minDaysBetweenPrompts = 10
    private let minMarkedDaysBeforePrompt = 5   // минимальное количество отмеченных дней
    
    // Тестовый режим – показывать при каждом открытии
    #if DEBUG
    var testMode = false  // в DEBUG можно включить
    #else
    var testMode = false // в релизе всегда выключен
    #endif
    
    // Метод проверки наличия записей
    func hasUserEntries(in daysData: [String: DayRecord]) -> Bool {
        return daysData.contains { (_, record) in
            // Есть отметка, если:
            // - drinkLevel не .none и не .unknown (алкоголь любой степени)
            // - или hasSport == true (спортивный день)
            (record.drinkLevel != .none && record.drinkLevel != .unknown) || record.hasSport
        }
    }
    
    // Подсчёт количества отмеченных дней
    func countUserMarkedDays(in daysData: [String: DayRecord]) -> Int {
        return daysData.filter { (_, record) in
            (record.drinkLevel != .none && record.drinkLevel != .unknown) || record.hasSport
        }.count
    }
    
    var hasRated: Bool {
        get { defaults.bool(forKey: hasRatedKey) }
        set { defaults.set(newValue, forKey: hasRatedKey) }
    }
    
    private var statsOpenCount: Int {
        get { defaults.integer(forKey: statsOpenCountKey) }
        set { defaults.set(newValue, forKey: statsOpenCountKey) }
    }
    
    private var lastPromptDate: Date? {
        get { defaults.object(forKey: lastPromptDateKey) as? Date }
        set { defaults.set(newValue, forKey: lastPromptDateKey) }
    }
    
    func incrementStatsOpenCount() {
        statsOpenCount += 1
    }
    
    func shouldShowPrompt(daysData: [String: DayRecord]) -> Bool {
        // Тестовый режим – показываем всегда, независимо от наличия записей
        if testMode { return true }
        
        guard !hasRated else { return false }
        
        // Должно быть минимум N отмеченных дней
        guard countUserMarkedDays(in: daysData) >= minMarkedDaysBeforePrompt else { return false }
        
        guard statsOpenCount >= minOpensBeforePrompt else { return false }
        
        if let lastDate = lastPromptDate {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minDaysBetweenPrompts else { return false }
        }
        
        return true
    }
    
    func didShowPrompt() {
        lastPromptDate = Date()
        statsOpenCount = 0
    }
    
    func didRate() {
        hasRated = true
        statsOpenCount = 0
        lastPromptDate = Date()
    }
}
