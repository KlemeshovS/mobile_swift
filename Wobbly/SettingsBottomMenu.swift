//
//  SettingsBottomMenu.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.01.2026.
//
import SwiftUI
import HealthKit

enum SettingsScreen {
    case main
    case about
    case userProfile
}

struct SettingsBottomMenu: View {
    @Binding var isShowing: Bool
    let onExport: () -> Void
    let onRestoreFromBackup: () -> Void
    let onImportFromFile: () -> Void
    let daysData: [String: DrinkLevel]
    let onLogout: () -> Void
    
    @StateObject private var restoreManager = DataRestoreManager()
    
    @State private var currentScreen: SettingsScreen = .main
    @State private var showAboutApp = false
    @State private var backupStatus = "Проверка..."
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                // Заголовок с кнопкой назад, если не main
                if currentScreen != .main && currentScreen != .userProfile {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentScreen = .main
                            }
                            HapticManager.shared.impact(.light)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .medium))
                                Text(NSLocalizedString("back", comment: ""))
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.9))
                        }
                        
                        Spacer()
                        
                        Text(currentScreen == .about ? NSLocalizedString("about", comment: "") : "")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Color.clear
                            .frame(width: 60, height: 30)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 40)
                    .padding(.bottom, 16)
                }
                
                // Контент в зависимости от экрана
                if currentScreen == .main {
                    MainMenuContent(
                        onExport: onExport,
                        onRestoreFromBackup: {
                            restoreManager.restoreFromAutoBackup()
                        },
                        onImportFromFile: onImportFromFile,
                        onShowAbout: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentScreen = .about
                            }
                            HapticManager.shared.impact(.light)
                        },
                        onShowUserProfile: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                currentScreen = .userProfile
                            }
                            HapticManager.shared.impact(.light)
                        },
                        backupStatus: backupStatus,
                        onLogout: onLogout
                    )
                } else if currentScreen == .about {
                    AboutAppView(daysData: daysData)
                } else if currentScreen == .userProfile {
                    UserProfileView(
                        onClose: {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                isShowing = false
                            }
                        },
                        onRegisterSuccess: { username, userId in
                            print("👤 Профиль обновлён: \(username ?? "none")")
                        },
                        onDisappear: nil,
                        daysData: daysData,                     // ← сначала daysData
                        onDeleteAccount: {                      // ← потом onDeleteAccount
                            Task {
                                do {
                                    try await AuthService.shared.deleteAccount()
                                    await MainActor.run {
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                            isShowing = false
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                    }
                                }
                            }
                        }
                    )
                }
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: "1E1E2E").opacity(0.98),
                        Color(hex: "2A2A3A").opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(32, corners: [.topLeft, .topRight])
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .ignoresSafeArea()
        .onAppear {
            updateBackupStatus()
        }
    }
    
    private func updateBackupStatus() {
        backupStatus = restoreManager.getBackupStatus()
    }
}

struct MainMenuContent: View {
    let onExport: () -> Void
    let onRestoreFromBackup: () -> Void
    let onImportFromFile: () -> Void
    let onShowAbout: () -> Void
    let onShowUserProfile: () -> Void
    let backupStatus: String
    let onLogout: () -> Void
    
    @StateObject private var languageManager = LanguageManager.shared
    @State private var languageRotation = 0.0
    @State private var healthSyncEnabled = HealthKitManager.shared.isSyncEnabled
    
