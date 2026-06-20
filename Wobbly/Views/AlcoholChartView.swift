//
//  AlcoholChartView.swift
//  Wobbly
//
import SwiftUI

struct AlcoholChartView: View {
    let daysData: [String: DrinkLevel]
    /// Выбранный год (из StatsTabView). По умолчанию — текущий.
    var selectedYear: Int = Calendar.current.component(.year, from: Date())
    /// Если передан — режим сравнения двух пользователей (вместо среднего)
    var comparisonData: [String: DrinkLevel]? = nil
    /// Названия линий для режима сравнения
    var primaryLabel: String? = nil      // красная (чей профиль смотрим)
    var comparisonLabel: String? = nil   // синяя (текущий пользователь)
    /// Callback для показа инфо-попапа (title, text) → FancyMotivationView
    var onShowInfo: ((String, String) -> Void)? = nil

    private let calendar    = Calendar.current
    private let accentColor = Color(hex: "FF0072")
    private let yAxisW: CGFloat = 22   // ширина зоны Y-подписей слева

    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.5

    // MARK: - Data helpers

    private var now:          Date { Date() }
    private var currentYear:  Int  { calendar.component(.year,  from: now) }
    private var currentMonth: Int  { calendar.component(.month, from: now) }
    private var today:        Int  { calendar.component(.day,   from: now) }
    private var daysInMonth:  Int  {
        calendar.range(of: .day, in: .month, for: now)?.count ?? 30
    }

    private func alcoholScore(_ level: DrinkLevel?) -> Int {
        switch level {
        case .little,  .little_sport: return 1
        case .medium,  .medium_sport: return 3
        case .heavy,   .heavy_sport:  return 5
        default:                      return 0
        }
    }

    // MARK: - Actual data

    private struct DayPoint { let day: Int; let cumulative: Int }

    /// Последний день для отображения данных
    private var lastDay: Int {
        if selectedYear == currentYear { return today }
        return daysInMonth  // прошлый год — показываем полный месяц
    }

    private var chartData: [DayPoint] {
        guard lastDay >= 1 else { return [] }
        var cum = 0
        return (1...lastDay).map { day in
            let key = "\(selectedYear)-\(currentMonth - 1)-\(day)"
            cum += alcoholScore(daysData[key])
            return DayPoint(day: day, cumulative: cum)
        }
    }

    // MARK: - Average trajectory (1..daysInMonth, по всем прошлым месяцам)

    private var averageTrajectory: [(day: Int, avg: Double)] {
        var byMonth: [String: [Int: Int]] = [:]
        for (key, level) in daysData {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let y  = Int(parts[0]),
                  let m0 = Int(parts[1]),
                  let d  = Int(parts[2]) else { continue }
            let m = m0 + 1
            if y == currentYear && m == currentMonth { continue }
            byMonth["\(y)-\(m)", default: [:]][d] = alcoholScore(level)
        }
        guard !byMonth.isEmpty else { return [] }

        var cumByDay: [Int: [Double]] = [:]
        for (mk, dayScores) in byMonth {
            let mParts = mk.split(separator: "-").map { String($0) }
            guard let y = Int(mParts[0]), let m = Int(mParts[1]) else { continue }
            var comps = DateComponents(); comps.year = y; comps.month = m; comps.day = 1
            guard let date = calendar.date(from: comps) else { continue }
            let dim = calendar.range(of: .day, in: .month, for: date)?.count ?? 30

            var cum = 0
            var cumPerDay: [Int: Int] = [:]
            for d in 1...dim { cum += dayScores[d] ?? 0; cumPerDay[d] = cum }
            let totalCum = cum

            // Заполняем все дни текущего месяца (1..daysInMonth)
            for d in 1...daysInMonth {
                let val = d <= dim ? Double(cumPerDay[d] ?? 0) : Double(totalCum)
                cumByDay[d, default: []].append(val)
            }
        }

        return (1...daysInMonth).map { day in
            let vals = cumByDay[day] ?? []
            let raw  = vals.isEmpty ? 0.0 : vals.reduce(0, +) / Double(vals.count)
            return (day: day, avg: raw.rounded())   // только целые значения
        }
    }

