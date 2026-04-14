// DayRecordSelectionViewVariants.swift
import SwiftUI

// MARK: - Мок-данные для превью
struct PreviewDayData {
    let date: Date
    
    static let today = PreviewDayData(date: Date())
}

struct PreviewDayRecord {
    var drinkLevel: DrinkLevel
    var hasSport: Bool
    
    static let empty = PreviewDayRecord(drinkLevel: .none, hasSport: false)
}

// MARK: - Вспомогательное расширение для Color
fileprivate extension Color {
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        return Color(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Превью контейнер для сравнения вариантов
struct DayRecordSelectionPreview: View {
    let dayData = PreviewDayData.today
    let currentRecord = PreviewDayRecord.empty
    let isFutureDate = false
    
    @State private var selectedVariant = 0
    let variants = ["Original", "Glass", "Hybrid"]
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Вариант", selection: $selectedVariant) {
                ForEach(0..<variants.count, id: \.self) { index in
                    Text(variants[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            switch selectedVariant {
            case 0:
                DayRecordSelectionViewOriginal(
                    dayData: dayData,
                    currentRecord: currentRecord,
                    onRecordSelected: { _ in },
                    isFutureDate: isFutureDate
                )
            case 1:
                DayRecordSelectionViewGlass(
                    dayData: dayData,
                    currentRecord: currentRecord,
                    onRecordSelected: { _ in },
                    isFutureDate: isFutureDate
                )
            case 2:
                DayRecordSelectionViewHybrid(
                    dayData: dayData,
                    currentRecord: currentRecord,
                    onRecordSelected: { _ in },
                    isFutureDate: isFutureDate
                )
            default:
                EmptyView()
            }
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Вариант 1: Оригинальный
struct DayRecordSelectionViewOriginal: View {
    let dayData: PreviewDayData
    let currentRecord: PreviewDayRecord
    let onRecordSelected: (PreviewDayRecord) -> Void
    let isFutureDate: Bool
    
    @State private var selectedDrinkLevel: DrinkLevel
    @State private var hasSport: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(dayData: PreviewDayData, currentRecord: PreviewDayRecord, onRecordSelected: @escaping (PreviewDayRecord) -> Void, isFutureDate: Bool) {
        self.dayData = dayData
        self.currentRecord = currentRecord
        self.onRecordSelected = onRecordSelected
        self.isFutureDate = isFutureDate
        
        _selectedDrinkLevel = State(initialValue: currentRecord.drinkLevel)
        _hasSport = State(initialValue: currentRecord.hasSport)
    }
    
    private let baseColor = Color(red: 2/255, green: 0/255, blue: 148/255, opacity: 0.7)
    private let sportColor = Color.hex("C7FF00")
    
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
                    Text("drink_log_prompt")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 30)
                        .padding(.top, 20)
                    
                    Spacer().frame(height: 15)
                    
                    HStack(spacing: 75) {
                        ForEach([DrinkLevel.little, .medium, .heavy], id: \.self) { level in
                            let isSelected = selectedDrinkLevel == level
                            
                            Button(action: {
                                if isSelected {
                                    selectedDrinkLevel = .none
                                } else {
                                    selectedDrinkLevel = level
                                    if level == .medium || level == .heavy {
                                        hasSport = false
                                    }
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Image(systemName: level == .little ? "wineglass" : level == .medium ? "mug" : "takeoutbag.and.cup.and.straw")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 48, height: 48)
                                        .foregroundColor(isSelected ? .yellow : .white)
                                        .scaleEffect(isSelected ? 1.2 : 1.0)
                                    
                                    Text(level.localizedTitle)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 5)
                    
                    Text("or_sport_prompt")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    
                    Spacer().frame(height: 10)
                    
                    Button(action: {
                        if hasSport {
                            hasSport = false
                        } else {
                            hasSport = true
                            if selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy {
                                selectedDrinkLevel = .none
                            }
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(hasSport ? sportColor.opacity(0.3) : Color.white.opacity(0.1))
                                    .frame(width: 48, height: 48)
                                    .overlay(
                                        Circle()
                                            .stroke(hasSport ? sportColor : Color.white.opacity(0.3), lineWidth: 2)
                                    )
                                
                                Image(systemName: "figure.run")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 28, height: 28)
                                    .foregroundColor(hasSport ? sportColor : Color.white.opacity(0.7))
                                    .scaleEffect(hasSport ? 1.2 : 1.0)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer().frame(height: 20)
                    
                    Button(action: {
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
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 20)
                }
            }
            .padding()
        }
        .frame(height: 320)
        .cornerRadius(20)
    }
    
    private func saveRecord() {
        var finalRecord = PreviewDayRecord(drinkLevel: selectedDrinkLevel, hasSport: hasSport)
        
        if (selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy) && hasSport {
            finalRecord.hasSport = false
        }
        
        onRecordSelected(finalRecord)
    }
}

// MARK: - Вариант 2: Glass (Стеклянный эффект)
struct DayRecordSelectionViewGlass: View {
    let dayData: PreviewDayData
    let currentRecord: PreviewDayRecord
    let onRecordSelected: (PreviewDayRecord) -> Void
    let isFutureDate: Bool
    
    @State private var selectedDrinkLevel: DrinkLevel
    @State private var hasSport: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(dayData: PreviewDayData, currentRecord: PreviewDayRecord, onRecordSelected: @escaping (PreviewDayRecord) -> Void, isFutureDate: Bool) {
        self.dayData = dayData
        self.currentRecord = currentRecord
        self.onRecordSelected = onRecordSelected
        self.isFutureDate = isFutureDate
        
        _selectedDrinkLevel = State(initialValue: currentRecord.drinkLevel)
        _hasSport = State(initialValue: currentRecord.hasSport)
    }
    
    var body: some View {
        ZStack {
            // Фон с размытием
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if isFutureDate {
                    errorView
                } else {
                    VStack(spacing: 28) {
                        headerView
                        selectionView
                        saveButton
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                }
            }
        }
        .frame(height: 450)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
    
    private var errorView: some View {
        GlassCard {
            VStack(spacing: 16) {
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                Text("error_future_date")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("drink_log_prompt")
                .font(.title2.bold())
                .foregroundColor(.primary)
            Text("Отметьте ваш день")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var selectionView: some View {
        VStack(spacing: 20) {
            // Алкоголь
            VStack(alignment: .leading, spacing: 12) {
                Text("АЛКОГОЛЬ")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                HStack(spacing: 16) {
                    ForEach([DrinkLevel.none, .little, .medium, .heavy], id: \.self) { level in
                        let isSelected = selectedDrinkLevel == level
                        
                        Button {
                            handleDrinkSelection(level)
                        } label: {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .frame(width: 60, height: 60)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? Color.blue.opacity(0.5) : Color.clear, lineWidth: 2)
                                        )
                                    
                                    if level != .none {
                                        Image(systemName: iconName(for: level))
                                            .font(.system(size: 20))
                                            .foregroundColor(isSelected ? .blue : .secondary)
                                    } else {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 20))
                                            .foregroundColor(isSelected ? .blue : .secondary)
                                    }
                                }
                                
                                Text(level == .none ? "Нет" : level.localizedTitle)
                                    .font(.caption2.bold())
                                    .foregroundColor(isSelected ? .blue : .secondary)
                            }
                        }
                    }
                }
            }
            
            Divider()
            
            // Спорт
            Button {
                handleSportSelection()
            } label: {
                HStack {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(hasSport ? Color.green.opacity(0.5) : Color.clear, lineWidth: 2)
                            )
                        
                        Image(systemName: "figure.run")
                            .font(.system(size: 20))
                            .foregroundColor(hasSport ? .green : .secondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ТРЕНИРОВКА")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        Text("Отметить активность")
                            .font(.subheadline)
                            .foregroundColor(hasSport ? .green : .primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: hasSport ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(hasSport ? .green : .secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(hasSport ? Color.green.opacity(0.3) : Color.clear, lineWidth: 1)
                )
            }
        }
    }
    
    private var saveButton: some View {
        Button {
            saveRecord()
            dismiss()
        } label: {
            Text("СОХРАНИТЬ")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [.blue, .blue.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(16)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    private func iconName(for level: DrinkLevel) -> String {
        switch level {
        case .little: return "wineglass"
        case .medium: return "mug"
        case .heavy: return "takeoutbag.and.cup.and.straw"
        default: return "xmark"
        }
    }
    
    private func handleDrinkSelection(_ level: DrinkLevel) {
        selectedDrinkLevel = level
        if (level == .medium || level == .heavy) && hasSport {
            hasSport = false
        }
    }
    
    private func handleSportSelection() {
        hasSport.toggle()
        if hasSport && (selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy) {
            selectedDrinkLevel = .none
        }
    }
    
    private func saveRecord() {
        var finalRecord = PreviewDayRecord(drinkLevel: selectedDrinkLevel, hasSport: hasSport)
        
        if (selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy) && hasSport {
            finalRecord.hasSport = false
        }
        
        onRecordSelected(finalRecord)
    }
}

// MARK: - Вариант 3: Hybrid (Оригинал + Glass)
struct DayRecordSelectionViewHybrid: View {
    let dayData: PreviewDayData
    let currentRecord: PreviewDayRecord
    let onRecordSelected: (PreviewDayRecord) -> Void
    let isFutureDate: Bool
    
    @State private var selectedDrinkLevel: DrinkLevel
    @State private var hasSport: Bool
    @Environment(\.dismiss) private var dismiss
    
    init(dayData: PreviewDayData, currentRecord: PreviewDayRecord, onRecordSelected: @escaping (PreviewDayRecord) -> Void, isFutureDate: Bool) {
        self.dayData = dayData
        self.currentRecord = currentRecord
        self.onRecordSelected = onRecordSelected
        self.isFutureDate = isFutureDate
        
        _selectedDrinkLevel = State(initialValue: currentRecord.drinkLevel)
        _hasSport = State(initialValue: currentRecord.hasSport)
    }
    
    private let baseGradient = LinearGradient(
        colors: [
            Color(red: 2/255, green: 0/255, blue: 148/255, opacity: 0.9),
            Color(red: 0/255, green: 64/255, blue: 255/255, opacity: 0.7)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    private let sportColor = Color.hex("C7FF00")
    private let drinkColors: [DrinkLevel: Color] = [
        .little: Color.hex("4DA8FF"),
        .medium: Color.hex("FFB347"),
        .heavy: Color.hex("FF6B6B")
    ]
    
    var body: some View {
        ZStack {
            // Фон: градиент из оригинала со стеклянным эффектом
            Rectangle()
                .fill(baseGradient)
                .overlay(
                    Rectangle()
                        .fill(.ultraThinMaterial.opacity(0.3))
                )
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if isFutureDate {
                    errorView
                } else {
                    VStack(spacing: 25) {
                        // Заголовок
                        Text("drink_log_prompt")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 25)
                        
                        // Выбор алкоголя с эффектом стекла
                        drinkSelectionView
                        
                        // Разделитель с эффектом стекла
                        GlassDivider()
                            .padding(.vertical, 10)
                        
                        // Спорт с эффектом стекла
                        Text("or_sport_prompt")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        sportSelectionView
                        
                        // Кнопка сохранения
                        saveButton
                            .padding(.top, 5)
                            .padding(.bottom, 25)
                    }
                    .padding(.horizontal, 30)
                }
            }
        }
        .frame(height: 350)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color(red: 0, green: 0, blue: 0.5, opacity: 0.3), radius: 15, x: 0, y: 5)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.9))
            Text("error_future_date")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
    
    private var drinkSelectionView: some View {
        HStack(spacing: 45) {
            ForEach([DrinkLevel.little, .medium, .heavy], id: \.self) { level in
                let isSelected = selectedDrinkLevel == level
                
                Button(action: {
                    handleDrinkSelection(level)
                }) {
                    VStack(spacing: 10) {
                        // Кнопка с эффектом стекла
                        ZStack {
                            Circle()
                                .fill(isSelected ? drinkColors[level]!.opacity(0.25) : .white.opacity(0.1))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            isSelected ? drinkColors[level]! : .white.opacity(0.25),
                                            lineWidth: isSelected ? 2.5 : 1.5
                                        )
                                )
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial.opacity(0.4))
                                        .blur(radius: 1)
                                )
                            
                            Image(systemName: level == .little ? "wineglass" :
                                  level == .medium ? "mug" : "takeoutbag.and.cup.and.straw")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 30, height: 30)
                                .foregroundColor(isSelected ? drinkColors[level]! : .white.opacity(0.8))
                                .scaleEffect(isSelected ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                        }
                        
                        Text(level.localizedTitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(isSelected ? drinkColors[level]! : .white.opacity(0.85))
                            .shadow(color: isSelected ? drinkColors[level]!.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var sportSelectionView: some View {
        Button(action: {
            handleSportSelection()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Круг с эффектом стекла
                    Circle()
                        .fill(hasSport ? sportColor.opacity(0.25) : .white.opacity(0.1))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(hasSport ? sportColor : .white.opacity(0.25), lineWidth: hasSport ? 2.5 : 1.5)
                        )
                        .background(
                            Circle()
                                .fill(.ultraThinMaterial.opacity(0.4))
                                .blur(radius: 1)
                        )
                    
                    Image(systemName: "figure.run")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                        .foregroundColor(hasSport ? sportColor : .white.opacity(0.8))
                        .scaleEffect(hasSport ? 1.15 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: hasSport)
                }
                
                Text("Спорт")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(hasSport ? sportColor : .white.opacity(0.85))
                    .shadow(color: hasSport ? sportColor.opacity(0.3) : .clear, radius: 2, x: 0, y: 1)
            }
        }
        .padding(.horizontal)
    }
    
    private var saveButton: some View {
        Button(action: {
            saveRecord()
            dismiss()
        }) {
            Text("ОК")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    ZStack {
                        // Градиент из оригинала
                        LinearGradient(
                            colors: [Color.hex("8B5CF6"), Color.hex("6366F1")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        
                        // Стеклянный эффект сверху
                        .overlay(
                            .white.opacity(0.1)
                                .blendMode(.overlay)
                        )
                    }
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.hex("6366F1").opacity(0.4), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 40)
        }
    }
    
    private func handleDrinkSelection(_ level: DrinkLevel) {
        print("🍷 Выбран уровень алкоголя: \(level.rawValue)")
        
        if selectedDrinkLevel == level {
            selectedDrinkLevel = .none
            print("   Снят выбор уровня алкоголя")
        } else {
            selectedDrinkLevel = level
            // Если выбран medium/heavy, снимаем спорт (не совместимо)
            if level == .medium || level == .heavy {
                hasSport = false
            }
        }
    }
    
    private func handleSportSelection() {
        print("💪 Выбор спорта")
        
        if hasSport {
            hasSport = false
            print("   Снят выбор спорта")
        } else {
            hasSport = true
            // Если выбран medium/heavy, снимаем их (не совместимо со спортом)
            if selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy {
                selectedDrinkLevel = .none
            }
        }
    }
    
    private func saveRecord() {
        var finalRecord = PreviewDayRecord(drinkLevel: selectedDrinkLevel, hasSport: hasSport)
        
        if (selectedDrinkLevel == .medium || selectedDrinkLevel == .heavy) && hasSport {
            print("⚠️ Medium/Heavy + Sport - сохраняем только алкоголь")
            finalRecord.hasSport = false
        }
        
        print("💾 Сохраняем запись:")
        print("   Алкоголь: \(finalRecord.drinkLevel.rawValue)")
        print("   Спорт: \(finalRecord.hasSport)")
        
        onRecordSelected(finalRecord)
    }
}

// MARK: - Вспомогательные компоненты
struct GlassCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct GlassDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.15))
            .frame(height: 1)
            .overlay(
                Rectangle()
                    .fill(.white.opacity(0.05))
                    .frame(height: 1)
                    .offset(y: 1)
            )
    }
}

// MARK: - Превью
#Preview {
    DayRecordSelectionPreview()
}
