//
//  ContentView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 04.09.2025.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import StoreKit
import WidgetKit

// MARK: - Main Content View
struct ContentView: View {
    @State private var selectedTab = 0
    @State private var daysData: [String: DayRecord] = [:]
    @StateObject private var motivationManager = MotivationNotificationManager()
    @State private var showSettingsMenu = false
    @StateObject private var dataRestoreManager = DataRestoreManager()
    @StateObject private var tutorialManager = TutorialManager()
    
    @State private var languageRefresh = UUID()
    
    @State private var showAchievementPopup = false
    @State private var selectedAchievement: Achievement? = nil

    @State private var showFileImporter = false
    @State private var importResultMessage = ""
    @State private var showImportResult = false
    @State private var isImportSuccessful = false
    
    @State private var showRestoreResult = false
    @State private var restoreResultMessage = ""
    
    @State private var showRestoreSuccess = false
    @State private var restoreErrorMessage = ""
    @State private var showRestoreError = false
    @State private var showTestMotivation = false
    
    @State private var showExplanation = false
    @State private var explanationText = ""
    @State private var explanationTitle = ""
    
    @State private var showRestoreSuccessAlert = false
    @State private var showRestoreErrorAlert = false
    
    @State private var statisticsProvider: StatisticsProvider?
    
    // Добавляем состояние для туториала
    @State private var showTutorial = false
    
    @State private var showReviewPrompt = false
    
    @AppStorage("hasShownNamePrompt") private var hasShownNamePrompt = false
    @State private var showNamePrompt = false
    @State private var didCheckNamePrompt = false
    
    @State private var showTopThreePopup = false
    @State private var selectedTopThreePlace = 1
    @State private var selectedTopThreeIsTop = true
    
