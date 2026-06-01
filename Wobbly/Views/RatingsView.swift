//
//  RatingsView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import SwiftUI
import Kingfisher

struct RatingsView: View {
    var onShowTopThreePopup: (Int, Bool) -> Void
    let daysData: [String: DrinkLevel]
    @State private var selectedSegment = 0
    @State private var topItems: [LeaderboardItem] = []
    @State private var bottomItems: [LeaderboardItem] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    // Состояния для попапа топ-3
    @State private var showTopThreePopup = false
    @State private var selectedTopThreePlace: Int = 1
    @State private var selectedTopThreeAvatarUrl: String? = nil
    
    // Состояния для окна ввода имени
    @State private var userName: String = ""
    @State private var participateInRating: Bool = true
    @State private var showNamePrompt = false
    @State private var isLoadingProfile = false
    
    @State private var showProfile = false
    
    @State private var selectedUserItem: LeaderboardItem? = nil

    @State private var showFriendsOnly: Bool = UserDefaults.standard.bool(forKey: "ratingsShowFriendsOnly")
    @State private var myFollowUsernames: Set<String> = []
    @State private var myMutualUsernames: Set<String> = []
    @State private var pendingFollowerUsernames: Set<String> = []
    @State private var myOneWayFollowUsernames: Set<String> = []
    @State private var isLoadingFollows = false
    
    @State private var myAvatarUrl: String? = nil

    private let segments = ["top_100", "bottom_100"]
    
    private var filteredTopItems: [LeaderboardItem] {
        guard showFriendsOnly else { return topItems }
        if myFollowUsernames.isEmpty { return [] }
        return topItems.filter { myFollowUsernames.contains($0.username) || $0.username == userName }
    }

