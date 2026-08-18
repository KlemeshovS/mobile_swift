//
//  BetsManager.swift
//  Wobbly
//
//  Синхронный локальный кэш поверх серверных данных о пари — сам источник истины
//  всегда бэкенд (GET /me/bets), но AchievementManager нужен синхронный доступ
//  к счётчикам побед/поражений/отклонений, поэтому кэшируем последний фетч.
//

import Foundation

final class BetsManager: ObservableObject {
    static let shared = BetsManager()

    @Published private(set) var bets: [Bet] = []
    @Published private(set) var isLoading = false

    private let userDefaults = UserDefaults.standard
    private let seenIncomingIdsKey = "betsSeenIncomingChallengeIds"

    private init() {}

    // MARK: - Загрузка

    @discardableResult
    func refresh() async -> [Bet] {
        await MainActor.run { isLoading = true }
        defer { Task { @MainActor in self.isLoading = false } }

        do {
            let response = try await UserAPIService.shared.getBets()
            await MainActor.run {
                self.bets = response.items
            }
            return response.items
        } catch {
            print("❌ BetsManager: не удалось загрузить пари: \(error)")
            return bets
        }
    }

    // MARK: - Производные списки (для UI)

    var incomingChallenges: [Bet] {
        let myId = AuthStateManager.shared.userId
        return bets.filter { $0.status == .pending && $0.opponent.userId == myId }
    }

    var outgoingPending: [Bet] {
        let myId = AuthStateManager.shared.userId
        return bets.filter { $0.status == .pending && $0.challenger.userId == myId }
    }

    var active: [Bet] {
        bets.filter { $0.status == .active }
    }

    var history: [Bet] {
        // Отменённые (отозванные автором до принятия) не несут ценности в истории —
        // в отличие от отклонённых, которые оставляем как есть.
        bets.filter { $0.status == .resolved && $0.resolutionType != .cancelled }
    }

    // MARK: - Бейдж на вкладке

    private var seenIncomingIds: Set<Int> {
        get {
            let array = userDefaults.array(forKey: seenIncomingIdsKey) as? [Int] ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: seenIncomingIdsKey)
        }
    }

    var hasUnseenIncomingChallenges: Bool {
        let seen = seenIncomingIds
        return incomingChallenges.contains { !seen.contains($0.id) }
    }

    /// Вызывается при открытии вкладки «Пари» — гасит точку-бейдж.
    func markIncomingChallengesSeen() {
        var seen = seenIncomingIds
        for bet in incomingChallenges {
            seen.insert(bet.id)
        }
        seenIncomingIds = seen
    }

    // MARK: - Счётчики для ачивок (синхронные, из последнего refresh())

    var wonCount: Int {
        bets.filter { $0.myOutcome == .won }.count
    }

    var lostCount: Int {
        bets.filter { $0.myOutcome == .lost }.count
    }

    var declinedByMeCount: Int {
        let myId = AuthStateManager.shared.userId
        return bets.filter { $0.resolutionType == .declined && $0.opponent.userId == myId }.count
    }

    var totalCount: Int {
        bets.count
    }

    // MARK: - Действия (обновляют кэш точечно после успешного ответа)

    func createBet(
        opponentUserId: Int,
        betType: BetType,
        durationMode: BetDurationMode,
        durationDays: Int?,
        targetEndDate: String?
    ) async throws -> Bet {
        let bet = try await UserAPIService.shared.createBet(
            opponentUserId: opponentUserId,
            betType: betType,
            durationMode: durationMode,
            durationDays: durationDays,
            targetEndDate: targetEndDate
        )
        await MainActor.run {
            self.bets.insert(bet, at: 0)
        }
        return bet
    }

    func accept(_ bet: Bet) async throws -> Bet {
        try await applyAction { try await UserAPIService.shared.acceptBet(id: bet.id) }
    }

    func decline(_ bet: Bet) async throws -> Bet {
        try await applyAction { try await UserAPIService.shared.declineBet(id: bet.id) }
    }

    func cancel(_ bet: Bet) async throws -> Bet {
        try await applyAction { try await UserAPIService.shared.cancelBet(id: bet.id) }
    }

    func forfeit(_ bet: Bet) async throws -> Bet {
        try await applyAction { try await UserAPIService.shared.forfeitBet(id: bet.id) }
    }

    private func applyAction(_ block: @escaping () async throws -> Bet) async throws -> Bet {
        let updated = try await block()
        await MainActor.run {
            if let index = self.bets.firstIndex(where: { $0.id == updated.id }) {
                self.bets[index] = updated
            } else {
                self.bets.insert(updated, at: 0)
            }
        }
        return updated
    }
}
