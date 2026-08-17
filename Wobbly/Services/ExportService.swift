//
//  ExportService.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//

import SwiftUI
import UniformTypeIdentifiers

class ExportService {
    static let shared = ExportService()
    private let dataManager = DrinkDataManager()
    
    func manualExport() -> URL? {
        let dataManager = DrinkDataManager()
        let fullData = dataManager.loadFullData()

        let workouts = WorkoutDataStorage.shared.loadAll()
        let triggers = TriggerManager.shared.allTriggers()

        let exportData = ExportData(
            daysData: fullData.daysData,
            workouts: workouts.isEmpty ? nil : workouts,
            triggers: triggers.isEmpty ? nil : triggers
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted

            let jsonData = try encoder.encode(exportData)

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let dateString = dateFormatter.string(from: Date())
            let fileName = "wobbly_export_\(dateString).json"
            let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

            try jsonData.write(to: tempURL)
            print("📤 Ручной экспорт: \(tempURL), тренировок: \(workouts.count)")

            return tempURL

        } catch {
            print("❌ Ошибка ручного экспорта: \(error)")
            return nil
        }
    }
    
    func restoreFromFile(_ fileURL: URL) -> Bool {
        do {
            let jsonData = try Data(contentsOf: fileURL)
            let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)
            
            dataManager.saveFullData(exportData)
            
            // Восстанавливаем тренировки если есть
            if let workouts = exportData.workouts, !workouts.isEmpty {
                for (dayKey, workout) in workouts {
                    WorkoutDataStorage.shared.save(workout, for: dayKey)
                }
                print("✅ Восстановлено тренировок: \(workouts.count)")
            }

            // Восстанавливаем дневник триггеров если есть (мёржим по дням, старые
            // файлы без этого поля просто ничего здесь не делают)
            if let triggers = exportData.triggers, !triggers.isEmpty {
                for (dayKey, dayTriggers) in triggers {
                    TriggerManager.shared.setTriggers(dayTriggers, for: dayKey)
                }
                print("✅ Восстановлено триггеров: \(triggers.count)")
            }

            print("✅ Данные восстановлены из файла: \(exportData.daysData.count) записей")
            return true
            
        } catch {
            print("❌ Ошибка восстановления: \(error)")
            return false
        }
    }
}
