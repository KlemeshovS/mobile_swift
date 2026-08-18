//
//  BetModels.swift
//  Wobbly
//
//  Пари между взаимными друзьями. Победитель считается на бэкенде — эти модели
//  только отражают серверное состояние, никакой локальной логики резолюшна нет.
//

import Foundation

enum BetType: String, CaseIterable, Codable {
    case sobriety
    case sport
    case scoreUp = "score_up"
    case scoreDown = "score_down"

    var localizedTitle: String {
        switch self {
        case .sobriety: return NSLocalizedString("bet_type_sobriety_title", comment: "")
        case .sport: return NSLocalizedString("bet_type_sport_title", comment: "")
        case .scoreUp: return NSLocalizedString("bet_type_score_up_title", comment: "")
        case .scoreDown: return NSLocalizedString("bet_type_score_down_title", comment: "")
        }
    }

    /// Текстовое описание, как определяется победитель — показывается при выборе типа.
    var conditionDescription: String {
        switch self {
        case .sobriety: return NSLocalizedString("bet_type_sobriety_condition", comment: "")
        case .sport: return NSLocalizedString("bet_type_sport_condition", comment: "")
        case .scoreUp: return NSLocalizedString("bet_type_score_up_condition", comment: "")
        case .scoreDown: return NSLocalizedString("bet_type_score_down_condition", comment: "")
        }
    }

    /// Для live-снапшота: у кого больше значение — тот сейчас лидирует.
    /// Для scoreDown («кто больше пьёт») побеждает меньшее значение, поэтому false.
    var higherValueLeads: Bool {
        switch self {
        case .scoreDown: return false
        case .sobriety, .sport, .scoreUp: return true
        }
    }
}

enum BetDurationMode: String, Codable {
    case period
    case fixedDate = "fixed_date"
}

enum BetStatus: String, Codable {
    case pending
    case active
    case resolved
}

enum BetResolutionType: String, Codable {
    case declined
    case cancelled
    case expired
    case natural
    case forfeit
}

struct BetParticipant: Codable, Equatable {
    let userId: Int
    let username: String?
    let avatarUrl: String?
}

struct BetResultSnapshot: Codable, Equatable {
    let challengerValue: AnyCodableValue?
    let opponentValue: AnyCodableValue?
}

/// Значение из resultSnapshot может быть числом (sport/score) или строкой-датой (sobriety) —
/// сервер отдаёт то, что вернул конкретный резолвер типа пари.
enum AnyCodableValue: Codable, Equatable {
    case int(Int)
    case string(String)
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .int(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }

    var displayString: String {
        switch self {
        case .int(let value): return "\(value)"
        case .string(let value): return value
        case .null: return "—"
        }
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }
}

struct Bet: Codable, Identifiable, Equatable {
    let id: Int
    let challenger: BetParticipant
    let opponent: BetParticipant
    let betType: BetType
    let durationMode: BetDurationMode
    let durationDays: Int?
    let targetEndDate: String?
    let status: BetStatus
    let resolutionType: BetResolutionType?
    let winnerId: Int?
    let forfeitedBy: Int?
    let respondBy: String
    let startAt: String?
    let endAt: String?
    let resultSnapshot: [String: AnyCodableValue]?
    let liveSnapshot: [String: AnyCodableValue]?
    let createdAt: String
    let acceptedAt: String?
    let resolvedAt: String?

    var isChallenger: Bool {
        challenger.userId == AuthStateManager.shared.userId
    }

    var opponentSide: BetParticipant {
        isChallenger ? opponent : challenger
    }

    var myOutcome: BetOutcomeForUser {
        guard status == .resolved else { return .pending }
        guard let winnerId = winnerId else {
            // Ничья, либо исход без победителя (declined/cancelled/expired)
            if resolutionType == .declined || resolutionType == .cancelled || resolutionType == .expired {
                return .voided
            }
            return .draw
        }
        let myId = AuthStateManager.shared.userId
        return winnerId == myId ? .won : .lost
    }
}

enum BetOutcomeForUser {
    case pending
    case won
    case lost
    case draw
    case voided // declined/cancelled/expired — пари не сыграло
}

struct BetListResponse: Codable {
    let items: [Bet]
    let total: Int
}
