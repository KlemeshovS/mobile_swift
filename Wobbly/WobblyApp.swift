import SwiftUI
import GoogleSignIn

@main
struct DrinklyApp: App {
    
    init() {
        print("🚀 Приложение запускается...")
        
    //     Настройка Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: "293241377764-fnmtgl5h16pprkhdhlm2bto77u9nf0pq.apps.googleusercontent.com")
        
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
