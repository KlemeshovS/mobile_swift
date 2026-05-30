import SwiftUI

// MARK: - Конвертация Int → DayRecord
private extension Int {
    var toDayRecord: DayRecord {
        switch self {
        case 0: return DayRecord(drinkLevel: .none, hasSport: false)
        case 1: return DayRecord(drinkLevel: .little, hasSport: false)
        case 2: return DayRecord(drinkLevel: .medium, hasSport: false)
        case 3: return DayRecord(drinkLevel: .heavy, hasSport: false)
        case 4: return DayRecord(drinkLevel: .none, hasSport: true)
        case 5: return DayRecord(drinkLevel: .little, hasSport: true)
        case 6: return DayRecord(drinkLevel: .medium, hasSport: true)
        case 7: return DayRecord(drinkLevel: .heavy, hasSport: true)
        default: return DayRecord(drinkLevel: .none, hasSport: false)
        }
    }
}

// MARK: - Главный виджет

struct FriendCalendarGridView: View {
    let calendarData: [String: Int]
    let updatedAt: String

    @State private var isExpanded = false
    @State private var scale: CGFloat = 1.0
    @State private var targetMonth: String = ""
    
    @ObservedObject private var languageManager = LanguageManager.shared

    private var dayRecords: [String: DayRecord] {
        calendarData.mapValues { $0.toDayRecord }
    }

    private var lastUpdatedDate: Date? {
        let iso = ISO8601DateFormatter()
        if let date = iso.date(from: updatedAt) { return date }
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: updatedAt) { return date }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSZ"
        return formatter.date(from: updatedAt)
    }

    private var last4Months: [(year: Int, month: Int)] {
        let now = Date()
        let calendar = Calendar.current
        return (0..<4).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let comps = calendar.dateComponents([.year, .month], from: date)
            return (comps.year!, comps.month! - 1) // 0-based
        }
    }

    private var last12Months: [(year: Int, month: Int)] {
        let now = Date()
        let calendar = Calendar.current
        return (0..<12).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .month, value: -offset, to: now) else { return nil }
            let comps = calendar.dateComponents([.year, .month], from: date)
            return (comps.year!, comps.month! - 1) // 0-based
        }
    }

    private var allMonths: [(year: Int, month: Int)] {
        var months = Set<String>()
        var result: [(year: Int, month: Int)] = []

        for key in calendarData.keys {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3,
                  let year = Int(parts[0]),
                  let month = Int(parts[1]),
                  month >= 0 && month <= 11 else { continue }  // ← фильтр невалидных
            let id = "\(year)-\(month)"
            if !months.contains(id) {
                months.insert(id)
                result.append((year: year, month: month))
            }
        }

        for ym in last12Months {
            let id = "\(ym.year)-\(ym.month)"
            if !months.contains(id) {
                months.insert(id)
                result.append(ym)
            }
        }

        return result.sorted {
            $0.year != $1.year ? $0.year < $1.year : $0.month < $1.month
        }
    }
    
    private var dayRecordsForMainCalendar: [String: DayRecord] {
        dayRecords // ключи уже в правильном 0-based формате
    }

    private func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale
        let names = formatter.standaloneMonthSymbols ?? []
        guard month >= 0 && month < names.count else { return "" }
        return names[month].capitalized
    }

    private func isCurrentMonth(_ ym: (year: Int, month: Int)) -> Bool {
        let c = Calendar.current.dateComponents([.year, .month], from: Date())
        return c.year == ym.year && c.month == ym.month + 1
    }

    var body: some View {
        ZStack {
            // Компактный вид
            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible())],
                spacing: 12
            ) {
                ForEach(Array(last4Months.enumerated()), id: \.offset) { _, ym in
                    FriendMonthView(
                        month: ym.month,
                        year: ym.year,
                        dayRecords: dayRecords,
                        lastUpdatedDate: lastUpdatedDate
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        targetMonth = "\(ym.year)-\(ym.month)"
                        expand()
                    }
                }
            }
            .scaleEffect(isExpanded ? 0.85 : scale)
            .opacity(isExpanded ? 0 : 1)

            // Увеличенный вид
            if isExpanded {
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(allMonths, id: \.month) { ym in
                                ZStack {
                                    MonthView(
                                        month: ym.month,
                                        year: ym.year,
                                        monthName: monthName(for: ym.month),
                                        isCurrentMonth: isCurrentMonth(ym),
                                        daysData: dayRecordsForMainCalendar,
                                        onDaySelected: { _ in },
                                        onDayLongPressed: { _ in }
                                    )
                                    
                                    // Прозрачный оверлей поверх всего — перехватывает все тапы
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .onTapGesture { collapse() }
                                }
                                .id("\(ym.year)-\(ym.month)")
                            }

                            Text(NSLocalizedString("friend_calendar_tap_to_collapse", comment: ""))
                                .font(.system(size: 11))
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.bottom, 8)
                        }
                    }
                    .frame(maxHeight: 520)
                    .onAppear {
                        // Диагностика
                        print("📅 === ДИАГНОСТИКА КАЛЕНДАРЯ ===")
                        print("📅 updatedAt: \(updatedAt)")
                        print("📅 Всего записей: \(calendarData.count)")
                        
                        let sortedKeys = calendarData.keys.sorted()
                        print("📅 Все ключи: \(sortedKeys)")
                        
                        var byMonth: [String: [(String, Int)]] = [:]
                        for (key, value) in calendarData {
                            let parts = key.split(separator: "-").map { String($0) }
                            guard parts.count == 3 else { continue }
                            let monthKey = "\(parts[0])-\(parts[1])"
                            byMonth[monthKey, default: []].append((key, value))
                        }
                        for monthKey in byMonth.keys.sorted() {
                            print("📅 Месяц \(monthKey): \(byMonth[monthKey]!.sorted { $0.0 < $1.0 })")
                        }
                        
                        let now = Calendar.current.dateComponents([.year, .month], from: Date())
                        let currentId = "\(now.year!)-\(now.month! - 1)"
                        let currentYear = now.year!
                        let currentMonth = now.month!
                        print("📅 Текущий месяц (1-based): \(currentMonth), год: \(currentYear)")
                        print("📅 SmallDayCell ищет ключи вида: \(currentYear)-\(currentMonth)-1 ...")
                        print("📅 FriendMonthView получает month=\(currentMonth - 1) (0-based)")
                        let mayKeys = calendarData.keys.filter { $0.hasPrefix("\(currentYear)-\(currentMonth)-") }
                        print("📅 Ключи мая в calendarData: \(mayKeys.sorted())")
                        
                        // Скролл к нужному месяцу
                        let scrollTo = targetMonth.isEmpty ? currentId : targetMonth
                        proxy.scrollTo(scrollTo, anchor: .top)
                    }
                }
                .scaleEffect(isExpanded ? 1.0 : 1.15)
                .opacity(isExpanded ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: scale)
    }

    private func expand() {
        HapticManager.shared.impact(.light)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isExpanded = true
        }
    }

    private func collapse() {
        HapticManager.shared.impact(.light)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            isExpanded = false
        }
    }
}

