//
//  BetsStatsWidgetView.swift
//  Wobbly
//
//  Маленький виджет на странице статистики: сколько пари выиграно/проиграно.
//

import SwiftUI

struct BetsStatsWidgetView: View {
    @ObservedObject private var betsManager = BetsManager.shared

    var body: some View {
        HStack(spacing: 12) {
            statBox(
                count: betsManager.wonCount,
                title: NSLocalizedString("bets_stat_won_title", comment: ""),
                imageName: "achievement_bet_win",
                backgroundColor: Color(hex: "C7FF9E")
            )
            statBox(
                count: betsManager.lostCount,
                title: NSLocalizedString("bets_stat_lost_title", comment: ""),
                imageName: "achievement_bet_loss",
                backgroundColor: Color(hex: "D8D8E0")
            )
        }
        .task {
            await betsManager.refresh()
        }
    }

    private func statBox(count: Int, title: String, imageName: String, backgroundColor: Color) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text("\(count)")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
            }

            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(backgroundColor)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}
