//
//  BetsTabView.swift
//  Wobbly
//
//  Главный экран вкладки «Пари»: входящие вызовы, активные пари, история.
//

import SwiftUI

struct BetsTabView: View {
    @ObservedObject private var betsManager = BetsManager.shared
    @State private var showCreateBet = false
    @State private var selectedBet: Bet?

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1A1830"), Color(hex: "2D2B55")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // ВРЕМЕННО: всегда list (не emptyState), чтобы секция превью снизу
                // была видна даже при пустом bets — уберётся вместе с debugPreviewSection.
                list
            }
            .navigationTitle(NSLocalizedString("bets_tab_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateBet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(Color(hex: "8B5CF6"))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showCreateBet) {
            CreateBetView()
        }
        .sheet(item: $selectedBet) { bet in
            BetDetailView(betId: bet.id)
        }
        .onAppear {
            betsManager.markIncomingChallengesSeen()
            Task { await betsManager.refresh() }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                section(
                    title: NSLocalizedString("bets_section_incoming", comment: ""),
                    bets: betsManager.incomingChallenges
                )
                section(
                    title: NSLocalizedString("bets_section_active", comment: ""),
                    bets: betsManager.active
                )
                section(
                    title: NSLocalizedString("bets_section_pending_sent", comment: ""),
                    bets: betsManager.outgoingPending
                )
                section(
                    title: NSLocalizedString("bets_section_history", comment: ""),
                    bets: betsManager.history
                )

                debugPreviewSection

                Button {
                    showCreateBet = true
                } label: {
                    Text(NSLocalizedString("bets_create_button", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "2D2B55"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .refreshable {
            await betsManager.refresh()
        }
    }

    @ViewBuilder
    private func section(title: String, bets: [Bet]) -> some View {
        if !bets.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)

                ForEach(bets) { bet in
                    Button {
                        selectedBet = bet
                    } label: {
                        BetCardView(bet: bet)
                    }
                }
            }
        }
    }

    /// ВРЕМЕННО (по просьбе Евгения) — превью карточек ничьей/победы/поражения без
    /// реальных данных на сервере. Не трогает BetsManager.shared.bets, так что
    /// не влияет на счётчики ачивок. Собирается в любую конфигурацию (не только
    /// Debug), т.к. Евгений ставит билд без дебага напрямую на телефон. Убрать
    /// этот computed var и его использование в `list` после того как посмотрит.
    private var debugPreviewSection: some View {
        let myId = AuthStateManager.shared.userId ?? 0
        let now = ISO8601DateFormatter().string(from: Date())
        let me = BetParticipant(userId: myId, username: "Ты", avatarUrl: nil)

        func fakeBet(id: Int, opponentName: String, winnerId: Int?) -> Bet {
            Bet(
                id: id,
                challenger: me,
                opponent: BetParticipant(userId: -id, username: opponentName, avatarUrl: nil),
                betType: .sobriety,
                durationMode: .period,
                durationDays: 14,
                targetEndDate: nil,
                status: .resolved,
                resolutionType: .natural,
                winnerId: winnerId,
                forfeitedBy: nil,
                respondBy: now,
                startAt: now,
                endAt: now,
                resultSnapshot: nil,
                liveSnapshot: nil,
                createdAt: now,
                acceptedAt: now,
                resolvedAt: now
            )
        }

        let previewBets = [
            fakeBet(id: -9001, opponentName: "Тест: ничья", winnerId: nil),
            fakeBet(id: -9002, opponentName: "Тест: победа", winnerId: myId),
            fakeBet(id: -9003, opponentName: "Тест: поражение", winnerId: -9003),
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("DEBUG PREVIEW (не настоящие пари)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: "FFCD3E"))
                .textCase(.uppercase)

            ForEach(previewBets) { bet in
                BetCardView(bet: bet)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.checkered.2.crossed")
                .font(.system(size: 56))
                .foregroundColor(.white.opacity(0.3))

            Text(NSLocalizedString("bets_empty_title", comment: ""))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("bets_empty_subtitle", comment: ""))
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showCreateBet = true
            } label: {
                Text(NSLocalizedString("bets_create_button", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2B55"))
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(14)
            }
            .padding(.top, 8)
        }
        .padding(24)
    }
}
