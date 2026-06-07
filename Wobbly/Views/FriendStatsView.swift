//
//  FriendStatsView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 07.06.26.
//

import SwiftUI

struct FriendStatsView: View {
    let days: [String: Int]
    let updatedAt: String

    private var daysData: [String: DrinkLevel] {
        var result: [String: DrinkLevel] = [:]
        for (key, value) in days {
            let level: DrinkLevel
            switch value {
            case 1: level = .little
            case 2: level = .medium
            case 3: level = .heavy
            case 4: level = .sport
            case 5: level = .little_sport
            case 6: level = .medium_sport
            case 7: level = .heavy_sport
            default: level = .none
            }
            result[key] = level
        }
        return result
    }

    private var updatedDate: Date? {
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: updatedAt) { return d }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return iso.date(from: updatedAt)
    }

    private var formattedDate: String {
        guard let date = updatedDate else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return String(format: NSLocalizedString("friend_stats_as_of", comment: ""), formatter.string(from: date))
    }

    private var currentYear: Int {
        Calendar.current.component(.year, from: updatedDate ?? Date())
    }

    // MARK: - Stats calculations

    private struct YearStats {
        let little, medium, heavy, sport, little_sport: Int
        let drinkingDays, totalDays, totalDrinking: Int
    }

    private func calculateYearStats() -> YearStats {
        let calendar = Calendar.current
        let today = updatedDate ?? Date()
        let currentMonth = calendar.component(.month, from: today) - 1
        let currentDay = calendar.component(.day, from: today)

        var little = 0, medium = 0, heavy = 0, sport = 0, little_sport = 0
        var totalDaysPassed = 0, drinkingDays = 0

        for month in 0..<12 {
            if month > currentMonth { continue }
            let daysInMonth = CalendarUtils.daysInMonth(month: month, year: currentYear)
            let lastDay = month == currentMonth ? currentDay : daysInMonth
            totalDaysPassed += lastDay

            for day in 1...lastDay {
                let key = "\(currentYear)-\(month)-\(day)"
                let level = daysData[key] ?? .none
                switch level {
                case .little: little += 1; drinkingDays += 1
                case .medium: medium += 1; drinkingDays += 1
                case .heavy: heavy += 1; drinkingDays += 1
                case .sport: sport += 1
                case .little_sport: little += 1; drinkingDays += 1; sport += 1; little_sport += 1
                case .medium_sport: medium += 1; drinkingDays += 1; sport += 1
                case .heavy_sport: heavy += 1; drinkingDays += 1; sport += 1
                default: break
                }
            }
        }

        return YearStats(little: little, medium: medium, heavy: heavy, sport: sport,
                         little_sport: little_sport, drinkingDays: drinkingDays,
                         totalDays: totalDaysPassed, totalDrinking: little + medium + heavy)
    }

    private func calculateSoberStreak() -> Int {
        let calendar = Calendar.current
        let today = updatedDate ?? Date()
        var streak = 0
        for offset in 0..<2000 {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date) - 1
            let d = calendar.component(.day, from: date)
            let key = "\(y)-\(m)-\(d)"
            let level = daysData[key] ?? .none
            if [DrinkLevel.little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport].contains(level) {
                return streak
            }
            streak += 1
        }
        return streak
    }

    private func calculateDrinkingStreak() -> Int {
        let calendar = Calendar.current
        let today = updatedDate ?? Date()
        var maxStreak = 0, current = 0
        // Только с начала текущего года
        guard let yearStart = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else { return 0 }
        var date = yearStart
        while date <= today {
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date) - 1
            let d = calendar.component(.day, from: date)
            let level = daysData["\(y)-\(m)-\(d)"] ?? .none
            if [DrinkLevel.little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport].contains(level) {
                current += 1; maxStreak = max(maxStreak, current)
            } else { current = 0 }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return maxStreak <= 1 ? 0 : maxStreak
    }

    private func calculateMaxSoberStreak() -> Int {
        let calendar = Calendar.current
        let today = updatedDate ?? Date()
        var maxStreak = 0, current = 0
        guard let yearStart = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else { return 0 }
        var date = yearStart
        while date <= today {
            let y = calendar.component(.year, from: date)
            let m = calendar.component(.month, from: date) - 1
            let d = calendar.component(.day, from: date)
            let level = daysData["\(y)-\(m)-\(d)"] ?? .none
            if [DrinkLevel.little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport].contains(level) {
                current = 0
            } else { current += 1; maxStreak = max(maxStreak, current) }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        return maxStreak
    }


    var body: some View {
        let yearStats = calculateYearStats()

        VStack(spacing: 16) {
            // Заголовок с датой
            HStack {
                Text(NSLocalizedString("friend_stats_title", comment: ""))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Основной блок
            VStack(spacing: 10) {
                // Трезвый стрик
                HStack {
                    Image("sober_icon").resizable().scaledToFit().frame(width: 32, height: 32)
                    Text(NSLocalizedString("sober_streak_title", comment: ""))
                        .font(.system(size: 14)).foregroundColor(.black)
                    Spacer()
                    Text("\(calculateSoberStreak())")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.black)
                }
                .padding(.horizontal, 12).frame(maxWidth: .infinity).frame(height: 56)
                .background(Color(hex: "F6C7DC")).cornerRadius(12)

                HStack(spacing: 8) {
                    statSmall(image: "drunk_icon", label: NSLocalizedString("drinking_streak_title", comment: ""),
                              value: "\(calculateDrinkingStreak())", color: Color(hex: "BBA0F2"))
                    statSmall(image: "max_sober_icon", label: NSLocalizedString("max_sober_streak_title", comment: ""),
                              value: "\(calculateMaxSoberStreak())", color: Color(hex: "A8E6A8"))
                }

                HStack(spacing: 8) {
                    statSmall(image: "total_drunk_icon", label: NSLocalizedString("total_drinking_days_title", comment: ""),
                              value: "\(yearStats.totalDrinking)", color: Color(hex: "BBA0F2"))
                    statSmall(image: "total_sober_icon", label: NSLocalizedString("total_sober_days_title", comment: ""),
                              value: "\(yearStats.totalDays - yearStats.totalDrinking)", color: Color(hex: "A8E6A8"))
                }

                HStack(spacing: 8) {
                    statSmall(image: "little_normal", label: NSLocalizedString("drink_level_little", comment: ""),
                              value: "\(yearStats.little)", color: Color(hex: "BDC7FA"))
                    statSmall(image: "medium_normal", label: NSLocalizedString("drink_level_medium", comment: ""),
                              value: "\(yearStats.medium)", color: Color(hex: "BDC7FA"))
                    statSmall(image: "heavy_normal", label: NSLocalizedString("drink_level_heavy", comment: ""),
                              value: "\(yearStats.heavy)", color: Color(hex: "BDC7FA"))
                }

                HStack {
                    Image("sport_icon").resizable().scaledToFit().frame(width: 28, height: 28)
                    Text(NSLocalizedString("sport_days_title", comment: ""))
                        .font(.system(size: 13)).foregroundColor(.black)
                    Spacer()
                    Text("\(yearStats.sport)")
                        .font(.system(size: 17, weight: .bold)).foregroundColor(.black)
                }
                .padding(.horizontal, 12).frame(maxWidth: .infinity).frame(height: 56)
                .background(Color(hex: "EFFFB6")).cornerRadius(12)
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))

            // Алко vs Спорт
            let totalTracked = yearStats.drinkingDays + yearStats.sport - yearStats.little_sport
            if totalTracked > 0 {
                let total = Double(yearStats.drinkingDays) + Double(yearStats.sport)
                let dp = (Double(yearStats.drinkingDays) / total * 100).rounded()
                let sp = (Double(yearStats.sport) / total * 100).rounded()
                FriendPercentageBarView(drinkingPercentage: dp, sportPercentage: sp)
            }

            // Неделя
            WeekStatsView(daysData: daysData, selectedYear: currentYear)
        }
    }

    private func statSmall(image: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(image).resizable().scaledToFit().frame(width: 24, height: 24)
                Text(value).font(.system(size: 17, weight: .bold)).foregroundColor(.black)
            }
            Text(label).font(.system(size: 14)).foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color).cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.3), lineWidth: 1))
    }
}

// Упрощённый бар для друга (без анимации)
private struct FriendPercentageBarView: View {
    let drinkingPercentage: Double
    let sportPercentage: Double

    var body: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("alco_vs_sport", comment: ""))
                .font(.headline).foregroundColor(.white)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.2)).frame(height: 20)
                    HStack(spacing: 0) {
                        if drinkingPercentage > 0 {
                            Rectangle()
                                .fill(LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(drinkingPercentage) / 100)
                        }
                        if sportPercentage > 0 {
                            Rectangle()
                                .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                                .frame(width: geometry.size.width * CGFloat(sportPercentage) / 100)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .frame(height: 20)

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text(NSLocalizedString("your_week_drink", comment: ""))
                        .font(.system(size: 12)).foregroundColor(.white.opacity(1.0))
                    Text("\(Int(drinkingPercentage))%")
                        .font(.system(size: 12)).foregroundColor(.white)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.green).frame(width: 8, height: 8)
                    Text(NSLocalizedString("your_week_sport", comment: ""))
                        .font(.system(size: 12)).foregroundColor(.white.opacity(1.0))
                    Text("\(Int(sportPercentage))%")
                        .font(.system(size: 12)).foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.2), lineWidth: 1))
    }
}
