//
//  WeekStatsView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 04.06.26.
//

import SwiftUI

struct WeekStatsView: View {
    let daysData: [String: DrinkLevel]
    let selectedYear: Int

    private struct DayStats {
        let sportCount: Int
        let drinkCount: Int
        var total: Int { sportCount + drinkCount }
    }

    private var weekdayNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        var symbols = formatter.shortWeekdaySymbols ?? []
        // Сдвигаем с воскресенья на понедельник
        if let sun = symbols.first {
            symbols.removeFirst()
            symbols.append(sun)
        }
        return symbols.map { String($0.prefix(2)).capitalized }
    }

    private var stats: [DayStats] {
        // weekday: 0=Пн, 1=Вт, ..., 6=Вс
        var sportCounts = [Int](repeating: 0, count: 7)
        var drinkCounts = [Int](repeating: 0, count: 7)

        let calendar = Calendar.current
        let currentYear = selectedYear
        
        for (key, level) in daysData {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  let day = Int(parts[2]),
                  year == currentYear else { continue }

            var comps = DateComponents()
            comps.year = year; comps.month = month + 1; comps.day = day
            guard let date = calendar.date(from: comps) else { continue }

            // iOS weekday: 1=Вс, 2=Пн...7=Сб → конвертируем в 0=Пн..6=Вс
            let iosWeekday = calendar.component(.weekday, from: date)
            let weekday = (iosWeekday + 5) % 7

            let isSport = [DrinkLevel.sport, .little_sport, .medium_sport, .heavy_sport].contains(level)
            let isDrink = [DrinkLevel.little, .medium, .heavy, .little_sport, .medium_sport, .heavy_sport].contains(level)

            if isSport { sportCounts[weekday] += 1 }
            if isDrink { drinkCounts[weekday] += 1 }
        }

        return (0..<7).map { DayStats(sportCount: sportCounts[$0], drinkCount: drinkCounts[$0]) }
    }

    private var maxTotal: Int {
        stats.map { $0.total }.max() ?? 1
    }
    
    private func barGradient(sport: Int, drink: Int) -> LinearGradient {
        if sport == 0 {
            return LinearGradient(
                colors: [Color(hex: "F87171"), Color(hex: "DC2626")],
                startPoint: .top, endPoint: .bottom
            )
        }
        if drink == 0 {
            return LinearGradient(
                colors: [Color(hex: "C7FF00"), Color(hex: "86EFAC")],
                startPoint: .top, endPoint: .bottom
            )
        }
        let ratio = Double(sport) / Double(sport + drink)
        return LinearGradient(
            stops: [
                .init(color: Color(hex: "C7FF00"), location: 0),
                .init(color: Color(hex: "86EFAC"), location: ratio * 0.7),
                .init(color: Color(hex: "FCD34D"), location: ratio),
                .init(color: Color(hex: "F87171"), location: ratio + (1 - ratio) * 0.3),
                .init(color: Color(hex: "DC2626"), location: 1)
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(NSLocalizedString("your_week_title", comment: ""))
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    let stat = stats[index]
                    let maxH: CGFloat = 120

                    VStack(spacing: 4) {
                        // Цифры над столбиком
                        VStack(spacing: 1) {
                            if stat.total > 0 {
                                HStack(spacing: 1) {
                                    Text("\(stat.sportCount)")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(Color(hex: "C7FF00"))
                                    Text("/")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.4))
                                    Text("\(stat.drinkCount)")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(Color(hex: "FF6B6B"))
                                }
                            } else {
                                Text("—")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .frame(height: 24, alignment: .bottom)

                        // Столбик
                        ZStack(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 28, height: maxH)
                            
                            if stat.total > 0 {
                                let totalH = CGFloat(stat.total) / CGFloat(maxTotal) * maxH
                                barGradient(sport: stat.sportCount, drink: stat.drinkCount)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .frame(width: 28, height: totalH)
                            }
                        }
                        .frame(height: maxH)

                        // День недели
                        Text(weekdayNames[index])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Легенда
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "C7FF00"))
                        .frame(width: 12, height: 8)
                    Text(NSLocalizedString("your_week_sport", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
                Text("/")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "DC2626"))
                        .frame(width: 12, height: 8)
                    Text(NSLocalizedString("your_week_drink", comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
