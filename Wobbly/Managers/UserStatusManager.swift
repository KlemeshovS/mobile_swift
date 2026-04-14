import Foundation


// MARK: - Настройки статусов (можно менять)
struct StatusSettings {
    static var lookBackDays: Int = 30            // Смотрим на последние 30 дней
    static var boringThreshold: Int = 4          // Меньше 4 активных дней = скучный
    static var extremeDaysThreshold: Int = 7    // Минимум дней для жестких статусов
    static var sportFanaticThreshold: Double = 30.0   // Порог для "Раб железного храма" (в процентах)
    static var alcoholicThreshold: Double = 30.0      // Порог для "КМС по алкоспорту" (в процентах)
}

enum UserStatus: String, CaseIterable {
    case sporty = "status_sporty"
    case alcoholic = "status_alcoholic"
    case boring = "status_boring"
    case balanced = "status_balanced"
    case moderateDrinker = "status_moderate_drinker"
    case activeLifestyle = "status_active_lifestyle"
    case weekendWarrior = "status_weekend_warrior"
    case soberEnthusiast = "status_sober_enthusiast"
    case sportsFanatic = "status_sports_fanatic"
    case partyAnimal = "status_party_animal"
    case alkoCyborg = "status_alko_cyborg"       // Новый статус
    
    var displayName: String {
        NSLocalizedString("\(self.rawValue)_title", comment: "")
    }
    
    var description: String {
        NSLocalizedString("\(self.rawValue)_description", comment: "")
    }
    
    var iconName: String {
        switch self {
        case .sporty: return "icon_sporty"
        case .alcoholic: return "icon_alcoholic"
        case .boring: return "icon_boring"
        case .balanced: return "icon_balanced"
        case .moderateDrinker: return "icon_moderate"
        case .activeLifestyle: return "icon_active"
        case .weekendWarrior: return "icon_weekend"
        case .soberEnthusiast: return "icon_sober"
        case .sportsFanatic: return "icon_fanatic"
        case .partyAnimal: return "icon_party"
        case .alkoCyborg: return "icon_cyborg"   // Новая иконка
        }
    }
    
    var color: String {
        switch self {
        case .sporty: return "#4CAF50"
        case .alcoholic: return "#F44336"
        case .boring: return "#9E9E9E"
        case .balanced: return "#2196F3"
        case .moderateDrinker: return "#FF9800"
        case .activeLifestyle: return "#00BCD4"
        case .weekendWarrior: return "#673AB7"
        case .soberEnthusiast: return "#8BC34A"
        case .sportsFanatic: return "#E91E63"
        case .partyAnimal: return "#FF5722"
        case .alkoCyborg: return "#9C27B0"        // Фиолетовый
        }
    }
}

struct UserStatusResult {
    let status: UserStatus
    let stats: UserStatusStats
    let periodDays: Int
}

struct UserStatusStats {
    let drinkingDays: Int
    let sportDays: Int
    let soberDays: Int
    let totalDays: Int
    let drinkingPercentage: Double
    let sportPercentage: Double
    let soberPercentage: Double
    let mediumHeavyDrinkingDays: Int   // Новое поле: дни с уровнями .medium или .heavy
}

class UserStatusManager {
    static let shared = UserStatusManager()
    
    private init() {}
    
    // Основная функция расчета статуса
    func calculateCurrentStatus(daysData: [String: DrinkLevel]) -> UserStatusResult {
        let stats = calculateRecentStats(daysData: daysData, daysCount: StatusSettings.lookBackDays)
        let status = determineStatus(stats: stats)
        
        return UserStatusResult(
            status: status,
            stats: stats,
            periodDays: StatusSettings.lookBackDays
        )
    }
    
    // Функция с кастомными настройками (для тестирования)
    func calculateStatusWithSettings(
        daysData: [String: DrinkLevel],
        lookBackDays: Int = 30,
        boringThreshold: Int = 4,
        extremeDaysThreshold: Int = 10
    ) -> UserStatusResult {
        StatusSettings.lookBackDays = lookBackDays
        StatusSettings.boringThreshold = boringThreshold
        StatusSettings.extremeDaysThreshold = extremeDaysThreshold
        
        let stats = calculateRecentStats(daysData: daysData, daysCount: lookBackDays)
        let status = determineStatus(stats: stats)
        
        return UserStatusResult(
            status: status,
            stats: stats,
            periodDays: lookBackDays
        )
    }
    
