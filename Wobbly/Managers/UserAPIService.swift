//
//  UserAPIService.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [12.04.2026].
//

import Foundation

// MARK: - Модели ошибок в новом формате
struct APIErrorResponse: Codable {
    let code: String
    let message: String
}

// MARK: - Новые модели ответов
struct SessionResponse: Codable {
    let userId: Int
    let username: String?
    let participateInRating: Bool
    let sessionType: String          // "guest" или "authenticated"
    let provider: String?            // "google", "apple", "yandex" или nil
}

struct RefreshResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let tokenType: String
}

enum UserAPIError: Error, LocalizedError {
    case missingAuthorizationHeader
    case invalidAuthorizationHeader
    case invalidToken
    case usernameAlreadyExists
    case usernameRequiredForRating
    case userNotFound
    case rateLimitExceeded
    case validationError
    case internalServerError
    case networkError(Error)
    case invalidResponse
    case unknownError(code: String, message: String)
    case missingTokenLocally
    case serverError(statusCode: Int)
    case invalidRefreshToken
    case googleAuthInvalid
    case appleAuthInvalid
    case authRequiredForRating
    case ratingDisabledForScore
    
    var errorDescription: String? {
        switch self {
        case .missingAuthorizationHeader:
            return NSLocalizedString("error_missing_auth_header", comment: "")
        case .invalidAuthorizationHeader:
            return NSLocalizedString("error_invalid_auth_header", comment: "")
        case .invalidToken:
            return NSLocalizedString("error_invalid_token", comment: "")
        case .usernameAlreadyExists:
            return NSLocalizedString("error_username_already_exists", comment: "")
        case .usernameRequiredForRating:
            return NSLocalizedString("error_username_required_for_rating", comment: "")
        case .userNotFound:
            return NSLocalizedString("error_user_not_found", comment: "")
        case .rateLimitExceeded:
            return NSLocalizedString("error_too_many_requests", comment: "")
        case .validationError:
            return NSLocalizedString("error_invalid_payload", comment: "")
        case .internalServerError:
            return NSLocalizedString("error_server", comment: "")
        case .networkError(let error):
            return String(format: NSLocalizedString("error_network", comment: ""), error.localizedDescription)
        case .invalidResponse:
            return NSLocalizedString("error_invalid_response", comment: "")
        case .unknownError(let code, let message):
            return "\(code): \(message)"
        case .missingTokenLocally:
            return NSLocalizedString("error_missing_token", comment: "")
        case .serverError(let code):
            return String(format: NSLocalizedString("error_server", comment: ""), code)
        case .invalidRefreshToken:
            return NSLocalizedString("error_invalid_refresh_token", comment: "")
        case .googleAuthInvalid:
            return NSLocalizedString("error_google_auth_invalid", comment: "")
        case .appleAuthInvalid:
            return NSLocalizedString("error_apple_auth_invalid", comment: "")
        case .authRequiredForRating:
            return NSLocalizedString("error_auth_required_for_rating", comment: "")
        case .ratingDisabledForScore:
            return NSLocalizedString("error_rating_disabled_for_score", comment: "")
        }
    }
}

// MARK: - Модели для ответов API (camelCase)
struct AnonymousAuthResponse: Codable {
    let userId: Int
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
}

struct MeResponse: Codable {
    let id: Int
    let username: String?
    let participateInRating: Bool
}

// Для удобства использования в приложении
struct MyProfileResponse {
    let id: Int
    let username: String?
    let participateInRating: Bool
}

struct ScoreResponse: Codable {
    let username: String
    let score: Int
}

// MARK: - Leaderboard models
struct LeaderboardItem: Codable, Identifiable {
    let username: String
    let score: Int

    var id: String { username }
}

struct LeaderboardResponse: Codable {
    let items: [LeaderboardItem]
    let total: Int
}

// MARK: - Основной сервис
class UserAPIService {
    static let shared = UserAPIService()
    private var baseURL: String { AppEnvironment.current.baseURL }
    private let session = URLSession.shared
    
    private init() {}
    