    var body: some View {
        VStack(spacing: 10) {
            
            //   🔥 ПРОСТАЯ КНОПКА ПЕРЕКЛЮЧЕНИЯ ЯЗЫКА
            Button(action: {
                // Анимация
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                }
                
                // Тактильный отклик
                HapticManager.shared.impact(.light)
                
                // Переключаем язык
                LanguageManager.shared.switchToNextLanguage()
            }) {
                HStack(spacing: 16) {
                    // Иконка глобуса с анимацией
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "globe")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    // Тексты
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("menu_language", comment: "Язык"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        HStack(spacing: 6) {
                            // Отображаем текущий язык
                            Text(languageManager.currentLanguage.shortName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color(hex: "C7FF00"))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.15))
                                .cornerRadius(6)
                            
                            Text(languageManager.currentLanguage.displayName)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    
                    Spacer()
                    
                    // Индикатор смены
                    Text("→")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Apple Health
            if HealthKitManager.shared.isAvailable {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "FF3B30"), Color(hex: "FF6B6B")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("menu_health_sync_title", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Text(NSLocalizedString("menu_health_sync_subtitle", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $healthSyncEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                        .labelsHidden()
                        .padding(.horizontal, 2)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                        .onChange(of: healthSyncEnabled) { newValue in
                            HealthKitManager.shared.isSyncEnabled = newValue
                            HapticManager.shared.impact(.light)
                        }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                )
            }
            
            // Пункты меню
            Button(action: {
                HapticManager.shared.impact(.light)
                onShowUserProfile()
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")], // синий градиент
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("menu_user_profile", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(NSLocalizedString("menu_user_profile_subtitle", comment: ""))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            MenuItem(
                icon: "square.and.arrow.up",
                title: NSLocalizedString("menu_export_title", comment: "Заголовок кнопки экспорта данных"),
                subtitle: NSLocalizedString("menu_export_subtitle", comment: "Подзаголовок кнопки экспорта данных"),
                gradient: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")]
            ) {
                onExport()
            }
            
            MenuItem(
                icon: "square.and.arrow.down",
                title: NSLocalizedString("menu_import_title", comment: "Заголовок кнопки импорта данных"),
                subtitle: NSLocalizedString("menu_import_subtitle", comment: "Подзаголовок кнопки импорта данных"),
                gradient: [Color(hex: "A8E6CF"), Color(hex: "7BCFAB")]
            ) {
                onImportFromFile()
            }
            
            // Пункт "О приложении" со стрелочкой
            Button(action: {
                HapticManager.shared.impact(.light)
                onShowAbout()
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "B8B5FF"), Color(hex: "7868E6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("about", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(Bundle.main.appVersion).\(Bundle.main.buildNumber)")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.12))
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Logout button (only if authenticated)
            if AuthStateManager.shared.sessionType == .authenticated {
                Button(action: {
                    HapticManager.shared.impact(.light)
                    Task {
                        await AuthService.shared.signOut()
                        // Закрываем меню после выхода
                        onLogout()
                    }
                }) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "F44336"), Color(hex: "D32F2F")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(NSLocalizedString("logout_button", comment: ""))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.12))
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // 🔥 ФУНКЦИЯ СБРОСА АЧИВОК
    private func resetAllAchievements() {
        HapticManager.shared.impact(.heavy)
        
        let achievementManager = NewAchievementManager.shared
        
        // 1. Получаем все ачивки
        let allAchievements = achievementManager.getAllAchievements()
        
        // 2. Создаем сброшенные ачивки
        var resetAchievements: [Achievement] = []
        for achievement in allAchievements {
            var resetAchievement = achievement
            resetAchievement.isUnlocked = false
            resetAchievement.unlockDate = nil
            resetAchievements.append(resetAchievement)
        }
        
        // 3. Сохраняем через правильный метод
        achievementManager.saveAchievements(resetAchievements)
        
        // 4. Пересчитываем ачивки из текущих данных
        let dataManager = DrinkDataManager()
        let currentDaysData = dataManager.loadData()
        _ = achievementManager.checkAllAchievements(daysData: currentDaysData)
        
        // 5. Уведомляем UI и показываем алерт
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
            
            // 🔥 ДОПОЛНИТЕЛЬНО: Показываем уведомление о сбросе
            let alert = UIAlertController(
                title: NSLocalizedString("achievements_reset_notification_title",
                                         value: "Ачивки сброшены",
                                         comment: "Заголовок уведомления о сбросе достижений"),
                message: NSLocalizedString("achievements_reset_notification_message",
                                           value: "Все достижения разблокированы заново на основе текущих данных",
                                           comment: "Сообщение уведомления о сбросе достижений"),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(alert, animated: true)
            }
        }
    }
}

struct AboutAppView: View {
    @State private var appearAnimation = false
    let daysData: [String: DrinkLevel]
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private var trackedDaysCount: Int {
        return daysData.count
    }
    
    private var unlockedAchievementsCount: Int {
        return NewAchievementManager.shared.loadUnlockedAchievements().filter { $0.isUnlocked }.count
    }

    private var totalAchievementsCount: Int {
        return NewAchievementManager.shared.getAllAchievements().count
    }
    
    private func openTelegram() {
        let telegramUsername = "wobbly_app"
        let telegramURL = URL(string: "tg://resolve?domain=\(telegramUsername)")!
        let webURL = URL(string: "https://t.me/\(telegramUsername)")!
        
        if UIApplication.shared.canOpenURL(telegramURL) {
            UIApplication.shared.open(telegramURL)
        } else {
            UIApplication.shared.open(webURL)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Логотип и название
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "4B3A91")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.white)
                    }
                    .scaleEffect(appearAnimation ? 1.0 : 0.8)
                    .opacity(appearAnimation ? 1.0 : 0.0)
                    
                    Text("WOBBLY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(NSLocalizedString("subtitle", comment: ""))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    StatRow(
                        icon: "paperplane",
                        title: NSLocalizedString("menu_tg_title", comment: "Пункт меню для связи в Telegram"),
                        value: "@wobbly"
                    )
                    .onTapGesture {
                        openTelegram()
                    }
                    
                    StatRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: NSLocalizedString("menu_version_title", comment: "Пункт меню с версией приложения"),
                        value: "\(Bundle.main.appVersion).\(Bundle.main.buildNumber)"
                    )
                }
                .opacity(appearAnimation ? 1.0 : 0.0)
                .offset(y: appearAnimation ? 0 : 20)
                
                // Описание
                VStack(alignment: .leading, spacing: 12) {
                    Text(NSLocalizedString("about", comment: ""))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(NSLocalizedString("app_origin_story_part1", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                    Text(NSLocalizedString("app_origin_story_part2", comment: ""))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                        .lineSpacing(4)
                    
                    Text(NSLocalizedString("about_creator_description", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "C7FF00"))
                        .padding(.top, 8)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .opacity(appearAnimation ? 1.0 : 0.0)
                .offset(y: appearAnimation ? 0 : 20)
                
                // Фичи
                VStack(alignment: .leading, spacing: 16) {
                    Text(NSLocalizedString("about_capabilities_title", comment: "Заголовок секции возможностей приложения"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    FeatureRow(
                        icon: "chart.bar.fill",
                        title: NSLocalizedString("feature_stats_title", comment: "Название функции: статистика"),
                        description: NSLocalizedString("feature_stats_desc", comment: "Описание функции статистики")
                    )
                    FeatureRow(
                        icon: "trophy.fill",
                        title: NSLocalizedString("feature_achievements_title", comment: "Название функции: ачивки"),
                        description: NSLocalizedString("feature_achievements_desc", comment: "Описание функции ачивок")
                    )
                    FeatureRow(
                        icon: "star.fill",
                        title: NSLocalizedString("feature_privacy_title", comment: "Название функции: конфиденциальность"),
                        description: NSLocalizedString("feature_privacy_desc", comment: "Описание функции конфиденциальности")
                    )
                }
                .opacity(appearAnimation ? 1.0 : 0.0)
                .offset(y: appearAnimation ? 0 : 20)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .padding(.bottom, 30)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "C7FF00"))
                    .frame(width: 24)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
            }
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(hex: "8B5CF6").opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(hex: "8B5CF6"))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - Menu Item Component
struct MenuItem: View {
    let icon: String
    let title: String
    let subtitle: String
    var gradient: [Color] = [.blue, .purple]
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticManager.shared.impact(.light)
            action()
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.12))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#Preview {
    // Для проверки создадим мок-данные
    let mockDaysData: [String: DrinkLevel] = ["2025-01-01": .little]
    
    SettingsBottomMenu(
        isShowing: .constant(true),
        onExport: { print("Export tapped") },
        onRestoreFromBackup: { print("Restore tapped") },
        onImportFromFile: { print("Import tapped") },
        daysData: mockDaysData,
        onLogout: { print("Logout tapped") }
    )
}
