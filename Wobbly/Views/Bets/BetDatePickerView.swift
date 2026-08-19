//
//  BetDatePickerView.swift
//  Wobbly
//
//  Кастомный календарь для выбора даты окончания пари. Нужен вместо системного
//  DatePicker(.graphical), потому что тот не умеет "ничего не выбрано" — всегда
//  подсвечивает привязанную дату фиолетовым кружком. Здесь фиолетовый кружок
//  появляется только после реального тапа пользователя, а "сегодня" всегда
//  помечено тонким кольцом.
//

import SwiftUI

struct BetDatePickerView: View {
    @Binding var selectedDate: Date?
    let minimumDate: Date

    @State private var displayedMonth: Date

    init(selectedDate: Binding<Date?>, minimumDate: Date) {
        self._selectedDate = selectedDate
        self.minimumDate = minimumDate
        self._displayedMonth = State(initialValue: selectedDate.wrappedValue ?? minimumDate)
    }

    private var calendar: Calendar {
        var cal = Calendar.current
        cal.locale = LanguageManager.shared.currentLocale
        return cal
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        formatter.setLocalizedDateFormatFromTemplate("LLLL yyyy")
        return formatter.string(from: displayedMonth).capitalized
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = LanguageManager.shared.currentLocale
        var symbols = formatter.shortWeekdaySymbols ?? ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        if let first = symbols.first {
            symbols.removeFirst()
            symbols.append(first)
        }
        return symbols
    }

    /// Сетка дней текущего отображаемого месяца, с ведущими `nil`-заглушками
    /// для выравнивания первого дня по правильному дню недели.
    private var daysGrid: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth) else { return [] }

        var leadingBlanks = calendar.component(.weekday, from: monthInterval.start) - calendar.firstWeekday
        if leadingBlanks < 0 { leadingBlanks += 7 }

        var days: [Date?] = Array(repeating: nil, count: leadingBlanks)
        var current = monthInterval.start
        while current < monthInterval.end {
            days.append(current)
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return days
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                monthNavButton(systemName: "chevron.left") { changeMonth(by: -1) }
                Spacer()
                Text(monthTitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                monthNavButton(systemName: "chevron.right") { changeMonth(by: 1) }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol.uppercased())
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                ForEach(Array(daysGrid.enumerated()), id: \.offset) { _, date in
                    if let date = date {
                        dayCell(date)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func monthNavButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 28, height: 28)
        }
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }

    @ViewBuilder
    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let isDisabled = date < calendar.startOfDay(for: minimumDate)

        Button {
            selectedDate = date
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: isSelected ? .bold : .regular))
                .foregroundColor(
                    isDisabled ? .white.opacity(0.2) : (isSelected ? .white : .white.opacity(0.85))
                )
                .frame(width: 36, height: 36)
                .background(Circle().fill(isSelected ? Color(hex: "8B5CF6") : Color.clear))
                .overlay(
                    Circle().stroke(
                        (isToday && !isSelected) ? Color(hex: "8B5CF6").opacity(0.7) : Color.clear,
                        lineWidth: 1.5
                    )
                )
        }
        .disabled(isDisabled)
    }
}
