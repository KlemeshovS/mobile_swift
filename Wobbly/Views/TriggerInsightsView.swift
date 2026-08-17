//
//  TriggerInsightsView.swift
//  Wobbly
//
//  Пассивная карточка со статистикой триггеров за выбранный год.
//  Данные из TriggerManager (локальные, без синка). Карточка скрыта, если триггеров нет.
//

import SwiftUI

struct TriggerInsightsView: View {
    let selectedYear: Int

    private struct TriggerCount: Identifiable {
        let trigger: DrinkTrigger
        let count: Int
        var id: DrinkTrigger { trigger }
    }

    private var counts: [TriggerCount] {
        var totals: [DrinkTrigger: Int] = [:]

        for (key, triggers) in TriggerManager.shared.allTriggers() {
            let parts = key.split(separator: "-").map { String($0) }
            guard parts.count == 3, let y = Int(parts[0]), y == selectedYear else { continue }
            for trigger in triggers {
                totals[trigger, default: 0] += 1
            }
        }

        return totals
            .map { TriggerCount(trigger: $0.key, count: $0.value) }
            .sorted { $0.count > $1.count }
    }

    var body: some View {
        let data = counts
        guard !data.isEmpty else { return AnyView(EmptyView()) }

        let maxCount = data.first?.count ?? 1

        return AnyView(
            VStack(alignment: .leading, spacing: 14) {
                Text(NSLocalizedString("trigger_insights_title", comment: ""))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                ForEach(data.prefix(5)) { item in
                    triggerRow(item: item, maxCount: maxCount)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.07))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
        )
    }

    @ViewBuilder
    private func triggerRow(item: TriggerCount, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.trigger.localizedTitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Text("\(item.count)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(hex: "8B5CF6").opacity(0.8))
                        .frame(width: geo.size.width * CGFloat(item.count) / CGFloat(maxCount), height: 8)
                        .animation(.easeOut(duration: 0.6), value: item.count)
                }
            }
            .frame(height: 8)
        }
    }
}
