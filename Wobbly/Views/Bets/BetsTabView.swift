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

                if betsManager.bets.isEmpty && !betsManager.isLoading {
                    emptyState
                } else {
                    list
                }
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
