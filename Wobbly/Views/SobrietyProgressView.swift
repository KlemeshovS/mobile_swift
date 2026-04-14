//
//  SobrietyProgressView.swift
//  Wobbly
//
//  Created by [Ваше имя] on [Дата].
//

import SwiftUI

struct SobrietyProgressView: View {
    let progressDays: Int
    let maxDays: Int = 444
    private let maxNegativeDays = 500  // порог для переключения на большой счётчик
    
    @State private var animatedProgress: Double = 0
    @State private var glowAnimation: Bool = false
    
    // Массив вех для положительных значений
    private let milestones = [
        (days: 50, titleKey: "milestone_50_label"),
        (days: 100, titleKey: "milestone_100_label"),
        (days: 146, titleKey: "milestone_146_label"),
        (days: 319, titleKey: "milestone_319_label"),
        (days: 443, titleKey: "milestone_443_label")
    ]
    
    // Массив вех после года
    private let postYearMilestones = [1234, 4810, 5642, 7010, 8848]
    
    // Массив вех для отрицательных значений (задаем положительные числа, отображаем без минуса)
    private let negativeMilestones = [50, 100, 202, 300, 500]
    
    // Массив больших отрицательных рубежей (после 500)
    private let postNegativeMilestones = [1642, 3800, 6066, 10047, 11022]
    
    // Определяем следующий рубеж после года
    private func nextPostYearMilestone() -> Int? {
        return postYearMilestones.first { $0 > progressDays }
    }
    
    // Определяем следующий рубеж для отрицательных значений
    private func nextNegativeMilestone() -> Int? {
        let absoluteValue = abs(progressDays)
        // Сначала ищем в обычных (до 500)
        if let next = negativeMilestones.first(where: { $0 > absoluteValue }) {
            return next
        }
        // Затем в больших
        return postNegativeMilestones.first(where: { $0 > absoluteValue })
    }
    
    // Выбор заголовка в зависимости от значения прогресса
    private var titleKey: String {
        if progressDays < 0 {
            return "your_negative_progress_title"
        } else {
            return "your_progress_title"
        }
    }
    
    // Выбор ключа для "Следующий рубеж"
    private var nextStepTitleKey: String {
        if progressDays < 0 {
            return "next_negative_step_title"
        } else {
            return "next_step_title"
        }
    }
    
    // Форматирование значения для отображения
    private var formattedValue: String {
        if progressDays < 0 {
            return "\(abs(progressDays))" + NSLocalizedString("negative_days_suffix", comment: "")
        } else if progressDays <= maxDays {
            return "\(progressDays)" + NSLocalizedString("positive_days_suffix", comment: "")
        } else {
            return "\(progressDays)" + NSLocalizedString("positive_days_suffix", comment: "")
        }
    }
    
    // Юмористические мотивационные сообщения (оставлено без изменений)
    private var motivationMessage: String {
        switch progressDays {
        case 0:
            return "Первый шаг - самый трудный! Давай начнем эту эпопею! 🚶‍♂️"
        case 1..<7:
            return "Один день уже позади! Алкоголь в панике! 😄"
        case 7..<14:
            return "Неделя! Тело начало благодарить тебя! 🎉"
        case 14..<30:
            return "Две недели! Печень уже отправила тебе благодарственное письмо! ✉️"
        case 30..<60:
            return "Месяц! Можно начинать собирать мили для клуба супергероев! 🦸‍♂️"
        case 60..<90:
            return "Два месяца! Ты уже на 66% круче среднестатистического человека! 📈"
        case 90..<120:
            return "90 дней! Ты пережил сезон 'Игры Престолов' без алкоголя! 👑"
        case 120..<180:
            return "4 месяца! Твоя печень танцует от счастья! 💃"
        case 180..<270:
            return "Полгода! Ты уже мог бы вырастить небольшой кактус! 🌵"
        case 270..<365:
            return "9 месяцев! Ты созрел для звания 'Мастер Трезвости'! 🥋"
        case 365...:
            return "ГОД! Ты только что завершил марафон трезвости! Медаль в пути! 🏅"
        default:
            return "Каждый трезвый день - это маленькая победа! 💪"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Заголовок
            HStack {
                Text(NSLocalizedString(titleKey, comment: ""))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Счётчик
                if progressDays <= maxDays && progressDays >= -maxNegativeDays {
                    Text(formattedValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(progressDays < 0 ? .red.opacity(0.9) : .white.opacity(0.9))
                }
            }
            
            // Отображение в зависимости от количества дней
            if progressDays < 0 {
                if abs(progressDays) > maxNegativeDays {
                    // БОЛЬШОЙ ОТРИЦАТЕЛЬНЫЙ ПРОГРЕСС
                    largeNegativeView
                } else {
                    // ОБЫЧНЫЙ ОТРИЦАТЕЛЬНЫЙ ПРОГРЕСС (шкала)
                    normalNegativeView
                }
            } else if progressDays < maxDays {
                // ПОЛОЖИТЕЛЬНЫЙ ПРОГРЕСС ДО ГОДА
                normalPositiveView
            } else {
                // ПРОГРЕСС ПОСЛЕ ГОДА (>365)
                largePositiveView
            }
            
            // Мотивационное сообщение (закомментировано, оставлено как было)
            // if progressDays > 0 {
            //     Text(motivationMessage)
            //         .font(.system(size: 13))
            //         .foregroundColor(.white.opacity(0.9))
            //         .multilineTextAlignment(.center)
            //         .padding(.vertical, 8)
            //         .padding(.horizontal, 12)
            //         .frame(maxWidth: .infinity)
            //         .background(
            //             RoundedRectangle(cornerRadius: 10)
            //                 .fill(Color.white.opacity(0.08))
            //                 .overlay(
            //                     RoundedRectangle(cornerRadius: 10)
            //                         .stroke(Color.white.opacity(0.15), lineWidth: 1)
            //                 )
            //         )
            // }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            updateAnimation()
        }
        .onChange(of: progressDays) { _ in
            updateAnimation()
        }
    }
    
    // MARK: - Вспомогательные View
    
    @ViewBuilder
    private var normalNegativeView: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая полоса для отрицательного прогресса
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 16)
                    
