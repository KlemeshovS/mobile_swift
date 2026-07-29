//
//  ScoreHistoryView.swift
//  Wobbly
//

import SwiftUI

struct ScoreHistoryView: View {
    let daysData: [String: DrinkLevel]
    let selectedYear: Int
    var embedded: Bool = false
    var onShowInfo: ((String, String) -> Void)? = nil

    private let calendar = Calendar.current
    private let positiveColor = Color(hex: "C7FF00")
    private let negativeColor = Color(hex: "FF0072")
    private let yAxisW: CGFloat = 30
    private let chartH: CGFloat = 100
    private let labelH: CGFloat = 16

    @State private var isPulsing = false

    // MARK: - Named milestone definitions

    private struct NamedMilestone {
        let score: Int
        let nameKey: String
    }

    private let namedPositive: [NamedMilestone] = [
        NamedMilestone(score: 1234,  nameKey: "ach_milestone_1234_title"),  // Ай-Петри
        NamedMilestone(score: 1917,  nameKey: "ach_milestone_1917_title"),  // Гора Вашингтон
        NamedMilestone(score: 3491,  nameKey: "ach_milestone_3491_title"),  // Мунку-Сардык
        NamedMilestone(score: 4478,  nameKey: "ach_milestone_4478_title"),  // Маттерхорн
        NamedMilestone(score: 4506,  nameKey: "ach_milestone_4506_title"),  // Белуха
        NamedMilestone(score: 4810,  nameKey: "ach_milestone_4810_title"),  // Монблан
        NamedMilestone(score: 5054,  nameKey: "ach_milestone_5054_title"),  // Казбек
        NamedMilestone(score: 5642,  nameKey: "ach_milestone_5642_title"),  // Эльбрус
        NamedMilestone(score: 7010,  nameKey: "ach_milestone_7010_title"),  // Хан-Тенгри
        NamedMilestone(score: 8848,  nameKey: "ach_milestone_8848_title")   // Эверест
    ]

    private let namedNegative: [NamedMilestone] = [
        NamedMilestone(score: -202,   nameKey: "ach_milestone_202_negative_title"),   // Голубая дыра
        NamedMilestone(score: -1642,  nameKey: "ach_milestone_1642_negative_title"),  // Байкал
        NamedMilestone(score: -3800,  nameKey: "ach_milestone_3800_negative_title"),  // Титаник
        NamedMilestone(score: -6066,  nameKey: "ach_milestone_6066_negative_title"),  // Атакамская впадина
        NamedMilestone(score: -7729,  nameKey: "ach_milestone_7729_negative_title"),  // Зондский желоб
        NamedMilestone(score: -10047, nameKey: "ach_milestone_10047_negative_title"), // Кермадек
        NamedMilestone(score: -11022, nameKey: "ach_milestone_11022_negative_title")  // Марианская впадина
    ]

    // MARK: - Milestone dot model

    private struct MilestoneDot: Identifiable {
        let id: Int           // milestone score (unique)
        let name: String
        let point: CGPoint    // where to draw the dot
        let isPositive: Bool
        let isPrePeriod: Bool // true = achieved before current chart period
        let milestoneY: CGFloat
    }

    // MARK: - Data

    private var history: [ScoreHistoryPoint] {
        ProgressCalculator.calculateHistory(from: daysData, forYear: selectedYear)
    }

    private var hasNegativeValues: Bool { history.contains { $0.score < 0 } }
    private var zeroY: CGFloat { hasNegativeValues ? chartH / 2 : chartH }

    private var maxAbsValue: Int {
        let pts = history
        guard !pts.isEmpty else { return 1 }
        let currentMax = pts.map { abs($0.score) }.max() ?? 1
        let currentScore = pts.last?.score ?? 0
        // Расширяем диапазон чтобы следующий майлстоун был виден на графике,
        // но только если он в пределах 2x от текущего максимума
        if let nextScore = nextMilestoneScore(currentScore: currentScore) {
            let nextAbs = abs(nextScore)
            if nextAbs <= currentMax * 2 {
                return max(nextAbs, currentMax, 1)
            }
        }
        return max(currentMax, 1)
    }

    private var daysInYear: Int {
        var c = DateComponents(); c.year = selectedYear; c.month = 12; c.day = 31
        guard let d = calendar.date(from: c) else { return 365 }
        return calendar.ordinality(of: .day, in: .year, for: d) ?? 365
    }