    @StateObject private var notificationManager = AppNotificationManager.shared
    @State private var selectedFollowerForProfile: LeaderboardItem? = nil
    
    
    var body: some View {
        ZStack {
            mainContentView()
            tutorialView()
            motivationViews()
            settingsMenuView()
            achievementPopupView()
            
            if showReviewPrompt {
                ReviewPromptView(
                    onRate: {
                        if let url = URL(string: "https://apps.apple.com/app/id6755603610?l") {
                            UIApplication.shared.open(url)
                        }
                        ReviewManager.shared.didRate()
                        withAnimation { showReviewPrompt = false }
                    },
                    onLater: {
                        ReviewManager.shared.didShowPrompt()
                        withAnimation { showReviewPrompt = false }
                    }
                )
                .zIndex(1004)
            }
            // Уведомления об ачивках и подписчиках
            if let notification = notificationManager.currentNotification {
                AppNotificationView(
                    item: notification,
                    onDismiss: {
                        notificationManager.dismiss()
                    },
                    onFollowerTap: { userId, username, avatarUrl in
                        selectedFollowerForProfile = LeaderboardItem(
                            userId: userId,
                            username: username,
                            score: 0,
                            avatarUrl: avatarUrl
                        )
                    }
                )
                .zIndex(9000)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            topThreePopupView()
        }
        .sheet(item: $selectedFollowerForProfile) { item in
            PublicUserProfileView(item: item)
        }
        
        // NEW: Sheet для экрана имени
        .sheet(isPresented: $showNamePrompt) {
            UserProfileView(
                onClose: {
                    hasShownNamePrompt = true
                    showNamePrompt = false
                },
                onRegisterSuccess: { username, userId in
                    // После сохранения профиля счёт отправится автоматически через ScoreSyncManager
                },
                onDisappear: {
                    hasShownNamePrompt = true
                },
                daysData: legacyDaysData,
                onDeleteAccount: nil
            )
        }
        
        .id(languageRefresh) // <-- добавляем эту строку
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("LanguageDidChange"))) { _ in
            languageRefresh = UUID() // <-- меняем UUID, чтобы перерисовать всё
        }
        .onReceive(NotificationCenter.default.publisher(for: .drinkDataChanged)) { _ in
            loadCalendarData()
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
        .alert("import_success_status", isPresented: $showImportResult) {
            Button("OK", role: .cancel) {
                if isImportSuccessful {
                    let drinkManager = DrinkDataManager()
                    let legacyData = drinkManager.loadData()
                    
                    // Конвертируем в DayRecord
                    var newData: [String: DayRecord] = [:]
                    for (key, level) in legacyData {
                        newData[key] = DayRecord.fromLegacyDrinkLevel(level)
                    }
                    daysData = newData
                }
            }
        } message: {
            Text(importResultMessage)
        }
        .alert("resored_message", isPresented: $showRestoreSuccessAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("import_success_status")
        }
        .alert("error_message", isPresented: $showRestoreErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(restoreErrorMessage)
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            // 1. Загружаем локальные данные сразу
            loadCalendarData()
            
            DrinkDataManager().syncDataForWidget()
            WidgetCenter.shared.reloadAllTimelines()
            
            // 2. Асинхронная инициализация
            Task {
                await AuthService.shared.restoreSession()
                
                await MainActor.run {
                    _ = ScoreSyncManager.shared
                    checkTutorialStatus()
                    setupAI()
                    let streakManager = StreakHistoryManager.shared
                    streakManager.recalculateMaxStreaksFromData(daysData: legacyDaysData)
                    recalculateAllAchievements()
                    ScoreSyncManager.shared.forceSendScore()
                    DataDebugger.debugAllData(daysData)
                }
                
                await CalendarSyncManager.shared.sync()
                await AppNotificationManager.shared.checkNewFollowers()

                let dataManager = DrinkDataManager()
                let legacyForNotifications = dataManager.loadData()
                AppNotificationManager.shared.checkNewAchievements(daysData: legacyForNotifications)

                // Синхронизация с Apple Health
                if HealthKitManager.shared.isAvailable && HealthKitManager.shared.isSyncEnabled {
                    await HealthKitManager.shared.requestAuthorization()
                    
                    if HealthKitManager.shared.isAuthorized() {
                        var updatedDaysData = await MainActor.run { daysData }
                        let autoAdded = await HealthKitManager.shared.syncWorkoutsToCalendar(daysData: &updatedDaysData)
                        
                        if !autoAdded.isEmpty {
                            let capturedAutoAdded = autoAdded
                            let capturedUpdated = updatedDaysData
                            
                            await MainActor.run {
                                let isRussian = LanguageManager.shared.currentLanguage == .russian

                                var revertedData = capturedUpdated
                                for key in capturedAutoAdded {
                                    var record = revertedData[key] ?? DayRecord()
                                    record.hasSport = false
                                    if record.drinkLevel == .none {
                                        revertedData.removeValue(forKey: key)
                                    } else {
                                        revertedData[key] = record
                                    }
                                }
                                daysData = revertedData

                                AppNotificationManager.shared.showHealthSyncProposal(
                                    autoAddedDays: capturedAutoAdded,
                                    isRussian: isRussian,
                                    onAccept: {
                                        var accepted = daysData
                                        for key in capturedAutoAdded {
                                            var record = accepted[key] ?? DayRecord()
                                            record.hasSport = true
                                            accepted[key] = record
                                        }
                                        daysData = accepted
                                        let dm = DrinkDataManager()
                                        var legacy: [String: DrinkLevel] = [:]
                                        for (key, rec) in accepted { legacy[key] = rec.toLegacyDrinkLevel }
                                        dm.saveData(legacy)
                                        CalendarSyncManager.shared.markLocalUpdated()
                                        NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
                                        
                                        // Отправляем на сервер
                                        Task {
                                            await CalendarSyncManager.shared.pushToServer()
                                        }
                                        Task {
                                            for key in capturedAutoAdded {
                                                let parts = key.split(separator: "-").map { String($0) }
                                                guard parts.count == 3,
                                                      let y = Int(parts[0]),
                                                      let m = Int(parts[1]),
                                                      let d = Int(parts[2]) else { continue }
                                                var comps = DateComponents()
                                                comps.year = y; comps.month = m + 1; comps.day = d
                                                if let date = Calendar.current.date(from: comps) {
                                                    await HealthKitManager.shared.fetchAndSaveWorkoutDetails(for: key, date: date)
                                                }
                                            }
                                        }
                                    },
                                    onDecline: {
                                        for key in capturedAutoAdded {
                                            HealthKitManager.shared.markDayAsManuallyRemovedSport(key)
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                
                // Показываем мотивацию только если нет других уведомлений
                await MainActor.run {
                    checkAndShowDailyMotivation()
                }
            }
        }
    }
        
    private func loadCalendarData() {
        let drinkManager = DrinkDataManager()
        let legacyData = drinkManager.loadData()
        var newData: [String: DayRecord] = [:]
        for (key, level) in legacyData {
            newData[key] = DayRecord.fromLegacyDrinkLevel(level)
        }
        daysData = newData
        statisticsProvider = StatisticsProvider(dayRecords: daysData)
    }
        
    // Вычисляемое свойство для обратной совместимости
    private var legacyDaysData: [String: DrinkLevel] {
        var result: [String: DrinkLevel] = [:]
        for (key, record) in daysData {
            result[key] = record.toLegacyDrinkLevel
        }
        return result
    }
        
    private func recalculateAllAchievements() {
        let dataManager = DrinkDataManager()
        let daysData = dataManager.loadData()
        _ = NewAchievementManager.shared.recalculateAllAchievements(daysData: daysData)
    }
    
    private func checkTutorialStatus() {
        if !tutorialManager.isTutorialShown {
            // Показываем туториал с задержкой после сплеш-скрина
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring()) {
                    showTutorial = true
                }
            }
        } else {
            // Продолжаем обычную инициализацию
            NewAchievementManager.shared.migrateFromOldData()
            statisticsProvider = StatisticsProvider(dayRecords: daysData)
            print("✅ statisticsProvider создан, записей: \(daysData.count)")
            
       //     checkAndShowDailyMotivation()
            
            let streakManager = StreakHistoryManager.shared
            streakManager.recalculateMaxStreaksFromData(daysData: legacyDaysData)
            recalculateAllAchievements()
        }
    }
    
    private func prepareStatisticsText() -> String {
        guard let provider = statisticsProvider else {
            return "Недостаточно данных для статистики."
        }
        
        let lastWeek = provider.statsForLast(days: 7)
        
        return """
        За последние 7 дней:
        - Трезвых дней: \(lastWeek.soberDays)
        - Дней с алкоголем: \(lastWeek.drinkingDays)
        - Спортивных дней: \(lastWeek.sportDays)
        """
    }
    
    private func calculateCurrentSoberStreak(daysData: [String: DrinkLevel]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var currentStreak = 0
        
        let periodManager = PeriodManager.shared
        
        for dayOffset in 0..<365 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { break }
            
            // Проверяем что дата после даты установки
            if date < periodManager.firstInstallDate {
                break
            }
            
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let day = components.day,
                  let month = components.month,
                  let year = components.year else { break }
            
            let dayData = DayData(day: day, month: month - 1, year: year)
            let level = daysData[dayData.key] ?? .unknown
            
            switch level {
            case .little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport:
                return currentStreak
            case .none, .sport:
                currentStreak += 1
            case .unknown:
                return currentStreak
            }
        }
        
        return currentStreak
    }
    
    // MARK: - Вынесенные части интерфейса
    @ViewBuilder
    private func mainContentView() -> some View {
        if !showTutorial {
            MainContentView(
                selectedTab: $selectedTab,
                daysData: $daysData,
                showSettingsMenu: $showSettingsMenu,
                showAchievementPopup: $showAchievementPopup,
                selectedAchievement: $selectedAchievement,
                showExplanation: $showExplanation,
                explanationTitle: $explanationTitle,
                explanationText: $explanationText,
                onShowTopThreePopup: { place, isTop in
                    selectedTopThreePlace = place
                    selectedTopThreeIsTop = isTop
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showTopThreePopup = true
                    }
                }
            )
            .zIndex(0)
        }
    }

    @ViewBuilder
    private func tutorialView() -> some View {
        if showTutorial {
            TutorialView(isShowing: $showTutorial)
                .transition(.opacity)
                .zIndex(1000)
        }
    }

    @ViewBuilder
    private func motivationViews() -> some View {
        Group {
            FancyMotivationView(
                isShowing: $motivationManager.showMotivation,
                text: motivationManager.motivationText,
                isPositive: motivationManager.isPositiveMotivation
            )
            .zIndex(1003)

            FancyMotivationView(
                isShowing: $showExplanation,
                text: explanationText,
                isPositive: true,
                customTitle: explanationTitle
            )
            .zIndex(1003)
        }
    }

    @ViewBuilder
    private func settingsMenuView() -> some View {
        if showSettingsMenu {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .animation(nil, value: showSettingsMenu)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSettingsMenu = false
                    }
                }
                .zIndex(1001)

            SettingsBottomMenu(
                isShowing: $showSettingsMenu,
                onExport: {
                    if let fileURL = ExportService.shared.manualExport() {
                        showShareSheet(fileURL: fileURL)
                    }
                },
                onRestoreFromBackup: {
                    DispatchQueue.global(qos: .userInitiated).async {
                        let restoreSuccess = dataRestoreManager.restoreFromAutoBackup()
                        DispatchQueue.main.async {
                            if restoreSuccess {
                                let drinkManager = DrinkDataManager()
                                let legacyData = drinkManager.loadData()
                                var newData: [String: DayRecord] = [:]
                                for (key, level) in legacyData {
                                    newData[key] = DayRecord.fromLegacyDrinkLevel(level)
                                }
                                daysData = newData
                                NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
                                showRestoreSuccessAlert = true
                            } else {
                                restoreErrorMessage = "Не удалось восстановить данные"
                                showRestoreErrorAlert = true
                            }
                        }
                    }
                },
                onImportFromFile: {
                    showFileImporter = true
                },
                daysData: legacyDaysData,
                onLogout: {
                    // Закрываем меню настроек
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSettingsMenu = false
                    }
                }
            )
            .transition(.move(edge: .bottom))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showSettingsMenu)
            .zIndex(1002)
        }
    }

    @ViewBuilder
    private func achievementPopupView() -> some View {
        if showAchievementPopup, let achievement = selectedAchievement {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAchievementPopup = false
                        selectedAchievement = nil
                    }
                }
                .zIndex(2000)

            VStack {
                Spacer()
                AchievementPopupView(achievement: achievement) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showAchievementPopup = false
                        selectedAchievement = nil
                    }
                }
            }
            .ignoresSafeArea()
            .zIndex(2001)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    @ViewBuilder
    private func topThreePopupView() -> some View {
        if showTopThreePopup {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showTopThreePopup = false
                    }
                }
                .zIndex(9999)
            
            VStack {
                Spacer()
                TopThreePopupView(place: selectedTopThreePlace, isTop: selectedTopThreeIsTop)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showTopThreePopup = false
                        }
                    }
            }
            .ignoresSafeArea()
            .zIndex(10000)
        }
    }

    
    // MARK: - Milestone Tracking
    private func saveMilestoneShown(_ soberDays: Int) {
        let todayString = getCurrentDateString()
        
        // Сохраняем в UserDefaults
        var shownData: [String: Int] = UserDefaults.standard.dictionary(forKey: "shownMilestones") as? [String: Int] ?? [:]
        shownData[todayString] = soberDays
        UserDefaults.standard.set(shownData, forKey: "shownMilestones")
        
    }

    private func hasMilestoneBeenShownToday(_ soberDays: Int) -> Bool {
        let todayString = getCurrentDateString()
        let shownData: [String: Int] = UserDefaults.standard.dictionary(forKey: "shownMilestones") as? [String: Int] ?? [:]
        
        // Проверяем, показывали ли этот milestone сегодня
        return shownData[todayString] == soberDays
    }

    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: Date())
    }
    
    private func checkAndShowDailyMotivation() {
        if !tutorialManager.isTutorialShown {
            return
        }
        
        // Показываем только раз в день
            let lastShownKey = "lastMotivationShownDate"
            let today = getCurrentDateString()
            let lastShown = UserDefaults.standard.string(forKey: lastShownKey)
            guard lastShown != today else { return }
            
            // Не показываем если есть уведомления об ачивках или подписчиках
            if AppNotificationManager.shared.currentNotification != nil { return }
            
            // Сохраняем дату показа
            UserDefaults.standard.set(today, forKey: lastShownKey)
        
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
        
        guard let day = components.day,
              let month = components.month,
              let year = components.year else { return }
        
        let yesterdayData = DayData(day: day, month: month - 1, year: year)
        let yesterdayRecord = daysData[yesterdayData.key] ?? DayRecord()
        
        // Определяем, был ли вчера алкоголь и какой уровень
        let yesterdayDrinking: Bool
        let yesterdayLevel: DrinkLevel?
        
        if yesterdayRecord.drinkLevel == .little ||
           yesterdayRecord.drinkLevel == .medium ||
           yesterdayRecord.drinkLevel == .heavy ||
           yesterdayRecord.drinkLevel == .little_sport {
            yesterdayDrinking = true
            yesterdayLevel = yesterdayRecord.drinkLevel
        } else {
            yesterdayDrinking = false
            yesterdayLevel = nil
        }
        
        let currentSoberStreak = calculateCurrentSoberStreak(daysData: legacyDaysData)
        
        // Проверяем, нужно ли показать восстановительный milestone (только если вчера не пил)
        if !yesterdayDrinking && MotivationManager.isRecoveryMilestoneDay(currentSoberStreak) && !hasMilestoneBeenShownToday(currentSoberStreak) {
            // Показываем восстановительный milestone (не AI)
            motivationManager.motivationText = MotivationManager.getRecoveryPhrase(forSoberDays: currentSoberStreak) ?? ""
            motivationManager.isPositiveMotivation = true
            motivationManager.showMotivation = true
            saveMilestoneShown(currentSoberStreak)
            return
        }
        
        // Во всех остальных случаях (включая алкогольный день и обычный трезвый) используем AI
        let statisticsText = prepareStatisticsText()
        motivationManager.showMotivationIfNeeded(
            yesterdayDrinking: yesterdayDrinking,
            statistics: statisticsText,
            yesterdayLevel: yesterdayLevel
        )
    }
    // 🔥 СОХРАНЕНИЕ ПОКАЗАННЫХ MILESTONE-ОВ
    private func saveMilestoneShown(soberDays: Int) {
        var shownMilestones = UserDefaults.standard.array(forKey: "shownRecoveryMilestones") as? [Int] ?? []
        if !shownMilestones.contains(soberDays) {
            shownMilestones.append(soberDays)
            UserDefaults.standard.set(shownMilestones, forKey: "shownRecoveryMilestones")
        }
    }

    // 🔥 ПРОВЕРКА, ПОКАЗЫВАЛСЯ ЛИ УЖЕ MILESTONE
    private func hasMilestoneBeenShown(_ soberDays: Int) -> Bool {
        let shownMilestones = UserDefaults.standard.array(forKey: "shownRecoveryMilestones") as? [Int] ?? []
        return shownMilestones.contains(soberDays)
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else {
                showImportResult(message: "Файл не выбран", isSuccess: false)
                return
            }
            
            _ = url.startAccessingSecurityScopedResource()
            defer { url.stopAccessingSecurityScopedResource() }
            
            // Просто вызываем импорт
            let success = dataRestoreManager.importFromFile(url)
            
            if success {
                showImportResult(message: " ", isSuccess: true)
            } else {
                let errorMessage = dataRestoreManager.restoreError ?? "Неизвестная ошибка"
                showImportResult(message: "❌ Ошибка импорта: \(errorMessage)", isSuccess: false)
            }
            
        case .failure(let error):
            showImportResult(message: "❌ Ошибка выбора файла: \(error.localizedDescription)", isSuccess: false)
        }
    }
    
    private func showImportResult(message: String, isSuccess: Bool) {
        importResultMessage = message
        isImportSuccessful = isSuccess
        showImportResult = true
    }
    
    private func showRestoreResult(message: String, isSuccess: Bool) {
        restoreResultMessage = message
        showRestoreResult = true
    }
    
    private func showShareSheet(fileURL: URL) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        
        if #available(iOS 15.0, *) {
            activityVC.overrideUserInterfaceStyle = .dark
        }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            
            if let popoverController = activityVC.popoverPresentationController {
                popoverController.sourceView = rootViewController.view
                popoverController.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                                    y: rootViewController.view.bounds.midY,
                                                    width: 0, height: 0)
                popoverController.permittedArrowDirections = []
            }
            
            activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                if completed {
                } else if let error = error {
                } else {
                }
                
                // Очищаем временный файл
                self.cleanupTempFile(fileURL)
            }
            
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    private func cleanupTempFile(_ fileURL: URL) {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
        }
    }
    
    private func checkAllAchievements() {
        let achievementManager = NewAchievementManager.shared
        
        // 🔥 ИСПОЛЬЗУЕМ НОВЫЙ МЕТОД С daysData
        _ = achievementManager.checkAllAchievements(daysData: legacyDaysData)
        
        // Обновляем UI
        NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
    }
    
    private func checkAndShowMotivation() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let components = calendar.dateComponents([.year, .month, .day], from: yesterday)
        
        guard let day = components.day,
              let month = components.month,
              let year = components.year else { return }
        
        let yesterdayData = DayData(day: day, month: month - 1, year: year)
        let yesterdayRecord = daysData[yesterdayData.key] ?? DayRecord()
        
        let yesterdayDrinking = (yesterdayRecord.drinkLevel == .little ||
                                 yesterdayRecord.drinkLevel == .medium ||
                                 yesterdayRecord.drinkLevel == .heavy)
        
        motivationManager.showMotivationIfNeeded(yesterdayDrinking: yesterdayDrinking, statistics: prepareStatisticsText())
    }
    
    private func setupAI() {
        // Вставьте свои реальные ключи
        let apiKey = "AQVN..."      // ваш API-ключ
        let folderId = "b1g..."     // ваш folder-id
        motivationManager.setupAI(apiKey: apiKey, folderId: folderId)
        print("✅ AI сервис настроен с ключом: \(apiKey.prefix(5))...")
    }
}
    
    

