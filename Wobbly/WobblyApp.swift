import SwiftUI
import GoogleSignIn
import Kingfisher

@main
struct DrinklyApp: App {
    
    init() {
        print("🚀 Приложение запускается...")
        
        // Настройка Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "293241377764-fnmtgl5h16pprkhdhlm2bto77u9nf0pq.apps.googleusercontent.com")
        
        // Настройка Kingfisher для staging-окружения
        if AppEnvironment.current == .staging, let key = AppEnvironment.stagingKey {
            let modifier = AnyModifier { request in
                var r = request
                r.setValue(key, forHTTPHeaderField: "X-Staging-Key")
                return r
            }
            KingfisherManager.shared.defaultOptions = [.requestModifier(modifier)]
            print("✅ Kingfisher настроен с X-Staging-Key")
        }
        
        // Запускаем миграцию в фоновом потоке, чтобы не блокировать UI
        DispatchQueue.global(qos: .background).async {
            let manager = DrinkDataManager()
            manager.migrateOldDataIfNeeded()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }
}
