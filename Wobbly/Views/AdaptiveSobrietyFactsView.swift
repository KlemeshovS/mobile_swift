//
//  AdaptiveSobrietyFactsView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 10.01.2026.
//

// AdaptiveSobrietyFactsView.swift
import SwiftUI

struct AdaptiveSobrietyFactsView: View {
    let soberDays: Int
    @State private var showAllMilestonesSheet = false
    
    private let messageSets: [(title: String, points: [(String, Color, String)])] = [
        (
            title: NSLocalizedString("hangover_title_1", comment: "Заголовок для похмельного сообщения 1"),
            points: [
                ("person.fill.xmark", Color(hex: "FF6B6B"), NSLocalizedString("hangover_1_point_1", comment: "Точка 1 для похмельного сообщения 1")),
                ("sparkles", Color(hex: "8B5CF6"), NSLocalizedString("hangover_1_point_2", comment: "Точка 2 для похмельного сообщения 1")),
                ("dollarsign.circle.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_1_point_3", comment: "Точка 3 для похмельного сообщения 1"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_2", comment: "Заголовок для похмельного сообщения 2"),
            points: [
                ("flame.fill", Color(hex: "FF6B6B"), NSLocalizedString("hangover_2_point_1", comment: "Точка 1 для похмельного сообщения 2")),
                ("brain.head.profile", Color(hex: "8B5CF6"), NSLocalizedString("hangover_2_point_2", comment: "Точка 2 для похмельного сообщения 2")),
                ("heart.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_2_point_3", comment: "Точка 3 для похмельного сообщения 2"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_3", comment: "Заголовок для похмельного сообщения 3"),
            points: [
                ("brain.head.profile", Color(hex: "FF6B6B"), NSLocalizedString("hangover_3_point_1", comment: "Точка 1 для похмельного сообщения 3")),
                ("crown.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_3_point_2", comment: "Точка 2 для похмельного сообщения 3")),
                ("chart.line.uptrend.xyaxis", Color(hex: "4ECDC4"), NSLocalizedString("hangover_3_point_3", comment: "Точка 3 для похмельного сообщения 3"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_4", comment: "Заголовок для похмельного сообщения 4"),
            points: [
                ("function", Color(hex: "FF6B6B"), NSLocalizedString("hangover_4_point_1", comment: "Точка 1 для похмельного сообщения 4")),
                ("sun.max.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_4_point_2", comment: "Точка 2 для похмельного сообщения 4")),
                ("lock.open.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_4_point_3", comment: "Точка 3 для похмельного сообщения 4"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_5", comment: "Заголовок для похмельного сообщения 5"),
            points: [
                ("heart.slash.fill", Color(hex: "FF6B6B"), NSLocalizedString("hangover_5_point_1", comment: "Точка 1 для похмельного сообщения 5")),
                ("eye.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_5_point_2", comment: "Точка 2 для похмельного сообщения 5")),
                ("wind.snow", Color(hex: "4ECDC4"), NSLocalizedString("hangover_5_point_3", comment: "Точка 3 для похмельного сообщения 5"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_6", comment: "Заголовок для похмельного сообщения 6"),
            points: [
                ("bolt.horizontal.circle.fill", Color(hex: "FF6B6B"), NSLocalizedString("hangover_6_point_1", comment: "Точка 1 для похмельного сообщения 6")),
                ("hand.thumbsup.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_6_point_2", comment: "Точка 2 для похмельного сообщения 6")),
                ("staroflife.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_6_point_3", comment: "Точка 3 для похмельного сообщения 6"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_7", comment: "Заголовок для похмельного сообщения 7"),
            points: [
                ("arrow.triangle.2.circlepath", Color(hex: "FF6B6B"), NSLocalizedString("hangover_7_point_1", comment: "Точка 1 для похмельного сообщения 7")),
                ("bed.double.circle.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_7_point_2", comment: "Точка 2 для похмельного сообщения 7")),
                ("gauge.with.dots.needle.100percent", Color(hex: "4ECDC4"), NSLocalizedString("hangover_7_point_3", comment: "Точка 3 для похмельного сообщения 7"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_8", comment: "Заголовок для похмельного сообщения 8"),
            points: [
                ("bubble.left.and.bubble.right.fill", Color(hex: "FF6B6B"), NSLocalizedString("hangover_8_point_1", comment: "Точка 1 для похмельного сообщения 8")),
                ("figure.walk.motion", Color(hex: "8B5CF6"), NSLocalizedString("hangover_8_point_2", comment: "Точка 2 для похмельного сообщения 8")),
                ("party.popper.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_8_point_3", comment: "Точка 3 для похмельного сообщения 8"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_9", comment: "Заголовок для похмельного сообщения 9"),
            points: [
                ("creditcard.trianglebadge.exclamationmark", Color(hex: "FF6B6B"), NSLocalizedString("hangover_9_point_1", comment: "Точка 1 для похмельного сообщения 9")),
                ("banknote.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_9_point_2", comment: "Точка 2 для похмельного сообщения 9")),
                ("gift.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_9_point_3", comment: "Точка 3 для похмельного сообщения 9"))
            ]
        ),
        (
            title: NSLocalizedString("hangover_title_10", comment: "Заголовок для похмельного сообщения 10"),
            points: [
                ("scalemass", Color(hex: "FF6B6B"), NSLocalizedString("hangover_10_point_1", comment: "Точка 1 для похмельного сообщения 10")),
                ("lightbulb.2.fill", Color(hex: "8B5CF6"), NSLocalizedString("hangover_10_point_2", comment: "Точка 2 для похмельного сообщения 10")),
                ("trophy.fill", Color(hex: "4ECDC4"), NSLocalizedString("hangover_10_point_3", comment: "Точка 3 для похмельного сообщения 10"))
            ]
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Заголовок
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("your_progress", comment: ""))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    if soberDays > 0 {
                        Text(String(format: NSLocalizedString("sober_days_count", comment: ""), soberDays))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "C7FF00"))
                    }
                }
                
                Spacer()
                
                if soberDays > 0 {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "C7FF00").opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Text(MilestoneData.shared.getCurrentMilestone(soberDays: soberDays)?.icon ?? "🎯")
                            .font(.system(size: 22))
                    }
                }
            }
            
            // СОДЕРЖИМОЕ В ЗАВИСИМОСТИ ОТ СОСТОЯНИЯ
            if let milestone = MilestoneData.shared.getCurrentMilestone(soberDays: soberDays) {
                // ЕСТЬ ДОСТИГНУТЫЙ РУБЕЖ (2+ дней)
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(MilestoneData.shared.getLocalizedFacts(for: milestone), id: \.self) { fact in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "4ECDC4"))
                                    .padding(.top, 2)
                                
                                Text(fact)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "2D2B55").opacity(0.9),
                            Color(hex: "3E3B6B").opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            } else {
                // НЕТ ДОСТИГНУТОГО РУБЕЖА (0-1 день)
                let selected = messageSets.randomElement() ?? messageSets[0]
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(selected.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(selected.points, id: \.2) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: point.0)
                                    .font(.system(size: 12))
                                    .foregroundColor(point.1)
                                    .padding(.top, 2)
                                
                                Text(point.2)
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.9))
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "2D2B55").opacity(0.9),
                            Color(hex: "3E3B6B").opacity(0.7)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
            }
            
            // Кнопка "Эволюция трезвого человека"
            Button(action: {
                HapticManager.shared.impact(.light)
                showAllMilestonesSheet = true
            }) {
                HStack {
                    Text(NSLocalizedString("evolution_of_sober_person_title", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "8B5CF6"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "2D2B55").opacity(0.8),
                            Color(hex: "3E3B6B").opacity(0.6)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "8B5CF6").opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.white.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .sheet(isPresented: $showAllMilestonesSheet) {
            AllMilestonesView(soberDays: soberDays)
        }
    }
}