struct MainContentView: View {
    @Binding var selectedTab: Int
    @Binding var daysData: [String: DayRecord]
    @Binding var showSettingsMenu: Bool
    @Binding var showAchievementPopup: Bool
    @Binding var selectedAchievement: Achievement?
    @Binding var showExplanation: Bool
    @Binding var explanationTitle: String
    @Binding var explanationText: String
        
    var onShowTopThreePopup: (Int, Bool) -> Void

    
    private var legacyDaysData: [String: DrinkLevel] {
        var result: [String: DrinkLevel] = [:]
        for (key, record) in daysData {
            result[key] = record.toLegacyDrinkLevel
        }
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SwipeTabView(selectedTab: $selectedTab) {
                ZStack {
                    if selectedTab == 0 {
                        CalendarTabView(daysData: $daysData)
                            .ignoresSafeArea(edges: .bottom)
                    } else if selectedTab == 1 {
                        StatsTabView(
                            daysData: legacyDaysData,
                            showSettingsMenu: $showSettingsMenu,
                            onShowAchievement: { achievement in
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    selectedAchievement = achievement
                                    showAchievementPopup = true
                                }
                            },
                            onShowExplanation: { title, text in
                                explanationTitle = title
                                explanationText = text
                                showExplanation = true
                            }
                        )
                        .ignoresSafeArea(edges: .bottom)
                    } else {
                        RatingsView(onShowTopThreePopup: onShowTopThreePopup, daysData: legacyDaysData)
                            .ignoresSafeArea(edges: .bottom)
                    }
                }
            }
            
            CustomTabBar(selectedTab: $selectedTab)
        }
    }
}

#Preview {
    SplashScreenView()
}
