// ExportData.swift
import Foundation

// MARK: - Export Data Structures
struct ExportData: Codable {
    let version: String
    let exportDate: Date
    var daysData: [String: DrinkLevel]  // 🔥 Старый формат для совместимости
    var dayRecords: [String: DayRecord]? // 🔥 НОВЫЙ формат (опционально)
    let userId: Int?
    let username: String?
    var workouts: [String: WorkoutData]?
    var triggers: [String: [DrinkTrigger]]? // Дневник триггеров (опционально, для обратной совместимости со старыми файлами)

    init(daysData: [String: DrinkLevel] = [:],
         dayRecords: [String: DayRecord]? = nil,
         workouts: [String: WorkoutData]? = nil,
         triggers: [String: [DrinkTrigger]]? = nil,
         userId: Int? = nil,
         username: String? = nil) {
        self.version = "2.1"
        self.exportDate = Date()
        self.daysData = daysData
        self.dayRecords = dayRecords
        self.workouts = workouts
        self.triggers = triggers
        self.userId = userId
        self.username = username
    }
    
    // 🔥 Конвертация между форматами
    func toNewFormat() -> [String: DayRecord] {
        if let dayRecords = dayRecords {
            return dayRecords
        } else {
            var newRecords: [String: DayRecord] = [:]
            for (key, level) in daysData {
                newRecords[key] = DayRecord.fromLegacyDrinkLevel(level)
            }
            return newRecords
        }
    }
    
    // 🔥 Конвертация в старый формат
    func toOldFormat() -> [String: DrinkLevel] {
        if let dayRecords = dayRecords {
            var oldData: [String: DrinkLevel] = [:]
            for (key, record) in dayRecords {
                oldData[key] = record.toLegacyDrinkLevel
            }
            return oldData
        } else {
            return daysData
        }
    }
    
    // Кастомная реализация Codable
    enum CodingKeys: String, CodingKey {
        case version, exportDate, daysData, dayRecords, userId, username
        case workouts, triggers
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(exportDate, forKey: .exportDate)
        
        // Кодируем оба формата данных
        if let dayRecords = dayRecords {
            try container.encode(dayRecords, forKey: .dayRecords)
        }
        try container.encode(daysData, forKey: .daysData)
        
        // Кодируем опциональные поля пользователя
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(workouts, forKey: .workouts)
        try container.encodeIfPresent(triggers, forKey: .triggers)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        workouts = try container.decodeIfPresent([String: WorkoutData].self, forKey: .workouts)
        triggers = try container.decodeIfPresent([String: [DrinkTrigger]].self, forKey: .triggers)

        version = try container.decode(String.self, forKey: .version)
        
        // Декодируем данные в зависимости от версии
        if version >= "2.0" {
            dayRecords = try container.decodeIfPresent([String: DayRecord].self, forKey: .dayRecords)
        } else {
            dayRecords = nil
        }
        
        daysData = try container.decode([String: DrinkLevel].self, forKey: .daysData)
        
        // Декодируем новые поля (опционально)
        userId = try container.decodeIfPresent(Int.self, forKey: .userId)
        username = try container.decodeIfPresent(String.self, forKey: .username)
        
        // Обработка даты
        do {
            exportDate = try container.decode(Date.self, forKey: .exportDate)
        } catch {
            let dateString = try container.decode(String.self, forKey: .exportDate)
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: dateString) {
                exportDate = date
            } else {
                exportDate = Date()
            }
        }
    }
    
    static var empty: ExportData {
        return ExportData()
    }
}
