import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct WobblyEntry: TimelineEntry {
    let date: Date
    let score: Int
    let soberDays: Int
    let drinkingDays: Int
    let isRussian: Bool
    let displayMode: WidgetDisplayMode
    let monthData: [String: Int]  // "1"..."31" -> уровень
    let daysInMonth: Int
    let firstWeekday: Int  // 1=Вс..7=Сб (iOS стандарт)
    let todayDay: Int

    var isDrinking: Bool { drinkingDays > 0 }
}

// MARK: - Provider

struct WobblyProvider: AppIntentTimelineProvider {
    typealias Intent = WobblyWidgetIntent

    func placeholder(in context: Context) -> WobblyEntry {
        WobblyEntry(date: Date(), score: 142, soberDays: 7, drinkingDays: 0,
                    isRussian: true, displayMode: .stats,
                    monthData: [:], daysInMonth: 31, firstWeekday: 2, todayDay: 15)
    }

    func snapshot(for configuration: WobblyWidgetIntent, in context: Context) async -> WobblyEntry {
        loadEntry(mode: configuration.displayMode)
    }

    func timeline(for configuration: WobblyWidgetIntent, in context: Context) async -> Timeline<WobblyEntry> {
        let entry = loadEntry(mode: configuration.displayMode)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func loadEntry(mode: WidgetDisplayMode) -> WobblyEntry {
        let defaults = UserDefaults(suiteName: "group.com.tritan.wobbly") ?? .standard
        let score = defaults.integer(forKey: "widget_score")
        let soberDays = defaults.integer(forKey: "widget_sober_days")
        let drinkingDays = defaults.integer(forKey: "widget_drinking_days")
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        let isRussian = preferredLanguage.hasPrefix("ru")
        let daysInMonth = defaults.integer(forKey: "widget_days_in_month")
        let firstWeekday = defaults.integer(forKey: "widget_first_weekday")
        let todayDay = defaults.integer(forKey: "widget_today_day")

        var monthData: [String: Int] = [:]
        if let data = defaults.data(forKey: "widget_month_data"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: data) {
            monthData = decoded
        }

        return WobblyEntry(date: Date(), score: score, soberDays: soberDays,
                          drinkingDays: drinkingDays, isRussian: isRussian,
                          displayMode: mode, monthData: monthData,
                          daysInMonth: daysInMonth == 0 ? 30 : daysInMonth,
                          firstWeekday: firstWeekday == 0 ? 2 : firstWeekday,
                          todayDay: todayDay)
    }
}

// MARK: - Calendar View

struct WidgetCalendarView: View {
    let entry: WobblyEntry
    let compact: Bool  // true = маленький виджет

    // Сдвиг: iOS weekday 1=Вс, нам нужно Пн=0
    private var offset: Int {
        (entry.firstWeekday + 5) % 7
    }

    private var cellSize: CGFloat { compact ? 22 : 20 }
    private var fontSize: CGFloat { compact ? 9.5 : 9 }

    var body: some View {
            VStack(spacing: 2) {
                // Заголовок месяца
                Text(monthName)
                    .font(.system(size: compact ? 12 : 13, weight: .semibold))
                    .foregroundColor(compact ? Color(red: 0.29, green: 0.23, blue: 0.57) : .white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Дни недели
                HStack(spacing: 0) {
                    ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { d in
                        Text(d)
                            .font(.system(size: fontSize - 1))
                            .foregroundColor(compact ? Color.gray.opacity(0.6) : .white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Сетка дней
                ForEach(0..<6, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<7, id: \.self) { col in
                            let index = row * 7 + col
                            let day = index - offset + 1
                            if day < 1 || day > entry.daysInMonth {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: cellSize)
                            } else {
                                WidgetDayCell(
                                    day: day,
                                    level: entry.monthData["\(day)"],
                                    isToday: day == entry.todayDay,
                                    isFuture: day > entry.todayDay,
                                    fontSize: fontSize,
                                    size: cellSize,
                                    darkText: compact
                                )
                            }
                        }
                    }
                }
            }
    }
    
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: entry.isRussian ? "ru" : "en")
        let now = Date()
        return formatter.standaloneMonthSymbols?[Calendar.current.component(.month, from: now) - 1].capitalized ?? ""
    }
}

