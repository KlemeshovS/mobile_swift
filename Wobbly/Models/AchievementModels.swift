//
//  AchievementModels.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.01.2026.
//

import Foundation
import SwiftUI

// MARK: - Achievement Types
enum AchievementType {
    case soberStreak(requiredDays: Int)
    case drinkingStreak(requiredDays: Int)
    case sportCount(period: SportPeriod, requiredCount: Int)
    case uniqueEvent(eventType: UniqueEvent)
    case milestone(target: Int, isNegative: Bool)
    case soberDaysInYear(requiredCount: Int)
    case drinkingDaysInYear(requiredCount: Int)
    case soberMonth(month: Int) // month: 1-12
}

enum SportPeriod {
    case last30Days
    case last60Days
    case last90Days
    case last180Days
    case last365Days
    
    var daysCount: Int {
        switch self {
        case .last30Days: return 30
        case .last60Days: return 60
        case .last90Days: return 90
        case .last180Days: return 180
        case .last365Days: return 365
        }
    }
}

enum UniqueEvent {
    case soberNewYear
    case sportNewYear
}

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: AchievementType
    var isUnlocked: Bool = false
    var unlockDate: Date? = nil
    var unlockCount: Int = 0
    
    // Сохраняем обратную совместимость со старыми полями
    var requiredStreak: Int {
        switch type {
        case .soberStreak(let days), .drinkingStreak(let days):
            return days
        case .sportCount(_, let count):
            return count
        case .uniqueEvent:
            return 1
        case .milestone(let target, _):
            return target
        case .soberDaysInYear(let count):
            return count
        case .drinkingDaysInYear(let count):
            return count
        case .soberMonth(let month):
            return month
        }
    }
    
    var isDrinking: Bool {
        switch type {
        case .drinkingStreak:
            return true
        case .milestone(_, let isNegative):
            return isNegative
        case .drinkingDaysInYear:
            return true
        default:
            return false
        }
    }
    
    var imageName: String {
        getAchievementImageName(for: id)
    }
    
    // Ключи для Codable
    enum CodingKeys: String, CodingKey {
        case id, title, description, type, isUnlocked, unlockDate
        case unlockCount
    }
    
    // Функция для получения имени изображения по ID
    private func getAchievementImageName(for id: String) -> String {
        switch id {
        case "sober_7": return "achievement_sober_7"
        case "sober_14": return "achievement_sober_14"
        case "sober_21": return "achievement_sober_21"
        case "sober_30": return "achievement_sober_30"
        case "sober_60": return "achievement_sober_60"
        case "sober_90": return "achievement_sober_90"
        case "sober_180": return "achievement_sober_180"
        case "sober_365": return "achievement_sober_365"
        case "drink_3": return "achievement_drink_3"
        case "drink_7": return "achievement_drink_7"
        case "drink_14": return "achievement_drink_14"
        case "drink_30": return "achievement_drink_30"
        case "sober_new_year": return "achievement_sober_new_year"
        case "sport_new_year": return "achievement_sport_new_year"
        case "sport_8_month": return "achievement_sport_8"
        case "sport_12_month": return "achievement_sport_12"
        case "sport_50_half_year": return "achievement_sport_50"
        case "sport_100_year": return "achievement_sport_100"
        case "milestone_146": return "achievement_milestone_146"
        case "milestone_319": return "achievement_milestone_319"
        case "milestone_443": return "achievement_milestone_443"
        case "milestone_1234": return "achievement_milestone_1234"
        case "milestone_4810": return "achievement_milestone_4810"
        case "milestone_5642": return "achievement_milestone_5642"
        case "milestone_7010": return "achievement_milestone_7010"
        case "milestone_8848": return "achievement_milestone_8848"
        case "milestone_202_negative": return "achievement_milestone_202_negative"
        case "milestone_1642_negative": return "achievement_milestone_1642_negative"
        case "milestone_3800_negative": return "achievement_milestone_3800_negative"
        case "milestone_6066_negative": return "achievement_milestone_6066_negative"
        case "milestone_10047_negative": return "achievement_milestone_10047_negative"
        case "milestone_11022_negative": return "achievement_milestone_11022_negative"
        case "sober_days_year_100": return "achievement_sober_days_year_100"
        case "sober_days_year_200": return "achievement_sober_days_year_200"
        case "sober_days_year_300": return "achievement_sober_days_year_300"
        case "drink_days_year_100": return "achievement_drink_days_year_100"
        case "drink_days_year_200": return "achievement_drink_days_year_200"
        case "drink_days_year_300": return "achievement_drink_days_year_300"
        case "sober_month_1": return "achievement_sober_month_1"
        case "sober_month_2": return "achievement_sober_month_2"
        case "sober_month_3": return "achievement_sober_month_3"
        case "sober_month_4": return "achievement_sober_month_4"
        case "sober_month_5": return "achievement_sober_month_5"
        case "sober_month_6": return "achievement_sober_month_6"
        case "sober_month_7": return "achievement_sober_month_7"
        case "sober_month_8": return "achievement_sober_month_8"
        case "sober_month_9": return "achievement_sober_month_9"
        case "sober_month_10": return "achievement_sober_month_10"
        case "sober_month_11": return "achievement_sober_month_11"
        case "sober_month_12": return "achievement_sober_month_12"
        default: return "achievement_default"
        }
    }
    
    init(id: String, title: String, description: String, type: AchievementType, isUnlocked: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.type = type
        self.isUnlocked = isUnlocked
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decode(String.self, forKey: .description)
        isUnlocked = try container.decode(Bool.self, forKey: .isUnlocked)
        unlockDate = try container.decodeIfPresent(Date.self, forKey: .unlockDate)
        unlockCount = (try? container.decodeIfPresent(Int.self, forKey: .unlockCount)) ?? 0
        
        // Custom decoding for AchievementType
        let typeString = try container.decode(String.self, forKey: .type)
        type = try AchievementType.from(string: typeString)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(description, forKey: .description)
        try container.encode(isUnlocked, forKey: .isUnlocked)
        try container.encodeIfPresent(unlockDate, forKey: .unlockDate)
        try container.encode(type.toString(), forKey: .type)
        try container.encode(unlockCount, forKey: .unlockCount)
    }
}

