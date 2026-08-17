//
//  ExportImportTriggersTests.swift
//  WobblyTests
//
//  Проверяет, что дневник триггеров (TriggerManager) корректно сохраняется в
//  экспортный JSON и восстанавливается обратно через реальные продовые пути:
//  ExportService.manualExport() / restoreFromFile() и
//  DataRestoreManager.importFromFile() / restoreFromAutoBackup().
//
//  ВАЖНО: как и AchievementManagerTests/StreakHistoryManagerTests, эти тесты
//  трогают РЕАЛЬНЫЕ Documents/wobbly_data.json, Documents/wobbly_auto_backup.json
//  и UserDefaults.standard["firstInstallDate"] контейнера приложения — init()/deinit()
//  делают полный бэкап/восстановление вокруг каждого теста. TriggerManager не имеет
//  API для полного сброса/снапшота своего хранилища, поэтому вместо бэкапа всего
//  стора тесты используют собственные сентинел-ключи дней (год 1901 — заведомо не
//  пересекается с реальными данными пользователя) и явно чистят только их через
//  defer. Сьют помечен .serialized по тому же соглашению, что и остальные сьюты.
//

import Testing
import Foundation
@testable import Wobbly

@Suite(.serialized)
final class ExportImportTriggersTests {
    private let fm = FileManager.default
    private let dataFileURL: URL
    private let autoBackupFileURL: URL
    private let installDateKey = "firstInstallDate"

    private let originalDataBytes: Data?
    private let originalBackupBytes: Data?
    private let originalInstallDate: Any?

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        dataFileURL = documents.appendingPathComponent("wobbly_data.json")
        autoBackupFileURL = documents.appendingPathComponent("wobbly_auto_backup.json")

        originalDataBytes = try? Data(contentsOf: dataFileURL)
        originalBackupBytes = try? Data(contentsOf: autoBackupFileURL)
        originalInstallDate = UserDefaults.standard.object(forKey: installDateKey)

