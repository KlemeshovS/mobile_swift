//
//  YearSectionView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 13.01.2026.
//
// YearSectionView.swift
import SwiftUI

struct YearSectionView: View {
    let year: Int
    let months: [String]
    let daysData: [String: DayRecord]
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
                .padding(.top, 20)
            
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
        }
    }
    
    private func isCurrentMonth(month: Int, year: Int) -> Bool {
        let current = Calendar.current.dateComponents([.year, .month], from: Date())
        return current.year == year && current.month == month + 1
    }
}
