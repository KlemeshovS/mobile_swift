//
//  DataDebugger.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 18.01.2026.
//

// DataDebugger.swift
import Foundation

class DataDebugger {
    static func debugDayRecord(_ key: String, _ record: DayRecord) {
        
        // Проверка проблемы
        if record.hasSport && record.drinkLevel == .little {
        }
    }
    
    static func debugAllData(_ data: [String: DayRecord]) {
        for (key, record) in data.sorted(by: { $0.key < $1.key }) {
            if record.drinkLevel != .none || record.hasSport {
                debugDayRecord(key, record)
            }
        }
    }
}
