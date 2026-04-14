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
        
        // 🔥 Добавляем userId и username из UserDefaults
        let userId = UserDefaults.standard.object(forKey: "userId") as? Int
        let username = UserDefaults.standard.string(forKey: "userName")
        
        // 🔥 СОЗДАЕМ НОВЫЙ ExportData с ТЕКУЩЕЙ датой
        let exportData = ExportData(
            daysData: fullData.daysData,
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
            print("📤 Ручной экспорт: \(tempURL)")
            print("📅 Дата экспорта в файле: \(exportData.exportDate)")
            
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
            
            // Просто сохраняем импортированные данные в основной файл
            dataManager.saveFullData(exportData)
            
            print("✅ Данные восстановлены из файла: \(exportData.daysData.count) записей")
            return true
            
        } catch {
            print("❌ Ошибка восстановления: \(error)")
            return false
        }
    }
}
