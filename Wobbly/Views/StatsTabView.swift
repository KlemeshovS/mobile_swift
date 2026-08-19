//
//  StatsTabView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//
import SwiftUI

struct StatsTabView: View {
    let daysData: [String: DrinkLevel]
    @Binding var showSettingsMenu: Bool
    var onShowAchievement: ((Achievement) -> Void)? = nil
    var onShowExplanation: ((String, String) -> Void)? = nil
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    @State private var localDaysData: [String: DrinkLevel] = [:]
    
    @State private var userStatus: UserStatus?
    @State private var achievements: [Achievement] = []
    @State private var showAllAchievements = false
    @State private var showExportSuccess = false
    @State private var exportErrorMessage = ""
    @State private var showExportError = false
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    
    
    private let achievementManager = NewAchievementManager.shared
    private let fileExportManager = FileExportManager()
    
    private var availableYears: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return [currentYear, currentYear - 1].filter { yearHasData(year: $0) }
    }
    
    private var globalStartDate: Date {
        return PeriodManager.shared.getAchievementStartDate(daysData: localDaysData)
    }
    
    private func yearHasData(year: Int) -> Bool {
        if year == Calendar.current.component(.year, from: Date()) {
            return true
        }
        
        return daysData.keys.contains { key in
            key.hasPrefix("\(year)-")
        }
    }
    
    var displayStreak: Int {
        let streak = calculateLongestDrinkingStreak()
        return streak == 1 ? 0 : streak
    }
    
    var body: some View {
        ZStack {
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
                
                VStack(spacing: 0) {
                    // КАСТОМНАЯ ШАПКА
                    HStack {
                        // ВЫБОР ГОДА
                        Menu {
                            ForEach(availableYears, id: \.self) { year in
                                Button(action: {
                                    selectedYear = year
                                    HapticManager.shared.impact(.light)
                                }) {
                                    HStack {
                                        // Вариант 1: Составная строка (проще)
                                        Text(String(year) + " " + NSLocalizedString("year_suffix", comment: "Слово 'год' после числа"))
                                        
                                        if year == selectedYear {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                // Аналогично для лейбла
                                Text(String(selectedYear) + " " + NSLocalizedString("year_suffix", comment: "Слово 'год' после числа"))
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        HStack(alignment: .center, spacing: 0) {
                            Button(action: { generateAndShare() }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .offset(y: -2) // компенсируем встроенный отступ стрелки
                            }

                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    showSettingsMenu.toggle()
                                }
                                HapticManager.shared.impact(.light)
                            }) {
                                Image(systemName: "gearshape")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: "000000"),
                                Color(hex: "000000")
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            // БЛОК СТАТУСА ПОЛЬЗОВАТЕЛЯ
                            VStack(spacing: 8) {
                                if let status = userStatus {
                                    // Кружок с иконкой статуса
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: status.color))
                                            .frame(width: 50, height: 50)
                                            .shadow(color: Color(hex: status.color).opacity(0.5), radius: 10, x: 0, y: 5)
                                        
                                        Image(status.iconName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 35, height: 35)
                                    }
                                    
                                    // Название статуса
                                    Text(status.displayName)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.center)
                                    
                                } else {
                                    // Пока данные загружаются
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 100, height: 100)
                                        
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    }
                                    
                                    Text("Определяем статус...")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            //       .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            //       .background(Color.white.opacity(0.05))
                            //       .cornerRadius(20)
                            .padding(.horizontal, 20)
                            //       .padding(.bottom, 5)
                            .onTapGesture {
                                if let status = userStatus {
                                    onShowExplanation?(status.displayName, status.description)
                                    HapticManager.shared.impact(.light)
                                }
                            }
                            
                            // БЛОК ПРОГРЕССА ТРЕЗВОСТИ
                            VStack(alignment: .leading, spacing: 12) {
                                SobrietyProgressView(
                                    progressDays: currentProgressDays,
                                    daysData: localDaysData,
                                    onShowInfo: onShowExplanation
                                )
                                .id(currentProgressDays)
                            }
                            .padding(.horizontal, 5)
                            
                            // Основная статистика
                            VStack(alignment: .leading, spacing: 8) {
                                VStack(spacing: 12) {
                                    HStack {
                                        SoberStatItemView(count: calculateCurrentSoberStreakOptimized(),
                                                          title: "sober_streak_title",
                                                          backgroundColor: Color(hex: "F6C7DC"),
                                                          textColor: .black,
                                                          imageName: "sober_icon")
                                        .frame(maxWidth: .infinity)
                                    }
                                    
                                    HStack {
                                        StatItemView(count: displayStreak,
                                                     title: "drinking_streak_title",
                                                     backgroundColor: Color(hex: "#BBA0F2"),
                                                     textColor: .black,
                                                     imageName: "drunk_icon")
                                        
                                        StatItemView(count: calculateLongestSoberStreak(),
                                                     title: "max_sober_streak_title",
                                                     backgroundColor: Color(hex: "#A8E6A8"),
                                                     textColor: .black,
                                                     imageName: "max_sober_icon")
                                    }
                                    
                                    let yearStats = calculateYearStats()
                                    HStack {
                                        StatItemView(count: yearStats.totalDrinking,
                                                     title: "total_drinking_days_title",
                                                     backgroundColor: Color(hex: "#BBA0F2"),
                                                     textColor: .black,
                                                     imageName: "total_drunk_icon")
                                        
                                        StatItemView(count: yearStats.totalDays - yearStats.totalDrinking,
                                                     title: "total_sober_days_title",
                                                     backgroundColor: Color(hex: "#A8E6A8"),
                                                     textColor: .black,
                                                     imageName: "total_sober_icon")
                                    }
                                    
                                    HStack {
                                        StatItemView(count: yearStats.little,
                                                     title: "drink_level_little",
                                                     backgroundColor: Color(hex: "#BDC7FA"),
                                                     textColor: .black,
                                                     imageName: "little_normal")
                                        
                                        StatItemView(count: yearStats.medium,
                                                     title: "drink_level_medium",
                                                     backgroundColor: Color(hex: "#BDC7FA"),
                                                     textColor: .black,
                                                     imageName: "medium_normal")
                                        
                                        StatItemView(count: yearStats.heavy,
                                                     title: "drink_level_heavy",
                                                     backgroundColor: Color(hex: "#BDC7FA"),
                                                     textColor: .black,
                                                     imageName: "heavy_normal")
                                    }
                                    
                                    HStack {
                                        SportStatItemView(count: calculateSportDays(), title: "sport_days_title")
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal, 5)

                            // Пари: выигрыши/поражения
                            if AuthStateManager.shared.sessionType == .authenticated {
                                BetsStatsWidgetView()
                                    .padding(.horizontal, 5)
                            }

                            // Алкоголь vs Спорт
                            VStack(alignment: .leading, spacing: 12) {
                                // Получаем статистику за год
                                let yearStats = calculateYearStats()
                                
                                // Считаем общее количество отмеченных дней (дни с алкоголем ИЛИ спортом ИЛИ тем и другим)
                                let totalTrackedDays = yearStats.drinkingDays + yearStats.sport - yearStats.little_sport
                                
                                // Если есть отмеченные дни
                                if totalTrackedDays > 0 {
                                    // Процент алкогольных дней от общего числа отмеченных дней
                                    let drinkingPercentage = (Double(yearStats.drinkingDays) / Double(totalTrackedDays) * 100).rounded()
                                    
                                    // Процент спортивных дней от общего числа отмеченных дней
                                    let sportPercentage = (Double(yearStats.sport) / Double(totalTrackedDays) * 100).rounded()
                                    
                                    // 🔥 КОРРЕКЦИЯ: Если сумма > 100 из-за комбинаций, нормализуем
                                    let total = drinkingPercentage + sportPercentage
                                    let normalizedDrinking = (drinkingPercentage / total * 100).rounded()
                                    let normalizedSport = (sportPercentage / total * 100).rounded()
                                    
                                    PercentageBarView(
                                        drinkingPercentage: normalizedDrinking,
                                        sportPercentage: normalizedSport
                                    )
                                } else {
                                    // Нет отмеченных дней - показываем пустую шкалу
                                    PercentageBarView(
                                        drinkingPercentage: 0,
                                        sportPercentage: 0
                                    )
                                }
                            }
                            .padding(.horizontal, 5)
                            
                            // Ваша неделя
                            WeekStatsView(daysData: localDaysData, selectedYear: selectedYear)
                                .padding(.horizontal, 5)

                            // Корреляция спорт / алкоголь
                            SportCorrelationView(daysData: localDaysData, selectedYear: selectedYear)
                                .padding(.horizontal, 5)

                            // Дневник триггеров — топ причин выпить
                            TriggerInsightsView(selectedYear: selectedYear)
                                .padding(.horizontal, 5)

                            // Среднее за месяц
                            MonthlyAverageView(daysData: localDaysData, selectedYear: selectedYear)
                                .padding(.horizontal, 5)

                            // График алкоголя в текущем месяце
                            AlcoholChartView(daysData: localDaysData, selectedYear: selectedYear,
                                             onShowInfo: onShowExplanation)
                                .padding(.horizontal, 5)

                            // БЛОК С ФАКТАМИ О ТРЕЗВОСТИ
                            VStack(alignment: .leading, spacing: 12) {
                                let progressDays = calculateSoftSoberStreak()
                                AdaptiveSobrietyFactsView(soberDays: progressDays)
                            }
                            .padding(.horizontal, 5)
                            
                            // Достижения
                            achievementsSection
                                .padding(.horizontal, 5)
                                .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 5)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .alert("export_finished_message", isPresented: $showExportSuccess) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("export_ready_message")
        }
        .alert("export_error_message", isPresented: $showExportError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(exportErrorMessage)
        }
        .sheet(isPresented: $showAllAchievements) {
            AllAchievementsView()
        }
        
        .onAppear {
            localDaysData = daysData
            forceRefreshAchievements()
            selectedYear = Calendar.current.component(.year, from: Date())
            updateUserStatus()
        }
        
        .onReceive(NotificationCenter.default.publisher(for: .drinkDataChanged)) { _ in
            DispatchQueue.main.async {
                print("📢 StatsTabView получил уведомление .drinkDataChanged")
                let newData = DrinkDataManager().loadData()
                print("   Загружено записей: \(newData.count)")
                localDaysData = newData
                print("   localDaysData обновлён, теперь count = \(localDaysData.count)")
                
                // Проверим количество спортивных дней до и после
                let sportDaysBefore = self.calculateSportDays()
                self.checkAchievements()
                self.updateUserStatus()
                let sportDaysAfter = self.calculateSportDays()
                print("   Спортивных дней до пересчёта: \(sportDaysBefore), после: \(sportDaysAfter)")
            }
        }
    }
    
    // MARK: - Вспомогательные View и функции
    
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("achievements", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    HapticManager.shared.impact(.light)
                    showAllAchievements = true
                }) {
                    Text(NSLocalizedString("all_achievements", comment: ""))
                }
                .font(.caption)
                .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            
            if achievements.isEmpty {
                Text(NSLocalizedString("achievement_not_earned_yet", comment: ""))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ZStack {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 16) {
                        ForEach(achievements) { achievement in
                            AchievementView(achievement: achievement) { selectedAchievement in
                                onShowAchievement?(selectedAchievement)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 100)
            }
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    private func SoberStatItemView(count: Int, title: String, backgroundColor: Color, textColor: Color, imageName: String) -> some View {
        HStack {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(textColor)
            
            Text(NSLocalizedString(title, comment: ""))
                .font(.system(size: 14))
                .foregroundColor(textColor)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(textColor)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .padding(.horizontal, 12)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            showExplanationForStat(title: title)
            HapticManager.shared.impact(.light)
        }
    }
    
    private func StatItemView(count: Int, title: String, backgroundColor: Color, textColor: Color, imageName: String) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(textColor)
                Text("\(count)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(textColor)
            }
            
            Text(NSLocalizedString(title, comment: ""))
                .font(.system(size: 14))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            showExplanationForStat(title: title)
            HapticManager.shared.impact(.light)
        }
    }
    
    private func SportStatItemView(count: Int, title: String) -> some View {
        HStack {
            Image("sport_icon")
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
            
            Text(NSLocalizedString(title, comment: ""))
                .font(.system(size: 14))
                .foregroundColor(Color.black)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.black)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .padding(.horizontal, 12)
        .background(Color(hex: "#EFFFB6"))
        .cornerRadius(16)
        .onTapGesture {
            showExplanationForStat(title: title)
            HapticManager.shared.impact(.light)
        }
    }
    
    struct PercentageBarView: View {
        let drinkingPercentage: Double
        let sportPercentage: Double
        @State private var animationProgress: CGFloat = 0
        
        var body: some View {
            VStack(spacing: 10) {
                Text(NSLocalizedString("alco_vs_sport", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white)
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Фоновая полоска (серая)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 25)
                        
                        HStack(spacing: 0) {
                            // Алкогольная часть
                            if drinkingPercentage > 0 {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.red, .orange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * CGFloat(drinkingPercentage) / 100) * animationProgress)
                            }
                            
                            // Спортивная часть
                            if sportPercentage > 0 {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: (geometry.size.width * CGFloat(sportPercentage) / 100) * animationProgress)
                            }
                        }
                    }
                    // Это ключевой момент - применяем скругление ко всему контейнеру
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .frame(height: 25)
                
                HStack(spacing: 20) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 10, height: 10)
                        Text(String(format: NSLocalizedString("alcohol_percentage %lld%%",
                                                              comment: "Alcohol: X%"),
                                    Int(drinkingPercentage)))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    }
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        Text(String(format: NSLocalizedString("Sport %lld%%",
                                                              comment: "Sport: X%"),
                                    Int(sportPercentage)))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                    }
                }
                .padding(.horizontal, 5)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animationProgress = 1.0
                }
            }
        }
    }
    // MARK: - Вычисления статистики
    
    private func forceRefreshAchievements() {
        let updatedAchievements = NewAchievementManager.shared.loadUnlockedAchievements()
        self.achievements = updatedAchievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockDate ?? .distantPast) > ($1.unlockDate ?? .distantPast) }
    }

    private func checkAchievements() {
        let updatedAchievements = achievementManager.recalculateAllAchievements(daysData: localDaysData)
        self.achievements = updatedAchievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockDate ?? .distantPast) > ($1.unlockDate ?? .distantPast) }
        print("🏆 StatsTabView: обновлено \(self.achievements.count) разблокированных ачивок")
    }
    
    private struct YearStats {
        let little: Int
        let medium: Int
        let heavy: Int
        let sport: Int
        let little_sport: Int
        let drinkingDays: Int
        let totalDays: Int
        let totalDrinking: Int
    }
    
    private func calculateYearStats() -> YearStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = globalStartDate
        let startYear = calendar.component(.year, from: startDate)
        let startMonth = calendar.component(.month, from: startDate) - 1 // 0-based
        let startDay = calendar.component(.day, from: startDate)
        
        // Если выбранный год меньше года начала – данных нет
        guard selectedYear >= startYear else {
            return YearStats(little: 0, medium: 0, heavy: 0, sport: 0, little_sport: 0,
                             drinkingDays: 0, totalDays: 0, totalDrinking: 0)
        }
        
        var little = 0, medium = 0, heavy = 0, sport = 0, little_sport = 0
        var totalDaysPassed = 0, drinkingDays = 0
        
        let currentYear = calendar.component(.year, from: Date())
        let isCurrentYear = selectedYear == currentYear
        let currentMonth = isCurrentYear ? calendar.component(.month, from: Date()) - 1 : 11
        let currentDay = isCurrentYear ? calendar.component(.day, from: Date()) : 31
        
        for month in 0..<12 {
            // Пропускаем месяцы до месяца начала, если год совпадает с годом начала
            if selectedYear == startYear && month < startMonth {
                continue
            }
            if isCurrentYear && month > currentMonth { continue }
            
            let yearForMonth = selectedYear
            let daysInMonth = CalendarUtils.daysInMonth(month: month, year: yearForMonth)
            
            // Определяем первый день месяца для учёта
            var firstDay = 1
            if selectedYear == startYear && month == startMonth {
                firstDay = startDay
            }
            
            let lastDay = (isCurrentYear && month == currentMonth) ? currentDay : daysInMonth
            guard firstDay <= lastDay else { continue }
            
            let daysPassed = lastDay - firstDay + 1
            totalDaysPassed += daysPassed
            
            for day in firstDay...lastDay {
                let dayData = DayData(day: day, month: month, year: yearForMonth)
                let level = getDrinkLevel(for: dayData)
                
                switch level {
                case .little:
                    little += 1
                    drinkingDays += 1
                case .medium:
                    medium += 1
                    drinkingDays += 1
                case .heavy:
                    heavy += 1
                    drinkingDays += 1
                case .sport:
                    sport += 1
                case .little_sport:
                    little += 1
                    drinkingDays += 1
                    sport += 1
                    little_sport += 1
                case .medium_sport:
                    medium += 1
                    drinkingDays += 1
                    sport += 1
                case .heavy_sport:
                    heavy += 1
                    drinkingDays += 1
                    sport += 1
                default: break
                }
            }
        }
        
        return YearStats(
            little: little,
            medium: medium,
            heavy: heavy,
            sport: sport,
            little_sport: little_sport,
            drinkingDays: drinkingDays,
            totalDays: totalDaysPassed,
            totalDrinking: little + medium + heavy
        )
    }
    
    
    private func calculateSportDays() -> Int {
        var sportDays = 0
        
        let calendar = Calendar.current
        let today = Date()
        let currentComponents = calendar.dateComponents([.year, .month, .day], from: today)
        let currentYear = currentComponents.year ?? selectedYear
        let currentMonth = (currentComponents.month ?? 1) - 1
        let currentDay = currentComponents.day ?? 1
        
        let isCurrentYear = selectedYear == currentYear
        
        for month in 0..<12 {
            if isCurrentYear && month > currentMonth {
                continue
            }
            
            let yearForMonth = selectedYear
            let daysInThisMonth = CalendarUtils.daysInMonth(month: month, year: yearForMonth)
            let daysPassedInThisMonth: Int
            
            if !isCurrentYear {
                daysPassedInThisMonth = daysInThisMonth
            } else if month < currentMonth {
                daysPassedInThisMonth = daysInThisMonth
            } else if month == currentMonth {
                daysPassedInThisMonth = currentDay
            } else {
                daysPassedInThisMonth = 0
            }
            
            guard daysPassedInThisMonth > 0 else { continue }
            
            for day in 1...daysPassedInThisMonth {
                let dayData = DayData(day: day, month: month, year: yearForMonth)
                let level = getDrinkLevel(for: dayData)
                
                if level == .sport || level == .little_sport || level == .medium_sport || level == .heavy_sport {
                    sportDays += 1
                }
            }
        }
        
        return sportDays
    }
    
    private func calculateSoftSoberStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = globalStartDate
        guard today >= startDate else { return 0 }
        let maxDays = (calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1

        var streak = 0
        for dayOffset in 0..<maxDays {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                  date >= startDate else { break }

            let dayData = DayData(
                day: calendar.component(.day, from: date),
                month: calendar.component(.month, from: date) - 1,
                year: calendar.component(.year, from: date)
            )
            let level = localDaysData[dayData.key] ?? .none

            // Сбрасываем только на medium и heavy (включая комбо со спортом)
            if level == .medium || level == .heavy || level == .medium_sport || level == .heavy_sport {
                return streak
            } else {
                streak += 1
            }
        }
        return streak
    }
    
    private func calculateCurrentSoberStreakOptimized() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = globalStartDate
        let currentYear = calendar.component(.year, from: Date())
        
        if selectedYear != currentYear {
            // Для не текущего года – streak на конец года
            guard let endDate = calendar.date(from: DateComponents(year: selectedYear, month: 12, day: 31)) else {
                return 0
            }
            guard endDate >= startDate else { return 0 }
            
            let daysInYear = calendar.range(of: .day, in: .year, for: endDate)?.count ?? 366
            var streak = 0
            for dayOffset in 0..<daysInYear {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: endDate),
                      date >= startDate,
                      calendar.component(.year, from: date) == selectedYear else { break }
                
                let dayData = DayData(day: calendar.component(.day, from: date),
                                      month: calendar.component(.month, from: date) - 1,
                                      year: selectedYear)
                let level = localDaysData[dayData.key] ?? .none
                
                if level == .little || level == .medium || level == .heavy || level == .little_sport || level == .medium_sport || level == .heavy_sport {
                    return streak
                } else {
                    streak += 1
                }
            }
            return streak
        } else {
            // Текущий год
            guard today >= startDate else { return 0 }
            let maxDays = (calendar.dateComponents([.day], from: startDate, to: today).day ?? 0) + 1
            var streak = 0
            for dayOffset in 0..<maxDays {
                guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today),
                      date >= startDate,
                      calendar.component(.year, from: date) == selectedYear else { break }
                
                let dayData = DayData(day: calendar.component(.day, from: date),
                                      month: calendar.component(.month, from: date) - 1,
                                      year: selectedYear)
                let level = localDaysData[dayData.key] ?? .none
                
                if level == .little || level == .medium || level == .heavy || level == .little_sport || level == .medium_sport || level == .heavy_sport{
                    return streak
                } else {
                    streak += 1
                }
            }
            return streak
        }
    }
    
    func calculateLongestSoberStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = globalStartDate
        
        let yearStart = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let yearEnd = calendar.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        let periodStart = max(startDate, yearStart)
        let periodEnd = min(today, yearEnd)
        
        guard periodStart <= periodEnd else { return 0 }
        
        var maxStreak = 0
        var currentStreak = 0
        var date = periodStart
        
        while date <= periodEnd {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let day = components.day, let month = components.month, let year = components.year else {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }
            
            let dayData = DayData(day: day, month: month - 1, year: year)
            let level = getDrinkLevel(for: dayData)
            
            if level == .little || level == .medium || level == .heavy || level == .little_sport || level == .medium_sport || level == .heavy_sport {
                currentStreak = 0
            } else {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            }
            
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return maxStreak
    }
    
    func calculateLongestDrinkingStreak() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startDate = globalStartDate
        
        let yearStart = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1))!
        let yearEnd = calendar.date(from: DateComponents(year: selectedYear, month: 12, day: 31))!
        let periodStart = max(startDate, yearStart)
        let periodEnd = min(today, yearEnd)
        
        guard periodStart <= periodEnd else { return 0 }
        
        var maxStreak = 0
        var currentStreak = 0
        var date = periodStart
        
        while date <= periodEnd {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let day = components.day, let month = components.month, let year = components.year else {
                date = calendar.date(byAdding: .day, value: 1, to: date)!
                continue
            }
            
            let dayData = DayData(day: day, month: month - 1, year: year)
            let level = getDrinkLevel(for: dayData)
            
            if level == .little || level == .medium || level == .heavy || level == .little_sport || level == .medium_sport || level == .heavy_sport {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
            
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        
        return maxStreak == 1 ? 0 : maxStreak
    }
    
    private func getDrinkLevel(for dayData: DayData) -> DrinkLevel {
        let level = localDaysData[dayData.key] ?? .none
        return level
    }
    
    private func showExplanationForStat(title: String) {
        let explanations: [String: (titleKey: String, textKey: String)] = [
            "sober_streak_title": (
                "stat_sober_streak_title",
                "stat_sober_streak_description"
            ),
            "drinking_streak_title": (
                "stat_drinking_streak_title",
                "stat_drinking_streak_description"
            ),
            "max_sober_streak_title": (
                "stat_max_sober_streak_title",
                "stat_max_sober_streak_description"
            ),
            "total_drinking_days_title": (
                "stat_total_drinking_days_title",
                "stat_total_drinking_days_description"
            ),
            "total_sober_days_title": (
                "stat_total_sober_days_title",
                "stat_total_sober_days_description"
            ),
            "drink_level_little": (
                "stat_drink_level_little_title",
                "stat_drink_level_little_description"
            ),
            "drink_level_medium": (
                "stat_drink_level_medium_title",
                "stat_drink_level_medium_description"
            ),
            "drink_level_heavy": (
                "stat_drink_level_heavy_title",
                "stat_drink_level_heavy_description"
            ),
            "sport_days_title": (
                "stat_sport_days_title",
                "stat_sport_days_description"
            )
        ]
        
        if let explanationKeys = explanations[title] {
            let localizedTitle = NSLocalizedString(explanationKeys.titleKey, comment: "")
            let localizedText = NSLocalizedString(explanationKeys.textKey, comment: "")
            onShowExplanation?(localizedTitle, localizedText)
        }
    }
    private func updateUserStatus() {
        let statusResult = UserStatusManager.shared.calculateCurrentStatus(daysData: localDaysData)
        userStatus = statusResult.status
    }
    
    private var currentProgressDays: Int {
        let result = ProgressCalculator.calculate(from: localDaysData)
        return result.current
    }
    
    @MainActor
    private func generateAndShare() {
        let yearStats = calculateYearStats()
        let isRussian = LanguageManager.shared.currentLanguage == .russian
        
        let shareView = AnyView(
            StatsShareView(
                soberStreak: calculateCurrentSoberStreakOptimized(),
                drinkingStreak: displayStreak,
                maxSoberStreak: calculateLongestSoberStreak(),
                totalDrinking: yearStats.totalDrinking,
                totalSober: yearStats.totalDays - yearStats.totalDrinking,
                little: yearStats.little,
                medium: yearStats.medium,
                heavy: yearStats.heavy,
                sportDays: calculateSportDays(),
                isRussian: isRussian,
                userStatus: userStatus
            )
            .frame(width: 320)
            .clipped()
        )
        
        let renderer = ImageRenderer(content: shareView)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = ProposedViewSize(width: 320, height: nil)
        
        guard let image = renderer.uiImage else {
            print("❌ ImageRenderer вернул nil")
            return
        }
        
        print("✅ Картинка создана: \(image.size)")
        
        let shareTexts = (1...15).map { NSLocalizedString("share_text_\($0)", comment: "") }
        let randomText = shareTexts.randomElement() ?? ""
        let appStoreLink = "https://apps.apple.com/ru/app/wobbly-sobriety-tracker/id6755603610"
        let shareText = "\(randomText)\n\n\(appStoreLink)"

        let activityVC = UIActivityViewController(
            activityItems: [image, shareText],
            applicationActivities: nil
        )
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        activityVC.modalPresentationStyle = .overFullScreen
        activityVC.view.backgroundColor = .clear
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootVC.view
            popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        
        topVC.present(activityVC, animated: true)
    }
}

struct StatsTabView_Previews: PreviewProvider {
    static var previews: some View {
        StatsTabView(
            daysData: [:],
            showSettingsMenu: .constant(false)
        )
    }
}

struct ActivityViewControllerWrapper: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
