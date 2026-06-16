import SwiftUI

struct YearSectionView: View {
    let year: Int
    let months: [String]
    let daysData: [String: DayRecord]
    let calendarViewMode: Int
    let onDaySelected: (DayData) -> Void
    let onDayLongPressed: (DayData) -> Void

    private var currentYear: Int {
        Calendar.current.component(.year, from: Date())
    }

    private var currentMonth: Int {
        Calendar.current.component(.month, from: Date()) - 1
    }

    var body: some View {
        VStack(spacing: 15) {
            Text(String(format: String(localized: "year_label"), year))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.top, 4)
                .id("\(year)-header")

            if calendarViewMode == 1 {
                // Один месяц на всю ширину
                ForEach(0..<12, id: \.self) { month in
                    MonthView(
                        month: month,
                        year: year,
                        monthName: months[month],
                        isCurrentMonth: isCurrentMonth(month: month, year: year),
                        daysData: daysData,
                        onDaySelected: onDaySelected,
                        onDayLongPressed: onDayLongPressed
                    )
                    .id("\(year)-\(month)")
                }
            } else {
                // Два или три месяца в строку
                let columns = calendarViewMode == 2 ? 2 : 3
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: columns),
                    spacing: 8
                ) {
                    ForEach(0..<12, id: \.self) { month in
                        CompactMonthView(
                            month: month,
                            year: year,
                            monthName: months[month],
                            isCurrentMonth: isCurrentMonth(month: month, year: year),
                            daysData: daysData,
                            columns: columns,
                            onDaySelected: onDaySelected,
                            onDayLongPressed: onDayLongPressed
                        )
                        .id("\(year)-\(month)")
                    }
                }
            }
        }
    }

    private func isCurrentMonth(month: Int, year: Int) -> Bool {
        let current = Calendar.current.dateComponents([.year, .month], from: Date())
        return current.year == year && current.month == month + 1
    }
}

// MARK: - Компактный месяц для режимов 2 и 3

private struct CompactMonthView: View {
    let month: Int
    let year: Int
    let monthName: String
    let isCurrentMonth: Bool
    let daysData: [String: DayRecord]
    let columns: Int
    let onDaySelected: (DayData) -> Void
    let onDayLongPressed: (DayData) -> Void

    private var totalDays: Int {
        CalendarUtils.daysInMonth(month: month, year: year)
    }

    private var firstWeekday: Int {
        var comps = DateComponents()
        comps.year = year; comps.month = month + 1; comps.day = 1
        guard let date = Calendar.current.date(from: comps) else { return 0 }
        let wd = Calendar.current.component(.weekday, from: date)
        return (wd + 5) % 7
    }

    private var fontSize: CGFloat { columns == 2 ? 9 : 7 }
    private var headerFontSize: CGFloat { columns == 2 ? 11 : 9 }

    var body: some View {
        VStack(spacing: 2) {
            Text(monthName)
                .font(.system(size: headerFontSize, weight: .semibold))
                .foregroundColor(isCurrentMonth ? Color(hex: "4B3A91") : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 6)

            // Дни недели
            HStack(spacing: 0) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: fontSize - 1))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

            // Строки дней
            ForEach(0..<6, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col
                        let day = index - firstWeekday + 1
                        if day < 1 || day > totalDays {
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        } else {
                            CompactDayCell(
                                day: day,
                                month: month,
                                year: year,
                                daysData: daysData,
                                fontSize: fontSize,
                                onTap: { onDaySelected(DayData(day: day, month: month, year: year)) },
                                onLongPress: { onDayLongPressed(DayData(day: day, month: month, year: year)) }
                            )
                        }
                    }
                }
            }

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
        )
    }
}

// MARK: - Компактная ячейка дня

private struct CompactDayCell: View {
    let day: Int
    let month: Int
    let year: Int
    let daysData: [String: DayRecord]
    let fontSize: CGFloat
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var dayData: DayData { DayData(day: day, month: month, year: year) }
    private var record: DayRecord? { daysData[dayData.key] }

    private var isToday: Bool {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return c.year == year && c.month == month + 1 && c.day == day
    }

    private var isFuture: Bool {
        var comps = DateComponents()
        comps.year = year; comps.month = month + 1; comps.day = day
        guard let date = Calendar.current.date(from: comps) else { return false }
        return date > Calendar.current.startOfDay(for: Date())
    }

    private var cellColor: Color {
        if isFuture { return .clear }
        guard let rec = record else {
            return isToday ? Color.blue.opacity(0.1) : .clear
        }
        if rec.hasSport && rec.drinkLevel == .none {
            return Color(hex: "C7FF00").opacity(0.3)
        } else if rec.drinkLevel != .none {
            return rec.drinkLevel.color
        }
        return isToday ? Color.blue.opacity(0.1) : .clear
    }

    var body: some View {
        ZStack {
            // Фон
            if let rec = record, !isFuture, rec.drinkLevel != .none && rec.hasSport {
                let alcoholColor: Color = {
                    switch rec.drinkLevel {
                    case .little: return Color(hex: "FF0072")
                    case .medium: return Color(hex: "9126EF")
                    default:      return Color(hex: "482FED")
                    }
                }()
                GeometryReader { geo in
                    let radius = min(geo.size.width, geo.size.height) / 2
                    let gradientColors: [Color] = fontSize <= 7 ? [
                        Color(hex: "C7FF00"),
                        Color(hex: "C7FF00").opacity(0.7),
                        Color(hex: "C7FF00").opacity(0.3),
                        alcoholColor.opacity(0.75)
                    ] : [
                        Color(hex: "C7FF00"),
                        Color(hex: "C7FF00"),
                        Color(hex: "C7FF00").opacity(0.7),
                        alcoholColor.opacity(0.5)
                    ]
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: gradientColors),
                                center: .center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            } else {
                Circle().fill(cellColor)
            }

            Text("\(day)")
                .font(.system(size: fontSize))
                .foregroundColor(isFuture ? .gray.opacity(0.4) : .primary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture { if !isFuture { onTap() } }
        .onLongPressGesture { if !isFuture { onLongPress() } }
    }
}
