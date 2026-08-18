//
//  CustomTabBar.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 14.03.26.
//
import SwiftUI


struct CustomTabBar: View {
    @Binding var selectedTab: Int
    @ObservedObject private var betsManager = BetsManager.shared

    private let selectedColor = Color(hex: "8B5CF6") // Фиолетовый
    private let unselectedColor = Color(hex: "6B7280") // Серый
    private let backgroundColor = Color(hex: "1F2937") // Темно-серый
    
    var selectedTextColor: Color = Color(red: 116/255, green: 88/255, blue: 255/255, opacity: 1.0)
    var unselectedTextColor: Color = .gray
    
    var body: some View {
        HStack {
            TabBarButton(
                selectedImage: "cal-selected",
                unselectedImage: "cal",
                title: NSLocalizedString("calendar_tab_title", comment: ""),
                isSelected: selectedTab == 0,
                selectedTextColor: selectedTextColor,
                unselectedTextColor: unselectedTextColor,
                action: {
                    if selectedTab != 0 {
                        HapticManager.shared.impact(.light)
                        selectedTab = 0
                    }
                }
            )
            
            TabBarButton(
                selectedImage: "stat-selected",
                unselectedImage: "stat",
                title: NSLocalizedString("stat_tab_title", comment: ""),
                isSelected: selectedTab == 1,
                selectedTextColor: selectedTextColor,
                unselectedTextColor: unselectedTextColor,
                action: {
                    if selectedTab != 1 {
                        HapticManager.shared.impact(.light)
                        selectedTab = 1
                    }
                }
            )
            
            // Новый таб для рейтингов
            TabBarButton(
                selectedImage: "ratings-selected",  // имя ассета для выбранного состояния
                unselectedImage: "ratings",          // имя ассета для обычного состояния
                title: NSLocalizedString("ratings_tab_title", comment: ""),
                isSelected: selectedTab == 2,
                selectedTextColor: selectedTextColor,
                unselectedTextColor: unselectedTextColor,
                action: {
                    if selectedTab != 2 {
                        HapticManager.shared.impact(.light)
                        selectedTab = 2
                    }
                }
            )

            // Пари между друзьями
            TabBarButton(
                selectedImage: "flag.checkered.2.crossed",
                unselectedImage: "flag.checkered.2.crossed",
                title: NSLocalizedString("bets_tab_title", comment: ""),
                isSelected: selectedTab == 3,
                selectedTextColor: selectedTextColor,
                unselectedTextColor: unselectedTextColor,
                useSystemImage: true,
                showBadge: betsManager.hasUnseenIncomingChallenges,
                action: {
                    if selectedTab != 3 {
                        HapticManager.shared.impact(.light)
                        selectedTab = 3
                    }
                }
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: -1)
        )
        .frame(height: 20)
    }
}
struct TabBarButton: View {
    let selectedImage: String
    let unselectedImage: String
    let title: String
    let isSelected: Bool
    let selectedTextColor: Color
    let unselectedTextColor: Color
    var useSystemImage: Bool = false
    var showBadge: Bool = false
    let action: () -> Void

    private let imageSize: CGFloat = 32

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if useSystemImage {
                            Image(systemName: isSelected ? selectedImage : unselectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } else {
                            Image(isSelected ? selectedImage : unselectedImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .frame(width: imageSize, height: imageSize)
                    .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor)

                    if showBadge {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 9, height: 9)
                            .offset(x: 4, y: -2)
                    }
                }

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? selectedTextColor : unselectedTextColor.opacity(0.7))
        }
    }
}
