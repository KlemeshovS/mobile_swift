//
//  AuthStateManager.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 11.04.26.
//

import Foundation

enum SessionType {
    case guest
    case authenticated
}

class AuthStateManager {
    static let shared = AuthStateManager()
    
    private let defaults = UserDefaults.standard
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    private let userIdKey = "userId"
    private let sessionTypeKey = "sessionType"
    
    private init() {}
    
    var accessToken: String? {
        get { defaults.string(forKey: accessTokenKey) }
        set { defaults.set(newValue, forKey: accessTokenKey) }
    }
    
    var refreshToken: String? {
        get { defaults.string(forKey: refreshTokenKey) }
        set { defaults.set(newValue, forKey: refreshTokenKey) }
    }
    
    var userId: Int? {
        get { defaults.object(forKey: userIdKey) as? Int }
        set { defaults.set(newValue, forKey: userIdKey) }
    }
    
    var sessionType: SessionType {
        get {
            let str = defaults.string(forKey: sessionTypeKey) ?? "guest"
            return str == "authenticated" ? .authenticated : .guest
        }
        set {
            defaults.set(newValue == .authenticated ? "authenticated" : "guest", forKey: sessionTypeKey)
        }
    }
    
    func saveGuestSession(accessToken: String, userId: Int) {
        self.accessToken = accessToken
        self.refreshToken = nil
        self.userId = userId
        self.sessionType = .guest
    }
    
    func saveAuthenticatedSession(accessToken: String, refreshToken: String, userId: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userId = userId
        self.sessionType = .authenticated
    }
    
    func updateTokens(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    
    func clear() {
        accessToken = nil
        refreshToken = nil
        userId = nil
        sessionType = .guest
    }
}