// MARK: - Один месяц (компактный)

private struct FriendMonthView: View {
    let month: Int   // 0-based
    let year: Int
    let dayRecords: [String: DayRecord]
    let lastUpdatedDate: Date?

    @ObservedObject private var languageManager = LanguageManager.shared

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale
        let names = formatter.standaloneMonthSymbols ?? []
        guard month >= 0 && month < names.count else { return "" }
        return names[month].capitalized
    }

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

    var body: some View {
        VStack(spacing: 3) {
            Text(monthName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: "4B3A91"))
                .padding(.top, 8)

            HStack(spacing: 0) {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 7))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }

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
                            SmallDayCell(
                                day: day,
                                month: month,
                                year: year,
                                dayRecords: dayRecords,
                                lastUpdatedDate: lastUpdatedDate
                            )
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Маленькая ячейка дня

private struct SmallDayCell: View {
    let day: Int
    let month: Int   // 0-based
    let year: Int
    let dayRecords: [String: DayRecord]
    let lastUpdatedDate: Date?

    private var thisDate: Date? {
        var comps = DateComponents()
        comps.year = year; comps.month = month + 1; comps.day = day
        return Calendar.current.date(from: comps)
    }

    private var isUnknown: Bool {
        guard let updated = lastUpdatedDate,
              let cellDate = thisDate else { return false }
        let startOfCell = Calendar.current.startOfDay(for: cellDate)
        let startOfUpdated = Calendar.current.startOfDay(for: updated)
        let startOfToday = Calendar.current.startOfDay(for: Date())
        return startOfCell > startOfUpdated && startOfCell <= startOfToday
    }

    private var key: String { "\(year)-\(month)-\(day)" }
    private var record: DayRecord? { dayRecords[key] }

    private var isToday: Bool {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        return c.year == year && c.month == month + 1 && c.day == day
    }

    private var isFuture: Bool {
        guard let date = thisDate else { return false }
        return date > Calendar.current.startOfDay(for: Date())
    }

    var body: some View {
        ZStack {
            if let rec = record, !isFuture, !isUnknown, rec.drinkLevel != .none, rec.hasSport {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "C7FF00"),          // центр зелёный
                                Color(hex: "C7FF00").opacity(0.7),
                                Color(hex: "C7FF00").opacity(0.3), // переход
                                rec.drinkLevel == .little ? Color(hex: "FF0072").opacity(0.4) :
                                rec.drinkLevel == .medium ? Color(hex: "9126EF").opacity(0.4) :
                                Color(hex: "482FED").opacity(0.4)  // края — алкоголь приглушённо
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 14
                        )
                    )
            } else {
                Circle().fill(cellColor)
            }

            if isToday {
                Circle().stroke(Color(hex: "4B3A91"), lineWidth: 1)
            }

            Text("\(day)")
                .font(.system(size: 9))
                .foregroundColor(
                    isFuture ? .gray.opacity(0.4) :
                    isUnknown ? .gray.opacity(0.5) :
                    .black
                )
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .allowsHitTesting(false) // тап проходит насквозь к родителю
    }

    private var cellColor: Color {
        if isFuture { return Color.clear }
        if isUnknown { return Color.clear }
        guard let rec = record else { return Color.clear }
        if rec.hasSport && rec.drinkLevel == .none {
            return Color(hex: "C7FF00").opacity(0.4)
        } else if rec.drinkLevel != .none {
            return rec.drinkLevel.color
        }
        return Color.clear
    }
}