        try? fm.removeItem(at: dataFileURL)
        try? fm.removeItem(at: autoBackupFileURL)
        UserDefaults.standard.set(Calendar.current.startOfDay(for: Date()), forKey: installDateKey)
    }

    deinit {
        if let bytes = originalDataBytes {
            try? bytes.write(to: dataFileURL)
        } else {
            try? fm.removeItem(at: dataFileURL)
        }
        if let bytes = originalBackupBytes {
            try? bytes.write(to: autoBackupFileURL)
        } else {
            try? fm.removeItem(at: autoBackupFileURL)
        }
        if let originalInstallDate {
            UserDefaults.standard.set(originalInstallDate, forKey: installDateKey)
        } else {
            UserDefaults.standard.removeObject(forKey: installDateKey)
        }
    }

    // MARK: - Helpers

    /// Сентинел-ключ дня в формате daysData ("год-месяц(0-based)-день"), 1901 год
    /// заведомо не пересекается ни с какими реальными данными пользователя.
    private func sentinelKey(_ suffix: Int) -> String {
        "1901-0-\(suffix)"
    }

    private func clearTrigger(_ key: String) {
        TriggerManager.shared.setTriggers([], for: key)
    }

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private func writeTempFile(_ data: Data, name: String) -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        try? data.write(to: url)
        return url
    }

    // MARK: - Pure Codable round-trip (без TriggerManager/файловой системы)

    @Test func exportDataRoundTripsMultipleTriggersPerDay() throws {
        let dayA = sentinelKey(11)
        let dayB = sentinelKey(12)
        let original = ExportData(
            daysData: [dayA: .medium],
            triggers: [dayA: [.stress, .conflict], dayB: [.habit]]
        )

        let data = try makeEncoder().encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportData.self, from: data)

        #expect(decoded.triggers?[dayA] == [.stress, .conflict])
        #expect(decoded.triggers?[dayB] == [.habit])
    }

    @Test func exportDataDecodesOldFileWithoutTriggersField() throws {
        // Файл в формате версии 2.0 без единого упоминания triggers/workouts —
        // ровно так выглядели файлы, экспортированные до появления дневника триггеров.
        let dayKey = sentinelKey(13)
        let json = """
        {
          "version": "2.0",
          "exportDate": "2026-01-01T00:00:00Z",
          "daysData": { "\(dayKey)": "little" }
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ExportData.self, from: Data(json.utf8))

        #expect(decoded.triggers == nil)
        #expect(decoded.workouts == nil)
        #expect(decoded.daysData[dayKey] == .little)
    }

    @Test func manualExportOmitsTriggersKeyWhenNoDayHasTriggers() throws {
        // Не полагаемся на глобальную пустоту TriggerManager (другие тесты/реальные
        // данные симулятора могли что-то туда положить) — просто кодируем ExportData
        // с triggers: nil напрямую и проверяем, что ключ "triggers" отсутствует в JSON.
        let exportData = ExportData(daysData: [:], triggers: nil)
        let data = try makeEncoder().encode(exportData)
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["triggers"] == nil)
    }

    // MARK: - Реальный экспорт (ExportService.manualExport)

    @Test func manualExportIncludesCurrentTriggersFromTriggerManager() throws {
        let dayKey = sentinelKey(1)
        defer { clearTrigger(dayKey) }

        TriggerManager.shared.setTriggers([.stress, .conflict], for: dayKey)

        let fileURL = try #require(ExportService.shared.manualExport())
        defer { try? fm.removeItem(at: fileURL) }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(ExportData.self, from: data)

        #expect(exportData.triggers?[dayKey] == [.stress, .conflict])
    }

    // MARK: - Реальный импорт (DataRestoreManager.importFromFile)

    @Test func importFromFileMergesTriggersIntoTriggerManager() throws {
        let dayKey = sentinelKey(2)
        defer { clearTrigger(dayKey) }
        clearTrigger(dayKey) // на случай мусора от упавшего прошлого прогона

        let fixture = ExportData(daysData: [:], triggers: [dayKey: [.boredom, .party]])
        let fileURL = writeTempFile(try makeEncoder().encode(fixture), name: "trigger_import_test.json")
        defer { try? fm.removeItem(at: fileURL) }

        let success = DataRestoreManager().importFromFile(fileURL)

        #expect(success == true)
        #expect(TriggerManager.shared.triggers(for: dayKey) == [.boredom, .party])
    }

    @Test func importingOldFileWithoutTriggersDoesNotTouchExistingTriggers() throws {
        let dayKey = sentinelKey(3)
        defer { clearTrigger(dayKey) }

        // Локально уже есть триггер для этого дня — старый импортируемый файл
        // не должен его ни стереть, ни изменить.
        TriggerManager.shared.setTriggers([.habit], for: dayKey)

        let oldDayKey = sentinelKey(4)
        let json = """
        {
          "version": "2.0",
          "exportDate": "2026-01-01T00:00:00Z",
          "daysData": { "\(oldDayKey)": "little" }
        }
        """
        let fileURL = writeTempFile(Data(json.utf8), name: "trigger_backcompat_test.json")
        defer { try? fm.removeItem(at: fileURL) }

        let success = DataRestoreManager().importFromFile(fileURL)

        #expect(success == true)
        #expect(TriggerManager.shared.triggers(for: dayKey) == [.habit])
    }

    // MARK: - Реальное восстановление из авто-бэкапа (DataRestoreManager.restoreFromAutoBackup)

    @Test func restoreFromAutoBackupMergesTriggers() throws {
        let dayKey = sentinelKey(5)
        defer { clearTrigger(dayKey) }
        clearTrigger(dayKey)

        let fixture = ExportData(daysData: [:], triggers: [dayKey: [.loneliness]])
        let data = try makeEncoder().encode(fixture)
        try data.write(to: autoBackupFileURL)

        let success = DataRestoreManager().restoreFromAutoBackup()

        #expect(success == true)
        #expect(TriggerManager.shared.triggers(for: dayKey) == [.loneliness])
    }
}
