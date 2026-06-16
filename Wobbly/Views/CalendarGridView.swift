//
//  CalendarGridView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI

// MARK: - Calendar Grid View
struct CalendarGridView: View {
    let calendarDays: [CalendarDay]
    let month: Int
    let year: Int
    let daysData: [String: DayRecord]
    var lastUpdatedDate: Date? = nil
    let onDaySelected: (DayData) -> Void
    let onDayLongPressed: (DayData) -> Void
    
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private var localizedShortWeekdays: [String] {
        let formatter = DateFormatter()
        formatter.locale = languageManager.currentLocale   // <-- использовать актуальную локаль
        var weekdays = formatter.shortWeekdaySymbols ?? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        // Сдвиг для начала недели с воскресенья (если нужно)
        if let sunday = weekdays.first {
            weekdays.removeFirst()
            weekdays.append(sunday)
        }
        return weekdays
    }
    
    var body: some View {
        VStack(spacing: 10) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(localizedShortWeekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(height: 30)
                }
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 5) {
                ForEach(calendarDays) { calendarDay in
                    if let day = calendarDay.day {
                        DayCellView(
                            day: day,
                            month: month,
                            year: year,
                            daysData: daysData,
                            lastUpdatedDate: lastUpdatedDate,
                            onTap: { onDaySelected(DayData(day: day, month: month, year: year)) },
                            onLongPress: { onDayLongPressed(DayData(day: day, month: month, year: year)) }
                        )
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

// MARK: - Day Cell View
struct DayCellView: View {
    let day: Int
    let month: Int
    let year: Int
    let daysData: [String: DayRecord] // ИЗМЕНИЛИ: теперь DayRecord
    var lastUpdatedDate: Date? = nil
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var dayData: DayData {
        DayData(day: day, month: month, year: year)
    }

    private var isToday: Bool {
        let calendar = Calendar.current
        let current = calendar.dateComponents([.year, .month, .day], from: Date())
        return current.year == year && current.month == month + 1 && current.day == day
    }

    private var isUnknown: Bool {
        guard let updated = lastUpdatedDate else { return false }
        let calendar = Calendar.current
        var comps = DateComponents()
        comps.year = year; comps.month = month + 1; comps.day = day
        guard let cellDate = calendar.date(from: comps) else { return false }
        let startOfCell    = calendar.startOfDay(for: cellDate)
        let startOfUpdated = calendar.startOfDay(for: updated)
        let startOfToday   = calendar.startOfDay(for: Date())
        return startOfCell > startOfUpdated && startOfCell <= startOfToday
    }

    private var isFutureDate: Bool {
        let calendar = Calendar.current
        let today = Date()
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1
        dateComponents.day = day
        
        guard let checkDate = calendar.date(from: dateComponents) else {
            return false
        }
        
        return checkDate > today
    }
    
    private var dayRecord: DayRecord? {
        let dayData = DayData(day: day, month: month, year: year)
        return daysData[dayData.key]
    }
    
    // ContentView.swift - DayCellView
    @ViewBuilder
    private var cellBackground: some View {
        if isUnknown && !isToday {
            Circle().fill(Color.clear)
        } else if let record = dayRecord {
            if record.hasSport && record.drinkLevel != .none {
                let alcoholColor: Color = {
                    switch record.drinkLevel {
                    case .little: return Color(hex: "FF0072")
                    case .medium: return Color(hex: "9126EF")
                    default:      return Color(hex: "482FED")
                    }
                }()
                GeometryReader { geo in
                    let radius = min(geo.size.width, geo.size.height) / 2
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "C7FF00"),
                                    Color(hex: "C7FF00"),
                                    Color(hex: "C7FF00").opacity(0.7),
                                    alcoholColor.opacity(0.5)
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: radius
                            )
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            else if record.hasSport {
                Circle()
                    .fill(Color(hex: "C7FF00").opacity(0.3))
            }
            else if record.drinkLevel != .none {
                Circle()
                    .fill(record.drinkLevel.color)
            }
            else {
                Circle()
                    .fill(isToday ? Color.blue.opacity(0.1) : Color.clear)
            }
        } else {
            Circle()
                .fill(isToday ? Color.blue.opacity(0.1) : Color.clear)
        }
    }
    
    // Определяем иконки для отображения!
    @ViewBuilder
    private var cellContent: some View {
        // Просто показываем номер дня
        Text("\(day)")
            .font(.system(size: 18, weight: isToday ? .medium : .regular))
            .foregroundColor(
                isFutureDate ? .gray :
                (isUnknown && !isToday) ? .gray.opacity(0.5) :
                .primary
            )
    }

    var body: some View {
        ZStack {
            cellBackground
            
            cellContent
        }
  //      .scaleEffect(isToday ? 1.1 : 1.0)
        .onTapGesture {
            if !isFutureDate {
                onTap()
            }
        }
        .onLongPressGesture {
            if !isFutureDate {
                onLongPress()
            }
        }
        .allowsHitTesting(!isFutureDate)
    }
}
