//
//  StreakHistoryManagerTests.swift
//  WobblyTests
//

import Testing
import Foundation
@testable import Wobbly

// PeriodManager.getAchievementStartDate = min(installDate, самая ранняя отметка) —
// реальная (историческая) firstInstallDate этого симулятора может оказаться раньше
// коротких тестовых окон ниже (calculateMaxSoberStreak её учитывает), поэтому так же,
// как в AchievementManagerTests, фиксируем installDate на "сегодня" на время тестов
// и восстанавливаем исходное значение в deinit. .serialized — чтобы параллельные
// экземпляры сьюта не гонялись за одним и тем же ключом UserDefaults.
@Suite(.serialized)
final class StreakHistoryManagerTests {
    private let installDateKey = "firstInstallDate"
    private let originalInstallDate: Any?

    init() {
        originalInstallDate = UserDefaults.standard.object(forKey: installDateKey)
        UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: installDateKey)
    }

    deinit {
        if let originalInstallDate {
            UserDefaults.standard.set(originalInstallDate, forKey: installDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: installDateKey)
        }
    }

    private func key(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month! - 1)-\(c.day!)"
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Calendar.current.startOfDay(for: Date()))!
    }

    @Test func maxSoberStreakCountsConsecutiveNonAlcoholDays() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...6 { data[key(daysAgo(i))] = DrinkLevel.none }
        let streak = StreakHistoryManager.shared.calculateMaxSoberStreak(daysData: data)
        #expect(streak == 7)
    }

    @Test func maxSoberStreakResetsOnAlcoholDay() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...6 { data[key(daysAgo(i))] = DrinkLevel.none }
        data[key(daysAgo(3))] = .medium
        let streak = StreakHistoryManager.shared.calculateMaxSoberStreak(daysData: data)
        #expect(streak == 3)
    }

    @Test func maxDrinkingStreakCountsConsecutiveAlcoholDays() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...2 { data[key(daysAgo(i))] = .heavy }
        let streak = StreakHistoryManager.shared.calculateMaxDrinkingStreak(daysData: data)
        #expect(streak == 3)
    }

    @Test func maxDrinkingStreakBreaksOnGap() {
        var data: [String: DrinkLevel] = [:]
        data[key(daysAgo(5))] = .medium
        data[key(daysAgo(4))] = .medium
        // разрыв на daysAgo(3) — намеренно не заполнен
        data[key(daysAgo(2))] = .medium
        let streak = StreakHistoryManager.shared.calculateMaxDrinkingStreak(daysData: data)
        #expect(streak == 2)
    }

    @Test func littleSportCountsAsAlcoholForDrinkingStreak() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...2 { data[key(daysAgo(i))] = .little_sport }
        let streak = StreakHistoryManager.shared.calculateMaxDrinkingStreak(daysData: data)
        #expect(streak == 3)
    }

    @Test func sportWithoutAlcoholDoesNotBreakSoberStreak() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...6 { data[key(daysAgo(i))] = DrinkLevel.none }
        data[key(daysAgo(3))] = .sport
        let streak = StreakHistoryManager.shared.calculateMaxSoberStreak(daysData: data)
        #expect(streak == 7)
    }
}
