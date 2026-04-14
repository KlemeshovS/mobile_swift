import SwiftUI

struct SelectionDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.15))
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1)
                    .offset(y: 1)
            )
    }
}

struct DayRecordSelectionView: View {
    let dayData: DayData
    let currentRecord: DayRecord
    let onRecordSelected: (DayRecord) -> Void
    let isFutureDate: Bool
    
    @State private var selectedDrinkLevel: DrinkLevel
    @State private var hasSport: Bool
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var languageManager = LanguageManager.shared

    init(dayData: DayData, currentRecord: DayRecord, onRecordSelected: @escaping (DayRecord) -> Void, isFutureDate: Bool) {
        self.dayData = dayData
        self.currentRecord = currentRecord
        self.onRecordSelected = onRecordSelected
        self.isFutureDate = isFutureDate
        
        let level = currentRecord.drinkLevel
        let sport = currentRecord.hasSport
        if level == .little_sport {
            _selectedDrinkLevel = State(initialValue: .little)
            _hasSport = State(initialValue: true)
        } else if level == .medium_sport {
            _selectedDrinkLevel = State(initialValue: .medium)
            _hasSport = State(initialValue: true)
        } else if level == .heavy_sport {
            _selectedDrinkLevel = State(initialValue: .heavy)
            _hasSport = State(initialValue: true)
        } else {
            _selectedDrinkLevel = State(initialValue: level)
            _hasSport = State(initialValue: sport)
        }
    }
    
    private let imageSpacing: CGFloat = 75
    private let imageSize: CGFloat = 48
    private let selectedScale: CGFloat = 1.2
    private let normalScale: CGFloat = 1.0
    
    private let baseColor = Color(red: 2/255, green: 0/255, blue: 148/255, opacity: 0.7)
    private let sportColor = Color(hex: "C7FF00")
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            baseColor,
                            baseColor.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isFutureDate {
                    Text("error_future_date")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding()
                    
                    Spacer()
                } else {
                    // Заголовок для алкоголя
                    Text(NSLocalizedString("drink_log_prompt", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .padding(.top, 20)
                    
                    Spacer()
                        .frame(height: 15)
                    
                    // Кнопки уровней алкоголя
                    HStack(spacing: imageSpacing) {
                        ForEach([DrinkLevel.little, .medium, .heavy], id: \.self) { level in
                            let isSelected = selectedDrinkLevel == level
                            
                            Button(action: {
                                print("🍷 Выбран уровень алкоголя: \(level.rawValue)")
                                
                                if isSelected {
                                    selectedDrinkLevel = .none
                                    print("   Снят выбор уровня алкоголя")
                                } else {
                                    selectedDrinkLevel = level
                                    // Если выбран medium/heavy, снимаем спорт (не совместимо)
                            //        if level == .medium || level == .heavy {
                            //            hasSport = false
                            //        }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    // Контейнер для иконки с фиксированным размером
                                    ZStack {
                                        Image(isSelected ?
                                              "\(level == .little ? "little" : level == .medium ? "medium" : "heavy")_selected" :
                                                "\(level == .little ? "little" : level == .medium ? "medium" : "heavy")_normal")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: imageSize, height: imageSize)
                                        .scaleEffect(isSelected ? selectedScale : normalScale)
                                        
                                        // Обводка поверх изображения, не влияющая на размер
                                        if isSelected {
                                            Circle()
                                                .stroke(Color(hex: "6366F1"), lineWidth: 3)
                                                .frame(width: imageSize + 10, height: imageSize + 10)
                                                .scaleEffect(1.0) // Не масштабируем обводку дополнительно
                                        }
                                    }
                                    .frame(width: imageSize, height: imageSize) // Фиксируем размер контейнера
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                                    
                                    Text(level.localizedTitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Разделитель с эффектом стекла
                    SelectionDivider()
                        .padding(.vertical, 15)
                    
                    // Заголовок для спорта
                    Text(NSLocalizedString("or_sport_prompt", comment: "Prompt for sport selection"))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                        .frame(height: 15)
                    
                    // Кнопка спорта
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            print("💪 Выбор спорта")
                            
                            if hasSport {
                                hasSport = false
                                print("   Снят выбор спорта")
                            } else {
                                hasSport = true
                                // Если выбран medium/heavy, снимаем их (не совместимо со спортом)
                         //       if selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy {
                         //           selectedDrinkLevel = .none
                         //       }
                            }
                        }
                    }) {
                        VStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .fill(hasSport ? sportColor.opacity(0.25) : Color.white.opacity(0.1))
                                        .frame(width: 50, height: 50)
                                        .overlay(
                                            Circle()
                                                .stroke(
                                                    hasSport ? sportColor : Color.white.opacity(0.25),
                                                    lineWidth: hasSport ? 2.5 : 1.5
                                                )
                                        )
                                    
                                    Image(systemName: "figure.run")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 30, height: 30)
                                        .foregroundColor(hasSport ? sportColor : Color.white.opacity(0.8))
                                        .scaleEffect(hasSport ? 1.15 : 1.0)
                                }
                            }
                        }
                        .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 20)
                    
                    // Кнопка ОК
                    Button(action: {
                        print("✅ Нажата кнопка ОК")
                        saveRecord()
                        dismiss()
                    }) {
                        Text("OK")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "8B5CF6"), Color(hex: "6366F1")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 10)
                }
            }
            .padding()
        }
        .presentationDetents([.height(320)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
        .onAppear {
            print("📱 DayRecordSelectionView открыт")
            print("   Текущая запись: alcohol=\(currentRecord.drinkLevel.rawValue), sport=\(currentRecord.hasSport)")
            print("   Инициализировано: alcohol=\(selectedDrinkLevel.rawValue), sport=\(hasSport)")
        }
    }
    
    private func saveRecord() {
        var finalRecord: DayRecord
        // Комбинации
        if selectedDrinkLevel == .little && hasSport {
            finalRecord = DayRecord(drinkLevel: .little, hasSport: true)
        } else if selectedDrinkLevel == .medium && hasSport {
            finalRecord = DayRecord(drinkLevel: .medium, hasSport: true)
        } else if selectedDrinkLevel == .heavy && hasSport {
            finalRecord = DayRecord(drinkLevel: .heavy, hasSport: true)
        } else if hasSport {
            finalRecord = DayRecord(drinkLevel: .none, hasSport: true)
        } else {
            finalRecord = DayRecord(drinkLevel: selectedDrinkLevel, hasSport: false)
        }
        
        onRecordSelected(finalRecord)
    }
}
