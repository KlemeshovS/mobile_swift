import Foundation

class TokenManager {
    static let shared = TokenManager()
    private let tokenKey = "accessToken"
    private let envKey = "savedEnvironment"
    
    private init() {}
    
    var currentToken: String? {
        get {
            let token = UserDefaults.standard.string(forKey: tokenKey)
            print("🔑 TokenManager: загружен токен: \(token?.prefix(10) ?? "nil")...")
            return token
        }
        set {
            if let newToken = newValue {
                UserDefaults.standard.set(newToken, forKey: tokenKey)
                print("💾 TokenManager: сохранён токен: \(newToken.prefix(10))...")
            } else {
                clearToken()
            }
        }
    }
    
    func clearToken() {
        print("🧹 TokenManager: очистка токена")
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: envKey)
    }
}
