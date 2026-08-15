//
//  AchievementManagerTests.swift
//  WobblyTests
//
//  ВАЖНО: NewAchievementManager хранит состояние в РЕАЛЬНОМ файле
//  Documents/wobbly_data.json + Documents/wobbly_auto_backup.json контейнера
//  приложения (WobblyTests подключается как host-injected бандл в Wobbly.app),
//  а PeriodManager может читать/писать UserDefaults.standard["firstInstallDate"].
//  Чтобы не задеть реальные данные пользователя в симуляторе, init()/deinit()
//  ниже делают полный бэкап и восстановление этих трёх точек персистентности
//  вокруг КАЖДОГО теста. Сьют помечен .serialized, чтобы тесты не выполнялись
//  параллельно и не гонялись за одним и тем же файлом.
//

import Testing
import Foundation
@testable import Wobbly

@Suite(.serialized)
final class AchievementManagerTests {
    private let fm = FileManager.default
    private let dataFileURL: URL
    private let autoBackupFileURL: URL
    private let installDateKey = "firstInstallDate"

    private let originalDataBytes: Data?
    private let originalBackupBytes: Data?
    private let originalInstallDate: Any?

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        dataFileURL = documents.appendingPathComponent("wobbly_data.json")
        autoBackupFileURL = documents.appendingPathComponent("wobbly_auto_backup.json")

        originalDataBytes = try? Data(contentsOf: dataFileURL)
        originalBackupBytes = try? Data(contentsOf: autoBackupFileURL)
        originalInstallDate = UserDefaults.standard.object(forKey: installDateKey)

        // Чистое состояние: без файла loadFullAppData() вернёт FullAppData.empty,
        // и recalculateAllAchievements() стартует со всеми ачивками заблокированными.
        try? fm.removeItem(at: dataFileURL)
        try? fm.removeItem(at: autoBackupFileURL)

