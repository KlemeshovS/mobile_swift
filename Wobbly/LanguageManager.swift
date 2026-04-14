// LanguageManager.swift
import Foundation
import SwiftUI

func NSLocalizedString(_ key: String, comment: String) -> String {
    let languageCode: String
    switch LanguageManager.shared.currentLanguage {
    case .russian: languageCode = "ru"
    case .english: languageCode = "en"
    }
    
    if let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
       let bundle = Bundle(path: path) {
        return bundle.localizedString(forKey: key, value: comment, table: nil)
    }
    return Foundation.NSLocalizedString(key, comment: comment)
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    // 🔥 ДОБАВЛЯЕМ: Сигнал для перезагрузки всего приложения
    @Published var refreshTrigger = UUID()
    
    enum AppLanguage: String, CaseIterable {
 //       case system = "system"
        case russian = "ru"
        case english = "en"
        
        var displayName: String {
            switch self {
  //          case .system: return "Auto"
            case .russian: return "Русский"
            case .english: return "English"
            }
        }
        
        var shortName: String {
            switch self {
    //        case .system: return "A"
            case .russian: return "RU"
            case .english: return "EN"
            }
        }
        
        
    }
    
    @Published var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            
            // 🔥 ВАЖНО: Запускаем перезагрузку всего интерфейса
            DispatchQueue.main.async {
                self.refreshTrigger = UUID()
                
                // Уведомляем все View об обновлении
                NotificationCenter.default.post(
                    name: Notification.Name("LanguageDidChange"),
                    object: nil
                )
                
                // Принудительно обновляем окружение
                self.objectWillChange.send()
            }
        }
    }
    
    var currentLocale: Locale {
        switch currentLanguage {
        case .russian:
            return Locale(identifier: "ru")
        case .english:
            return Locale(identifier: "en")
        }
    }
    
    private init() {
        if let savedLanguage = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLanguage) {
            self.currentLanguage = language
        } else {
            // Определяем язык системы
            let systemLang = Locale.current.languageCode ?? "ru"
            self.currentLanguage = systemLang == "ru" ? .russian : .english
        }
    }
    
    func switchToNextLanguage() {
        let allLanguages = AppLanguage.allCases
        guard let currentIndex = allLanguages.firstIndex(of: currentLanguage) else { return }
        
        let nextIndex = (currentIndex + 1) % allLanguages.count
        currentLanguage = allLanguages[nextIndex]
    }
}