struct WidgetDayCell: View {
    let day: Int
    let level: Int?
    let isToday: Bool
    let isFuture: Bool
    let fontSize: CGFloat
    let size: CGFloat
    var darkText: Bool = false

    private var cellColor: Color {
        guard let lvl = level, !isFuture else { return .clear }
        switch lvl {
        case 1, 5: return Color(red: 1, green: 0, blue: 0.45).opacity(0.5)
        case 2, 6: return Color(red: 0.57, green: 0.15, blue: 0.94).opacity(0.6)
        case 3, 7: return Color(red: 0.28, green: 0.18, blue: 0.93).opacity(0.7)
        case 4: return Color(red: 0.78, green: 1, blue: 0).opacity(0.4)
        default: return .clear
        }
    }

    private var hasSport: Bool {
        guard let lvl = level else { return false }
        return [4, 5, 6, 7].contains(lvl)
    }

    private var hasAlcohol: Bool {
        guard let lvl = level else { return false }
        return [1, 2, 3, 5, 6, 7].contains(lvl)
    }

    var body: some View {
        ZStack {
            if hasSport && hasAlcohol {
                Circle()
                    .fill(Color(red: 0.78, green: 1, blue: 0).opacity(0.4))
                Circle()
                    .stroke(alcoholBorderColor, lineWidth: 1)
            } else {
                Circle().fill(cellColor)
            }

            if isToday {
                Circle().stroke(Color(red: 0.55, green: 0.36, blue: 0.96), lineWidth: 1)
            }

            Text("\(day)")
                .font(.system(size: fontSize))
                .foregroundColor(
                    isFuture ? (darkText ? Color.gray.opacity(0.3) : .white.opacity(0.2)) :
                    (darkText ? Color.primary : .white.opacity(0.9))
                )
        }
        .frame(maxWidth: .infinity)
        .frame(height: size)
    }

    private var alcoholBorderColor: Color {
        guard let lvl = level else { return .clear }
        switch lvl {
        case 1, 5: return Color(red: 1, green: 0, blue: 0.45)
        case 2, 6: return Color(red: 0.92, green: 0.02, blue: 0.02)
        case 3, 7: return Color(red: 0.61, green: 0.15, blue: 0.69)
        default: return .clear
        }
    }
}

// MARK: - Small Stats View

struct WobblyWidgetSmallView: View {
    let entry: WobblyEntry

    private var daysLabel: String {
        let n = entry.isDrinking ? entry.drinkingDays : entry.soberDays
        if entry.isRussian {
            if n % 10 == 1 && n % 100 != 11 { return "день" }
            if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "дня" }
            return "дней"
        } else {
            return n == 1 ? "day" : "days"
        }
    }

    private var streakTitle: String {
        entry.isRussian ? (entry.isDrinking ? "Пью уже" : "Уже не пью")
                        : (entry.isDrinking ? "Drinking" : "Sober")
    }

    private var altitudeTitle: String {
        entry.isRussian ? (entry.score >= 0 ? "Высота" : "Глубина")
                        : (entry.score >= 0 ? "Altitude" : "Depth")
    }

    private var altitudeSuffix: String {
        entry.isRussian ? (entry.score >= 0 ? "м н.у.м." : "м под водой")
                        : (entry.score >= 0 ? "m a.s.l." : "m underwater")
    }

    private var daysCount: Int { entry.isDrinking ? entry.drinkingDays : entry.soberDays }
    private var accentColor: Color { entry.isDrinking ? .pink : .mint }
    private var scoreColor: Color { entry.score >= 0 ? .mint : .pink }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 2) {
                Text(streakTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(1.0))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(daysCount)")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundColor(accentColor)
                    Text(daysLabel)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(1.0))
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(altitudeTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(1.0))
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Image(systemName: entry.score >= 0 ? "mountain.2.fill" : "water.waves")
                        .font(.system(size: 12))
                        .foregroundColor(scoreColor)
                    Text("\(abs(entry.score)) \(altitudeSuffix)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(scoreColor)
                        .minimumScaleFactor(0.6)
                        .lineLimit(2)
                }
            }

            Spacer()
        }
        .padding(.vertical, 20)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Small Calendar View

