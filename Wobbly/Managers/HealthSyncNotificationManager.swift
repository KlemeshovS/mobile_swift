//
//  HealthSyncNotificationManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 31.05.26.
//

import Foundation

class HealthSyncNotificationManager {
    static let shared = HealthSyncNotificationManager()
    
    // Показываем внутреннее уведомление через AppNotificationManager
    func notifyIfNeeded(autoAddedDays: [String], isRussian: Bool) {
        guard !autoAddedDays.isEmpty else { return }
        
        let key = "lastHealthSyncNotificationDate"
        let today = Calendar.current.startOfDay(for: Date())
        if let last = UserDefaults.standard.object(forKey: key) as? Date,
           Calendar.current.startOfDay(for: last) == today { return }
        UserDefaults.standard.set(Date(), forKey: key)
        
        let count = autoAddedDays.count
        let message: String
        
        if count == 1 {
            message = NSLocalizedString("health_sync_one", comment: "")
        } else {
            message = String(format: NSLocalizedString("health_sync_many", comment: ""), count)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            AppNotificationManager.shared.showCustomMessage(message)
        }
    }
}
