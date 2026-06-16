//
//  MonthView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 13.01.2026.
//
// MonthView.swift
import SwiftUI

struct MonthView: View {
    let month: Int
    let year: Int
    let monthName: String
    let isCurrentMonth: Bool
    let daysData: [String: DayRecord]
    var lastUpdatedDate: Date? = nil
    let onDaySelected: (DayData) -> Void
    let onDayLongPressed: (DayData) -> Void
    
    private var calendarDays: [CalendarDay] {
        generateCalendarDays(for: month, year: year)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(monthName)
                    .font(.headline)
                    .foregroundColor(isCurrentMonth ? Color(hex: "4B3A91") : .primary)

            }
            .padding(.horizontal) // ГОРИЗОНТАЛЬНЫЙ PADDING К ЗАГОЛОВКУ
            .padding(.top, 24) // PADDING СВЕРХУ К ЗАГОЛОВКУ
            
            CalendarGridView(
                calendarDays: calendarDays,
                month: month,
                year: year,
                daysData: daysData,
                lastUpdatedDate: lastUpdatedDate,
                onDaySelected: onDaySelected,
                onDayLongPressed: onDayLongPressed
            )
        }
        .padding(.horizontal, 12) // ГОРИЗОНТАЛЬНЫЙ PADDING К СЕТКЕ
        .padding(.bottom, 16) //  PADDING СНИЗУ К СЕТКЕ
        
        .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal, 8)

    }
    
    private func generateCalendarDays(for month: Int, year: Int) -> [CalendarDay] {
        let firstWeekday = firstWeekdayOfMonth(month: month, year: year)
        let totalDays = CalendarUtils.daysInMonth(month: month, year: year)
        
        var calendarDays: [CalendarDay] = []
        
        for _ in 0..<firstWeekday {
            calendarDays.append(CalendarDay(day: nil, month: month, year: year, isPlaceholder: true))
        }
        
        for day in 1...totalDays {
            calendarDays.append(CalendarDay(day: day, month: month, year: year))
        }
        
        return calendarDays
    }
    
    private func firstWeekdayOfMonth(month: Int, year: Int) -> Int {
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month + 1
        dateComponents.day = 1
        
        guard let date = Calendar.current.date(from: dateComponents) else { return 0 }
        
        let weekday = Calendar.current.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
}
