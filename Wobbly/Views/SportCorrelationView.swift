//
//  SportCorrelationView.swift
//  Wobbly
//

import SwiftUI

struct SportCorrelationView: View {
    let daysData: [String: DrinkLevel]
    let selectedYear: Int

    private let calendar = Calendar.current

    // MARK: - Calculation

    private struct CorrelationData {
        let sportTotal: Int          // дней со спортом
        let sportWithAlcohol: Int    // из них с алкоголем
        let noSportTotal: Int        // дней без спорта
        let noSportWithAlcohol: Int  // из них с алкоголем

        var sportPct: Double {
            guard sportTotal > 0 else { return 0 }
            return (Double(sportWithAlcohol) / Double(sportTotal) * 100).rounded()
        }
        var noSportPct: Double {
            guard noSportTotal > 0 else { return 0 }
            return (Double(noSportWithAlcohol) / Double(noSportTotal) * 100).rounded()
        }
        var hasEnoughData: Bool { sportTotal >= 5 && noSportTotal >= 5 }
    }

    private var data: CorrelationData {
        let currentYear = calendar.component(.year, from: Date())
        let isCurrentYear = selectedYear == currentYear

        // Последний день для подсчёта
        let lastMonth: Int
        let lastDay: Int
        if isCurrentYear {
            lastMonth = calendar.component(.month, from: Date())
            lastDay   = calendar.component(.day,   from: Date())
        } else {
            lastMonth = 12; lastDay = 31
        }

        // Общее число дней в году (прошедших)
        var totalDays = 0
        for m in 1...lastMonth {
            var comps = DateComponents()
            comps.year = selectedYear; comps.month = m; comps.day = 1
            guard let monthStart = calendar.date(from: comps) else { continue }
            let dim = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 30
            let daysInThisMonth = (m == lastMonth) ? lastDay : dim
            totalDays += daysInThisMonth
        }

        // Считаем из daysData
        var sportTotal = 0
        var sportWithAlcohol = 0
        var noSportWithAlcohol = 0 // дней без спорта, но с алкоголем

        for (key, level) in daysData {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let y = Int(parts[0]),
                  let m0 = Int(parts[1]),
                  let d = Int(parts[2]),
                  y == selectedYear else { continue }
            let m = m0 + 1  // 1-based

            // Не считаем будущие дни
            if m > lastMonth || (m == lastMonth && d > lastDay) { continue }

            let hasSport = (level == .sport || level == .little_sport ||
                            level == .medium_sport || level == .heavy_sport)
            let hasAlcohol = (level == .little || level == .medium || level == .heavy ||
                              level == .little_sport || level == .medium_sport || level == .heavy_sport)

            if hasSport {
                sportTotal += 1
                if hasAlcohol { sportWithAlcohol += 1 }
            } else {
                if hasAlcohol { noSportWithAlcohol += 1 }
            }
        }

        let noSportTotal = totalDays - sportTotal

        return CorrelationData(
            sportTotal: sportTotal,
            sportWithAlcohol: sportWithAlcohol,
            noSportTotal: max(noSportTotal, 0),
            noSportWithAlcohol: noSportWithAlcohol
        )
    }

    // MARK: - Conclusion text

    private var conclusionText: String {
        let d = data
        let lang = LanguageManager.shared.currentLanguage
        guard d.sportTotal > 0 else { return "" }

        if d.noSportPct == 0 && d.sportPct == 0 {
            return lang == .russian
                ? "В этом году ты не пил ни в дни со спортом, ни без него"
                : "You haven't drunk on either sport or non-sport days this year"
        }

        if d.sportPct == 0 {
            return lang == .russian
                ? "В дни со спортом ты не пил совсем 🎉"
                : "You never drink on sport days 🎉"
        }

        let absDiff = abs(d.sportPct - d.noSportPct)
        let absDaysDiff = abs(d.sportWithAlcohol - d.noSportWithAlcohol)

        // Разница незначительная — не делаем громких выводов
        if absDiff < 7 || absDaysDiff < 3 {
            return lang == .russian
                ? "Спорт практически не влияет на твоё употребление алкоголя"
                : "Sport doesn't seem to affect your drinking much"
        }

        let ratio = d.sportPct < d.noSportPct
            ? d.noSportPct / max(d.sportPct, 1)
            : d.sportPct / max(d.noSportPct, 1)
        let ratioStr = ratio >= 2 ? String(format: "%.0fx", ratio) : ""

        if d.sportPct < d.noSportPct {
            return lang == .russian
                ? (ratioStr.isEmpty ? "В дни со спортом ты пьёшь реже" : "В дни со спортом ты пьёшь в \(ratioStr) реже")
                : (ratioStr.isEmpty ? "You drink less on sport days" : "You drink \(ratioStr) less on sport days")
        } else {
            return lang == .russian
                ? (ratioStr.isEmpty ? "В дни со спортом ты пьёшь чаще — интересно 🤔" : "В дни со спортом ты пьёшь в \(ratioStr) чаще — интересно 🤔")
                : (ratioStr.isEmpty ? "You actually drink more on sport days — interesting 🤔" : "You drink \(ratioStr) more on sport days — interesting 🤔")
        }
    }

    // MARK: - View

    var body: some View {
        let d = data
        guard d.hasEnoughData else { return AnyView(EmptyView()) }

        return AnyView(
            VStack(alignment: .leading, spacing: 14) {

                // Заголовок
                Text(NSLocalizedString("correlation_title", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                // Полоска: дни со спортом
                correlationRow(
                    label: NSLocalizedString("correlation_sport_days", comment: ""),
                    pct: d.sportPct,
                    total: d.sportTotal,
                    withAlcohol: d.sportWithAlcohol,
                    color: Color(hex: "C7FF00")
                )

                // Полоска: дни без спорта
                correlationRow(
                    label: NSLocalizedString("correlation_no_sport_days", comment: ""),
                    pct: d.noSportPct,
                    total: d.noSportTotal,
                    withAlcohol: d.noSportWithAlcohol,
                    color: Color(hex: "FF0072")
                )

                // Итоговая фраза
                if !conclusionText.isEmpty {
                    Text(conclusionText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.leading)
                        .padding(.top, 2)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        )
    }

    // MARK: - Row

    @ViewBuilder
    private func correlationRow(label: String, pct: Double, total: Int, withAlcohol: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(Int(pct))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Фон полоски
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    // Заполнение
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(pct / 100), height: 8)
                        .animation(.easeOut(duration: 0.6), value: pct)
                }
            }
            .frame(height: 8)

            // Подпись: X из Y дней
            let lang = LanguageManager.shared.currentLanguage
            Text(lang == .russian
                 ? "\(withAlcohol) из \(total) \(daysWord(total))"
                 : "\(withAlcohol) of \(total) \(total == 1 ? "day" : "days")")
                .font(.system(size: 10, weight: .regular))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    private func daysWord(_ n: Int) -> String {
        let m100 = n % 100; let m10 = n % 10
        if m100 >= 11 && m100 <= 14 { return "дней" }
        switch m10 {
        case 1: return "день"
        case 2, 3, 4: return "дня"
        default: return "дней"
        }
    }
}
