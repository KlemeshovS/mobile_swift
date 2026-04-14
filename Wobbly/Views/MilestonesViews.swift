//
//  MilestonesViews.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI

struct AllMilestonesView: View {
    let soberDays: Int
    @Environment(\.dismiss) private var dismiss
    private let milestoneData = MilestoneData.shared
    @ObservedObject private var languageManager = LanguageManager.shared

    
    var body: some View {
        NavigationView {
            ZStack {
                // Фон
                LinearGradient(
                    colors: [
                        Color(hex: "000000"),
                        Color(hex: "2A1E5C"),
                        Color(hex: "4B3A91")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(milestoneData.getAllMilestones(), id: \.days) { milestone in
                            let nextMilestone = milestoneData.getNextMilestoneAfterCurrent(soberDays: soberDays)
                            let isCurrent = soberDays >= milestone.days &&
                                           (milestone.days == soberDays ||
                                           (soberDays < 365 && milestone.days == nextMilestone?.days ?? 0))
                            
                            MilestoneCard(
                                milestone: milestone,
                                isCompleted: soberDays >= milestone.days,
                                isCurrent: isCurrent
                            )
                        }
                    }
                    .padding()
                }
            }
        //    .navigationTitle("all_milestones_screen_title")
            .navigationTitle(NSLocalizedString("all_milestones_screen_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(
                Color.black,
                for: .navigationBar
            )
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
struct MilestoneCard: View {
    let milestone: MilestoneDataModel
    let isCompleted: Bool
    let isCurrent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок
            HStack {
                HStack(spacing: 12) {
                    Text(milestone.icon)
                        .font(.system(size: 24))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(MilestoneData.shared.getLocalizedTitle(for: milestone))
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(hex: "4ECDC4"))
                } else if isCurrent {
                    Text("current_label")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "C7FF00"))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "C7FF00").opacity(0.2))
                        .cornerRadius(10)
                }
            }
            
            // Медицинские факты (полная версия - 6 фактов)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(MilestoneData.shared.getLocalizedFacts(for: milestone, isFullVersion: true), id: \.self) { fact in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 10))
                            .foregroundColor(isCompleted ? Color(hex: "4ECDC4") : .white.opacity(0.5))
                            .padding(.top, 2)
                        
                        Text(fact)
                            .font(.system(size: 14))
                            .foregroundColor(isCompleted ? .white.opacity(0.9) : .white.opacity(0.6))
                            .lineSpacing(2)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: isCompleted ? [
                    Color(hex: "2D2B55").opacity(0.9),
                    Color(hex: "3E3B6B").opacity(0.7)
                ] : [
                    Color.white.opacity(0.05),
                    Color.white.opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isCurrent ? Color(hex: "C7FF00").opacity(0.3) :
                    isCompleted ? Color.white.opacity(0.1) : Color.white.opacity(0.05),
                    lineWidth: 1
                )
        )
    }
}
struct SobrietyFactRow: View {
    let fact: (icon: String, title: String, description: String)
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Иконка
            Text(fact.icon)
                .font(.system(size: 22))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
            
            // Текст
            VStack(alignment: .leading, spacing: 4) {
                Text(fact.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(fact.description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}
