//
//  CalendarTabView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//

import SwiftUI

struct CalendarTabView: View {
    @Binding var daysData: [String: DayRecord]
    @State private var selectedDay: DayData?
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private let years = [2025, 2026, 2027]
    
    private var localizedCapitalizedMonths: [String] {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale
        return formatter.standaloneMonthSymbols?.map {
            $0.capitalized
        } ?? []
    }
    
    private var currentProgressDays: Int {
        let legacy = daysData.mapValues { $0.toLegacyDrinkLevel }
        let progress = ProgressCalculator.calculate(from: legacy).current
        print("📊 CalendarTabView currentProgressDays = \(progress), daysData.count = \(daysData.count)")
        return progress
    }
    
    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }
    
    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date()) - 1
    }
    
    private let dataManager = DrinkDataManager()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "000000"),
                    Color(hex: "4B3A91")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        SobrietyProgressView(progressDays: currentProgressDays)
                            .id(currentProgressDays)
                            .padding(.horizontal)
                        ForEach(years, id: \.self) { year in
                            YearSectionView(
                                year: year,
                                months: localizedCapitalizedMonths,
                                daysData: daysData,
                                onDaySelected: { day in
                                    selectedDay = day
                                },
                                onDayLongPressed: { day in
                                    handleDayLongPress(day)
                                }
                            )
                        }
                    }
                    .padding()
                }
                .onAppear {
                    proxy.scrollTo("\(currentYear)-\(currentMonth)", anchor: .center)
                }
            }
        }
        .sheet(item: $selectedDay) { dayData in
            // 🔥 ИСПРАВЛЕНИЕ: Берем данные напрямую, не через функцию
            let currentRecord = daysData[dayData.key] ?? DayRecord()
            let isFutureDate = isFutureDay(day: dayData.day, month: dayData.month, year: dayData.year)
            
            DayRecordSelectionView(
                dayData: dayData,
                currentRecord: currentRecord,
                onRecordSelected: { newRecord in
                    print("🎯 onRecordSelected вызван с записью: drinkLevel=\(newRecord.drinkLevel), hasSport=\(newRecord.hasSport)")
                    setDayRecord(for: dayData, record: newRecord)
                    selectedDay = nil
                },
                isFutureDate: isFutureDate
            )
        }
    }
    
    private func refreshData() {
        // Загружаем старые данные и конвертируем в новые
        let legacyData = dataManager.loadData()
        
        var newData: [String: DayRecord] = [:]
        for (key, level) in legacyData {
            newData[key] = DayRecord.fromLegacyDrinkLevel(level)
        }
        
        if newData != daysData {
            daysData = newData
            print("🔄 Данные обновлены в UI: \(daysData.count) записей")
        }
    }
    
    private func getDayRecord(for dayData: DayData) -> DayRecord {
        return daysData[dayData.key] ?? DayRecord()
    }
    
    private func setDayRecord(for dayData: DayData, record: DayRecord) {
        print("🔄 Устанавливаем запись для \(dayData.key): drinkLevel=\(record.drinkLevel), hasSport=\(record.hasSport)")
        
        var updatedData = daysData
        
        // Если запись пустая (нет алкоголя и нет спорта) — удаляем ключ
        if record.drinkLevel == .none && !record.hasSport {
            updatedData.removeValue(forKey: dayData.key)
            print("🗑️ Удалена запись для \(dayData.key) (пустой день)")
        } else {
            updatedData[dayData.key] = record
        }
        
        // Сохраняем через DrinkDataManager
        let dataManager = DrinkDataManager()
        var legacyData: [String: DrinkLevel] = [:]
        for (key, rec) in updatedData {
            legacyData[key] = rec.toLegacyDrinkLevel
        }
        dataManager.saveData(legacyData)
        
        daysData = updatedData
        
        // 🔥 ПРИНУДИТЕЛЬНЫЙ ПЕРЕСЧЁТ АЧИВОК С ТЕКУЩИМИ ДАННЫМИ
        let achievementManager = NewAchievementManager.shared
        let currentLegacyData = dataManager.loadData() // загружаем свежие данные
        let unlocked = achievementManager.checkAllAchievements(daysData: currentLegacyData)
        print("🎯 Пересчитаны ачивки после изменения данных, разблокировано: \(unlocked.filter { $0.isUnlocked }.count)")
        
        // Уведомляем все подписанные View (например, StatsTabView) для обновления UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .drinkDataChanged, object: nil)

            // Проверяем новые ачивки после изменения дня
            let freshData = DrinkDataManager().loadData()
            AppNotificationManager.shared.checkNewAchievements(daysData: freshData)
        }
    }
    
    private func handleDayLongPress(_ dayData: DayData) {
        let currentRecord = getDayRecord(for: dayData)
        var newRecord = currentRecord
        
        // Переключаем спорт при долгом нажатии
        newRecord.hasSport = !currentRecord.hasSport
        
        // Если был medium/heavy и включаем спорт - сбрасываем спорт
        if (currentRecord.drinkLevel == .medium || currentRecord.drinkLevel == .heavy) && newRecord.hasSport {
            newRecord.hasSport = false
        }
        
        HapticManager.shared.impact(.medium)
        
        print("🔁 Долгое нажатие на \(dayData.key): hasSport \(currentRecord.hasSport) -> \(newRecord.hasSport)")
        setDayRecord(for: dayData, record: newRecord)
    }
    
    private func isFutureDay(day: Int, month: Int, year: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1
        dateComponents.day = day
        
        guard let checkDate = calendar.date(from: dateComponents) else {
            return false
        }
        
        return checkDate > today
    }
}

struct CalendarTabView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarTabView(daysData: .constant([:]))
    }
}