extension Achievement {
    var milestoneTarget: Int? {
        if case .milestone(let target, _) = type {
            return target
        }
        return nil
    }

    var isNegativeMilestone: Bool {
        if case .milestone(_, let isNegative) = type {
            return isNegative
        }
        return false
    }
    
    var requirementDescription: String {
        // Сначала особые случаи по id
        switch id {
        case "sober_new_year":
            return NSLocalizedString("ach_requirement_sober_new_year", comment: "")
        case "sport_new_year":
            return NSLocalizedString("ach_requirement_sport_new_year", comment: "")
        case "sport_8_month":
            return NSLocalizedString("condition_sport_8", comment: "") // используем старый ключ
        case "sport_12_month":
            return NSLocalizedString("condition_sport_12", comment: "")
        case "sport_50_half_year":
            return NSLocalizedString("condition_sport_50", comment: "")
        case "sport_100_year":
            return NSLocalizedString("condition_sport_100", comment: "")
            
        default:
            break
        }
        
        // Общая логика по типу
        switch type {
        case .soberStreak(let days):
            return String(format: NSLocalizedString("ach_requirement_sober_streak", comment: ""), days)
        case .drinkingStreak(let days):
            return String(format: NSLocalizedString("ach_requirement_drinking_streak", comment: ""), days)
        case .sportCount(let period, let count):
            // Для спортивных ачивок, у которых нет специального id, используем общий шаблон
            return String(format: NSLocalizedString("ach_requirement_sport_count", comment: ""), count, period.daysCount)
        case .uniqueEvent(let eventType):
            return NSLocalizedString(eventType == .soberNewYear ? "ach_requirement_sober_new_year" : "ach_requirement_sport_new_year", comment: "")
        case .soberDaysInYear(let count):
            return String(format: NSLocalizedString("ach_requirement_sober_days_year", comment: ""), count)
        case .drinkingDaysInYear(let count):
            return String(format: NSLocalizedString("ach_requirement_drinking_days_year", comment: ""), count)
        case .soberMonth(let month):
            let monthKey = "month_prepositional_\(month)"
            let monthName = NSLocalizedString(monthKey, comment: "")
            return String(format: NSLocalizedString("ach_requirement_sober_month", comment: ""), monthName)
        case .milestone(let target, let isNegative):
            if isNegative {
                return String(format: NSLocalizedString("ach_requirement_milestone_negative", comment: ""), target)
            } else {
                return String(format: NSLocalizedString("ach_requirement_milestone_positive", comment: ""), target)
            }
        }
    }
}