struct WobblyWidgetSmallCalendarView: View {
    let entry: WobblyEntry

    var body: some View {
        WidgetCalendarView(entry: entry, compact: true)
            .padding(.top, 20)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Medium View

struct WobblyWidgetMediumView: View {
    let entry: WobblyEntry

    private var daysLabel: String {
        let n = entry.isDrinking ? entry.drinkingDays : entry.soberDays
        if entry.isRussian {
            if n % 10 == 1 && n % 100 != 11 { return "день" }
            if (2...4).contains(n % 10) && !(12...14).contains(n % 100) { return "дня" }
            return "дней"
        } else { return n == 1 ? "day" : "days" }
    }

    private var streakTitle: String {
        entry.isRussian ? (entry.isDrinking ? "Пью уже" : "Уже не пью")
                        : (entry.isDrinking ? "Drinking" : "Sober")
    }

    private var altitudeTitle: String {
        entry.isRussian ? (entry.score >= 0 ? "Высота" : "Глубина")
                        : (entry.score >= 0 ? "Altitude" : "Depth")
    }

    private var altitudeSuffix: String {
        entry.isRussian ? (entry.score >= 0 ? "м н.у.м." : "м под водой")
                        : (entry.score >= 0 ? "m a.s.l." : "m underwater")
    }

    private var daysCount: Int { entry.isDrinking ? entry.drinkingDays : entry.soberDays }
    private var accentColor: Color { entry.isDrinking ? .pink : .mint }
    private var scoreColor: Color { entry.score >= 0 ? .mint : .pink }

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                // Стрик
                VStack(alignment: .leading, spacing: 4) {
                    Text(streakTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(1.0))
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(daysCount)")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(accentColor)
                        Text(daysLabel)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(1.0))
                    }
                }

                // Высота/Глубина
                VStack(alignment: .leading, spacing: 4) {
                    Text(altitudeTitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(1.0))
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Image(systemName: entry.score >= 0 ? "mountain.2.fill" : "water.waves")
                            .font(.system(size: 12))
                            .foregroundColor(scoreColor)
                        Text("\(abs(entry.score)) \(altitudeSuffix)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(scoreColor)
                            .minimumScaleFactor(0.6)
                            .lineLimit(2)
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Rectangle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 1)
                .padding(.vertical, 8)

            WidgetCalendarView(entry: entry, compact: false)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 10)
        }
        .padding(.top, 14)
        .padding(.bottom, 8)
        .padding(.leading, 8)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Entry View

struct WobblyWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WobblyEntry

    var body: some View {
        switch family {
        case .systemSmall:
            if entry.displayMode == .calendar {
                WobblyWidgetSmallCalendarView(entry: entry)
            } else {
                WobblyWidgetSmallView(entry: entry)
            }
        case .systemMedium:
            WobblyWidgetMediumView(entry: entry)
        default:
            WobblyWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Widget

struct WobblyWidget: Widget {
    let kind = "WobblyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: WobblyWidgetIntent.self, provider: WobblyProvider()) { entry in
            WobblyWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    if entry.displayMode == .calendar {
                        Color(.systemBackground)
                    } else {
                        LinearGradient(
                            colors: [Color(red: 0, green: 0, blue: 0),   // верх
                                     Color(red: 0.4, green: 0.33, blue: 0.70)],   // низ — фиолетовый светлее
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
        }
        .configurationDisplayName("Wobbly")
        .description("Трезвые дни, высота и календарь")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    WobblyWidget()
} timeline: {
    WobblyEntry(date: .now, score: 142, soberDays: 7, drinkingDays: 0,
                isRussian: true, displayMode: .stats,
                monthData: ["1": 1, "2": 4, "3": 0, "5": 2, "10": 5],
                daysInMonth: 31, firstWeekday: 5, todayDay: 15)
}

#Preview(as: .systemMedium) {
    WobblyWidget()
} timeline: {
    WobblyEntry(date: .now, score: 142, soberDays: 7, drinkingDays: 0,
                isRussian: true, displayMode: .stats,
                monthData: ["1": 1, "2": 4, "3": 0, "5": 2, "10": 5],
                daysInMonth: 31, firstWeekday: 5, todayDay: 15)
}
