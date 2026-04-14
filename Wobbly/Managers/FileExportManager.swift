//fileexportmanager.swift

import Foundation
import UniformTypeIdentifiers

// MARK: - File Export Manager
class FileExportManager: ObservableObject {
    private let dataManager = DrinkDataManager()
    
    func autoBackupData(dayRecords: [String: DayRecord]) -> URL? {
        // Получаем текущие данные пользователя из UserDefaults
        let userId = UserDefaults.standard.object(forKey: "userId") as? Int
        let username = UserDefaults.standard.string(forKey: "userName")
        
        let exportData = ExportData(
            daysData: [:],  // Пустой старый формат
            dayRecords: dayRecords,
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let jsonData = try encoder.encode(exportData)
            
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let backupURL = documentsURL.appendingPathComponent("wobbly_auto_backup.json")
            
            try jsonData.write(to: backupURL)
            print("✅ Авто-бэкап создан с новым форматом (версия 2.1)")
            
            return backupURL
            
        } catch {
            print("❌ Ошибка создания авто-бэкапа: \(error)")
            return nil
        }
    }
    
    func manualExportData(dayRecords: [String: DayRecord]) -> URL? {
        let userId = UserDefaults.standard.object(forKey: "userId") as? Int
        let username = UserDefaults.standard.string(forKey: "userName")
        
        let exportData = ExportData(
            dayRecords: dayRecords,
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
            print("📤 Ручной экспорт (версия 2.1): \(tempURL)")
            print("📤 Экспорт: userId=\(String(describing: userId)), username=\(String(describing: username))")
            return tempURL
            
        } catch {
            print("❌ Ошибка ручного экспорта: \(error)")
            return nil
        }
    }
    
    func getAutoBackupURL() -> URL? {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupURL = documentsURL.appendingPathComponent("wobbly_auto_backup.json")
        
        if FileManager.default.fileExists(atPath: backupURL.path) {
            do {
                let fileSize = try FileManager.default.attributesOfItem(atPath: backupURL.path)[.size] as? Int ?? 0
                print("📁 Авто-бэкап найден: \(backupURL.path)")
                print("   Размер: \(fileSize) байт")
                return backupURL
            } catch {
                print("❌ Ошибка проверки бэкапа: \(error)")
                return nil
            }
        } else {
            print("❌ Авто-бэкап не найден по пути: \(backupURL.path)")
            return nil
        }
    }
    
    func restoreFromAutoBackup() -> ([String: DrinkLevel], [String: DayRecord]?) {
        guard let backupURL = getAutoBackupURL() else {
            print("❌ Авто-бэкап не найден")
            return ([:], nil)
        }
        
        do {
            let jsonData = try Data(contentsOf: backupURL)
            let exportData = try JSONDecoder().decode(ExportData.self, from: jsonData)
            
            print("📊 Версия данных: \(exportData.version)")
            
            // Восстанавливаем данные пользователя, если они есть
            if let userId = exportData.userId {
                UserDefaults.standard.set(userId, forKey: "userId")
                print("✅ Восстановлен userId: \(userId)")
            }
            if let username = exportData.username {
                UserDefaults.standard.set(username, forKey: "userName")
                print("✅ Восстановлен username: \(username)")
            }
            
            if exportData.version >= "2.0", let dayRecords = exportData.dayRecords {
                print("✅ Восстановлены данные в новом формате")
                let oldFormat = exportData.toOldFormat()
                return (oldFormat, dayRecords)
            } else {
                print("⚠️ Восстановлены данные в старом формате")
                let newRecords = exportData.toNewFormat()
                return (exportData.daysData, newRecords)
            }
            
        } catch {
            print("❌ Ошибка восстановления: \(error)")
            return ([:], nil)
        }
    }
    
    func importData(from url: URL) -> ExportData? {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                
                if let timestamp = try? container.decode(Double.self) {
                    return Date(timeIntervalSince1970: timestamp)
                }
                
                let dateString = try container.decode(String.self)
                let formatter = ISO8601DateFormatter()
                if let date = formatter.date(from: dateString) {
                    return date
                }
                
                let fallbackFormatter = DateFormatter()
                fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                if let date = fallbackFormatter.date(from: dateString) {
                    return date
                }
                
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Cannot decode date string: \(dateString)"
                )
            }
            
            let exportData = try decoder.decode(ExportData.self, from: jsonData)
            print("✅ Данные импортированы из: \(url)")
            print("📊 Версия: \(exportData.version)")
            if let userId = exportData.userId {
                print("👤 userId: \(userId)")
            }
            if let username = exportData.username {
                print("👤 username: \(username)")
            }
            return exportData
            
        } catch {
            print("❌ Ошибка импорта данных: \(error)")
            return nil
        }
    }
}