    private var filteredBottomItems: [LeaderboardItem] {
        guard showFriendsOnly else { return bottomItems }
        if myFollowUsernames.isEmpty { return [] }
        return bottomItems.filter { myFollowUsernames.contains($0.username) || $0.username == userName }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "4B3A91")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    customTabView
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)

                    Button(action: { showProfile = true }) {
                        if let avatarPath = myAvatarUrl, let url = makeFullURL(path: avatarPath) {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 36, height: 36)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white.opacity(0.8))
                                        .font(.system(size: 18))
                                )
                        }
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 4)
                }

                // Тоггл "Только мои друзья"
                if AuthStateManager.shared.sessionType == .authenticated {
                    HStack {
                        Text(NSLocalizedString("ratings_friends_only_toggle", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        if isLoadingFollows {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Toggle("", isOn: $showFriendsOnly)
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                                .labelsHidden()
                                .onChange(of: showFriendsOnly) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: "ratingsShowFriendsOnly")
                                    if newValue && myFollowUsernames.isEmpty {
                                        Task { await loadMyFollows() }
                                    }
                                }
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 0)
                }
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = error {
                    errorView(error: error)
                } else {
                    let items = selectedSegment == 0 ? filteredTopItems : filteredBottomItems
                    if items.isEmpty {
                        Group {
                            if showFriendsOnly {
                                friendsEmptyStateView
                            } else {
                                emptyStateView
                            }
                        }
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
                        TopThreePopupView(place: selectedTopThreePlace,
                                          isTop: selectedSegment == 0,
                                          avatarUrl: selectedTopThreeAvatarUrl)
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
                onClose: { showNamePrompt = false },
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
        
        .sheet(isPresented: $showProfile, onDismiss: { loadData() }) {
            UserProfileView(
                onClose: { showProfile = false },
                onRegisterSuccess: { username, userId in
                    loadData()
                },
                onDisappear: nil,
                daysData: daysData,
                onDeleteAccount: nil
            )
        }
        
        .sheet(item: $selectedUserItem) { item in
            PublicUserProfileView(item: item)
        }
        
        .onAppear {
            Task {
                if AuthStateManager.shared.accessToken == nil {
                    await AuthService.shared.restoreSession()
                }
                await MainActor.run {
                    checkProfileAndLoad()
                }
                if AuthStateManager.shared.sessionType == .authenticated {
                    await loadMyFollows()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .followStatusChanged)) { _ in
            Task { await loadMyFollows() }
        }
    }
    
    // MARK: - Кастомные табы (без изменений)
    private var customTabView: some View {
        GeometryReader { geometry in
            let tabCount = CGFloat(segments.count)
            let tabWidth = geometry.size.width / tabCount
            
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "2D2B55").opacity(0.3))
                    .overlay(Capsule().stroke(Color.white.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
                
                Capsule()
                    .fill(Color(hex: "2D2B55").opacity(0.9))
                    .overlay(Capsule().stroke(selectedSegment == 0 ? darkGreen : darkRed, lineWidth: 1.5))
                    .shadow(color: (selectedSegment == 0 ? darkGreen : darkRed).opacity(0.4), radius: 10, x: 0, y: 0)
                    .frame(width: tabWidth)
                    .offset(x: CGFloat(selectedSegment) * tabWidth, y: 0)
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
        .padding(.horizontal, 0)
    }
    
    private var darkGreen: Color { Color(red: 0.2, green: 0.4, blue: 0.2) }
    private var darkRed: Color { Color(red: 0.4, green: 0.2, blue: 0.2) }
    
    // MARK: - Виджет топ-3
    private func topThreeView(items: [LeaderboardItem]) -> some View {
        HStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                TopThreeCardView(
                    item: item,
                    place: index + 1,
                    isTop: selectedSegment == 0,
                    onTap: { place, isTop in
                        selectedUserItem = item
                    },
                    isCurrentUser: item.username == userName,
                    onProfileTap: { showProfile = true }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Ряд лидерборда
    private func leaderboardRow(item: LeaderboardItem, position: Int) -> some View {
        let isCurrentUser = (item.username == userName)
        let highlightColor: Color = isCurrentUser ? (item.score >= 0 ? .green : .red.opacity(0.8)) : .white.opacity(0.1)
        let highlightBgColor: Color = isCurrentUser ? (item.score >= 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.05)) : Color.white.opacity(0.05)
        
        let avatarURL = makeFullURL(path: item.avatarUrl)
        
        return HStack(spacing: 8) {
            Text("\(position).")
                .font(.headline)
                .foregroundColor(isCurrentUser ? highlightColor : .white.opacity(0.7))
                .frame(width: 30, alignment: .leading) // уменьшено для экономии места
            
            if let url = avatarURL {
                KFImage(url)
                    .placeholder {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 15))
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                    )
            }
            
            Text(item.username)
                .font(.headline)
                .foregroundColor(isCurrentUser ? highlightColor : .white)
            
            Spacer()
            
            HStack(spacing: 6) {
                if !isCurrentUser && myMutualUsernames.contains(item.username) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(Color(hex: "C7FF00"))
                        .font(.system(size: 13))
                } else if !isCurrentUser && myOneWayFollowUsernames.contains(item.username) {
                    IFollowThemIcon()
                } else if !isCurrentUser && pendingFollowerUsernames.contains(item.username) {
                    TheyFollowMeIcon()
                }
                Text("\(abs(item.score))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(scoreColor(for: item.score))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(highlightBgColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUser ? highlightColor : Color.white.opacity(0.1), lineWidth: isCurrentUser ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if isCurrentUser {
                showProfile = true
            } else {
                selectedUserItem = item
            }
        }
    }
    
    private var stagingImageOptions: KingfisherOptionsInfo {
        guard AppEnvironment.current == .staging,
              let key = AppEnvironment.stagingKey else { return [] }
        let modifier = AnyModifier { request in
            var r = request
            r.setValue(key, forHTTPHeaderField: "X-Staging-Key")
            return r
        }
        return [.requestModifier(modifier)]
    }
    
    private func cupImageName(for position: Int, isTop: Bool) -> String {
        let prefix = isTop ? "cup" : "anti_cup"
        switch position {
        case 1: return "\(prefix)_gold"
        case 2: return "\(prefix)_silver"
        case 3: return "\(prefix)_bronze"
        default: return ""
        }
    }
    
    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") {
            return URL(string: path)
        }
        let base = AppEnvironment.current.baseURL
            .replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
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
                await MainActor.run { isLoading = false }
            } catch {
                await MainActor.run {
                    self.error = error
                    isLoading = false
                }
            }
        }
    }
    
    private func checkProfileAndLoad() {
        guard AuthStateManager.shared.accessToken != nil else {
            if Reachability.isConnectedToNetwork() { showNamePrompt = true }
            return
        }
        isLoadingProfile = true
        Task {
            do {
                let profile = try await UserAPIService.shared.getMyProfile()
                await MainActor.run {
                    self.userName = profile.username ?? ""
                    self.myAvatarUrl = profile.avatarUrl
                    self.participateInRating = profile.participateInRating
                    if AuthStateManager.shared.sessionType == .guest || !profile.participateInRating {
                        if Reachability.isConnectedToNetwork() { showNamePrompt = true }
                    }
                    isLoadingProfile = false
                    loadData()
                    ScoreSyncManager.shared.forceSendScore()
                }
            } catch {
                await MainActor.run {
                    if Reachability.isConnectedToNetwork() { showNamePrompt = true }
                    isLoadingProfile = false
                    loadData()
                }
            }
        }
    }
    
    private func loadMyFollows() async {
        guard AuthStateManager.shared.sessionType == .authenticated else { return }
        await MainActor.run { isLoadingFollows = true }
        do {
            async let followsResp = UserAPIService.shared.getMyFollows()
            async let followersResp = UserAPIService.shared.getMyFollowers()
            let (follows, followers) = try await (followsResp, followersResp)
            await MainActor.run {
                myFollowUsernames = Set(follows.items.map { $0.username })
                myMutualUsernames = Set(follows.items.filter { $0.isMutual }.map { $0.username })
                // Подписаны на меня, но я на них нет
                let followingMe = Set(followers.items.map { $0.username })
                pendingFollowerUsernames = followingMe.subtracting(myFollowUsernames)
                myOneWayFollowUsernames = myFollowUsernames.subtracting(myMutualUsernames)
                isLoadingFollows = false
            }
        } catch {
            await MainActor.run { isLoadingFollows = false }
        }
    }

    private var friendsEmptyStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "person.2")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.4))
            Text(NSLocalizedString("ratings_friends_empty", comment: ""))
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
}