        // PeriodManager.getAchievementStartDate теперь берёт min(installDate, самая
        // ранняя отметка) — если оставить реальную (историческую) firstInstallDate
        // этого симулятора, она может оказаться раньше, чем окно данных конкретного
        // теста, и расчёт "расползётся" далеко назад. Фиксируем installDate на
        // "сегодня" как детерминированную базовую линию; тесты, которые явно
        // проверяют роль installDate, переопределяют её сами.
        UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: installDateKey)
    }

    deinit {
        if let bytes = originalDataBytes {
            try? bytes.write(to: dataFileURL)
        } else {
            try? fm.removeItem(at: dataFileURL)
        }
        if let bytes = originalBackupBytes {
            try? bytes.write(to: autoBackupFileURL)
        } else {
            try? fm.removeItem(at: autoBackupFileURL)
        }
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

    private func find(_ id: String, in achievements: [Achievement]) -> Achievement? {
        achievements.first { $0.id == id }
    }

    // MARK: - drinkingStreak / soberStreak

    @Test func unlocksDrinkingStreakAchievement() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...2 { data[key(daysAgo(i))] = .heavy }
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("drink_3", in: result)?.isUnlocked == true)
        #expect(find("drink_7", in: result)?.isUnlocked == false)
    }

    @Test func soberStreakRelocksWhenStreakIsBroken() {
        var soberData: [String: DrinkLevel] = [:]
        for i in 0...6 { soberData[key(daysAgo(i))] = DrinkLevel.none }
        let first = NewAchievementManager.shared.recalculateAllAchievements(daysData: soberData)
        #expect(find("sober_7", in: first)?.isUnlocked == true)

        var brokenData = soberData
        brokenData[key(daysAgo(3))] = .medium
        let second = NewAchievementManager.shared.recalculateAllAchievements(daysData: brokenData)
        #expect(find("sober_7", in: second)?.isUnlocked == false)
    }

    // MARK: - milestone

    // Однажды разблокированная milestone-ачивка не блокируется обратно, даже если
    // текущий прогресс упал ниже порога — как и во Flutter-версии (там это сделано
    // явно в updateAchievements). recalculateAllAchievements() теперь исключает
    // .milestone из общей bidirectional-синхронизации так же, как .leftReview.
    @Test func milestoneNeverRelocksOnceUnlocked() {
        // ProgressCalculator.findFirstMarkedDate игнорирует .none/.unknown как
        // "неотмеченные" дни — если ВСЕ записи .none, стартовую дату найти не
        // удаётся и calculate() сразу возвращает (0,0,0). Поэтому самый ранний
        // день явно помечаем .sport, чтобы задать точку отсчёта (см. также
        // ProgressCalculatorTests.onlyNoneMarkedDaysYieldZeroProgress).
        var data: [String: DrinkLevel] = [key(daysAgo(199)): .sport]
        for i in 0...198 { data[key(daysAgo(i))] = DrinkLevel.none } // копим прогресс > 146
        let first = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("milestone_146", in: first)?.isUnlocked == true)

        let second = NewAchievementManager.shared.recalculateAllAchievements(daysData: [:])
        #expect(find("milestone_146", in: second)?.isUnlocked == true)
    }

    @Test func unlocksNegativeMilestoneWhenProgressDropsBelowThreshold() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...9 { data[key(daysAgo(i))] = .heavy }
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("milestone_202_negative", in: result)?.isUnlocked == true)
    }

    // MARK: - drinkingLevelDaysInYear (little/medium/heavy x 50/100)

    // Ключи не обязаны быть валидными календарными датами — countDrinkingLevelDaysInYear
    // просто парсит год из строки "год-месяц-день" и не строит из него Date, поэтому
    // достаточно уникальных ключей с нужным годом.
    private func yearDays(_ count: Int, level: DrinkLevel) -> [String: DrinkLevel] {
        let year = Calendar.current.component(.year, from: Date())
        var data: [String: DrinkLevel] = [:]
        for day in 1...count { data["\(year)-0-\(day)"] = level }
        return data
    }

    @Test func unlocksLittleDaysYear50ButNot100() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(50, level: .little)
        )
        #expect(find("drink_little_days_year_50", in: result)?.isUnlocked == true)
        #expect(find("drink_little_days_year_100", in: result)?.isUnlocked == false)
    }

    @Test func unlocksLittleDaysYear100() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(100, level: .little)
        )
        #expect(find("drink_little_days_year_100", in: result)?.isUnlocked == true)
    }

    @Test func unlocksMediumDaysYear50ButNot100() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(50, level: .medium)
        )
        #expect(find("drink_medium_days_year_50", in: result)?.isUnlocked == true)
        #expect(find("drink_medium_days_year_100", in: result)?.isUnlocked == false)
    }

    @Test func unlocksHeavyDaysYear50ButNot100() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(50, level: .heavy)
        )
        #expect(find("drink_heavy_days_year_50", in: result)?.isUnlocked == true)
        #expect(find("drink_heavy_days_year_100", in: result)?.isUnlocked == false)
    }

    @Test func littleSportCountsTowardTheLittleLevelAchievement() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(50, level: .little_sport)
        )
        #expect(find("drink_little_days_year_50", in: result)?.isUnlocked == true)
    }

    @Test func daysAtOneLevelDoNotCountTowardAnotherLevelsAchievement() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(
            daysData: yearDays(50, level: .heavy)
        )
        #expect(find("drink_little_days_year_50", in: result)?.isUnlocked == false)
        #expect(find("drink_medium_days_year_50", in: result)?.isUnlocked == false)
        #expect(find("drink_heavy_days_year_50", in: result)?.isUnlocked == true)
    }

    // MARK: - leftReview (ручная разблокировка)

    @Test func leftReviewIsNeverAutoUnlocked() {
        var data: [String: DrinkLevel] = [:]
        for i in 0...399 { data[key(daysAgo(i))] = DrinkLevel.none }
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("left_review", in: result)?.isUnlocked == false)
    }

    @Test func unlockReviewAchievementUnlocksExactlyOnce() {
        let unlocked = NewAchievementManager.shared.unlockReviewAchievement()
        #expect(unlocked != nil)
        #expect(unlocked?.id == "left_review")

        let again = NewAchievementManager.shared.unlockReviewAchievement()
        #expect(again == nil)
    }

    // MARK: - uniqueEvent — Новый год (см. Flutter-регрессию "фикс новогодней ачивки")

    @Test func emptyDataNeverUnlocksSoberNewYear() {
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: [:])
        #expect(find("sober_new_year", in: result)?.isUnlocked == false)
    }

    // Намеренное поведение (НЕ баг): если пользователь уже пользовался приложением
    // на момент 31 декабря (т.е. дата раньше startDate), но просто не отметил этот
    // конкретный день, отсутствующая запись по умолчанию считается трезвой — так же,
    // как и в остальной логике приложения (ProgressCalculator/StreakHistoryManager
    // трактуют неотмеченные дни как трезвые). checkNewYearEvent обязан отличать
    // "день был, но не отмечен" от "приложение ещё не использовалось" — это и
    // делает проверка `dec31 >= startDate` чуть ниже.
    @Test func missingDec31RecordCountsAsSoberIfAppWasAlreadyInUse() {
        // Единственная запись — намеренно не 31 декабря, просто чтобы задать
        // достаточно раннюю startDate, покрывающую весь 3-летний диапазон проверки.
        let data: [String: DrinkLevel] = [key(daysAgo(3000)): .none]

        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)

        #expect(find("sober_new_year", in: result)?.isUnlocked == true)
    }

    // Дата установки — тоже валидный признак "приложением уже пользовались", даже
    // если пользователь ни разу не отмечал ни одного дня до этого конкретного 31
    // декабря. getAchievementStartDate() берёт min(installDate, самая ранняя
    // отметка) именно для этого случая.
    @Test func missingDec31RecordCountsAsSoberWhenOnlyInstallDatePrecedesIt() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date()) - 1
        let dec31 = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        let installDate = calendar.date(byAdding: .day, value: -5, to: dec31)!
        UserDefaults.standard.set(installDate, forKey: installDateKey)

        // Первая ОТМЕЧЕННАЯ запись — намного позже 31 декабря (не отмечал месяцами).
        let data: [String: DrinkLevel] = [key(daysAgo(10)): .none]

        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)

        #expect(find("sober_new_year", in: result)?.isUnlocked == true)
    }

    // И наоборот: если приложение установили ПОСЛЕ 31 декабря, тот Новый год не
    // должен засчитываться, даже если данных вообще нет.
    @Test func doesNotUnlockSoberNewYearWhenInstalledAfterDec31() {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date()) - 1
        let dec31 = calendar.date(from: DateComponents(year: year, month: 12, day: 31))!
        let installDate = calendar.date(byAdding: .day, value: 5, to: dec31)!
        UserDefaults.standard.set(installDate, forKey: installDateKey)

        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: [:])

        #expect(find("sober_new_year", in: result)?.isUnlocked == false)
    }

    @Test func unlocksSoberNewYearForAnActualSoberDec31Record() {
        let year = Calendar.current.component(.year, from: Date()) - 1
        var data: [String: DrinkLevel] = [key(daysAgo(3000)): .none]
        data["\(year)-11-31"] = DrinkLevel.none // 31 декабря, месяц 0-based => 11
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("sober_new_year", in: result)?.isUnlocked == true)
    }

    // В отличие от sober_new_year, здесь отсутствие записи НЕ засчитывается:
    // она дефолтится в .none, а .none не удовлетворяет условию
    // hadSport = (level == .sport || level == .little_sport). Для sport_new_year
    // нужна явная отметка тренировки.
    @Test func missingDec31RecordDoesNotUnlockSportNewYear() {
        let data: [String: DrinkLevel] = [key(daysAgo(3000)): .none]
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("sport_new_year", in: result)?.isUnlocked == false)
    }

    @Test func sportOnDec31UnlocksSportNewYear() {
        let year = Calendar.current.component(.year, from: Date()) - 1
        var data: [String: DrinkLevel] = [key(daysAgo(3000)): .none]
        data["\(year)-11-31"] = .sport
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("sport_new_year", in: result)?.isUnlocked == true)
    }

    // Каждый проверяемый год явно помечен пьяным 31 декабря — иначе отсутствие
    // записи само по себе засчиталось бы как трезвый день (см. тест выше) и
    // замаскировало бы то, что мы на самом деле хотим проверить: пьяный Новый год
    // не должен разблокировать ачивку.
    @Test func drinkingOnEveryCheckedDec31DoesNotUnlockSoberNewYear() {
        let currentYear = Calendar.current.component(.year, from: Date())
        var data: [String: DrinkLevel] = [key(daysAgo(3000)): .none]
        for year in (currentYear - 3)...currentYear {
            data["\(year)-11-31"] = .heavy
        }
        let result = NewAchievementManager.shared.recalculateAllAchievements(daysData: data)
        #expect(find("sober_new_year", in: result)?.isUnlocked == false)
    }
}
