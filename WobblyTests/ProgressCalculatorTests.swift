//
//  ProgressCalculatorTests.swift
//  WobblyTests
//

import Testing
import Foundation
@testable import Wobbly

struct ProgressCalculatorTests {

    private func key(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(c.year!)-\(c.month! - 1)-\(c.day!)"
    }

    private func daysAgo(_ n: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -n, to: Calendar.current.startOfDay(for: Date()))!
    }

    @Test func emptyDataYieldsZeroProgress() {
        let result = ProgressCalculator.calculate(from: [:])
        #expect(result.current == 0)
        #expect(result.max == 0)
        #expect(result.min == 0)
    }

    // findFirstMarkedDate пропускает дни .none/.unknown как "неотмеченные" —
    // без хотя бы одной .sport/.little/... записи расчёт стартовать не может.
    @Test func onlyNoneMarkedDaysYieldZeroProgress() {
        let result = ProgressCalculator.calculate(from: [key(daysAgo(0)): .none])
        #expect(result.current == 0)
    }

    @Test func consecutiveSoberDaysAccumulatePositiveProgress() {
        let result = ProgressCalculator.calculate(from: [key(daysAgo(10)): .sport])
        #expect(result.current > 0)
        #expect(result.max == result.current)
        #expect(result.min == 0)
    }

    @Test func heavyDrinkingStreakDrivesProgressNegative() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...9 { data[key(daysAgo(i))] = .heavy }
        let result = ProgressCalculator.calculate(from: data)
        #expect(result.current < 0)
        #expect(result.min == result.current)
    }

    @Test func sportDayScoresTwentyOnItsOwn() {
        let result = ProgressCalculator.calculate(from: [key(daysAgo(0)): .sport])
        #expect(result.current == 20)
    }

    // Документирует РАСХОЖДЕНИЕ с Flutter-версией (SobrietyProgressCalculator._calculatePenalty):
    // там штрафной коэффициент фиксируется на 3.5x начиная с 4-го дня подряд и дальше
    // не меняется. В Swift-версии (ProgressCalculator.calculatePenalty) коэффициент
    // явно задан только для дней 1-4 (1.0/1.5/2.5/3.5), а с 5-го дня default-кейс
    // ПАДАЕТ до 3.0x — то есть длинный запой "дешевеет" день ото дня после 4-го,
    // а не остаётся на пике штрафа, как во Flutter-версии.
    @Test func penaltyCoefficientPeaksAtDayFourThenDropsOnDayFive() {
        #expect(ProgressCalculator.calculatePenalty(base: 10, consecutiveDays: 4) == 35) // ceil(10 * 3.5)
        #expect(ProgressCalculator.calculatePenalty(base: 10, consecutiveDays: 5) == 30) // ceil(10 * 3.0), а не 35
    }

    @Test func findFirstMarkedDateIgnoresNoneAndUnknown() {
        let data: [String: DrinkLevel] = [
            key(daysAgo(5)): .none,
            key(daysAgo(3)): .unknown,
            key(daysAgo(1)): .little,
        ]
        let first = ProgressCalculator.findFirstMarkedDate(daysData: data)
        #expect(first != nil)
        #expect(Calendar.current.isDate(first!, inSameDayAs: daysAgo(1)))
    }
}
