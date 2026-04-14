import Foundation

class SessionManager {
    static let shared = SessionManager()
    private let userDefaults = UserDefaults.standard
    private let tokenKey = "accessToken"
    private let userIdKey = "userId"

    var accessToken: String? {
        get { userDefaults.string(forKey: tokenKey) }
        set { userDefaults.set(newValue, forKey: tokenKey) }
    }

    var userId: Int? {
        get { userDefaults.object(forKey: userIdKey) as? Int }
        set { userDefaults.set(newValue, forKey: userIdKey) }
    }

    func clear() {
        accessToken = nil
        userId = nil
    }
}
