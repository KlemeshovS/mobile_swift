//
//  MonthlyAverageView.swift
//  Wobbly
//
import SwiftUI

struct MonthlyAverageView: View {
    let daysData: [String: DrinkLevel]
    let selectedYear: Int
    var username: String? = nil   // nil → "вы", иначе имя пользователя

    // 0 = алкоголь, 1 = спорт, 2 = общее
    @AppStorage("monthlyAverageModeIndex") private var modeIndex: Int = 0

    private var isAlcohol:  Bool { modeIndex == 0 }
    private var isSport:    Bool { modeIndex == 1 }
    private var isCombined: Bool { modeIndex == 2 }

    private let calendar = Calendar.current

    // MARK: - Data

    private struct MonthData {
        let index: Int
        let count: Int
        let isFuture: Bool
    }

    private var monthLetters: [String] {
        let locale = LanguageManager.shared.currentLocale
        let formatter = DateFormatter()
        formatter.locale = locale
        return (1...12).map { month in
            let date = DateComponents(calendar: calendar, year: 2000, month: month, day: 1).date!
            let full = formatter.standaloneMonthSymbols?[month - 1] ?? ""
            return String((full.first ?? " ")).uppercased()
        }
    }

    private func monthDataFor(alcohol: Bool) -> [MonthData] {
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let currentMonth = calendar.component(.month, from: now)

        return (1...12).map { month in
            let isFuture = selectedYear > currentYear
                || (selectedYear == currentYear && month > currentMonth)

            var count = 0
            if !isFuture {
                for (key, level) in daysData {
                    let parts = key.split(separator: "-").map { String($0) }
                    guard parts.count == 3,
                          let y = Int(parts[0]),
                          let m = Int(parts[1]),
                          y == selectedYear,
                          m + 1 == month else { continue }

                    if alcohol {
                        let isDrink = [DrinkLevel.little, .medium, .heavy,
                                       .little_sport, .medium_sport, .heavy_sport].contains(level)
                        if isDrink { count += 1 }
                    } else {
                        let isSportDay = [DrinkLevel.sport, .little_sport,
                                          .medium_sport, .heavy_sport].contains(level)
                        if isSportDay { count += 1 }
                    }
                }
            }
            return MonthData(index: month - 1, count: count, isFuture: isFuture)
        }
    }

    private var monthData: [MonthData] { monthDataFor(alcohol: isAlcohol) }
    private var alcoholData: [MonthData] { monthDataFor(alcohol: true) }
    private var sportData:   [MonthData] { monthDataFor(alcohol: false) }

    private func averageFor(_ data: [MonthData]) -> Double {
        let past = data.filter { !$0.isFuture }
        guard !past.isEmpty else { return 0 }
        return Double(past.reduce(0) { $0 + $1.count }) / Double(past.count)
    }

    private var averageRaw: Double     { averageFor(monthData) }
    private var averageRounded: Int    { Int(averageRaw.rounded()) }

    private var alcoholAvgRaw: Double  { averageFor(alcoholData) }
    private var alcoholAvgInt: Int     { Int(alcoholAvgRaw.rounded()) }
    private var sportAvgRaw: Double    { averageFor(sportData) }
    private var sportAvgInt: Int       { Int(sportAvgRaw.rounded()) }

    private var maxCount: Int {
        if isCombined {
            let aMax = alcoholData.map(\.count).max() ?? 1
            let sMax = sportData.map(\.count).max() ?? 1
            return max(max(aMax, sMax), 1)
        }
        return max(monthData.map(\.count).max() ?? 1, 1)
    }

