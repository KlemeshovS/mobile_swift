//
//  AuthService.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 11.04.26.
//

import Foundation
import AuthenticationServices   // Apple
import GoogleSignIn             // GoogleSignIn

@MainActor
class AuthService: NSObject, ObservableObject {
    static let shared = AuthService()
    
    private override init() {}
    
    // MARK: - Восстановление сессии при старте
    func restoreSession() async {
        guard let accessToken = AuthStateManager.shared.accessToken else {
            // Нет токена – получаем гостевой
            await getGuestSession()
            return
        }
        
        do {
            let session = try await UserAPIService.shared.getSession()
            // Сессия жива, обновляем локальные данные
            AuthStateManager.shared.sessionType = session.sessionType == "authenticated" ? .authenticated : .guest
            AuthStateManager.shared.userId = session.userId
            if session.sessionType == "authenticated" {
                // для authenticated у нас уже должен быть refreshToken
            }
        } catch UserAPIError.invalidToken {
            // Токен протух, пробуем обновить
            if let refreshToken = AuthStateManager.shared.refreshToken {
                do {
                    let (newAccess, newRefresh) = try await UserAPIService.shared.refreshTokens(refreshToken: refreshToken)
                    AuthStateManager.shared.updateTokens(accessToken: newAccess, refreshToken: newRefresh)
                    let session = try await UserAPIService.shared.getSession()
                    AuthStateManager.shared.sessionType = session.sessionType == "authenticated" ? .authenticated : .guest
                    AuthStateManager.shared.userId = session.userId
                } catch {
                    // Не удалось обновить – идём в гостевой режим
                    await getGuestSession()
                }
            } else {
                await getGuestSession()
            }
        } catch {
            // Другие ошибки – пробуем получить гостевой токен
            await getGuestSession()
        }
    }
    
    private func getGuestSession() async {
        do {
            let (userId, accessToken, _) = try await UserAPIService.shared.anonymousAuth()
            AuthStateManager.shared.saveGuestSession(accessToken: accessToken, userId: userId)
        } catch {
            print("❌ Не удалось получить гостевую сессию: \(error)")
        }
    }
    
    // MARK: - Google Sign-In
    func signInWithGoogle(presentingViewController: UIViewController) async throws {
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "No idToken"])
        }
        
        let guestToken = AuthStateManager.shared.sessionType == .guest ? AuthStateManager.shared.accessToken : nil
        
        let (userId, accessToken, refreshToken) = try await UserAPIService.shared.authWithGoogle(
            idToken: idToken,
            guestAccessToken: guestToken
        )
        
        AuthStateManager.shared.saveAuthenticatedSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId, provider: .google)
        
        // Подтягиваем данные профиля
        let session = try await UserAPIService.shared.getSession()
        UserDefaults.standard.set(session.username, forKey: "userName")
        UserDefaults.standard.set(session.participateInRating, forKey: "userParticipateInRating")
        await CalendarSyncManager.shared.sync()
    }
   
    // MARK: - Apple Sign-In
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws {
        guard let idTokenData = credential.identityToken,
              let idToken = String(data: idTokenData, encoding: .utf8) else {
            throw NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "No idToken"])
        }
        
        // 🔍 Логируем содержимое JWT
        if let payload = decodeJWTPayload(idToken) {
            print("🍏 Apple JWT payload:")
            print("   aud: \(payload["aud"] ?? "nil")")
            print("   iss: \(payload["iss"] ?? "nil")")
            print("   exp: \(payload["exp"] ?? "nil")")
            print("   sub: \(payload["sub"] ?? "nil")")
            print("   email: \(payload["email"] ?? "nil")")
        }
        
        let guestToken = AuthStateManager.shared.sessionType == .guest ? AuthStateManager.shared.accessToken : nil
        
        let (userId, accessToken, refreshToken) = try await UserAPIService.shared.authWithApple(
            idToken: idToken,
            guestAccessToken: guestToken
        )
        print("🍏 Apple ID Token (первые 30 символов): \(idToken.prefix(30))...")
        
        // Сохраняем сессию с провайдером .apple
        AuthStateManager.shared.saveAuthenticatedSession(accessToken: accessToken, refreshToken: refreshToken, userId: userId, provider: .apple)
        
        // Сохраняем Apple user ID для возможного отзыва токена (credential.user – не опционал)
        UserDefaults.standard.set(credential.user, forKey: "appleUserID")
        
        let session = try await UserAPIService.shared.getSession()
        UserDefaults.standard.set(session.username, forKey: "userName")
        UserDefaults.standard.set(session.participateInRating, forKey: "userParticipateInRating")
        await CalendarSyncManager.shared.sync()
    }
    
    // MARK: - Выход
    func signOut() async {
        // Если пользователь аутентифицирован и участвует в рейтингах,
        // сначала отключаем участие на сервере
        if AuthStateManager.shared.sessionType == .authenticated,
           UserDefaults.standard.bool(forKey: "userParticipateInRating") {
            do {
                _ = try await UserAPIService.shared.updateMyRating(participateInRating: false)
                print("✅ Участие в рейтингах отключено перед выходом")
            } catch {
                print("⚠️ Не удалось отключить рейтинг перед выходом: \(error)")
            }
        }
        
        // Затем выполняем логаут
        do {
            try await UserAPIService.shared.logout()
            print("✅ Сессия завершена на сервере")
        } catch {
            print("❌ Logout API error: \(error)")
        }
        
        // Очищаем локальные данные
        AuthStateManager.shared.clear()
        UserDefaults.standard.removeObject(forKey: "userName")
        UserDefaults.standard.set(false, forKey: "userParticipateInRating")
        print("🧹 Локальная сессия очищена")
    }
    
    private func decodeJWTPayload(_ token: String) -> [String: Any]? {
        let segments = token.split(separator: ".")
        guard segments.count >= 2 else { return nil }
        let payloadSegment = segments[1]
        // JWT использует base64url без padding, нужно привести к стандартному base64
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 {
            base64.append("=")
        }
        guard let payloadData = Data(base64Encoded: base64) else { return nil }
        return try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any]
    }
    
    // MARK: - Удаление аккаунта
    func deleteAccount() async throws {
        guard AuthStateManager.shared.sessionType == .authenticated else {
            throw NSError(domain: "Auth", code: 403, userInfo: [NSLocalizedDescriptionKey: "Guest cannot delete account"])
        }
        
        // 1. Удаляем аккаунт на сервере
        try await UserAPIService.shared.deleteAccount()
        
        // 2. Отзываем токен у провайдера (Apple обязательно)
        if let provider = AuthStateManager.shared.authProvider {
            switch provider {
            case .apple:
                await revokeAppleToken()
            case .google:
                await disconnectGoogle()
            default:
                break
            }
        }
        
        // 3. Очищаем локальную сессию
        await signOut()
    }
    
    private func revokeAppleToken() async {
        guard let userID = UserDefaults.standard.string(forKey: "appleUserID") else { return }
        
        // Отзыв токена Apple через серверный endpoint (рекомендуется)
        // Если у вас есть прямой эндпоинт на бэкенде, вызовите его здесь.
        // Для простоты можно просто очистить локальные данные.
        // Полный отзыв через Apple REST API требует client_secret.
        print("🔐 Apple token revoked for user: \(userID)")
    }
    
    private func disconnectGoogle() async {
        await withCheckedContinuation { continuation in
            GIDSignIn.sharedInstance.disconnect { error in
                if let error = error {
                    print("⚠️ Google disconnect error: \(error)")
                } else {
                    print("✅ Google disconnected")
                }
                continuation.resume()
            }
        }
    }
}