// MARK: - Top Three Card View
struct TopThreeCardView: View {
    let item: LeaderboardItem
    let place: Int
    let isTop: Bool
    let onTap: (Int, Bool) -> Void
    
    let isCurrentUser: Bool
    var onProfileTap: (() -> Void)? = nil
    
    @State private var isGlowing = false
    
    var body: some View {
        VStack(spacing: 4) {
            // Аватар
            let avatarURL = makeFullURL(path: item.avatarUrl)
            if let url = avatarURL {
                KFImage(url)
                    .placeholder {                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 50, height: 50)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            )
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(cupImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }

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
        .contentShape(Rectangle())
        .onTapGesture {
            if isCurrentUser {
                onProfileTap?()
            } else {
                onTap(place, isTop)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
    
    private var stagingImageOptions: KingfisherOptionsInfo {
        guard AppEnvironment.current == .staging,
              let key = AppEnvironment.stagingKey else { return [] }
        let modifier = AnyModifier { request in
            var r = request
            r.setValue(key, forHTTPHeaderField: "X-Staging-Key")
            return r
        }
        return [.requestModifier(modifier)]
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
    
    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        let base = AppEnvironment.current.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
    }
}

// MARK: - Попап для топ-3
struct TopThreePopupView: View {
    let place: Int
    let isTop: Bool
    var avatarUrl: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            // Аватар или кубок (без белой обводки)
            let url = makeFullURL(path: avatarUrl)
            if let url = url {
                KFImage(url)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(cupImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }

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

    private var title: String {
        let key = isTop ? "top_\(place)_place_title" : "bottom_\(place)_place_title"
        return NSLocalizedString(key, comment: "")
    }

    private var description: String {
        let key = isTop ? "top_\(place)_place_description" : "bottom_\(place)_place_description"
        return NSLocalizedString(key, comment: "")
    }
    
    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        let base = AppEnvironment.current.baseURL.replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
    }
}

// Я подписан на них, они нет — я (зелёный) слева, они (серый) справа
private struct IFollowThemIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "person.fill")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 13))
                .offset(x: 4)
            Image(systemName: "person.fill")
                .foregroundColor(Color(hex: "C7FF00"))
                .font(.system(size: 13))
                .offset(x: -4)
        }
        .frame(width: 24, height: 16)
    }
}

// Они подписаны на меня, я нет — они (серый) слева, я (зелёный) справа
private struct TheyFollowMeIcon: View {
    var body: some View {
        ZStack {
            Image(systemName: "person.fill")
                .foregroundColor(Color(hex: "C7FF00"))
                .font(.system(size: 13))
                .offset(x: 4)
            Image(systemName: "person.fill")
                .foregroundColor(.gray.opacity(0.5))
                .font(.system(size: 13))
                .offset(x: -4)
        }
        .frame(width: 24, height: 16)
    }
}