    private var accentColor: Color {
        isAlcohol ? Color(hex: "FF0072") : Color(hex: "C7FF00")
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Заголовок
            Text(NSLocalizedString("monthly_average_title", comment: ""))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))
                .padding(.bottom, 12)

            // Тоггл
            HStack(spacing: 0) {
                toggleButton(label: NSLocalizedString("monthly_mode_alcohol", comment: ""),
                             active: isAlcohol,
                             activeColor: Color(hex: "FF0072")) {
                    withAnimation(.easeInOut(duration: 0.18)) { modeIndex = 0 }
                    HapticManager.shared.impact(.light)
                }
                toggleButton(label: NSLocalizedString("monthly_mode_sport", comment: ""),
                             active: isSport,
                             activeColor: Color(hex: "C7FF00")) {
                    withAnimation(.easeInOut(duration: 0.18)) { modeIndex = 1 }
                    HapticManager.shared.impact(.light)
                }
                toggleButton(label: NSLocalizedString("monthly_mode_combined", comment: ""),
                             active: isCombined,
                             activeColor: Color(hex: "A78BFA")) {
                    withAnimation(.easeInOut(duration: 0.18)) { modeIndex = 2 }
                    HapticManager.shared.impact(.light)
                }
            }
            .background(Color.white.opacity(0.07))
            .cornerRadius(10)
            .padding(.bottom, 14)

            // График
            GeometryReader { geo in
                let labelH: CGFloat = 16
                let chartH = geo.size.height - labelH

                if isCombined {
                    combinedChart(geo: geo, chartH: chartH, labelH: labelH)
                } else {
                    singleChart(geo: geo, chartH: chartH, labelH: labelH)
                }
            }
            .frame(height: 140)

            // Легенда для режима "Общее"
            if isCombined {
                VStack(alignment: .leading, spacing: 6) {
                    legendRow(color: Color(hex: "FF0072"),
                              text: NSLocalizedString("monthly_legend_alcohol", comment: ""))
                    legendRow(color: Color(hex: "C7FF00"),
                              text: NSLocalizedString("monthly_legend_sport", comment: ""))
                }
                .padding(.top, 12)
            }

            // Аналитическая фраза (только в одиночных режимах)
            if !isCombined, let phrase = analyticsPhrase {
                Text(phrase)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.07))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    // MARK: - Single chart (алкоголь / спорт)

    @ViewBuilder
    private func singleChart(geo: GeometryProxy, chartH: CGFloat, labelH: CGFloat) -> some View {
        let spacing: CGFloat = 6
        let barWidth = (geo.size.width - 11 * spacing) / 12
        let avgFraction = Double(averageRounded) / Double(maxCount)
        let avgY = chartH - CGFloat(avgFraction) * chartH

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                gridLines(chartH: chartH, width: geo.size.width)

                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<12, id: \.self) { i in
                        let data = monthData[i]
                        let barH = barHeight(count: data.count, isFuture: data.isFuture, chartH: chartH)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(barFill(data))
                            .frame(width: barWidth, height: barH)
                    }
                }
                .frame(width: geo.size.width, height: chartH, alignment: .bottom)

                if averageRaw > 0 {
                    avgLine(y: avgY, width: geo.size.width, color: .white.opacity(0.5))
                    avgLabel(text: avgLabelText(averageRounded),
                             y: avgY,
                             x: geo.size.width - labelTextWidth(averageRounded) - 4)
                }
            }
            .frame(height: chartH)

            monthLabels(spacing: spacing, barWidth: barWidth, height: labelH)
        }
    }

    // MARK: - Combined chart (алкоголь + спорт)

    @ViewBuilder
    private func combinedChart(geo: GeometryProxy, chartH: CGFloat, labelH: CGFloat) -> some View {
        let pairSpacing: CGFloat = 4   // между парами
        let innerSpacing: CGFloat = 2  // между двумя столбиками внутри пары
        let pairWidth = (geo.size.width - 11 * pairSpacing) / 12
        let barWidth = (pairWidth - innerSpacing) / 2

        let alcoholFraction = Double(alcoholAvgInt) / Double(maxCount)
        let sportFraction   = Double(sportAvgInt)   / Double(maxCount)
        let alcoholAvgY = chartH - CGFloat(alcoholFraction) * chartH
        let sportAvgY   = chartH - CGFloat(sportFraction)   * chartH

        VStack(spacing: 0) {
            ZStack(alignment: .topLeading) {
                gridLines(chartH: chartH, width: geo.size.width)

                // Пары столбиков
                HStack(alignment: .bottom, spacing: pairSpacing) {
                    ForEach(0..<12, id: \.self) { i in
                        let a = alcoholData[i]
                        let s = sportData[i]
                        HStack(alignment: .bottom, spacing: innerSpacing) {
                            // Левый — алкоголь
                            RoundedRectangle(cornerRadius: 2)
                                .fill(combinedBarFill(isFuture: a.isFuture, count: a.count,
                                                      color: Color(hex: "FF0072")))
                                .frame(width: barWidth,
                                       height: barHeight(count: a.count, isFuture: a.isFuture, chartH: chartH))
                            // Правый — спорт
                            RoundedRectangle(cornerRadius: 2)
                                .fill(combinedBarFill(isFuture: s.isFuture, count: s.count,
                                                      color: Color(hex: "C7FF00")))
                                .frame(width: barWidth,
                                       height: barHeight(count: s.count, isFuture: s.isFuture, chartH: chartH))
                        }
                    }
                }
                .frame(width: geo.size.width, height: chartH, alignment: .bottom)

                // Линия спорта + подпись слева
                if sportAvgRaw > 0 {
                    avgLine(y: sportAvgY, width: geo.size.width, color: Color(hex: "C7FF00").opacity(0.6))
                    avgLabel(text: avgLabelText(sportAvgInt),
                             y: sportAvgY,
                             x: 4,
                             textColor: Color(hex: "C7FF00").opacity(0.9))
                }

                // Линия алкоголя + подпись справа
                if alcoholAvgRaw > 0 {
                    avgLine(y: alcoholAvgY, width: geo.size.width, color: Color(hex: "FF0072").opacity(0.6))
                    avgLabel(text: avgLabelText(alcoholAvgInt),
                             y: alcoholAvgY,
                             x: geo.size.width - labelTextWidth(alcoholAvgInt) - 4,
                             textColor: Color(hex: "FF0072").opacity(0.9))
                }
            }
            .frame(height: chartH)

            // Буквы месяцев — ширина = pairWidth
            HStack(spacing: pairSpacing) {
                ForEach(0..<12, id: \.self) { i in
                    Text(monthLetters[i])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(isCurrentMonth(i) ? .white : .white.opacity(0.4))
                        .frame(width: pairWidth)
                }
            }
            .frame(height: labelH)
        }
    }

    // MARK: - Shared drawing helpers

    @ViewBuilder
    private func gridLines(chartH: CGFloat, width: CGFloat) -> some View {
        ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { fraction in
            let y = chartH - CGFloat(fraction) * chartH
            Path { p in
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: width, y: y))
            }
            .stroke(Color.white.opacity(0.07),
                    style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))
        }
    }

    @ViewBuilder
    private func avgLine(y: CGFloat, width: CGFloat, color: Color) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: width, y: y))
        }
        .stroke(color, lineWidth: 1.5)
    }

    @ViewBuilder
    private func avgLabel(text: String,
                          y: CGFloat,
                          x: CGFloat,
                          textColor: Color = .white.opacity(0.85)) -> some View {
        let w = text.size(font: .systemFont(ofSize: 9, weight: .semibold)).width + 10
        let labelY = y - 16

        RoundedRectangle(cornerRadius: 4)
            .fill(Color.black.opacity(0.45))
            .frame(width: w, height: 14)
            .offset(x: x, y: labelY)

        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundColor(textColor)
            .offset(x: x + 5, y: labelY + 1)
    }

    @ViewBuilder
    private func monthLabels(spacing: CGFloat, barWidth: CGFloat, height: CGFloat) -> some View {
        HStack(spacing: spacing) {
            ForEach(0..<12, id: \.self) { i in
                Text(monthLetters[i])
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(isCurrentMonth(i) ? .white : .white.opacity(0.4))
                    .frame(width: barWidth)
            }
        }
        .frame(height: height)
    }

    private func barHeight(count: Int, isFuture: Bool, chartH: CGFloat) -> CGFloat {
        if isFuture { return chartH * 0.10 }
        if count == 0 { return 3 }
        return max(CGFloat(count) / CGFloat(maxCount) * chartH, 3)
    }

    // MARK: - Helpers

    @ViewBuilder
    private func legendRow(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color.opacity(0.75))
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    @ViewBuilder
    private func toggleButton(label: String, active: Bool, activeColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: active ? .semibold : .regular))
                .foregroundColor(active ? .white : .white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(active ? activeColor.opacity(0.2) : Color.clear)
                .cornerRadius(10)
                .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func barFill(_ data: MonthData) -> Color {
        if data.isFuture { return Color.white.opacity(0.10) }
        if data.count == 0 { return Color.white.opacity(0.06) }
        return accentColor.opacity(0.75)
    }

    private func combinedBarFill(isFuture: Bool, count: Int, color: Color) -> Color {
        if isFuture { return Color.white.opacity(0.10) }
        if count == 0 { return Color.white.opacity(0.06) }
        return color.opacity(0.75)
    }

    private func isCurrentMonth(_ index: Int) -> Bool {
        let now = Date()
        return calendar.component(.year, from: now) == selectedYear
            && calendar.component(.month, from: now) == index + 1
    }

    private func avgLabelText(_ n: Int) -> String {
        let prefix = NSLocalizedString("monthly_avg_prefix", comment: "")
        return "\(prefix) \(n) \(daysWord(n))"
    }

    private func labelTextWidth(_ n: Int) -> CGFloat {
        avgLabelText(n).size(font: .systemFont(ofSize: 9, weight: .semibold)).width + 10
    }

    private var analyticsPhrase: String? {
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        guard selectedYear == currentYear, averageRaw > 0 else { return nil }

        let currentMonthIndex = calendar.component(.month, from: now) - 1
        let current = monthData[currentMonthIndex]
        guard !current.isFuture else { return nil }

        let diff = current.count - averageRounded
        let lang = LanguageManager.shared.currentLanguage

        if lang == .russian {
            let subject  = username ?? "вы"
            let drinkV   = username != nil ? "пьёт" : "пьёте"
            let sportV   = username != nil ? "занимается спортом" : "занимаетесь спортом"
            if diff == 0 {
                return isAlcohol
                    ? "В этом месяце \(subject) \(drinkV) как обычно"
                    : "В этом месяце \(subject) \(sportV) как обычно"
            }
            let n = abs(diff)
            let direction = diff > 0 ? "чаще" : "реже"
            return isAlcohol
                ? "В этом месяце \(subject) \(drinkV) на \(n) \(daysWord(n)) \(direction), чем обычно"
                : "В этом месяце \(subject) \(sportV) на \(n) \(daysWord(n)) \(direction), чем обычно"
        } else {
            let subject  = username ?? "you"
            let drinkV   = username != nil ? "drinks" : "drink"
            let sportV   = username != nil ? "works out" : "work out"
            if diff == 0 {
                return isAlcohol
                    ? "This month \(subject) \(drinkV) as usual"
                    : "This month \(subject) \(sportV) as usual"
            }
            let n = abs(diff)
            let direction = diff > 0 ? "more" : "less"
            return isAlcohol
                ? "This month \(subject) \(drinkV) \(n) \(n == 1 ? "day" : "days") \(direction) than usual"
                : "This month \(subject) \(sportV) \(n) \(n == 1 ? "day" : "days") \(direction) than usual"
        }
    }

    private func daysWord(_ n: Int) -> String {
        let lang = LanguageManager.shared.currentLanguage
        if lang == .russian {
            let mod100 = n % 100
            let mod10  = n % 10
            if mod100 >= 11 && mod100 <= 14 { return "дней" }
            switch mod10 {
            case 1:       return "день"
            case 2, 3, 4: return "дня"
            default:      return "дней"
            }
        } else {
            return n == 1 ? "day" : "days"
        }
    }
}

// MARK: - String size helper

private extension String {
    func size(font: UIFont) -> CGSize {
        (self as NSString).size(withAttributes: [.font: font])
    }
}
