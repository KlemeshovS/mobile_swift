// SobrietyProgressPreview.swift
import SwiftUI

// MARK: - Основной прогресс-бар (самый простой вариант)
struct SobrietyProgressBar: View {
    let soberDays: Int
    let maxDays: Int = 365
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Заголовок и счетчик
            HStack {
                Text("Дней трезвости")
                    .font(.headline)
                Spacer()
                Text("\(soberDays)/\(maxDays)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Прогресс-бар
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фон
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 20)
                    
                    // Прогресс
                    RoundedRectangle(cornerRadius: 10)
                        .fill(progressColor)
                        .frame(width: CGFloat(soberDays) / CGFloat(maxDays) * geometry.size.width, height: 20)
                    
                    // Маркеры достижений
                    ForEach([7, 30, 90, 180, 365], id: \.self) { milestone in
                        if milestone <= maxDays {
                            Marker(milestone: milestone, width: geometry.size.width, isAchieved: soberDays >= milestone)
                        }
                    }
                }
            }
            .frame(height: 20)
            
            // Легенда
            HStack(spacing: 16) {
                MarkerLabel(day: 7, label: "Неделя", isAchieved: soberDays >= 7)
                MarkerLabel(day: 30, label: "Месяц", isAchieved: soberDays >= 30)
                MarkerLabel(day: 90, label: "3 мес", isAchieved: soberDays >= 90)
                MarkerLabel(day: 180, label: "Полгода", isAchieved: soberDays >= 180)
                MarkerLabel(day: 365, label: "Год", isAchieved: soberDays >= 365)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
    }
    
    private var progressColor: Color {
        let progress = Double(soberDays) / Double(maxDays)
        if progress < 0.25 {
            return .blue
        } else if progress < 0.5 {
            return .green
        } else if progress < 0.75 {
            return .orange
        } else {
            return .red
        }
    }
}

// MARK: - Компонент маркера
struct Marker: View {
    let milestone: Int
    let width: CGFloat
    let isAchieved: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            Rectangle()
                .fill(isAchieved ? Color.green : Color.gray.opacity(0.5))
                .frame(width: 1, height: 24)
                .offset(y: -12)
            
            Text("\(milestone)")
                .font(.caption2)
                .foregroundColor(isAchieved ? .green : .secondary)
        }
        .offset(x: CGFloat(milestone) / 365 * width - 0.5)
    }
}

// MARK: - Компонент легенды
struct MarkerLabel: View {
    let day: Int
    let label: String
    let isAchieved: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isAchieved ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundColor(isAchieved ? .green : .secondary)
        }
    }
}

// MARK: - Превью с контролом для тестирования
struct SobrietyProgressPreview: View {
    @State private var soberDays: Int = 45
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Прогресс трезвости")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Контрол для тестирования
                VStack(spacing: 10) {
                    Text("Тестируем: \(soberDays) дней")
                        .font(.headline)
                    
                    Slider(
                        value: Binding(
                            get: { Double(soberDays) },
                            set: { soberDays = Int($0) }
                        ),
                        in: 0...365,
                        step: 1
                    )
                    .padding(.horizontal)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Сам прогресс-бар
                SobrietyProgressBar(soberDays: soberDays)
                    .padding(.horizontal)
                
                // Примеры разных значений
                VStack(spacing: 16) {
                    Text("Примеры:")
                        .font(.headline)
                    
                    SobrietyProgressBar(soberDays: 7)
                    SobrietyProgressBar(soberDays: 30)
                    SobrietyProgressBar(soberDays: 90)
                    SobrietyProgressBar(soberDays: 180)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Preview Provider
struct SobrietyProgressPreview_Previews: PreviewProvider {
    static var previews: some View {
        SobrietyProgressPreview()
    }
}