    // MARK: - Новые методы авторизации
//1111111
    /// Получить текущую сессию (проверка валидности токена)
    func getSession() async throws -> SessionResponse {
        let token = try requireToken()
        guard let url = URL(string: "\(baseURL)/auth/session") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        configureRequest(&request)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            return try JSONDecoder().decode(SessionResponse.self, from: data)
        case 401:
            throw UserAPIError.invalidToken
        default:
            throw handleAPIError(data: data, response: httpResponse)
        }
    }
    
    private func performAuthenticatedRequest<T>(_ requestBlock: @escaping (String) async throws -> T) async throws -> T {
        guard let token = AuthStateManager.shared.accessToken else {
            throw UserAPIError.missingTokenLocally
        }
        do {
            return try await requestBlock(token)
        } catch UserAPIError.invalidToken {
            // Пробуем обновить
            guard let refreshToken = AuthStateManager.shared.refreshToken else {
                throw UserAPIError.invalidToken
            }
            let (newAccess, newRefresh) = try await refreshTokens(refreshToken: refreshToken)
            AuthStateManager.shared.updateTokens(accessToken: newAccess, refreshToken: newRefresh)
            // Повторяем запрос с новым токеном
            return try await requestBlock(newAccess)
        }
    }

    /// Обновить токены
    func refreshTokens(refreshToken: String) async throws -> (accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/auth/refresh") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        configureRequest(&request)
        let body = ["refreshToken": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200:
            let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
            return (decoded.accessToken, decoded.refreshToken)
        case 401:
            throw UserAPIError.invalidRefreshToken
        default:
            throw handleAPIError(data: data, response: httpResponse)
        }
    }

    /// Выход
    func logout() async throws {
        guard let token = AuthStateManager.shared.accessToken else { return }
        guard let url = URL(string: "\(baseURL)/auth/logout") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        configureRequest(&request)
        
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserAPIError.invalidResponse
        }
        if httpResponse.statusCode != 200 {
            throw UserAPIError.serverError(statusCode: httpResponse.statusCode)
        }
    }

    /// Google авторизация
    func authWithGoogle(idToken: String, guestAccessToken: String?) async throws -> (userId: Int, accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/auth/google") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let guestToken = guestAccessToken {
            request.setValue("Bearer \(guestToken)", forHTTPHeaderField: "Authorization")
        }
        configureRequest(&request)
        let body = ["idToken": idToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200, 201:
            let decoded = try JSONDecoder().decode(AnonymousAuthResponse.self, from: data)
            // Важно: бэкенд теперь возвращает refreshToken в этом ответе!
            return (decoded.userId, decoded.accessToken, decoded.refreshToken ?? "")
        default:
            throw handleAPIError(data: data, response: httpResponse)
        }
    }

    /// Apple авторизация
    func authWithApple(idToken: String, guestAccessToken: String?) async throws -> (userId: Int, accessToken: String, refreshToken: String) {
        guard let url = URL(string: "\(baseURL)/auth/apple") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let guestToken = guestAccessToken {
            request.setValue("Bearer \(guestToken)", forHTTPHeaderField: "Authorization")
        }
        configureRequest(&request)
        let body = ["idToken": idToken]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw UserAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200, 201:
            let decoded = try JSONDecoder().decode(AnonymousAuthResponse.self, from: data)
            return (decoded.userId, decoded.accessToken, decoded.refreshToken ?? "")
        default:
            throw handleAPIError(data: data, response: httpResponse)
        }
    }
    
    private func configureRequest(_ request: inout URLRequest) {
        request.setValue("ios", forHTTPHeaderField: "X-Client-Platform")

        if AppEnvironment.current.requiresStagingKey {
            if let key = AppEnvironment.stagingKey {
                request.setValue(key, forHTTPHeaderField: "X-Staging-Key")
                print("✅ Отправляю X-Staging-Key: \(key)")
            } else {
                print("❌ ОШИБКА: STAGING_API_KEY не задан в переменных окружения!")
            }
        } else {
            print("ℹ️ Режим production, ключ не нужен")
        }
    }
    
    private func requireToken() throws -> String {
        guard let token = AuthStateManager.shared.accessToken else {
            throw UserAPIError.missingTokenLocally
        }
        return token
    }
    
    // MARK: - Обработка ошибок в новом формате
    private func handleAPIError(data: Data, response: HTTPURLResponse) -> Error {
        // Пытаемся распарсить стандартный ответ об ошибке
        if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            switch errorResponse.code {
            case "MISSING_AUTHORIZATION_HEADER":
                return UserAPIError.missingAuthorizationHeader
            case "INVALID_AUTHORIZATION_HEADER":
                return UserAPIError.invalidAuthorizationHeader
            case "INVALID_TOKEN":
                return UserAPIError.invalidToken
            case "USERNAME_ALREADY_EXISTS":
                return UserAPIError.usernameAlreadyExists
            case "USERNAME_REQUIRED_FOR_RATING":
                return UserAPIError.usernameRequiredForRating
            case "USER_NOT_FOUND":
                return UserAPIError.userNotFound
            case "RATE_LIMIT_EXCEEDED":
                return UserAPIError.rateLimitExceeded
            case "VALIDATION_ERROR":
                return UserAPIError.validationError
            case "INTERNAL_SERVER_ERROR":
                return UserAPIError.internalServerError
            default:
                return UserAPIError.unknownError(code: errorResponse.code, message: errorResponse.message)
            }
        }
        // Если не удалось распарсить, возвращаем ошибку по статус-коду
        return UserAPIError.serverError(statusCode: response.statusCode)
    }
    
    // MARK: - 1. Анонимная авторизация
    func anonymousAuth() async throws -> (userId: Int, accessToken: String, refreshToken: String?) {
        guard let url = URL(string: "\(baseURL)/auth/anonymous") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        configureRequest(&request)

        request.httpBody = try JSONEncoder().encode([String: String]())

        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200, 201:
                let decoded = try JSONDecoder().decode(AnonymousAuthResponse.self, from: data)
                AuthStateManager.shared.saveGuestSession(accessToken: decoded.accessToken, userId: decoded.userId)
                return (decoded.userId, decoded.accessToken, decoded.refreshToken)
            default:
                throw handleAPIError(data: data, response: httpResponse)
            }
        } catch let error as UserAPIError {
            throw error
        } catch {
            throw UserAPIError.networkError(error)
        }
    }
    
    
    // MARK: - 2. Получение профиля
    func getMyProfile() async throws -> MyProfileResponse {
        return try await performAuthenticatedRequest { token in
            print("📤 getMyProfile: используем токен: \(token.prefix(10))...")
            guard let url = URL(string: "\(self.baseURL)/me") else {
                throw UserAPIError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            self.configureRequest(&request)
            
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)
                return MyProfileResponse(id: decoded.id, username: decoded.username, participateInRating: decoded.participateInRating)
            case 401:
                throw UserAPIError.invalidToken
            default:
                throw self.handleAPIError(data: data, response: httpResponse)
            }
        }
    }
    
    // MARK: - 3. Обновление профиля (имя + участие)
    func updateMyProfile(username: String?, participateInRating: Bool) async throws -> MyProfileResponse {
        return try await performAuthenticatedRequest { token in
            guard let url = URL(string: "\(self.baseURL)/me/profile") else {
                throw UserAPIError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.configureRequest(&request)
            
            let body: [String: Any] = [
                "username": username as Any,
                "participateInRating": participateInRating
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)
                return MyProfileResponse(id: decoded.id, username: decoded.username, participateInRating: decoded.participateInRating)
            case 401:
                throw UserAPIError.invalidToken
            default:
                throw self.handleAPIError(data: data, response: httpResponse)
            }
        }
    }
    
    
    // MARK: - 4. Обновление только участия в рейтинге
    func updateMyRating(participateInRating: Bool) async throws -> MyProfileResponse {
        return try await performAuthenticatedRequest { token in
            guard let url = URL(string: "\(self.baseURL)/me/rating") else {
                throw UserAPIError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.configureRequest(&request)
            
            let body = ["participateInRating": participateInRating]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(MeResponse.self, from: data)
                return MyProfileResponse(id: decoded.id, username: decoded.username, participateInRating: decoded.participateInRating)
            case 401:
                throw UserAPIError.invalidToken
            default:
                throw self.handleAPIError(data: data, response: httpResponse)
            }
        }
    }
    
    // MARK: - 5. Отправка счёта
    func updateMyScore(score: Int) async throws -> (username: String, score: Int) {
        return try await performAuthenticatedRequest { token in
            guard let url = URL(string: "\(self.baseURL)/me/score") else {
                throw UserAPIError.invalidResponse
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            self.configureRequest(&request)
            
            let body = ["score": score]
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await self.session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(ScoreResponse.self, from: data)
                return (decoded.username, decoded.score)
            case 401:
                throw UserAPIError.invalidToken
            default:
                throw self.handleAPIError(data: data, response: httpResponse)
            }
        }
    }
    
    // MARK: - Leaderboard methods (публичные, токен не нужен)
    func fetchTop100() async throws -> [LeaderboardItem] {
        guard let url = URL(string: "\(baseURL)/leaderboard/top?limit=100") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        configureRequest(&request)   // важно для staging
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(LeaderboardResponse.self, from: data)
                return decoded.items
            default:
                throw handleAPIError(data: data, response: httpResponse)
            }
        } catch {
            throw UserAPIError.networkError(error)
        }
    }
    
    func fetchBottom100() async throws -> [LeaderboardItem] {
        guard let url = URL(string: "\(baseURL)/leaderboard/bottom?limit=100") else {
            throw UserAPIError.invalidResponse
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        configureRequest(&request)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw UserAPIError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoded = try JSONDecoder().decode(LeaderboardResponse.self, from: data)
                return decoded.items
            default:
                throw handleAPIError(data: data, response: httpResponse)
            }
        } catch {
            throw UserAPIError.networkError(error)
        }
    }
}
