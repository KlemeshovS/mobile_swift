//  AppNotificationView.swift
//  Wobbly

import SwiftUI
import Kingfisher

struct AppNotificationView: View {
    let item: AppNotificationItem
    let onDismiss: () -> Void
    let onFollowerTap: ((Int, String, String?) -> Void)?

    @State private var offset: CGFloat = 300
    @State private var opacity: Double = 0

    var body: some View {
        VStack {
            Spacer()
            content
                .offset(y: offset)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        offset = 0
                        opacity = 1
                    }
                    // Автозакрытие через 6 секунд
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                        dismissWithAnimation()
                    }
                }
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var content: some View {
        switch item.type {
        case .achievement(let title, let description, let achievementDescription, let imageName, let isDrinking):
            achievementView(title: title, description: description, achievementDescription: achievementDescription, imageName: imageName, isDrinking: isDrinking)

        case .newFollower(let username, let userId, let avatarUrl):
            followerView(username: username, userId: userId, avatarUrl: avatarUrl)
            
        case .healthSyncProposal(let text, let onAccept, let onDecline):
            healthSyncProposalView(text: text, onAccept: onAccept, onDecline: onDecline)

        case .customMessage(let text):
            customMessageView(text: text)

        case .betEvent(let kind, let bet):
            betEventView(kind: kind, bet: bet)
        }
    }

    private func betEventView(kind: BetEventKind, bet: Bet) -> some View {
        let opponentName = bet.opponentSide.username ?? "?"
        let (icon, title, subtitle, accentColor): (String, String, String, Color) = {
            switch kind {
            case .challenged:
                return (
                    "bolt.fill",
                    NSLocalizedString("notification_bet_challenged_title", comment: ""),
                    String(format: NSLocalizedString("notification_bet_challenged_subtitle", comment: ""), opponentName),
                    Color(hex: "8B5CF6")
                )
            case .accepted:
                return (
                    "checkmark.seal.fill",
                    NSLocalizedString("notification_bet_accepted_title", comment: ""),
                    String(format: NSLocalizedString("notification_bet_accepted_subtitle", comment: ""), opponentName),
                    Color(hex: "C7FF00")
                )
            case .declined:
                return (
                    "xmark.seal.fill",
                    NSLocalizedString("notification_bet_declined_title", comment: ""),
                    String(format: NSLocalizedString("notification_bet_declined_subtitle", comment: ""), opponentName),
                    Color(hex: "FF0072")
                )
            case .expired:
                return (
                    "clock.badge.exclamationmark.fill",
                    NSLocalizedString("notification_bet_expired_title", comment: ""),
                    String(format: NSLocalizedString("notification_bet_expired_subtitle", comment: ""), opponentName),
                    .white.opacity(0.6)
                )
            case .finished:
                let won = bet.myOutcome == .won
                return (
                    won ? "trophy.fill" : "flag.checkered",
                    NSLocalizedString("notification_bet_finished_title", comment: ""),
                    String(format: NSLocalizedString("notification_bet_finished_subtitle", comment: ""), opponentName),
                    won ? Color(hex: "C7FF00") : Color(hex: "FF0072")
                )
            }
        }()

        return HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(accentColor)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(subtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(accentColor.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
        .onTapGesture { dismissWithAnimation() }
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.height > 20 { dismissWithAnimation() }
        })
    }

    private func achievementView(title: String, description: String, achievementDescription: String, imageName: String, isDrinking: Bool) -> some View {
        HStack(spacing: 14) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("notification_achievement_title", comment: ""))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(achievementDescription)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isDrinking ? Color(hex: "FF6B6B") : Color(hex: "C7FF00"))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "C7FF00").opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
        .onTapGesture { dismissWithAnimation() }
        .gesture(DragGesture(minimumDistance: 20).onEnded { value in
            if value.translation.height > 20 { dismissWithAnimation() }
        })
    }
    
    private func followerView(username: String, userId: Int, avatarUrl: String?) -> some View {
        Button(action: {
            onFollowerTap?(userId, username, avatarUrl)
            dismissWithAnimation()
        }) {
            HStack(spacing: 14) {
                let url = makeFullURL(path: avatarUrl)
                if let url = url {
                    KFImage(url)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color(hex: "8B5CF6").opacity(0.4))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 20))
                        )
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("notification_new_follower_title", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text(username)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(hex: "C7FF00"))
                    Text(NSLocalizedString("notification_new_follower_subtitle", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(hex: "8B5CF6").opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 20 {
                        dismissWithAnimation()
                    }
                }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
    }
    
    private func healthSyncProposalView(text: String, onAccept: @escaping () -> Void, onDecline: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "figure.run")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "C7FF00"))
                    .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Apple Health")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 10) {
                Button(action: {
                    onDecline()
                    dismissWithAnimation()
                }) {
                    Text(NSLocalizedString("no_button", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {
                    onAccept()
                    dismissWithAnimation()
                }) {
                    Text(NSLocalizedString("yes_button", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(hex: "C7FF00"))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(LinearGradient(
                    colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "C7FF00").opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 20 { dismissWithAnimation() }
                }
        )
    }
    
    private func customMessageView(text: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.run")
                .font(.system(size: 26))
                .foregroundColor(Color(hex: "C7FF00"))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text("Apple Health")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(hex: "C7FF00").opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
        .padding(.horizontal, 16)
        .padding(.bottom, 30)
        .onTapGesture {
            dismissWithAnimation()
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.height > 20 {
                        dismissWithAnimation()
                    }
                }
        )
    }
    
    private func dismissWithAnimation() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            offset = 300
            opacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            onDismiss()
        }
    }

    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        let base = AppEnvironment.current.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
    }
}
