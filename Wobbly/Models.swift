//models.swift
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let drinkDataChanged = Notification.Name("drinkDataChanged")
    static let followStatusChanged = Notification.Name("followStatusChanged")
}

// MARK: - Drink Levels
enum DrinkLevel: String, CaseIterable, Codable, Hashable {
    case none = "none"
    case little = "little"
    case medium = "medium"
    case heavy = "heavy"
    case sport = "sport"
    case unknown = "unknown"
    case little_sport = "little_sport"
    case medium_sport
    case heavy_sport
    
    // Локализованное отображаемое имя
    var localizedTitle: String {
        switch self {
        case .none: return NSLocalizedString("drink_level_none", comment: "")
        case .little: return NSLocalizedString("drink_level_little", comment: "")
        case .medium: return NSLocalizedString("drink_level_medium", comment: "")
        case .heavy: return NSLocalizedString("drink_level_heavy", comment: "")
        case .sport: return NSLocalizedString("drink_level_sport", comment: "")
        case .little_sport: return NSLocalizedString("drink_level_little", comment: "")
        case .unknown: return NSLocalizedString("drink_level_unknown", comment: "")
        case .medium_sport: return NSLocalizedString("drink_level_medium", comment: "") + " + " + NSLocalizedString("sport", comment: "")
        case .heavy_sport: return NSLocalizedString("drink_level_heavy", comment: "") + " + " + NSLocalizedString("sport", comment: "")
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .clear
        case .little: return Color(hex: "FF0072").opacity(0.3)
        case .medium: return Color(hex: "9126EF").opacity(0.4)
        case .heavy: return Color(hex: "482FED").opacity(0.6)
        case .sport: return Color(hex: "C7FF00").opacity(0.3)
        case .little_sport: return Color(hex: "FF0072").opacity(0.3)
        case .unknown: return .gray.opacity(0.3)
        case .medium_sport: return Color(hex: "9126EF").opacity(0.4)
        case .heavy_sport: return Color(hex: "482FED").opacity(0.6)
        }
    }
    
    var emoji: String {
        switch self {
        case .none: return "○"
        case .little: return "🍺"
        case .medium: return "🍷"
        case .heavy: return "🥴"
        case .sport: return "💪"
        case .little_sport: return "🍺"
        case .medium_sport: return "🍷💪"
        case .heavy_sport: return "🥴💪"
        case .unknown: return ""
        }
    }

    init(safeRawValue: String) {
        if let level = DrinkLevel(rawValue: safeRawValue.lowercased()) {
            self = level
            return
        }
        
        switch safeRawValue {
        case "Нет", "none":
            self = .none
        case "Чучуть", "Чуть-чуть", "Мало", "little":
            self = .little
        case "Средне", "Обычно", "medium":
            self = .medium
        case "Всрало", "Много", "Сильно", "heavy":
            self = .heavy
        case "Спорт", "sport":
            self = .sport
        case "little_sport":
            self = .little_sport
        case "medium_sport":
            self = .medium_sport
        case "heavy_sport":
            self = .heavy_sport
        default:
            self = .unknown
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        if let level = DrinkLevel(rawValue: rawValue) {
            self = level
        } else {
            self = .unknown
        }
    }
}

// MARK: - Drink Trigger (дневник триггеров)
// Хранится отдельно от DayRecord/FullAppData (см. TriggerManager) — намеренно,
// т.к. DayRecord повсеместно проходит лоссовый round-trip через DrinkLevel
// (синк, экспорт, восстановление, пересчёт ачивок), где любое доп. поле было бы стёрто.
// rawValue зафиксирован явно (а не выведен из имени кейса) — это формат хранения
// в экспортных файлах и в персистентности ачивок (AchievementType.toString()).
// Если переименовывать кейсы в коде для читаемости, не меняя raw value — старые
// файлы/сохранённые ачивки продолжат корректно декодироваться.
enum DrinkTrigger: String, CaseIterable, Codable, Hashable {
    case stress = "stress"
    case boredom = "boredom"
    case party = "party"
    case company = "company"
    case loneliness = "loneliness"
    case conflict = "conflict"
    case habit = "habit"
    case other = "other"

    var localizedTitle: String {
        switch self {
        case .stress: return NSLocalizedString("trigger_stress", comment: "")
        case .boredom: return NSLocalizedString("trigger_boredom", comment: "")
        case .party: return NSLocalizedString("trigger_party", comment: "")
        case .company: return NSLocalizedString("trigger_company", comment: "")
        case .loneliness: return NSLocalizedString("trigger_loneliness", comment: "")
        case .conflict: return NSLocalizedString("trigger_conflict", comment: "")
        case .habit: return NSLocalizedString("trigger_habit", comment: "")
        case .other: return NSLocalizedString("trigger_other", comment: "")
        }
    }
}

// MARK: - Day Data
struct DayData: Identifiable, Hashable, Codable {
    let id = UUID()
    let day: Int
    let month: Int
    let year: Int
    
    var key: String {
        "\(year)-\(month)-\(day)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(key)
    }
    
    static func == (lhs: DayData, rhs: DayData) -> Bool {
        lhs.key == rhs.key
    }
}

// MARK: - Calendar Utils
struct CalendarUtils {
    static func daysInMonth(month: Int, year: Int) -> Int {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1
        
        guard let date = Calendar.current.date(from: dateComponents),
              let range = Calendar.current.range(of: .day, in: .month, for: date) else {
            return 0
        }
        
        return range.count
    }
}

// MARK: - Calendar Day Model
struct CalendarDay: Identifiable {
    let id = UUID()
    let day: Int?
    let month: Int
    let year: Int
    let isPlaceholder: Bool
    
    init(day: Int?, month: Int, year: Int, isPlaceholder: Bool = false) {
        self.day = day
        self.month = month
        self.year = year
        self.isPlaceholder = isPlaceholder
    }
}

// MARK: - Year Stats
struct YearStats {
    let little: Int
    let medium: Int
    let heavy: Int
    let sport: Int
    let drinkingDays: Int
    let totalDays: Int
    let totalDrinking: Int
}


// MARK: - Day Record (новая структура для комбинаций)
struct DayRecord: Codable, Hashable {
    var drinkLevel: DrinkLevel
    var hasSport: Bool
    
    init(drinkLevel: DrinkLevel = .none, hasSport: Bool = false) {
        self.drinkLevel = drinkLevel
        self.hasSport = hasSport
    }
    
    var toLegacyDrinkLevel: DrinkLevel {
        if hasSport {
            if drinkLevel == .little {
                return .little_sport
            } else if drinkLevel == .medium {
                return .medium_sport
            } else if drinkLevel == .heavy {
                return .heavy_sport
            } else if drinkLevel != .none {
                return drinkLevel
            } else {
                return .sport
            }
        } else {
            return drinkLevel
        }
    }
    
    static func fromLegacyDrinkLevel(_ level: DrinkLevel) -> DayRecord {
        switch level {
        case .sport:
            // TODO: Нужно как-то отличать "только спорт" от "little+sport"
            // Пока что считаем все .sport как "только спорт"
            return DayRecord(drinkLevel: .none, hasSport: true)
        case .little_sport:
            return DayRecord(drinkLevel: .little, hasSport: true)
        case .medium_sport:
            return DayRecord(drinkLevel: .medium, hasSport: true)
        case .heavy_sport:
            return DayRecord(drinkLevel: .heavy, hasSport: true)
        default:
            return DayRecord(drinkLevel: level, hasSport: false)
        }
    }
}
