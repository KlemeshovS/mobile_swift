//
//  AchievementViews.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//

import SwiftUI


// MARK: - Achievement Popup View
struct AchievementPopupView: View {
    let achievement: Achievement
    let onDismiss: () -> Void
    
    @State private var contentOpacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                // Иконка ачивки
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.isDrinking ?
                                [Color(hex: "FF6B6B"), Color(hex: "FF8E53")] :
                                    [Color(hex: "4ECDC4"), Color(hex: "44A08D")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(achievement.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 35, height: 35)
                        .foregroundColor(.white)
                }
                
                // Заголовок
                Text(achievement.title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Дата получения для всех разблокированных ачивок
                if achievement.isUnlocked, let date = achievement.unlockDate {
                    Text(String(format: NSLocalizedString("ach_unlocked_on", comment: ""), date.formatted(date: .abbreviated, time: .omitted)))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }

                // Счётчик только для годовых ачивок
                if achievement.unlockCount >= 1 {
                    switch achievement.type {
                    case .soberDaysInYear, .drinkingDaysInYear, .uniqueEvent, .soberMonth:
                        Text(String(format: NSLocalizedString("ach_received_count", comment: ""), achievement.unlockCount))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                    default:
                        EmptyView()
                    }
                }
            }
            
            // Описание
            Text(achievement.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            
            // Условие получения
            Text(achievement.requirementDescription)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(achievement.isUnlocked ? Color(hex: "C7FF00") : Color(hex: "8B5CF6"))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .frame(maxWidth: 320)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "2D2B55").opacity(0.95),  // Глубокий фиолетово-синий
                            Color(hex: "3E3B6B").opacity(0.95)   // Более светлый оттенок
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .scaleEffect(scale)
        .opacity(contentOpacity)
        .onAppear {
            // Сначала показываем, потом анимируем контент
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                contentOpacity = 1.0
            }
        }
    }
}

    // MARK: - Achievement View
struct AchievementView: View {
    let achievement: Achievement
    var onSelect: (Achievement) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ?
                         (achievement.isDrinking ?
                          Color.orange.opacity(0.3) :
                          Color.green.opacity(0.3)
                         ) :
                         Color.gray.opacity(0.2)
                    )
                    .frame(width: 60, height: 60)
                
                Circle()
                    .stroke(achievement.isUnlocked ?
                           (achievement.isDrinking ? .orange : .green) :
                           .gray.opacity(0.5),
                           lineWidth: 2
                    )
                    .frame(width: 60, height: 60)
                
                Image(achievement.imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
            }
            
            Text(achievement.title)
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(height: 30)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 100, height: 100)
        .onTapGesture {
            onSelect(achievement)
        }
    }
}

// MARK: - All Achievements View
struct AllAchievementsView: View {
    @State private var allAchievements: [Achievement] = []
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAchievement: Achievement? = nil
    
    var body: some View {
        ZStack {
            NavigationView {
                ZStack {
                    // Темный фон как в основном приложении
                    LinearGradient(
                        colors: [
                            Color(hex: "000000"),
                            Color(hex: "4B3A91")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
                            ForEach(allAchievements) { achievement in
                                VStack(spacing: 8) {
                                    ZStack {
                                        Circle()
                                            .fill(achievement.isUnlocked ?
                                                 (achievement.isDrinking ?
                                                  Color.orange.opacity(0.2) :
                                                  Color.green.opacity(0.2)
                                                 ) :
                                                 Color.gray.opacity(0.1)
                                            )
                                            .frame(width: 60, height: 60)
                                        
                                        Circle()
                                            .stroke(achievement.isUnlocked ?
                                                   (achievement.isDrinking ? .orange : .green) :
                                                   .gray.opacity(0.3),
                                                   lineWidth: 2
                                            )
                                            .frame(width: 60, height: 60)
                                        
                                        Image(achievement.imageName)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                    Text(achievement.title)
                                        .font(.system(size: 12, weight: .medium))
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.white)
                                        .frame(height: 30)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(10)
                                .opacity(achievement.isUnlocked ? 1.0 : 0.7)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedAchievement = achievement
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("achievements")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.black, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbar {
                    // Явно задаем белый цвет для заголовка
                    ToolbarItem(placement: .principal) {
                        Text(NSLocalizedString("achievements", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            HapticManager.shared.impact(.light)
                            dismiss()
                        }) {
                            Image(systemName: "multiply")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .ignoresSafeArea(.all, edges: .all)
            
            // ТЕМНЫЙ ПОПАП ДЛЯ АЧИВОК (как в основном приложении)
            if let achievement = selectedAchievement {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedAchievement = nil
                        }
                    }
                    .zIndex(2000)
                
                VStack {
                    Spacer()
                    
                    AchievementPopupView(achievement: achievement) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            selectedAchievement = nil
                        }
                    }
                }
                .ignoresSafeArea()
                .zIndex(2001)
            }
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea(.all, edges: .all)
        .onAppear {
            loadAchievements()
        }
    }
    
    private func loadAchievements() {
        let achievementManager = NewAchievementManager.shared
        let allBaseAchievements = achievementManager.getAllAchievements()
        let unlockedAchievements = achievementManager.loadUnlockedAchievements()
        
        var updatedAchievements = allBaseAchievements
        for index in updatedAchievements.indices {
            if let unlockedAchievement = unlockedAchievements.first(where: { $0.id == updatedAchievements[index].id }) {
                updatedAchievements[index].isUnlocked = unlockedAchievement.isUnlocked
                updatedAchievements[index].unlockDate = unlockedAchievement.unlockDate
                updatedAchievements[index].unlockCount = unlockedAchievement.unlockCount
            }
        }
        
        self.allAchievements = updatedAchievements
    }
}
