//
//  BetDetailView.swift
//  Wobbly
//
//  Детали одного пари + действия (принять/отклонить/отменить/слиться).
//

import SwiftUI

struct BetDetailView: View {
    let betId: Int

    @Environment(\.dismiss) private var dismiss
    @State private var bet: Bet?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isPerformingAction = false
    @State private var showForfeitConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1A1830"), Color(hex: "2D2B55")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if isLoading {
                    ProgressView().tint(.white)
                } else if let bet = bet {
                    content(for: bet)
                } else {
                    Text(errorMessage ?? NSLocalizedString("bets_detail_load_error", comment: ""))
                        .foregroundColor(.white.opacity(0.7))
                        .padding()
                }
            }
            .navigationTitle(NSLocalizedString("bets_detail_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("close_button", comment: "")) { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
                if let bet = bet {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Text(statusText(bet))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(statusColor(bet))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await load() }
    }

    private func content(for bet: Bet) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack(spacing: 24) {
                    participantColumn(bet.challenger, isWinner: bet.winnerId == bet.challenger.userId)
                    PulsingBoltView()
                    participantColumn(bet.opponent, isWinner: bet.winnerId == bet.opponent.userId)
                }
                .padding(.top, 12)

                infoCard(bet)

                if let snapshot = bet.resultSnapshot, !snapshot.isEmpty {
                    resultCard(bet: bet, snapshot: snapshot)
                } else if bet.status == .active, let live = bet.liveSnapshot, !live.isEmpty {
                    liveScoreCard(bet: bet, snapshot: live)
                }

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "FF0072"))
                }

                actions(for: bet)
            }
            .padding(16)
        }
    }

    private func participantColumn(_ participant: BetParticipant, isWinner: Bool) -> some View {
        VStack(spacing: 6) {
            BetAvatarView(
                username: participant.username,
                avatarUrl: participant.avatarUrl,
                size: 64,
                ringColor: isWinner ? Color(hex: "C7FF00") : nil
            )
            .padding(.top, 4)
            Text(participant.username ?? "—")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            if isWinner {
                Text(NSLocalizedString("bets_detail_winner_badge", comment: ""))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(hex: "C7FF00"))
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func infoCard(_ bet: Bet) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(bet.betType.localizedTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            Text(bet.betType.conditionDescription)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.6))

            Divider().background(Color.white.opacity(0.1))

            infoRow(durationLabel(bet), durationText(bet))
            if bet.status == .active, let remaining = bet.daysRemaining {
                infoRow(NSLocalizedString("bets_detail_days_remaining", comment: ""), "\(remaining) \(betDaysWord(remaining))")
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.07)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.12), lineWidth: 1))
    }

    private func resultCard(bet: Bet, snapshot: [String: AnyCodableValue]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("bets_detail_result", comment: ""))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
            HStack {
                Text(bet.challenger.username ?? "—")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(snapshot["challengerValue"]?.displayString ?? "—")
                    .foregroundColor(.white)
            }
            HStack {
                Text(bet.opponent.username ?? "—")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(snapshot["opponentValue"]?.displayString ?? "—")
                    .foregroundColor(.white)
            }
        }
        .font(.system(size: 14))
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
    }

    private func liveScoreCard(bet: Bet, snapshot: [String: AnyCodableValue]) -> some View {
        let cVal = snapshot["challengerValue"]?.intValue
        let oVal = snapshot["opponentValue"]?.intValue
        let challengerLeads: Bool? = {
            guard let c = cVal, let o = oVal, c != o else { return nil }
            return bet.betType.higherValueLeads ? c > o : c < o
        }()
        func color(isChallenger: Bool) -> Color {
            guard let challengerLeads = challengerLeads else { return .white }
            return challengerLeads == isChallenger ? Color(hex: "C7FF00") : .white.opacity(0.4)
        }
        func weight(isChallenger: Bool) -> Font.Weight {
            challengerLeads == isChallenger ? .bold : .regular
        }

        return VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("bets_detail_live_score", comment: ""))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
            HStack {
                Text(bet.challenger.username ?? "—")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(snapshot["challengerValue"]?.displayString ?? "—")
                    .fontWeight(weight(isChallenger: true))
                    .foregroundColor(color(isChallenger: true))
            }
            HStack {
                Text(bet.opponent.username ?? "—")
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text(snapshot["opponentValue"]?.displayString ?? "—")
                    .fontWeight(weight(isChallenger: false))
                    .foregroundColor(color(isChallenger: false))
            }
        }
        .font(.system(size: 14))
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.05)))
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value).foregroundColor(.white)
        }
        .font(.system(size: 13))
    }

    @ViewBuilder
    private func actions(for bet: Bet) -> some View {
        VStack(spacing: 10) {
            if bet.status == .pending && !bet.isChallenger {
                actionButton(NSLocalizedString("bets_action_accept", comment: ""), style: .primary) {
                    await perform { try await BetsManager.shared.accept(bet) }
                }
                actionButton(NSLocalizedString("bets_action_decline", comment: ""), style: .destructive) {
                    await perform { try await BetsManager.shared.decline(bet) }
                }
            } else if bet.status == .pending && bet.isChallenger {
                actionButton(NSLocalizedString("bets_action_cancel", comment: ""), style: .destructive) {
                    await perform { try await BetsManager.shared.cancel(bet) }
                }
            } else if bet.status == .active {
                Button {
                    showForfeitConfirm = true
                } label: {
                    Text(NSLocalizedString("bets_action_forfeit", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "FF0072"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "FF0072"), lineWidth: 1))
                }
                .confirmationDialog(
                    NSLocalizedString("bets_forfeit_confirm_title", comment: ""),
                    isPresented: $showForfeitConfirm,
                    titleVisibility: .visible
                ) {
                    Button(NSLocalizedString("bets_action_forfeit", comment: ""), role: .destructive) {
                        Task { await perform { try await BetsManager.shared.forfeit(bet) } }
                    }
                    Button(NSLocalizedString("cancel", comment: ""), role: .cancel) {}
                }
            }
        }
    }

    private enum ButtonStyleKind { case primary, destructive }

    private func actionButton(_ title: String, style: ButtonStyleKind, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            if isPerformingAction {
                ProgressView().tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            } else {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(style == .primary ? Color(hex: "2D2B55") : .white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(style == .primary ? Color.white : Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
        .disabled(isPerformingAction)
    }

    private func durationLabel(_ bet: Bet) -> String {
        bet.durationMode == .period
            ? NSLocalizedString("bet_duration_mode_period", comment: "")
            : NSLocalizedString("bets_detail_duration", comment: "")
    }

    private func durationText(_ bet: Bet) -> String {
        if bet.durationMode == .period, let days = bet.durationDays {
            return String(format: NSLocalizedString("bets_duration_days_format", comment: ""), days)
        } else if let targetEndDate = bet.targetEndDate {
            return formatBetDate(targetEndDate)
        }
        return "—"
    }

    private func statusColor(_ bet: Bet) -> Color {
        switch bet.myOutcome {
        case .won: return Color(hex: "C7FF00")
        case .lost: return Color(hex: "FF0072")
        case .draw: return .white.opacity(0.6)
        case .voided: return .white.opacity(0.4)
        case .pending: return Color(hex: "8B5CF6")
        }
    }

    private func statusText(_ bet: Bet) -> String {
        switch bet.status {
        case .pending: return NSLocalizedString("bet_status_pending", comment: "")
        case .active: return NSLocalizedString("bet_status_active", comment: "")
        case .resolved:
            switch bet.resolutionType {
            case .declined: return NSLocalizedString("bet_status_declined", comment: "")
            case .cancelled: return NSLocalizedString("bet_status_cancelled", comment: "")
            case .expired: return NSLocalizedString("bet_status_expired", comment: "")
            case .forfeit: return NSLocalizedString("bet_status_forfeit", comment: "")
            case .natural, .none: return NSLocalizedString("bet_status_resolved", comment: "")
            }
        }
    }

    private func load() async {
        isLoading = true
        do {
            bet = try await UserAPIService.shared.getBet(id: betId)
        } catch {
            errorMessage = (error as? UserAPIError)?.errorDescription ?? NSLocalizedString("bets_detail_load_error", comment: "")
        }
        isLoading = false
    }

    private func perform(_ block: @escaping () async throws -> Bet) async {
        isPerformingAction = true
        errorMessage = nil
        do {
            bet = try await block()
        } catch {
            errorMessage = (error as? UserAPIError)?.errorDescription ?? NSLocalizedString("bets_create_generic_error", comment: "")
        }
        isPerformingAction = false
    }
}
