//
//  DataRestoreManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//

import SwiftUI
import Foundation

class DataRestoreManager: ObservableObject {
    private let drinkDataManager = DrinkDataManager()
    private let achievementManager = NewAchievementManager.shared
    private let streakHistoryManager = StreakHistoryManager.shared
    
    @Published var restoreError: String?
    @Published var restoreSuccess = false
    @Published var showRestoreResult = false

    func restoreFromAutoBackup() -> Bool {
        print("🔍 Попытка ручного восстановления из авто-бэкапа...")
        
        let fileExportManager = FileExportManager()
        guard let backupURL = fileExportManager.getAutoBackupURL() else {
            print("❌ Авто-бэкап не найден")
            return false
        }
        
        print("📁 Восстанавливаем из: \(backupURL.lastPathComponent)")
        
        do {
            let jsonData = try Data(contentsOf: backupURL)
            
            // 🔥 ИСПРАВЛЕННЫЙ ДЕКОДЕР С ПРАВИЛЬНОЙ ОБРАБОТКОЙ ДАТ
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                
                // Пробуем декодировать как Double (timestamp)
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp)
                }
                
                // Пробуем декодировать как строку ISO8601
                if let dateString = try? container.decode(String.self) {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Пробуем другие форматы дат если нужно
                    let fallbackFormatter = DateFormatter()
                    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    if let date = fallbackFormatter.date(from: dateString) {
                        return date
                    }
                    
                    fallbackFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    if let date = fallbackFormatter.date(from: dateString) {
                        return date
                    }
                }
                
                // Если ничего не сработало, возвращаем текущую дату
                print("⚠️ Не удалось декодировать дату, использую текущую дату")
                return Date()
            }
            
            let exportData = try decoder.decode(ExportData.self, from: jsonData)
            
            // 🔥 ИСПРАВЛЕНИЕ: Используем DrinkDataManager для сохранения
            let dataManager = DrinkDataManager()
            dataManager.saveFullData(exportData)
            
            if let workouts = exportData.workouts, !workouts.isEmpty {
                for (dayKey, workout) in workouts {
                    WorkoutDataStorage.shared.save(workout, for: dayKey)
                }
                print("✅ Восстановлено тренировок из бэкапа: \(workouts.count)")
            }
            
            print("✅ Ручное восстановление из авто-бэкапа завершено: \(exportData.daysData.count) записей")
            
            // Обновляем UI после восстановления
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
            }
            
            return true
            
        } catch {
            print("❌ Ошибка восстановления из авто-бэкапа: \(error)")
            return false
        }
    }
    private func getAutoBackupURL() -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsURL.appendingPathComponent("wobbly_auto_backup.json")
        
        if FileManager.default.fileExists(atPath: backupURL.path) {
            do {
                let fileSize = try FileManager.default.attributesOfItem(atPath: backupURL.path)[.size] as? Int ?? 0
                print("📁 Авто-бэкап найден: \(backupURL.path)")
                print("   Размер: \(fileSize) байт")
                return backupURL
            } catch {
                print("⚠️ Ошибка проверки бэкапа: \(error)")
                return backupURL
            }
        } else {
            print("❌ Авто-бэкап не найден по пути: \(backupURL.path)")
            return nil
        }
    }
    
    func importFromFile(_ fileURL: URL) -> Bool {
        print("🔄 Ручной импорт из файла: \(fileURL.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            restoreError = "Файл не найден"
            return false
        }
        
        do {
            let jsonData = try Data(contentsOf: fileURL)
            
            // Используем кастомный декодер для обработки дат
            let decoder = JSONDecoder()
            
            // Пробуем разные стратегии декодирования даты
            let exportData: ExportData
            do {
                // Сначала пробуем стандартную стратегию
                decoder.dateDecodingStrategy = .iso8601
                exportData = try decoder.decode(ExportData.self, from: jsonData)
            } catch {
                // Если не получается, пробуем кастомную стратегию
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    let formatter = ISO8601DateFormatter()
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Пробуем другие форматы если нужно
                    let fallbackFormatter = DateFormatter()
                    fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    if let date = fallbackFormatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Cannot decode date string: \(dateString)"
                    )
                }
                exportData = try decoder.decode(ExportData.self, from: jsonData)
            }
            
            // Сохраняем импортированные данные
            drinkDataManager.saveFullData(exportData)
            
            // Восстанавливаем тренировки если есть
            if let workouts = exportData.workouts, !workouts.isEmpty {
                for (dayKey, workout) in workouts {
                    WorkoutDataStorage.shared.save(workout, for: dayKey)
                }
                print("✅ Восстановлено тренировок: \(workouts.count)")
            }
            
            print("✅ Импорт завершен: \(exportData.daysData.count) записей")
            
            // После успешного импорта
            DispatchQueue.main.async {
                // Пересчитываем ачивки
                let achievementManager = NewAchievementManager.shared
                _ = achievementManager.checkAllAchievements(daysData: exportData.daysData)
                
                // Принудительно отправляем счёт
                ScoreSyncManager.shared.forceSendScore()
                
                // Обновляем UI
                NotificationCenter.default.post(name: .drinkDataChanged, object: nil)
            }
            
            return true
            
        } catch {
                    let errorMessage = "Ошибка восстановления: \(error.localizedDescription)"
                    print("❌ \(errorMessage)")
                    restoreError = errorMessage
                    showRestoreResult = true
                    return false
                }
    }
    
    func resetRestoreState() {
            restoreError = nil
            restoreSuccess = false
            showRestoreResult = false
        }
    
    func getBackupStatus() -> String {
        let backupInfo = drinkDataManager.getBackupInfo()
        
        if backupInfo.exists {
            let sizeMB = Double(backupInfo.size) / 1024.0 / 1024.0
            
            let dateString = backupInfo.date.map { formatDate($0) } ??
                             NSLocalizedString("backup_date_unknown", comment: "Значение даты, если она неизвестна")
            
            let format = NSLocalizedString("backup_status_exists",
                                          comment: "Статус бэкапа при его наличии. %.2f - размер в МБ, %@ - дата создания")
            return String(format: format, sizeMB, dateString)
            
        } else {
            return NSLocalizedString("backup_status_not_found",
                                    comment: "Статус бэкапа, когда он не найден")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
}
