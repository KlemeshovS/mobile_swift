//
//  BetCardView.swift
//  Wobbly
//
//  Карточка пари в списке: два аватара, имена, иконка между ними, статус.
//

import SwiftUI
import Kingfisher

func betAvatarURL(path: String?) -> URL? {
    guard let path = path else { return nil }
    if path.hasPrefix("http") { return URL(string: path) }
    let base = AppEnvironment.current.baseURL.replacingOccurrences(of: "/api/v1", with: "")
    return URL(string: base + path)
}

struct BetAvatarView: View {
    let username: String?
    let avatarUrl: String?
    let size: CGFloat
    var ringColor: Color? = nil

    var body: some View {
        KFImage(betAvatarURL(path: avatarUrl))
            .placeholder {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .overlay(
                        Text(String((username ?? "?").prefix(1)).uppercased())
                            .font(.system(size: size * 0.4, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(
                Circle().stroke(ringColor ?? Color.white.opacity(0.15), lineWidth: ringColor != nil ? 3 : 1)
            )
    }
}

struct BetCardView: View {
    let bet: Bet

    private var statusColor: Color {
        switch bet.myOutcome {
        case .won: return Color(hex: "C7FF00")
        case .lost: return Color(hex: "FF0072")
        case .draw: return .white.opacity(0.6)
        case .voided: return .white.opacity(0.4)
        case .pending: return Color(hex: "8B5CF6")
        }
    }

    private var statusText: String {
        switch bet.status {
        case .pending:
            return bet.isChallenger
                ? NSLocalizedString("bet_status_awaiting_opponent", comment: "")
                : NSLocalizedString("bet_status_awaiting_you", comment: "")
        case .active:
            return NSLocalizedString("bet_status_active", comment: "")
        case .resolved:
            switch bet.myOutcome {
            case .won: return NSLocalizedString("bet_status_won", comment: "")
            case .lost: return NSLocalizedString("bet_status_lost", comment: "")
            case .draw: return NSLocalizedString("bet_status_draw", comment: "")
            case .voided: return bet.resolutionType == .declined
                ? NSLocalizedString("bet_status_declined", comment: "")
                : bet.resolutionType == .cancelled
                ? NSLocalizedString("bet_status_cancelled", comment: "")
                : NSLocalizedString("bet_status_expired", comment: "")
            case .pending: return ""
            }
        }
    }

    /// Кто сейчас лидирует по live-снапшоту (для активного пари) — красим имена под этот исход.
    private var liveLeader: Bool? {
        guard bet.status == .active,
              let snapshot = bet.liveSnapshot,
              let c = snapshot["challengerValue"]?.intValue,
              let o = snapshot["opponentValue"]?.intValue,
              c != o
        else { return nil }
        let challengerAhead = bet.betType.higherValueLeads ? c > o : c < o
        return challengerAhead
    }

    private func liveValueColor(isChallenger: Bool) -> Color {
        guard let leader = liveLeader else { return .white.opacity(0.7) }
        return leader == isChallenger ? Color(hex: "C7FF00") : .white.opacity(0.4)
    }

    var body: some View {
        HStack(spacing: 14) {
            HStack(spacing: -10) {
                BetAvatarView(
                    username: bet.challenger.username,
                    avatarUrl: bet.challenger.avatarUrl,
                    size: 44,
                    ringColor: bet.status == .resolved && bet.winnerId == bet.challenger.userId ? Color(hex: "C7FF00") : nil
                )
                .opacity(bet.status == .resolved && bet.winnerId == bet.opponent.userId ? 0.4 : 1)
                BetAvatarView(
                    username: bet.opponent.username,
                    avatarUrl: bet.opponent.avatarUrl,
                    size: 44,
                    ringColor: bet.status == .resolved && bet.winnerId == bet.opponent.userId ? Color(hex: "C7FF00") : nil
                )
                .opacity(bet.status == .resolved && bet.winnerId == bet.challenger.userId ? 0.4 : 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("\(bet.challenger.username ?? "?") vs \(bet.opponent.username ?? "?")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(bet.betType.localizedTitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))

                if let snapshot = bet.liveSnapshot,
                   let c = snapshot["challengerValue"]?.displayString,
                   let o = snapshot["opponentValue"]?.displayString {
                    HStack(spacing: 4) {
                        Text(c)
                            .fontWeight(liveLeader == true ? .bold : .regular)
                            .foregroundColor(liveValueColor(isChallenger: true))
                        Text(":")
                            .foregroundColor(.white.opacity(0.3))
                        Text(o)
                            .fontWeight(liveLeader == false ? .bold : .regular)
                            .foregroundColor(liveValueColor(isChallenger: false))
                    }
                    .font(.system(size: 12))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(statusText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(statusColor)
                    .multilineTextAlignment(.trailing)

                if let remaining = bet.daysRemaining {
                    Text("\(remaining) \(betDaysWord(remaining))")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