    private func cgPoints(from pts: [ScoreHistoryPoint], totalWidth: CGFloat) -> [CGPoint] {
        guard !pts.isEmpty else { return [] }
        let w = totalWidth - yAxisW
        let zLine = zeroY
        let sc = zLine / CGFloat(max(maxAbsValue, 1))
        let totalDays = CGFloat(max(daysInYear - 1, 1))
        return pts.map { p in
            let x = yAxisW + CGFloat(p.dayOfYear - 1) / totalDays * w
            let y = zLine - CGFloat(p.score) * sc
            return CGPoint(x: x, y: y)
        }
    }

    private func smoothPath(_ points: [CGPoint]) -> Path {
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

    // MARK: - Milestone logic

    /// Следующий незакрытый именной майлстоун (score-значение).
    private func nextMilestoneScore(currentScore: Int) -> Int? {
        if currentScore >= 0 {
            // Идём вверх — ищем следующую гору
            return namedPositive
                .filter { $0.score > currentScore }
                .min(by: { $0.score < $1.score })?.score
        } else {
            // Идём вниз — ищем следующую глубину (более отрицательную)
            return namedNegative
                .filter { $0.score < currentScore }
                .max(by: { $0.score < $1.score })?.score
        }
    }

    private func nextMilestoneName(for score: Int) -> String {
        let key = score > 0
            ? namedPositive.first(where: { $0.score == score })?.nameKey
            : namedNegative.first(where: { $0.score == score })?.nameKey
        return key.map { NSLocalizedString($0, comment: "") } ?? "\(abs(score))"
    }

    /// Строит список точек майлстоунов для отображения на графике.
    /// - Если майлстоун достигнут ВНУТРИ периода графика: точка на линии в день пересечения.
    /// - Если майлстоун достигнут ДО периода: точка на левом крае графика на нужной высоте.
    private func buildMilestoneDots(
        historyPts: [ScoreHistoryPoint],
        cgPts: [CGPoint]
    ) -> [MilestoneDot] {
        guard !historyPts.isEmpty, historyPts.count == cgPts.count else { return [] }
        let currentScore = historyPts.last?.score ?? 0
        let zLine = zeroY
        let sc = zLine / CGFloat(max(maxAbsValue, 1))
        var result: [MilestoneDot] = []

        func milestoneY(for score: Int) -> CGFloat {
            zLine - CGFloat(score) * sc
        }

        // Положительные майлстоуны
        for ms in namedPositive {
            guard currentScore >= ms.score else { continue }
            let mY = milestoneY(for: ms.score)
            guard mY >= 0 && mY <= chartH else { continue }

            let name = NSLocalizedString(ms.nameKey, comment: "")
            // Достигнут до начала периода?
            if historyPts[0].score >= ms.score {
                let pt = CGPoint(x: yAxisW + 4, y: mY)
                result.append(MilestoneDot(id: ms.score, name: name, point: pt,
                                           isPositive: true, isPrePeriod: true, milestoneY: mY))
            } else if let idx = historyPts.firstIndex(where: { $0.score >= ms.score }) {
                result.append(MilestoneDot(id: ms.score, name: name, point: cgPts[idx],
                                           isPositive: true, isPrePeriod: false, milestoneY: mY))
            }
        }

        // Отрицательные майлстоуны
        for ms in namedNegative {
            guard currentScore <= ms.score else { continue }
            let mY = milestoneY(for: ms.score)
            guard mY >= 0 && mY <= chartH else { continue }

            let name = NSLocalizedString(ms.nameKey, comment: "")
            if historyPts[0].score <= ms.score {
                let pt = CGPoint(x: yAxisW + 4, y: mY)
                result.append(MilestoneDot(id: ms.score, name: name, point: pt,
                                           isPositive: false, isPrePeriod: true, milestoneY: mY))
            } else if let idx = historyPts.firstIndex(where: { $0.score <= ms.score }) {
                result.append(MilestoneDot(id: ms.score, name: name, point: cgPts[idx],
                                           isPositive: false, isPrePeriod: false, milestoneY: mY))
            }
        }

        return result
    }

    // MARK: - View

    var body: some View {
        let pts = history
        guard !pts.isEmpty else { return AnyView(EmptyView()) }
        let inner = AnyView(chartBody(pts: pts))
        if embedded { return inner }
        return AnyView(
            inner
                .padding(16)
                .background(Color.white.opacity(0.07))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private func chartBody(pts: [ScoreHistoryPoint]) -> some View {
        let currentScore = pts.last?.score ?? 0

        VStack(alignment: .leading, spacing: 0) {
            if !embedded {
                Text(NSLocalizedString("score_history_title", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.bottom, 14)
            }

            GeometryReader { geo in
                let totalW = geo.size.width
                let points = cgPoints(from: pts, totalWidth: totalW)
                let zLine = zeroY
                let dotColor = currentScore >= 0 ? positiveColor : negativeColor
                let scoreStr = currentScore >= 0 ? "+\(currentScore)" : "\(currentScore)"

                ZStack(alignment: .topLeading) {
                    // 1. Линия следующего майлстоуна (если в диапазоне)
                    nextMilestoneLine(currentScore: currentScore, totalWidth: totalW)

                    // 2. Ось X
                    Path { p in
                        p.move(to: CGPoint(x: yAxisW, y: zLine))
                        p.addLine(to: CGPoint(x: totalW, y: zLine))
                    }
                    .stroke(Color.white.opacity(hasNegativeValues ? 0.2 : 0.15),
                            style: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))

                    if points.count >= 2 {
                        // 3. Заливка
                        fillAboveZero(points: points, zLine: zLine)
                            .fill(LinearGradient(
                                colors: [positiveColor.opacity(0.3), positiveColor.opacity(0.0)],
                                startPoint: .top, endPoint: .bottom
                            ))
                        if hasNegativeValues {
                            fillBelowZero(points: points, zLine: zLine)
                                .fill(LinearGradient(
                                    colors: [negativeColor.opacity(0.0), negativeColor.opacity(0.25)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        }

                        // 4. Линия графика
                        smoothPath(points)
                            .stroke(
                                LinearGradient(
                                    colors: hasNegativeValues
                                        ? [positiveColor, negativeColor]
                                        : [positiveColor, positiveColor.opacity(0.75)],
                                    startPoint: .top, endPoint: .bottom
                                ),
                                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
                            )

                        // 5. Точки майлстоунов
                        milestoneDots(historyPts: pts, cgPts: points, totalWidth: totalW)

                        // 6. Пульсирующая точка (текущая позиция)
                        if let lastPt = points.last {
                            Circle()
                                .stroke(dotColor.opacity(0.45), lineWidth: 1.5)
                                .frame(width: 16, height: 16)
                                .scaleEffect(isPulsing ? 2.0 : 0.9)
                                .opacity(isPulsing ? 0.0 : 0.9)
                                .offset(x: lastPt.x - 8, y: lastPt.y - 8)
                                .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false),
                                           value: isPulsing)

                            Circle()
                                .fill(dotColor)
                                .frame(width: 7, height: 7)
                                .offset(x: lastPt.x - 3.5, y: lastPt.y - 3.5)

                            let labelAbove = lastPt.y > 22
                            let labelY = labelAbove ? lastPt.y - 22 : lastPt.y + 10
                            let labelX = min(lastPt.x - 10, totalW - 38)
                            Text(scoreStr)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(dotColor)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.black.opacity(0.45))
                                .cornerRadius(4)
                                .offset(x: labelX, y: labelY)
                        }
                    }

                    // 7. Y-подписи
                    yLabels()

                    // 8. Метки месяцев
                    monthLabels(totalWidth: totalW)
                }
            }
            .frame(height: chartH + labelH)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { isPulsing = true }
            }

            // 9. Легенда: следующий майлстоун
            nextMilestoneLegend(currentScore: currentScore)
                .padding(.top, 10)

            // 10. Кубки / глубины
            trophyScrollView(currentScore: currentScore)
                .padding(.top, 8)
        }
    }

    // MARK: - Next milestone line (in-range only)

    // Обычная функция (не @ViewBuilder) — guard let работает без ограничений
    private func nextMilestoneLine(currentScore: Int, totalWidth: CGFloat) -> some View {
        guard let nextScore = nextMilestoneScore(currentScore: currentScore) else {
            return AnyView(EmptyView())
        }
        let zLine = zeroY
        let sc = zLine / CGFloat(max(maxAbsValue, 1))
        let lineY = zLine - CGFloat(nextScore) * sc
        guard lineY >= 0 && lineY <= chartH else { return AnyView(EmptyView()) }

        let color = nextScore > 0 ? positiveColor : negativeColor
        let name = nextMilestoneName(for: nextScore)
        let absHeight = abs(nextScore)
        let heightSuffix = NSLocalizedString(nextScore > 0 ? "positive_days_suffix" : "negative_days_suffix", comment: "")
        let label = "\(name) · \(absHeight)\(heightSuffix)"

        return AnyView(
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: yAxisW, y: lineY))
                    p.addLine(to: CGPoint(x: totalWidth, y: lineY))
                }
                .stroke(color.opacity(0.35),
                        style: StrokeStyle(lineWidth: 0.8, dash: [4, 5]))

                // Название + высота у правого края пунктирной линии
                Text(label)
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(color.opacity(0.7))
                    .lineLimit(1)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1.5)
                    .background(Color.black.opacity(0.45))
                    .cornerRadius(3)
                    .fixedSize()
                    .offset(x: totalWidth - 84, y: lineY - 13)
            }
            .frame(width: totalWidth, height: chartH)
        )
    }

    // MARK: - Next milestone legend (below chart)

    private func nextMilestoneLegend(currentScore: Int) -> some View {
        guard let nextScore = nextMilestoneScore(currentScore: currentScore) else {
            return AnyView(EmptyView())
        }
        let isPos = nextScore > 0
        let distance = abs(nextScore - currentScore)
        let color = isPos ? positiveColor : negativeColor
        let suffix = NSLocalizedString(isPos ? "positive_days_suffix" : "negative_days_suffix", comment: "")
        let titleKey = isPos ? "next_step_title" : "next_negative_step_title"

        return AnyView(
            HStack(spacing: 4) {
                Text(NSLocalizedString(titleKey, comment: ""))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
                Text(verbatim: "\(distance)\(suffix)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
        )
    }

    // MARK: - Trophy scroll row

    private func trophyScrollView(currentScore: Int) -> some View {
        let isPositive = currentScore >= 0
        let milestones = isPositive ? namedPositive : namedNegative
        let nextTarget = milestones.first(where: {
            isPositive ? (currentScore < $0.score) : (currentScore > $0.score)
        })?.score ?? milestones.last?.score ?? 0

        return ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(milestones, id: \.score) { ms in
                        let isCompleted = isPositive
                            ? (currentScore >= ms.score)
                            : (currentScore <= ms.score)
                        PostYearMilestoneIndicator(
                            milestone: abs(ms.score),
                            isCompleted: isCompleted,
                            isPositive: isPositive
                        )
                        .frame(width: 56)
                        .id(ms.score)
                        .onTapGesture {
                            let suffix = NSLocalizedString(
                                isPositive ? "positive_days_suffix" : "negative_days_suffix",
                                comment: ""
                            )
                            let name = NSLocalizedString(ms.nameKey, comment: "")
                            let factKey = ms.nameKey
                                .replacingOccurrences(of: "ach_", with: "")
                                .replacingOccurrences(of: "_title", with: "_fact")
                            let fact = NSLocalizedString(factKey, comment: "")
                            onShowInfo?("\(name) \(abs(ms.score))\(suffix)", fact)
                            HapticManager.shared.impact(.light)
                        }
                    }
                }
            }
            .mask(
                HStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: 44)
                }
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    withAnimation(.none) { proxy.scrollTo(nextTarget, anchor: .center) }
                }
            }
        }
    }

    // MARK: - Milestone dots on chart

    @ViewBuilder
    private func milestoneDots(
        historyPts: [ScoreHistoryPoint],
        cgPts: [CGPoint],
        totalWidth: CGFloat
    ) -> some View {
        let dots = buildMilestoneDots(historyPts: historyPts, cgPts: cgPts)

        ForEach(dots) { dot in
            let color = dot.isPositive ? positiveColor : negativeColor
            let pt = dot.point
            // Тернарные операторы вместо var-мутаций (запрещены в @ViewBuilder)
            let labelX = dot.isPrePeriod
                ? pt.x + 5
                : min(max(pt.x - 26, yAxisW), totalWidth - 56)
            let labelY = dot.isPrePeriod
                ? pt.y - 8
                : (dot.isPositive ? pt.y - 16 : pt.y + 6)

            // Тёмный фон + цветная точка
            Circle()
                .fill(Color.black.opacity(0.65))
                .frame(width: 9, height: 9)
                .offset(x: pt.x - 4.5, y: pt.y - 4.5)

            Circle()
                .fill(color)
                .frame(width: 5, height: 5)
                .offset(x: pt.x - 2.5, y: pt.y - 2.5)

            // Подпись с тёмным фоном
            Text(dot.name)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(color.opacity(0.9))
                .lineLimit(1)
                .padding(.horizontal, 3)
                .padding(.vertical, 1.5)
                .background(Color.black.opacity(0.55))
                .cornerRadius(3)
                .offset(x: labelX, y: labelY)
        }
    }

    // MARK: - Fill paths

    private func fillAboveZero(points: [CGPoint], zLine: CGFloat) -> Path {
        guard points.count >= 2 else { return Path() }
        var path = Path()
        path.move(to: CGPoint(x: points[0].x, y: zLine))
        for pt in points { path.addLine(to: CGPoint(x: pt.x, y: min(pt.y, zLine))) }
        path.addLine(to: CGPoint(x: points.last!.x, y: zLine))
        path.closeSubpath()
        return path
    }

    private func fillBelowZero(points: [CGPoint], zLine: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: points[0].x, y: zLine))
        for pt in points { path.addLine(to: CGPoint(x: pt.x, y: max(pt.y, zLine))) }
        path.addLine(to: CGPoint(x: points.last!.x, y: zLine))
        path.closeSubpath()
        return path
    }

    // MARK: - Y-axis labels

    private struct YLabel: Identifiable {
        let id: Int; let text: String; let y: CGFloat
    }

    private func yLabelItems() -> [YLabel] {
        let zLine = zeroY
        if !hasNegativeValues {
            return [
                YLabel(id: maxAbsValue, text: "+\(maxAbsValue)", y: 2),
                YLabel(id: 0, text: "0", y: zLine - 12)
            ]
        }
        let sc = zLine / CGFloat(max(maxAbsValue, 1))
        let top = maxAbsValue
        return [top, 0, -top].map { val in
            let rawY = zLine - CGFloat(val) * sc
            let y: CGFloat = val > 0 ? rawY + 2 : rawY - 12
            let text = val == 0 ? "0" : (val > 0 ? "+\(val)" : "\(val)")
            return YLabel(id: val, text: text, y: y)
        }
    }

    @ViewBuilder
    private func yLabels() -> some View {
        ForEach(yLabelItems()) { item in
            Text(item.text)
                .font(.system(size: 8, weight: .regular))
                .foregroundColor(.white.opacity(0.3))
                .frame(width: yAxisW - 2, alignment: .trailing)
                .offset(x: 0, y: item.y)
        }
    }

    // MARK: - Month labels

    private struct MonthLabel: Identifiable {
        let id: Int; let text: String; let x: CGFloat
    }

    private func monthLabelItems(totalWidth: CGFloat) -> [MonthLabel] {
        let lang = LanguageManager.shared.currentLanguage
        let names: [String] = lang == .russian
            ? ["Я","Ф","М","А","М","И","И","А","С","О","Н","Д"]
            : ["J","F","M","A","M","J","J","A","S","O","N","D"]
        let chartW = totalWidth - yAxisW
        let totalDays = CGFloat(max(daysInYear - 1, 1))
        return (0..<12).compactMap { i -> MonthLabel? in
            var comps = DateComponents()
            comps.year = selectedYear; comps.month = i + 1; comps.day = 1
            guard let d = calendar.date(from: comps) else { return nil }
            let doy = calendar.ordinality(of: .day, in: .year, for: d) ?? 1
            let x = yAxisW + CGFloat(doy - 1) / totalDays * chartW
            return MonthLabel(id: i, text: names[i], x: x)
        }
    }

    @ViewBuilder
    private func monthLabels(totalWidth: CGFloat) -> some View {
        ForEach(monthLabelItems(totalWidth: totalWidth)) { item in
            Text(item.text)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 14)
                .offset(x: item.x - 7, y: chartH + 4)
        }
    }
}