    private var totalScore: Int    { chartData.last?.cumulative ?? 0 }
    private var avgAtToday: Double { averageTrajectory.first(where: { $0.day == today })?.avg ?? 0 }
    private var isClean:    Bool   { totalScore == 0 }

    /// Накопительный график для второго датасета (режим сравнения)
    private var comparisonChartData: [DayPoint] {
        guard let data = comparisonData, lastDay >= 1 else { return [] }
        var cum = 0
        return (1...lastDay).map { day in
            let key = "\(selectedYear)-\(currentMonth - 1)-\(day)"
            cum += alcoholScore(data[key])
            return DayPoint(day: day, cumulative: cum)
        }
    }

    private var maxYValue: Int {
        let actual = chartData.map(\.cumulative).max() ?? 0
        if comparisonData != nil {
            let comp = comparisonChartData.map(\.cumulative).max() ?? 0
            return max(max(actual, comp), 1)
        }
        let avg = Int((averageTrajectory.map(\.avg).max() ?? 0).rounded(.up))
        return max(max(actual, avg), 1)
    }

    // Y-отметки для сетки и подписей.
    // yFraction вычисляется из самого value, чтобы линия и цифра совпадали на графике.
    private var yTicks: [(yFraction: Double, value: Int)] {
        var seen = Set<Int>()
        return [0.25, 0.5, 0.75, 1.0].compactMap { f in
            let v = max(Int((Double(maxYValue) * f).rounded()), 1)
            if seen.contains(v) { return nil }
            seen.insert(v)
            return (yFraction: Double(v) / Double(maxYValue), value: v)
        }
    }

    // MARK: - Title / Month name

    private var titleText: String {
        let lang = LanguageManager.shared.currentLanguage
        if lang == .russian {
            let prep = ["январе","феврале","марте","апреле","мае","июне",
                        "июле","августе","сентябре","октябре","ноябре","декабре"]
            return "Алкоголь в \(prep[currentMonth - 1])"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "MMMM"
            fmt.locale = Locale(identifier: "en")
            return "Alcohol in \(fmt.string(from: now))"
        }
    }