    // Расчет статистики за последние N дней
    private func calculateRecentStats(daysData: [String: DrinkLevel], daysCount: Int) -> UserStatusStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        var drinkingDays = 0
        var sportDays = 0
        var totalDays = 0
        var mediumHeavyDrinkingDays = 0   // Счётчик для medium/heavy
        
        for dayOffset in 0..<daysCount {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else {
                continue
            }
            
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            guard let day = components.day,
                  let month = components.month,
                  let year = components.year else {
                continue
            }
            
            let dayData = DayData(day: day, month: month - 1, year: year)
            let level = daysData[dayData.key] ?? .none
            
            switch level {
            case .little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport:
                drinkingDays += 1
                if level == .medium || level == .heavy || level == .medium_sport || level == .heavy_sport {
                    mediumHeavyDrinkingDays += 1
                }
            case .sport:
                sportDays += 1
            default:
                break
            }
            
            totalDays += 1
        }
        
        let soberDays = totalDays - drinkingDays - sportDays
        
        let drinkingPercentage = totalDays > 0 ? Double(drinkingDays) / Double(totalDays) * 100 : 0
        let sportPercentage = totalDays > 0 ? Double(sportDays) / Double(totalDays) * 100 : 0
        let soberPercentage = totalDays > 0 ? Double(soberDays) / Double(totalDays) * 100 : 0
        
        return UserStatusStats(
            drinkingDays: drinkingDays,
            sportDays: sportDays,
            soberDays: soberDays,
            totalDays: totalDays,
            drinkingPercentage: drinkingPercentage,
            sportPercentage: sportPercentage,
            soberPercentage: soberPercentage,
            mediumHeavyDrinkingDays: mediumHeavyDrinkingDays
        )
    }
    
    // Упрощенная логика определения статуса
    private func determineStatus(stats: UserStatusStats) -> UserStatus {
        let sport = stats.sportDays
        let drink = stats.drinkingDays
        let totalActive = sport + drink
        let mediumHeavyDays = stats.mediumHeavyDrinkingDays
        let mediumHeavyPct = stats.totalDays > 0 ? Double(mediumHeavyDays) / Double(stats.totalDays) * 100 : 0

        // 1. Алкокиборг – очень много алкоголя или много тяжёлых дней
        if drink >= 20 || (mediumHeavyPct > 55 && mediumHeavyDays >= 7) {
            return .alkoCyborg
        }

        // 2. Раб железного храма – только спорт, очень много
        if sport >= 15 && drink < 5 {
            return .sportsFanatic
        }

        // 3. КМС по алкоспорту – много алкоголя, мало спорта
        if drink >= 15 && drink < 20 && sport < 5 {
            return .alcoholic
        }

        // 4. Фитнес-мученик – много спорта, мало алкоголя
        if sport >= 11 && sport < 15 && drink < 3 {
            return .activeLifestyle
        }

        // 5. Тусовщик-легенда – прилично алкоголя
        if drink >= 10 && drink < 15 && sport < 5 {
            return .partyAnimal
        }

        // 6. Трезвый садист – прилично спорта
        if sport >= 8 && sport < 11 && drink < 5 {
            return .soberEnthusiast
        }

        // 7. Грешник выходного дня – умеренно алкоголя
        if drink >= 5 && drink < 10 && sport < 5 {
            return .moderateDrinker
        }

        // 8. Любитель зарядки – умеренно спорта
        if sport >= 5 && sport < 8 && drink < 3 {
            return .sporty
        }

        // 9. Субботний герой – немного алкоголя
        if drink >= 2 && drink < 5 && sport < 3 {
            return .weekendWarrior
        }

        // 10. Скучный как пробка – почти ничего не делает
        if totalActive < 4 {
            return .boring
        }

        // 11. Баланс – и спорт, и алкоголь в сопоставимых количествах
        if sport >= 5 && sport <= 15 && drink >= 5 && drink <= 15 && abs(sport - drink) <= 5 {
            return .balanced
        }

        // Дефолт по преобладанию
        if sport > drink {
            return sport >= 3 ? .sporty : .boring
        } else if drink > sport {
            return drink >= 2 ? .moderateDrinker : .weekendWarrior
        } else {
            return .balanced
        }
    }}