// MARK: - Extension for AchievementType Codable
extension AchievementType: Codable {
    enum CodingKeys: String, CodingKey {
        case base, associated
    }
    
    private enum BaseType: String, Codable {
        case soberStreak, drinkingStreak, sportCount, uniqueEvent, milestone
        case soberDaysInYear, drinkingDaysInYear
        case soberMonth
    }
    
    private struct MilestoneData: Codable {
        let target: Int
        let isNegative: Bool
    }
    
    // MARK: - Encodable
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .soberStreak(let days):
            try container.encode(BaseType.soberStreak, forKey: .base)
            try container.encode(days, forKey: .associated)
            
        case .drinkingStreak(let days):
            try container.encode(BaseType.drinkingStreak, forKey: .base)
            try container.encode(days, forKey: .associated)
            
        case .sportCount(let period, let count):
            try container.encode(BaseType.sportCount, forKey: .base)
            let sportData = SportCountData(period: period, count: count)
            try container.encode(sportData, forKey: .associated)
            
        case .uniqueEvent(let event):
            try container.encode(BaseType.uniqueEvent, forKey: .base)
            try container.encode(event, forKey: .associated)
            
        case .milestone(let target, let isNegative):
            try container.encode(BaseType.milestone, forKey: .base)
            let milestoneData = MilestoneData(target: target, isNegative: isNegative)
            try container.encode(milestoneData, forKey: .associated)
            
        case .soberDaysInYear(let count):
            try container.encode(BaseType.soberDaysInYear, forKey: .base)
            try container.encode(count, forKey: .associated)
        case .drinkingDaysInYear(let count):
            try container.encode(BaseType.drinkingDaysInYear, forKey: .base)
            try container.encode(count, forKey: .associated)
            
