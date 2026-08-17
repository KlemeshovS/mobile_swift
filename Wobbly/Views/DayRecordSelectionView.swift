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
    @State private var selectedTriggers: Set<DrinkTrigger>
    @State private var workoutData: WorkoutData? = nil
    @State private var showWorkoutEditor = false
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
        _selectedTriggers = State(initialValue: Set(TriggerManager.shared.triggers(for: dayData.key)))
    }

    private var showsTriggerPicker: Bool {
        selectedDrinkLevel == .little || selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy
    }

    private var sheetHeight: CGFloat {
        showsTriggerPicker ? 400 : 320
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

                    // Триггеры — необязательно, только если отмечен алкоголь
                    if showsTriggerPicker {
                        SelectionDivider()
                            .padding(.vertical, 12)

                        Text(NSLocalizedString("trigger_prompt", comment: ""))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 10)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(DrinkTrigger.allCases, id: \.self) { trigger in
                                    let isSelected = selectedTriggers.contains(trigger)
                                    Button(action: {
                                        if isSelected {
                                            selectedTriggers.remove(trigger)
                                        } else {
                                            selectedTriggers.insert(trigger)
                                        }
                                        HapticManager.shared.impact(.light)
                                    }) {
                                        Text(trigger.localizedTitle)
                                            .font(.system(size: 13, weight: .medium))
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(isSelected ? Color(hex: "6366F1") : Color.white.opacity(0.12))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    // Разделитель с эффектом стекла
                    SelectionDivider()
                        .padding(.vertical, 15)

                    // Заголовок для спорта
                    HStack {
                        Spacer()
                        Text(NSLocalizedString("or_sport_prompt", comment: ""))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { showWorkoutEditor = true }) {
                            Image(systemName: "info.circle")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: 15)

                    // Кнопка спорта
                    ZStack {
                        // Иконка по центру всегда
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    hasSport = hasSport ? false : true
                                }
                            }) {
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
                            Spacer()
                        }

                        // Данные тренировки справа от иконки
                        if let workout = workoutData {
                            HStack {
                                Spacer()
                                    .frame(width: UIScreen.main.bounds.width / 2 + 10)
                                VStack(alignment: .trailing, spacing: 3) {
                                    Text(workout.activityName)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                    if let dist = workout.distanceFormatted {
                                        Text(dist)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                    Text(workout.durationFormatted)
                                        .font(.system(size: 13))
                                        .foregroundColor(.white.opacity(0.8))
                                    if let cal = workout.caloriesFormatted {
                                        Text(cal)
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
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
        }
        .ignoresSafeArea()
        .presentationDetents([.height(sheetHeight)])
        .presentationCornerRadius(20)
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showWorkoutEditor) {
            WorkoutEditorView(dayKey: dayData.key, workout: workoutData) { updated in
                if updated.activityName.isEmpty && updated.durationSeconds == 0 {
                    workoutData = nil
                } else {
                    workoutData = updated
                }
            }
        }
        .onAppear {
            workoutData = WorkoutDataStorage.shared.load(for: dayData.key)
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

        // Триггеры имеют смысл только для дней с алкоголем
        let triggersToSave = (finalRecord.drinkLevel == .none) ? [] : Array(selectedTriggers)
        TriggerManager.shared.setTriggers(triggersToSave, for: dayData.key)
        TriggerSyncManager.shared.markLocalUpdated()
        Task {
            await TriggerSyncManager.shared.pushToServer()
        }

        onRecordSelected(finalRecord)
    }
}
