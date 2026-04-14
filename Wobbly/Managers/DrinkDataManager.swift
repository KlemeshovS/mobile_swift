//
//  DrinkDataManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//1111111

import Foundation

// MARK: - Full App Data (для внутреннего хранения)
struct FullAppData: Codable {
    let version: String
    let exportDate: Date
    var daysData: [String: DayRecord] // ИЗМЕНЕНО: теперь DayRecord вместо DrinkLevel
    var achievements: [Achievement]
    
    init(daysData: [String: DayRecord] = [:], achievements: [Achievement] = []) {
        self.version = "2.0" // Увеличили версию
        self.exportDate = Date()
        self.daysData = daysData
        self.achievements = achievements
    }
    
    // Кастомный инициализатор для декодирования (поддержка старого формата)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Сначала пробуем получить версию
        let version = try container.decode(String.self, forKey: .version)
        
        if version == "2.0" {
            // Новая версия
            self.version = version
            self.exportDate = try container.decode(Date.self, forKey: .exportDate)
            self.daysData = try container.decode([String: DayRecord].self, forKey: .daysData)
            self.achievements = try container.decode([Achievement].self, forKey: .achievements)
        } else {
            // Старая версия (1.0 или другая)
            print("🔄 Обнаружены старые данные версии \(version), начинаем конвертацию...")
            
            // Декодируем старые данные
            self.version = "2.0"
            self.exportDate = try container.decode(Date.self, forKey: .exportDate)
            self.achievements = try container.decode([Achievement].self, forKey: .achievements)
            
            // Декодируем старые данные и конвертируем
            let oldDaysData = try container.decode([String: DrinkLevel].self, forKey: .daysData)
            
            // Конвертируем старые данные в новый формат
            var newDaysData: [String: DayRecord] = [:]
            for (key, level) in oldDaysData {
                newDaysData[key] = DayRecord.fromLegacyDrinkLevel(level)
            }
            self.daysData = newDaysData
            
            print("✅ Конвертировано \(newDaysData.count) записей в новый формат")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exportDate, forKey: .exportDate)
        try container.encode(daysData, forKey: .daysData)
        try container.encode(achievements, forKey: .achievements)
    }
    
    enum CodingKeys: String, CodingKey {
        case version
        case exportDate
        case daysData
        case achievements
    }
    
    static var empty: FullAppData {
        return FullAppData()
    }
}

// MARK: - Drink Data Manager
class DrinkDataManager {
    private let dataFileName = "wobbly_data.json"
    private let autoBackupFileName = "wobbly_auto_backup.json"
    
