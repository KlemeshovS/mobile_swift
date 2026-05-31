//
//  CalendarTabView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//

import SwiftUI
import WidgetKit

struct CalendarTabView: View {
    @Binding var daysData: [String: DayRecord]
    @State private var selectedDay: DayData?
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @AppStorage("calendarViewMode") private var calendarViewMode: Int = 1
    
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
                colors: [Color(hex: "000000"), Color(hex: "4B3A91")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Шапка ──────────────────────────────────────
                HStack {
                    // Очки вместо месяца и года
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(abs(currentProgressDays))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(currentProgressDays >= 0 ? Color.mint : Color.pink)
                        Text(currentProgressDays >= 0
                             ? NSLocalizedString("progress_label_positive", comment: "")
                             : NSLocalizedString("progress_label_negative", comment: ""))
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    Spacer()

                    Button(action: {
                        calendarViewMode = calendarViewMode == 3 ? 1 : calendarViewMode + 1
                        HapticManager.shared.impact(.light)
                    }) {
                        Image(systemName: viewModeIcon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)

                // ── Контент ─────────────────────────────────────
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(years, id: \.self) { year in
                                YearSectionView(
                                    year: year,
                                    months: localizedCapitalizedMonths,
                                    daysData: daysData,
                                    calendarViewMode: calendarViewMode,
                                    onDaySelected: { day in selectedDay = day },
                                    onDayLongPressed: { day in handleDayLongPress(day) }
                                )
                            }
                        }
                        .padding()
                    }
                    .onAppear {
                        proxy.scrollTo(scrollTarget, anchor: calendarViewMode == 1 ? .center : .top)
                    }
                    .onChange(of: calendarViewMode) { _ in
                        var transaction = Transaction()
                        transaction.disablesAnimations = true
                        withTransaction(transaction) {
                            proxy.scrollTo(scrollTarget, anchor: calendarViewMode == 1 ? .center : .top)
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedDay) { dayData in
            let currentRecord = daysData[dayData.key] ?? DayRecord()
            let isFutureDate = isFutureDay(day: dayData.day, month: dayData.month, year: dayData.year)
            DayRecordSelectionView(
                dayData: dayData,
                currentRecord: currentRecord,
                onRecordSelected: { newRecord in
                    setDayRecord(for: dayData, record: newRecord)
                    selectedDay = nil
                },
                isFutureDate: isFutureDate
            )
        }
    }

    // Куда скроллить в зависимости от режима
    private var scrollTarget: String {
        switch calendarViewMode {
        case 3:
            return "\(currentYear)-header"
        case 2:
            // Показываем строку с предыдущей парой над текущим месяцем
            // Находим начало строки (чётная позиция) для текущего месяца
            let rowStart = (currentMonth / 2) * 2
            // Берём начало предыдущей строки
            let targetMonth = max(rowStart - 2, 0)
            return "\(currentYear)-\(targetMonth)"
        default:
            return "\(currentYear)-\(currentMonth)"
        }
    }

    private var viewModeIcon: String {
        switch calendarViewMode {
        case 1: return "rectangle.grid.1x2"
        case 2: return "rectangle.grid.2x2"
        case 3: return "rectangle.grid.3x2"
        default: return "rectangle.grid.1x2"
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
        }
    }
    
    private func getDayRecord(for dayData: DayData) -> DayRecord {
        return daysData[dayData.key] ?? DayRecord()
    }
    
    private func setDayRecord(for dayData: DayData, record: DayRecord) {
        
        // Если пользователь вручную убрал спорт — запоминаем
        let oldRecord = daysData[dayData.key] ?? DayRecord()
        if oldRecord.hasSport && !record.hasSport {
            HealthKitManager.shared.markDayAsManuallyRemovedSport(dayData.key)
        }
        
        var updatedData = daysData
        
        // Если запись пустая (нет алкоголя и нет спорта) — удаляем ключ
        if record.drinkLevel == .none && !record.hasSport {
            updatedData.removeValue(forKey: dayData.key)
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
        CalendarSyncManager.shared.markLocalUpdated()
        daysData = updatedData
        
        DrinkDataManager().syncDataForWidget()
        WidgetCenter.shared.reloadAllTimelines()

        // Отправляем изменения на сервер
        Task {
            await CalendarSyncManager.shared.pushToServer()
        }
        
        // 🔥 ПРИНУДИТЕЛЬНЫЙ ПЕРЕСЧЁТ АЧИВОК С ТЕКУЩИМИ ДАННЫМИ
        let achievementManager = NewAchievementManager.shared
        let currentLegacyData = dataManager.loadData() // загружаем свежие данные
        let unlocked = achievementManager.checkAllAchievements(daysData: currentLegacyData)
        
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