        case .soberMonth(let month):
            try container.encode(BaseType.soberMonth, forKey: .base)
            try container.encode(month, forKey: .associated)
        }
    }
    
    // MARK: - Decodable
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let base = try container.decode(BaseType.self, forKey: .base)
        
        switch base {
        case .soberStreak:
            let days = try container.decode(Int.self, forKey: .associated)
            self = .soberStreak(requiredDays: days)
            
        case .drinkingStreak:
            let days = try container.decode(Int.self, forKey: .associated)
            self = .drinkingStreak(requiredDays: days)
            
        case .sportCount:
            let sportData = try container.decode(SportCountData.self, forKey: .associated)
            self = .sportCount(period: sportData.period, requiredCount: sportData.count)
            
        case .uniqueEvent:
            let event = try container.decode(UniqueEvent.self, forKey: .associated)
            self = .uniqueEvent(eventType: event)
            
        case .milestone:
            let milestoneData = try container.decode(MilestoneData.self, forKey: .associated)
            self = .milestone(target: milestoneData.target, isNegative: milestoneData.isNegative)
            
        case .soberDaysInYear:
            let count = try container.decode(Int.self, forKey: .associated)
            self = .soberDaysInYear(requiredCount: count)
        case .drinkingDaysInYear:
            let count = try container.decode(Int.self, forKey: .associated)
            self = .drinkingDaysInYear(requiredCount: count)
            
        case .soberMonth:
            let month = try container.decode(Int.self, forKey: .associated)
            self = .soberMonth(month: month)
        }
    }
    
    // Вспомогательная структура для спортивных ачивок
    private struct SportCountData: Codable {
        let period: SportPeriod
        let count: Int
    }
    
    // MARK: - String conversion (для обратной совместимости)
    func toString() -> String {
        switch self {
        case .soberStreak(let days):
            return "soberStreak:\(days)"
        case .drinkingStreak(let days):
            return "drinkingStreak:\(days)"
        case .sportCount(let period, let count):
            return "sportCount:\(period.daysCount):\(count)"
        case .uniqueEvent(let event):
            return "uniqueEvent:\(event == .soberNewYear ? "soberNewYear" : "sportNewYear")"
        case .milestone(let target, let isNegative):
            return "milestone:\(target):\(isNegative ? "negative" : "positive")"
        case .soberDaysInYear(let count):
            return "soberDaysInYear:\(count)"
        case .soberMonth(let month):
            return "soberMonth:\(month)"
        case .drinkingDaysInYear(let count):
            return "drinkingDaysInYear:\(count)"
        }
        
    }
    
    static func from(string: String) throws -> AchievementType {
        let components = string.split(separator: ":")
        guard !components.isEmpty else {
            throw NSError(domain: "AchievementType", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid achievement type string"])
        }
        
        let firstComponent = String(components[0])
        
        switch firstComponent {
        case "soberStreak":
            guard components.count == 2,
                  let days = Int(String(components[1])) else {
                throw NSError(domain: "AchievementType", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid sober streak format"])
            }
            return .soberStreak(requiredDays: days)
            
        case "drinkingStreak":
            guard components.count == 2,
                  let days = Int(String(components[1])) else {
                throw NSError(domain: "AchievementType", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid drinking streak format"])
            }
            return .drinkingStreak(requiredDays: days)
            
        case "sportCount":
            guard components.count == 3,
                  let periodDays = Int(String(components[1])),
                  let count = Int(String(components[2])) else {
                throw NSError(domain: "AchievementType", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invalid sport count format"])
            }
            let period: SportPeriod
            switch periodDays {
            case 30: period = .last30Days
            case 60: period = .last60Days
            case 90: period = .last90Days
            case 180: period = .last180Days
            case 365: period = .last365Days
            default:
                throw NSError(domain: "AchievementType", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invalid sport period: \(periodDays)"])
            }
            return .sportCount(period: period, requiredCount: count)
            
        case "uniqueEvent":
            guard components.count == 2 else {
                throw NSError(domain: "AchievementType", code: 6, userInfo: [NSLocalizedDescriptionKey: "Invalid unique event format"])
            }
            let eventString = String(components[1])
            let event: UniqueEvent = eventString == "soberNewYear" ? .soberNewYear : .sportNewYear
            return .uniqueEvent(eventType: event)
            
        case "milestone":
            guard components.count == 3,
                  let target = Int(components[1]) else {
                throw NSError(domain: "AchievementType", code: 8, userInfo: [NSLocalizedDescriptionKey: "Invalid milestone format"])
            }
            let isNegative = components[2] == "negative"
            return .milestone(target: target, isNegative: isNegative)
        
        case "soberDaysInYear":
            guard components.count == 2, let count = Int(components[1]) else {
                throw NSError(domain: "AchievementType", code: 9, userInfo: nil)
            }
            return .soberDaysInYear(requiredCount: count)

        case "drinkingDaysInYear":
            guard components.count == 2, let count = Int(components[1]) else {
                throw NSError(domain: "AchievementType", code: 10, userInfo: nil)
            }
            return .drinkingDaysInYear(requiredCount: count)
            
        case "soberMonth":
            guard components.count == 2, let month = Int(components[1]) else {
                throw NSError(domain: "AchievementType", code: 11, userInfo: nil)
            }
            return .soberMonth(month: month)
            
        default:
            throw NSError(domain: "AchievementType", code: 7, userInfo: [NSLocalizedDescriptionKey: "Unknown achievement type: \(firstComponent)"])
        }
    }
}

// MARK: - Делаем SportPeriod и UniqueEvent Codable
extension SportPeriod: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        
        switch rawValue {
        case 30: self = .last30Days
        case 60: self = .last60Days
        case 90: self = .last90Days
        case 180: self = .last180Days
        case 365: self = .last365Days
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid SportPeriod value: \(rawValue)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.daysCount)
    }
}

extension UniqueEvent: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        
        switch rawValue {
        case "soberNewYear": self = .soberNewYear
        case "sportNewYear": self = .sportNewYear
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UniqueEvent value: \(rawValue)"
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let rawValue = self == .soberNewYear ? "soberNewYear" : "sportNewYear"
        try container.encode(rawValue)
    }
}
