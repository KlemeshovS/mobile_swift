//
//  RatingsView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import SwiftUI

struct RatingsView: View {
    var onShowTopThreePopup: (Int, Bool) -> Void
    let daysData: [String: DrinkLevel]
    @State private var selectedSegment = 0
    @State private var topItems: [LeaderboardItem] = []
    @State private var bottomItems: [LeaderboardItem] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    // Состояния для попапа топ-3
    @State private var showTopThreePopup = false
    @State private var selectedTopThreePlace: Int = 1
    
    // Состояния для окна ввода имени
    @State private var userName: String = ""
    @State private var participateInRating: Bool = true
    @State private var showNamePrompt = false
    @State private var isLoadingProfile = false
    
    // Состояние для отслеживания получения токена
    @State private var isEnsuringToken = false
    
    private let segments = ["top_100", "bottom_100"]
    
    var body: some View {
        ZStack {
            // Фоновый градиент
            LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "4B3A91")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Кастомные табы
                customTabView
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = error {
                    errorView(error: error)
                } else {
                    let items = selectedSegment == 0 ? topItems : bottomItems
                    if items.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                if items.count >= 3 {
                                    topThreeView(items: Array(items.prefix(3)))
                                }
                                
                                let remainingItems = items.count >= 3 ? Array(items.dropFirst(3)) : items
                                
                                LazyVStack(spacing: 8) {
                                    ForEach(Array(remainingItems.enumerated()), id: \.element.id) { index, item in
                                        let position = items.count >= 3 ? index + 4 : index + 1
                                        leaderboardRow(item: item, position: position)
                                    }
                                }
                                .padding(.horizontal, 20)
                                
                                Spacer(minLength: 30)
                            }
                            .padding(.vertical, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
        }
        .overlay(
            Group {
                if showTopThreePopup {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                showTopThreePopup = false
                            }
                        }
                        .transition(.opacity)
                        .zIndex(10000)
                    
                    VStack {
                        Spacer()
                        TopThreePopupView(place: selectedTopThreePlace, isTop: selectedSegment == 0)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showTopThreePopup = false
                                }
                            }
                    }
                    .ignoresSafeArea()
                    .zIndex(10000)
                }
            }
        )
        .sheet(isPresented: $showNamePrompt) {
            UserProfileView(
                onClose: {
                    showNamePrompt = false
                },
                onRegisterSuccess: { username, userId in
                    showNamePrompt = false
                    self.userName = username
                    self.participateInRating = true
                    loadData()
                    ScoreSyncManager.shared.forceSendScore()
                },
                onDisappear: nil,
                daysData: daysData,
                onDeleteAccount: nil
            )
        }
        .onAppear {
            // Восстанавливаем сессию, если нужно
            Task {
                if AuthStateManager.shared.accessToken == nil {
                    await AuthService.shared.restoreSession()
                }
                await MainActor.run {
                    checkProfileAndLoad()
                }
            }
        }
    }
    
    // MARK: - Кастомные табы
    private var customTabView: some View {
        GeometryReader { geometry in
            let tabCount = CGFloat(segments.count)
            let tabWidth = geometry.size.width / tabCount
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "2D2B55").opacity(0.3))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                
                Capsule()
                    .fill(Color(hex: "2D2B55").opacity(0.9))
                    .overlay(
                        Capsule()
                            .stroke(selectedSegment == 0 ? darkGreen : darkRed, lineWidth: 1.5)
                    )
                    .shadow(color: (selectedSegment == 0 ? darkGreen : darkRed).opacity(0.4), radius: 10, x: 0, y: 0)
                    .frame(width: tabWidth - 8)
                    .offset(x: (CGFloat(selectedSegment) * tabWidth) + 4, y: 0)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: selectedSegment)
                
                HStack(spacing: 0) {
                    ForEach(0..<segments.count, id: \.self) { index in
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                selectedSegment = index
                                loadData()
                            }
                        }) {
                            Text(NSLocalizedString(segments[index], comment: ""))
                                .font(.headline)
                                .fontWeight(.medium)
                                .foregroundColor(selectedSegment == index ? .white : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .frame(height: 40)
        .padding(.horizontal, 12)
    }
    
    private var darkGreen: Color {
        Color(red: 0.2, green: 0.4, blue: 0.2)
    }
    
    private var darkRed: Color {
        Color(red: 0.4, green: 0.2, blue: 0.2)
    }
    
    // MARK: - Виджет топ-3
    private func topThreeView(items: [LeaderboardItem]) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TopThreeCardView(
                    item: item,
                    place: index + 1,
                    isTop: selectedSegment == 0,
                    onTap: onShowTopThreePopup
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Ряд лидерборда
    private func leaderboardRow(item: LeaderboardItem, position: Int) -> some View {
        let isCurrentUser = (item.username == userName)
        
        let highlightColor: Color
        let highlightBgColor: Color
        
        if isCurrentUser {
            if item.score >= 0 {
                highlightColor = .green
                highlightBgColor = Color.green.opacity(0.1)
            } else {
                highlightColor = .red.opacity(0.8)
                highlightBgColor = Color.red.opacity(0.05)
            }
        } else {
            highlightColor = .white.opacity(0.1)
            highlightBgColor = Color.white.opacity(0.05)
        }
        
        return HStack {
            Text("\(position).")
                .font(.headline)
                .foregroundColor(isCurrentUser ? highlightColor : .white.opacity(0.7))
                .frame(width: 40, alignment: .leading)
            
            Text(item.username)
                .font(.headline)
                .foregroundColor(isCurrentUser ? highlightColor : .white)
            
            Spacer()
            
            Text("\(abs(item.score))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(scoreColor(for: item.score))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(highlightBgColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? highlightColor : Color.white.opacity(0.1), lineWidth: isCurrentUser ? 2 : 1)
        )
    }
    
    private func scoreColor(for score: Int) -> Color {
        score >= 0 ? Color.mint : Color.pink
    }
    
    private var emptyStateView: some View {
        VStack {
            Spacer()
            Text(NSLocalizedString("no_leaderboard_data", comment: ""))
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.7))
            Text(error.localizedDescription)
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button(action: loadData) {
                Text(NSLocalizedString("retry", comment: ""))
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "EFFFB6"), Color(hex: "C7FF00")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(25)
            }
            Spacer()
        }
    }
    
    // MARK: - Загрузка рейтингов
    private func loadData() {
        isLoading = true
        error = nil
        
        Task {
            do {
                if selectedSegment == 0 {
                    topItems = try await UserAPIService.shared.fetchTop100()
                } else {
                    bottomItems = try await UserAPIService.shared.fetchBottom100()
                }
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    // MARK: - Проверка профиля (GET /me)
    private func checkProfileAndLoad() {
        guard AuthStateManager.shared.accessToken != nil else {
            // Если нет интернета, не показываем окно ввода имени
            if Reachability.isConnectedToNetwork() {
                showNamePrompt = true
            }
            return
        }
        
        isLoadingProfile = true
        Task {
            do {
                let profile = try await UserAPIService.shared.getMyProfile()
                await MainActor.run {
                    self.userName = profile.username ?? ""
                    self.participateInRating = profile.participateInRating
                    
                    if AuthStateManager.shared.sessionType == .guest || !profile.participateInRating {
                        if Reachability.isConnectedToNetwork() {
                            showNamePrompt = true
                        }
                    }
                    
                    isLoadingProfile = false
                    loadData()
                    ScoreSyncManager.shared.forceSendScore()
                }
            } catch {
                await MainActor.run {
                    // При ошибке (скорее всего, нет сети) не показываем окно
                    if Reachability.isConnectedToNetwork() {
                        showNamePrompt = true
                    }
                    isLoadingProfile = false
                    loadData()
                }
            }
        }
    }
}

// MARK: - Top Three Card View
struct TopThreeCardView: View {
    let item: LeaderboardItem
    let place: Int
    let isTop: Bool
    let onTap: (Int, Bool) -> Void
    
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 8) {
            Image(cupImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 50)
                .shadow(color: cupGlowColor.opacity(0.8), radius: isGlowing ? 3 : 1, x: 0, y: 0)
                .shadow(color: cupGlowColor.opacity(0.6), radius: isGlowing ? 4 : 3, x: 0, y: 0)
                .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)

            Text(item.username)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text("\(abs(item.score))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(scoreColor)
                .shadow(color: scoreColor.opacity(0.6), radius: isGlowing ? 12 : 6)
                .shadow(color: scoreColor.opacity(0.4), radius: isGlowing ? 20 : 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .onTapGesture {
            onTap(place, isTop)
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
    
    private var cupImageName: String {
        let prefix = isTop ? "cup" : "anti_cup"
        switch place {
        case 1: return "\(prefix)_gold"
        case 2: return "\(prefix)_silver"
        case 3: return "\(prefix)_bronze"
        default: return ""
        }
    }
    
    private var cupGlowColor: Color {
        switch place {
        case 1: return .yellow
        case 2: return Color(white: 0.8)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .clear
        }
    }
    
    private var scoreColor: Color {
        item.score >= 0 ? Color.mint : Color.pink
    }
}

// MARK: - Попап для топ-3
struct TopThreePopupView: View {
    let place: Int
    let isTop: Bool

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color(hex: "2D2B55"), Color(hex: "3E3B6B")],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
    }

    private var title: String {
        let key = isTop ? "top_\(place)_place_title" : "bottom_\(place)_place_title"
        return NSLocalizedString(key, comment: "")
    }

    private var description: String {
        let key = isTop ? "top_\(place)_place_description" : "bottom_\(place)_place_description"
        return NSLocalizedString(key, comment: "")
    }
}