    /// Именительный падеж месяца для легенды: "Апрель", "May"
    private var currentMonthName: String {
        let fmt = DateFormatter()
        fmt.locale = LanguageManager.shared.currentLocale
        fmt.dateFormat = "LLLL"
        let name = fmt.string(from: now)
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    // MARK: - View

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Заголовок + кнопка (i)
            ZStack(alignment: .topTrailing) {
                Text(titleText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    let title = NSLocalizedString("alcohol_chart_info_title", comment: "")
                    let body  = NSLocalizedString("alcohol_chart_info_body",  comment: "")
                    onShowInfo?(title, body)
                } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.bottom, 14)

            if isClean {
                cleanMonthView
            } else {
                chartView
                legendView
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

    // MARK: - Clean month

    private var cleanMonthView: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundColor(Color(hex: "C7FF00"))
                .font(.system(size: 20))
            Text(NSLocalizedString("alcohol_chart_clean_month", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    // MARK: - Chart

    private let labelH: CGFloat = 14

    private var chartView: some View {
        GeometryReader { geo in
            let w      = geo.size.width
            let h      = geo.size.height
            let chartH = h - labelH
            let chartW = w - yAxisW

            let actualPts  = cgPoints(data: chartData.map { Double($0.cumulative) },
                                      days: chartData.map(\.day),
                                      chartW: chartW, chartH: chartH)
            let avgPts     = cgPoints(data: averageTrajectory.map(\.avg),
                                      days: averageTrajectory.map(\.day),
                                      chartW: chartW, chartH: chartH)
            // Синяя линия смещается на 1.5px вверх, чтобы была видна при совпадении с красной
            let compPts    = cgPoints(data: comparisonChartData.map { Double($0.cumulative) },
                                      days: comparisonChartData.map(\.day),
                                      chartW: chartW, chartH: chartH)
                                      .map { CGPoint(x: $0.x, y: $0.y - 1.5) }

            ZStack(alignment: .topLeading) {

                // Сетка + Y-подписи
                ForEach(yTicks, id: \.value) { tick in
                    let y = chartH - CGFloat(tick.yFraction) * chartH

                    Path { p in
                        p.move(to: CGPoint(x: yAxisW, y: y))
                        p.addLine(to: CGPoint(x: w, y: y))
                    }
                    .stroke(Color.white.opacity(0.07),
                            style: StrokeStyle(lineWidth: 0.5, dash: [3, 4]))

                    Text("\(tick.value)")
                        .font(.system(size: 8, weight: .regular))
                        .foregroundColor(.white.opacity(0.35))
                        .frame(width: yAxisW - 2, alignment: .trailing)
                        .offset(x: 0, y: y - 5)
                }

                // Заливка под фактической линией
                if actualPts.count >= 2 {
                    fillPath(points: actualPts, chartH: chartH)
                        .fill(LinearGradient(
                            colors: [accentColor.opacity(0.35), accentColor.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                }

                // Серая линия среднего (только в режиме без сравнения)
                if comparisonData == nil, avgPts.count >= 2 {
                    smoothPath(points: avgPts)
                        .stroke(Color.white.opacity(0.35),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }

                // Синяя линия текущего пользователя (режим сравнения)
                if comparisonData != nil, compPts.count >= 2 {
                    smoothPath(points: compPts)
                        .stroke(Color(hex: "60A5FA"),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }

                // Фактическая линия (красная)
                if actualPts.count >= 2 {
                    smoothPath(points: actualPts)
                        .stroke(accentColor,
                                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }

                // Точка сегодня — красная (с пульсацией)
                if let last = actualPts.last {
                    Circle()
                        .fill(accentColor.opacity(pulseOpacity * 0.6))
                        .frame(width: 14 * pulseScale, height: 14 * pulseScale)
                        .offset(x: last.x - 7 * pulseScale, y: last.y - 7 * pulseScale)
                    Circle()
                        .fill(accentColor)
                        .frame(width: 7, height: 7)
                        .offset(x: last.x - 3.5, y: last.y - 3.5)
                }

                // Точка сегодня — синяя (с пульсацией, только в режиме сравнения)
                if comparisonData != nil, let last = compPts.last {
                    Circle()
                        .fill(Color(hex: "60A5FA").opacity(pulseOpacity * 0.6))
                        .frame(width: 14 * pulseScale, height: 14 * pulseScale)
                        .offset(x: last.x - 7 * pulseScale, y: last.y - 7 * pulseScale)
                    Circle()
                        .fill(Color(hex: "60A5FA"))
                        .frame(width: 7, height: 7)
                        .offset(x: last.x - 3.5, y: last.y - 3.5)
                }

                // Метки дней по X
                dayLabels(width: w, chartW: chartW, height: h)
            }
        }
        .frame(height: 110)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.6
                pulseOpacity = 0.0
            }
        }
    }

    // MARK: - Legend

    private var legendView: some View {
        VStack(alignment: .center, spacing: 6) {
            if let primLabel = primaryLabel, let compLabel = comparisonLabel {
                // Режим сравнения двух пользователей — по центру
                HStack(spacing: 14) {
                    legendRow(color: accentColor,          text: primLabel)
                    legendRow(color: Color(hex: "60A5FA"), text: compLabel)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if let text = userComparisonText {
                    Text(text)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            } else {
                // Обычный режим: месяц + среднее — по центру
                HStack(spacing: 14) {
                    legendRow(color: accentColor, text: currentMonthName)
                    if !averageTrajectory.isEmpty {
                        legendRow(color: .white.opacity(0.4),
                                  text: NSLocalizedString("alcohol_chart_legend_avg", comment: ""))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                if !averageTrajectory.isEmpty {
                    Text(comparisonText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(comparisonColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func legendRow(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 1)
                .fill(color)
                .frame(width: 16, height: 2.5)
            Text(text)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var comparisonText: String {
        let diff = totalScore - Int(avgAtToday.rounded())
        let lang = LanguageManager.shared.currentLanguage
        if lang == .russian {
            if diff == 0 { return "Вы пьёте как обычно" }
            let adverb = abs(diff) >= 5 ? "сильно " : ""
            return diff > 0
                ? "Вы пьёте \(adverb)больше обычного"
                : "Вы пьёте \(adverb)меньше обычного"
        } else {
            if diff == 0 { return "You drink as usual" }
            let adverb = abs(diff) >= 5 ? "a lot " : ""
            return diff > 0
                ? "You drink \(adverb)more than usual"
                : "You drink \(adverb)less than usual"
        }
    }

    private var comparisonColor: Color { .white.opacity(0.85) }

    /// Текст сравнения двух пользователей (режим публичного профиля)
    private var userComparisonText: String? {
        guard let primLabel = primaryLabel, let compLabel = comparisonLabel else { return nil }
        let primScore = totalScore
        let compScore = comparisonChartData.last?.cumulative ?? 0
        let diff = primScore - compScore
        guard diff != 0 else { return nil }
        let lang = LanguageManager.shared.currentLanguage
        let adverb = abs(diff) >= 5 ? (lang == .russian ? "сильно " : "a lot ") : ""
        if lang == .russian {
            return diff > 0
                ? "\(primLabel) пьёт \(adverb)больше, чем \(compLabel)"
                : "\(primLabel) пьёт \(adverb)меньше, чем \(compLabel)"
        } else {
            return diff > 0
                ? "\(primLabel) drinks \(adverb)more than \(compLabel)"
                : "\(primLabel) drinks \(adverb)less than \(compLabel)"
        }
    }

    private func pointsWord(_ n: Int) -> String {
        let lang = LanguageManager.shared.currentLanguage
        guard lang == .russian else { return n == 1 ? "pt" : "pts" }
        let m100 = n % 100; let m10 = n % 10
        if m100 >= 11 && m100 <= 14 { return "баллов" }
        switch m10 {
        case 1:       return "балл"
        case 2, 3, 4: return "балла"
        default:      return "баллов"
        }
    }

    // MARK: - Path helpers

    /// Точки с учётом отступа yAxisW слева
    private func cgPoints(data: [Double], days: [Int], chartW: CGFloat, chartH: CGFloat) -> [CGPoint] {
        guard !data.isEmpty else { return [] }
        let totalDays = CGFloat(daysInMonth - 1)
        return zip(days, data).map { day, value in
            let x = yAxisW + (totalDays == 0 ? 0 : (CGFloat(day) - 1) / totalDays * chartW)
            let y = chartH - (maxYValue == 0 ? 0 : CGFloat(value) / CGFloat(maxYValue) * chartH)
            return CGPoint(x: x, y: y)
        }
    }

    private func smoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }
        path.move(to: points[0])
        for i in 0..<points.count - 1 {
            let p0 = points[max(i - 1, 0)]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = points[min(i + 2, points.count - 1)]
            let cp1 = CGPoint(x: p1.x + (p2.x - p0.x) / 6, y: p1.y + (p2.y - p0.y) / 6)
            let cp2 = CGPoint(x: p2.x - (p3.x - p1.x) / 6, y: p2.y - (p3.y - p1.y) / 6)
            path.addCurve(to: p2, control1: cp1, control2: cp2)
        }
        return path
    }

    private func fillPath(points: [CGPoint], chartH: CGFloat) -> Path {
        var path = smoothPath(points: points)
        path.addLine(to: CGPoint(x: points.last!.x, y: chartH))
        path.addLine(to: CGPoint(x: points[0].x,    y: chartH))
        path.closeSubpath()
        return path
    }

    @ViewBuilder
    private func dayLabels(width: CGFloat, chartW: CGFloat, height: CGFloat) -> some View {
        let totalDays = CGFloat(daysInMonth - 1)
        let labelDays = [1, 5, 10, 15, 20, 25, daysInMonth]
        ForEach(labelDays, id: \.self) { day in
            let x = yAxisW + (totalDays == 0 ? 0 : (CGFloat(day) - 1) / totalDays * chartW)
            Text("\(day)")
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 20)
                .offset(x: x - 10, y: height - labelH)
        }
    }
}