    // Основной файл данных
    private var dataFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(dataFileName)
    }
    
    // Файл авто-бэкапа (только для ручного восстановления)
    private var autoBackupFileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(autoBackupFileName)
    }
    
    // MARK: - Public Methods (сохраняем обратную совместимость)
    
    func loadData() -> [String: DrinkLevel] {
        let fullData = loadFullAppData()
        
        // Конвертируем DayRecord обратно в DrinkLevel для обратной совместимости
        var legacyData: [String: DrinkLevel] = [:]
        for (key, record) in fullData.daysData {
            // Используем метод toLegacyDrinkLevel из DayRecord
            legacyData[key] = record.toLegacyDrinkLevel
        }
        
        return legacyData
    }
    
    func saveData(_ newData: [String: DrinkLevel]) {
        print("💾 DrinkDataManager.saveData вызван")
        print("📈 Размер данных: \(newData.count) записей")
        
        let currentData = loadFullAppData()
        
        // Конвертируем [String: DrinkLevel] в [String: DayRecord]
        var newDayRecords: [String: DayRecord] = [:]
        for (key, level) in newData {
            newDayRecords[key] = DayRecord.fromLegacyDrinkLevel(level)
        }
        
        let updatedData = FullAppData(
            daysData: newDayRecords,
            achievements: currentData.achievements // Сохраняем ачивки
        )
        
        saveFullAppData(updatedData)
    }
    
    // НОВЫЕ МЕТОДЫ ДЛЯ ВНУТРЕННЕГО ХРАНЕНИЯ
    func loadFullAppData() -> FullAppData {
        if FileManager.default.fileExists(atPath: dataFileURL.path) {
            return loadFullDataFromFile(dataFileURL)
        }
        
        print("📁 Основной файл данных не найден, возвращаем пустые данные")
        return FullAppData.empty
    }
    
    func saveFullAppData(_ appData: FullAppData) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(appData)
            
            // Сохраняем основные данные
            try jsonData.write(to: dataFileURL)
            
            print("💾 Основные данные сохранены: \(appData.daysData.count) дней, \(appData.achievements.count) ачивок")
            
            // 🔥 СОЗДАЕМ АВТО-БЭКАП ТОЛЬКО ЕСЛИ ЕСТЬ ДАННЫЕ
            if !appData.daysData.isEmpty {
                createAutoBackup(appData)
            } else {
                print("⚠️ Пропускаем авто-бэкап: нет данных для сохранения")
            }
            
        } catch {
            print("❌ Ошибка сохранения данных: \(error)")
        }
    }
    
    // Методы для экспорта (без ачивок)
    func getExportData() -> ExportData {
        let fullData = loadFullAppData()
        
        // Конвертируем DayRecord в DrinkLevel для экспорта (обратная совместимость)
        var legacyDaysData: [String: DrinkLevel] = [:]
        for (key, record) in fullData.daysData {
            legacyDaysData[key] = record.toLegacyDrinkLevel
        }
        
        return ExportData(daysData: legacyDaysData)
    }
    
    // СТАРЫЕ МЕТОДЫ ДЛЯ ОБРАТНОЙ СОВМЕСТИМОСТИ (оставьте их для AchievementManager)
    func loadFullData() -> ExportData {
        return getExportData()
    }
    
    func saveFullData(_ exportData: ExportData) {
        let currentData = loadFullAppData()
        
        // Конвертируем ExportData.daysData ([String: DrinkLevel]) в [String: DayRecord]
        var newDayRecords: [String: DayRecord] = [:]
        for (key, level) in exportData.daysData {
            newDayRecords[key] = DayRecord.fromLegacyDrinkLevel(level)
        }
        
        let appData = FullAppData(
            daysData: newDayRecords,
            achievements: currentData.achievements // Сохраняем ачивки
        )
        saveFullAppData(appData)
    }
    
    // MARK: - Manual Backup Methods
    
    func createAutoBackup(_ appData: FullAppData) {
        // 🔥 ПРОВЕРКА: НЕ СОЗДАЕМ БЭКАП ЕСЛИ ДАННЫЕ ПУСТЫЕ
        guard !appData.daysData.isEmpty else {
            print("⚠️ Пропускаем создание авто-бэкапа: данные пустые")
            return
        }
        
        // 🔥 ДОПОЛНИТЕЛЬНАЯ ПРОВЕРКА: ЕСЛИ УЖЕ ЕСТЬ БЭКАП С ДАННЫМИ, НЕ ПЕРЕЗАПИСЫВАЕМ ПУСТЫМИ
        if FileManager.default.fileExists(atPath: autoBackupFileURL.path) {
            let existingBackup = loadFullDataFromFile(autoBackupFileURL)
            if !existingBackup.daysData.isEmpty && appData.daysData.isEmpty {
                print("⚠️ Сохраняем существующий бэкап: не перезаписываем данные пустыми")
                return
            }
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(appData)
            
            try jsonData.write(to: autoBackupFileURL)
            
            print("🤖 Авто-бэкап создан: \(appData.daysData.count) записей, \(appData.achievements.count) ачивок")
            
        } catch {
            print("❌ Ошибка создания авто-бэкапа: \(error)")
        }
    }
    
    func manualBackupExists() -> Bool {
        return FileManager.default.fileExists(atPath: autoBackupFileURL.path)
    }
    
    func restoreFromBackup() -> Bool {
        // ВОССТАНОВЛЕНИЕ ТОЛЬКО ПО ЯВНОМУ ВЫЗОВУ
        guard FileManager.default.fileExists(atPath: autoBackupFileURL.path) else {
            print("❌ Авто-бэкап не найден для восстановления")
            return false
        }
        
        do {
            let backupData = try Data(contentsOf: autoBackupFileURL)
            let appData = try JSONDecoder().decode(FullAppData.self, from: backupData)
            
            // Сохраняем восстановленные данные в основной файл
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(appData)
            try jsonData.write(to: dataFileURL)
            
            print("✅ Данные восстановлены из авто-бэкапа: \(appData.daysData.count) записей, \(appData.achievements.count) ачивок")
            return true
            
        } catch {
            print("❌ Ошибка восстановления из авто-бэкапа: \(error)")
            return false
        }
    }
    
    func getBackupInfo() -> (exists: Bool, size: Int, date: Date?) {
        guard FileManager.default.fileExists(atPath: autoBackupFileURL.path) else {
            return (false, 0, nil)
        }
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: autoBackupFileURL.path)
            let size = attributes[.size] as? Int ?? 0
            let date = attributes[.modificationDate] as? Date
            
            return (true, size, date)
            
        } catch {
            return (true, 0, nil)
        }
    }
    
    func clearAllData() {
        do {
            if FileManager.default.fileExists(atPath: dataFileURL.path) {
                try FileManager.default.removeItem(at: dataFileURL)
            }
            print("🧹 Все основные данные удалены")
        } catch {
            print("❌ Ошибка удаления данных: \(error)")
        }
    }
    
    // MARK: - Private Methods
    private func loadFullDataFromFile(_ fileURL: URL) -> FullAppData {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let appData = try decoder.decode(FullAppData.self, from: jsonData)
            
     //       print("📁 Данные загружены из \(fileURL.lastPathComponent): \(appData.daysData.count) записей, \(appData.achievements.count) ачивок")
            return appData
            
        } catch {
            print("❌ Ошибка загрузки данных из \(fileURL.lastPathComponent): \(error)")
            
            // Если файл поврежден, создаем новый
            print("🔄 Создаем новые данные...")
            return FullAppData.empty
        }
    }
    
    private func loadDataFromFile(_ fileURL: URL) -> ExportData {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let appData = try decoder.decode(FullAppData.self, from: jsonData)
                        
            // Конвертируем DayRecord в DrinkLevel для обратной совместимости
            var legacyDaysData: [String: DrinkLevel] = [:]
            for (key, record) in appData.daysData {
                legacyDaysData[key] = record.toLegacyDrinkLevel
            }
            
            return ExportData(daysData: legacyDaysData)
            
        } catch {
            print("❌ Ошибка загрузки данных из \(fileURL.lastPathComponent): \(error)")
            
            // Если файл поврежден, создаем новый
            print("🔄 Создаем новые данные...")
            return ExportData.empty
        }
    }
    
    func migrateOldDataIfNeeded() {
        let userDefaultsKey = "hasMigratedDrinkLevels"
        
        // Проверяем, уже делали миграцию
        if UserDefaults.standard.bool(forKey: userDefaultsKey) {
            return
        }
        
        print("🔄 Начинаем миграцию старых данных...")
        
        // Загружаем текущие данные
        var data = loadData()
        var migratedCount = 0
        
        // Проходим по всем записям
        for (key, oldLevel) in data {
            // Получаем сырое значение (старое русское или уже новое)
            let oldRawValue = oldLevel.rawValue
            
            // Создаём новый уровень через safeRawValue
            let newLevel = DrinkLevel(safeRawValue: oldRawValue)
            
            // Если уровень изменился (старый русский -> новый английский)
            if newLevel != oldLevel {
                data[key] = newLevel
                migratedCount += 1
                print("  Мигрируем \(key): \(oldRawValue) -> \(newLevel.rawValue)")
            }
        }
        
        // Сохраняем мигрированные данные
        if migratedCount > 0 {
            saveData(data)
            print("✅ Миграция завершена. Обновлено \(migratedCount) записей.")
        } else {
            print("✅ Миграция не требуется.")
        }
        
        // Помечаем, что миграция выполнена
        UserDefaults.standard.set(true, forKey: userDefaultsKey)
    }
}