                    // Отрицательный прогресс - справа налево
                    HStack(spacing: 0) {
                        Spacer(minLength: 0)
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.darkRed, .red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: min(CGFloat(animatedProgress), 1.0) * geometry.size.width,
                                height: 16
                            )
                            .shadow(color: .red.opacity(0.3), radius: 2, x: 0, y: 0)
                            .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                    }
                }
            }
            .frame(height: 16)
            
            // Индикатор следующей вехи (до следующего отрицательного рубежа)
            if let nextMilestone = nextNegativeMilestone() {
                let daysToNext = nextMilestone - abs(progressDays)
                HStack(spacing: 4) {
                    Text(NSLocalizedString(nextStepTitleKey, comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(daysToNext)" + NSLocalizedString("days", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
            }
        }
        
        // Вехи для отрицательного прогресса
        HStack(spacing: 0) {
            ForEach(negativeMilestones, id: \.self) { milestone in
                NegativeMilestoneIndicator(
                    milestone: milestone,
                    isCompleted: abs(progressDays) >= milestone
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var largeNegativeView: some View {
        VStack(spacing: 12) {
            // Большая красная цифра
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(abs(progressDays))")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .shadow(color: .red, radius: glowAnimation ? 15 : 10)
                    .shadow(color: .red.opacity(0.7), radius: glowAnimation ? 25 : 15)
                    .animation(.easeOut(duration: 1.5), value: glowAnimation)
                
                Text(NSLocalizedString("negative_days_suffix", comment: ""))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.red.opacity(0.8))
            }
            .frame(maxWidth: .infinity)

            // Следующий рубеж
            if let nextMilestone = nextNegativeMilestone() {
                HStack(spacing: 4) {
                    Text(NSLocalizedString(nextStepTitleKey, comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(nextMilestone - abs(progressDays)) " + NSLocalizedString("days", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.red)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        
        // Вехи после 500
        HStack(spacing: 0) {
            ForEach(postNegativeMilestones, id: \.self) { milestone in
                PostNegativeMilestoneIndicator(
                    milestone: milestone,
                    isCompleted: abs(progressDays) >= milestone
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
    
    @ViewBuilder
    private var normalPositiveView: some View {
        VStack(spacing: 10) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Фоновая полоса
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 16)
                    
                    // Анимированный прогресс
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.red, .orange, .yellow, .green],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: CGFloat(animatedProgress) * geometry.size.width, height: 16)
                        .shadow(color: .green.opacity(0.3), radius: 2, x: 0, y: 0)
                        .animation(.easeInOut(duration: 1.0), value: animatedProgress)
                }
            }
            .frame(height: 16)
            
            // Индикатор следующей вехи
            if let nextMilestone = nextMilestone() {
                HStack(spacing: 4) {
                    Text(NSLocalizedString(nextStepTitleKey, comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(nextMilestone.days - progressDays)" + NSLocalizedString("days", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        
        // Вехи прогресса
        HStack(spacing: 0) {
            ForEach(milestones, id: \.days) { milestone in
                MilestoneIndicator(
                    milestone: milestone,
                    isCompleted: progressDays >= milestone.days,
                    isNext: nextMilestone()?.days == milestone.days
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private var largePositiveView: some View {
        VStack(spacing: 12) {
            // Большая цифра с анимацией свечения - по центру
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(progressDays)")
                    .font(.system(size: 60, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .yellow, radius: glowAnimation ? 15 : 10)
                    .shadow(color: .green.opacity(0.7), radius: glowAnimation ? 25 : 15)
                    .animation(.easeOut(duration: 1.5), value: glowAnimation)
                
                Text(NSLocalizedString("positive_days_suffix", comment: ""))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            
            // Следующий рубеж - также по центру
            if let nextMilestone = nextPostYearMilestone() {
                HStack(spacing: 4) {
                    Text(NSLocalizedString(nextStepTitleKey, comment: ""))
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(nextMilestone - progressDays)" + NSLocalizedString("days", comment: ""))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        
        // Вехи после года - подсвечиваем только достигнутые
        HStack(spacing: 0) {
            ForEach(postYearMilestones, id: \.self) { milestone in
                PostYearMilestoneIndicator(
                    milestone: milestone,
                    isCompleted: progressDays >= milestone
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 4)
    }
    
    // MARK: - Анимация
    
    private func updateAnimation() {
        if progressDays < 0 {
            if abs(progressDays) > maxNegativeDays {
                // Запускаем свечение для больших отрицательных
                withAnimation(.easeOut(duration: 1.5)) {
                    glowAnimation = true
                }
            } else {
                withAnimation(.easeInOut(duration: 1.0)) {
                    animatedProgress = min(Double(abs(progressDays)) / Double(maxNegativeDays), 1.0)
                }
            }
        } else if progressDays < maxDays {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = min(Double(progressDays) / Double(maxDays), 1.0)
            }
            print("🟢 animatedProgress установлен = \(animatedProgress) для progressDays = \(progressDays)")
        } else {
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = 1.0
            }
            if progressDays > maxDays {
                withAnimation(.easeOut(duration: 1.5)) {
                    glowAnimation = true
                }
            }
        }
    }
    
    // Определяем следующую веху для положительных значений до года
    private func nextMilestone() -> (days: Int, titleKey: String)? {
        return milestones.first { $0.days > progressDays }
    }
}

// MARK: - Индикаторы вех

struct MilestoneIndicator: View {
    let milestone: (days: Int, titleKey: String)
    let isCompleted: Bool
    let isNext: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Иконка - зеленая галочка для достигнутых, белый кружок для будущих
            ZStack {
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.5), radius: 2, x: 0, y: 0)
                } else {
                    Circle()
                        .stroke(isNext ? Color.white : Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .fill(isNext ? Color.white.opacity(0.1) : Color.clear)
                        )
                }
            }
            .frame(width: 24, height: 24)
            
            // Название вехи
            Text(NSLocalizedString(milestone.titleKey, comment: ""))
                .font(.system(size: 10, weight: isNext ? .medium : .regular))
                .foregroundColor(
                    isCompleted ? .green :
                    isNext ? .white : .white.opacity(0.6)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
    }
}

struct PostYearMilestoneIndicator: View {
    let milestone: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Иконка
            ZStack {
                if isCompleted {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 2, x: 0, y: 0)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .overlay(
                            Image(systemName: "trophy")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
            }
            .frame(width: 24, height: 24)
            
            // Название вехи
            Text("\(milestone)" + NSLocalizedString("positive_days_suffix", comment: ""))
                .font(.system(size: 9, weight: isCompleted ? .bold : .regular))
                .foregroundColor(
                    isCompleted ? .yellow : .white.opacity(0.6)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
    }
}

struct NegativeMilestoneIndicator: View {
    let milestone: Int
    let isCompleted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Иконка - красная галочка для достигнутых, белый кружок для будущих
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                        )
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.7), radius: 1, x: 0, y: 0)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        .background(
                            Circle()
                                .fill(Color.clear)
                        )
                }
            }
            .frame(width: 24, height: 24)
            
            // Название вехи (без минуса, с суффиксом)
            Text("\(milestone)" + NSLocalizedString("negative_days_suffix", comment: ""))
                .font(.system(size: 9, weight: isCompleted ? .bold : .regular))
                .foregroundColor(
                    isCompleted ? .red : .white.opacity(0.6)
                )
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 2)
        .contentShape(Rectangle())
    }
}

// Новый индикатор для больших отрицательных рубежей
struct PostNegativeMilestoneIndicator: View {
    let milestone: Int
    let isCompleted: Bool

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                if isCompleted {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                        )
                    Image(systemName: "checkmark") // ✅ Заменили на галочку
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.red)
                        .shadow(color: .red.opacity(0.7), radius: 1)
                } else {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 16, height: 16)
                        // Убрали overlay с иконкой
                }
            }
            .frame(width: 24, height: 24)

            Text("\(milestone)" + NSLocalizedString("negative_days_suffix", comment: ""))
                .font(.system(size: 9, weight: isCompleted ? .bold : .regular))
                .foregroundColor(isCompleted ? .red : .white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 2)
    }
}

// Расширение для темно-красного цвета
extension Color {
    static let darkRed = Color(red: 0.5, green: 0, blue: 0)
}

// MARK: - Preview для тестирования
struct SobrietyProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "4B3A91")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                SobrietyProgressView(progressDays: -200)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: -140)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: -50)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: -10)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 0)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 7)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 130)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 180)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 365)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 366)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 500)
                    .padding(.horizontal)
                
                SobrietyProgressView(progressDays: 620)
                    .padding(.horizontal)
            }
        }
        .previewLayout(.sizeThatFits)
    }
}
