import SwiftUI
import Kingfisher

struct PublicUserProfileView: View {
    let item: LeaderboardItem
    init(item: LeaderboardItem) {
            self.item = item
        }
        
        init(follow: FollowModel) {
            self.item = LeaderboardItem(
                userId: follow.userId,
                username: follow.username,
                score: 0,
                avatarUrl: follow.avatarUrl
            )
        }
    @Environment(\.dismiss) private var dismiss
    
    @State private var followStatus: FollowStatus = .notFollowing
    @State private var isLoadingFollow = true
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    @State private var actualScore: Int? = nil
    @State private var friendCalendar: UserAPIService.FriendCalendarResponse? = nil
    @State private var isLoadingCalendar = false
    @State private var calendarNotFriends = false
    
    enum FollowStatus {
        case notFollowing
        case following(isMutual: Bool)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // фон
                LinearGradient(
                    colors: scoreForGradient >= 0
                        ? [Color(hex: "080F08"), Color(hex: "0A1F10"), Color(hex: "122A18")]
                        : [Color(hex: "1A0A0A"), Color(hex: "2A1020"), Color(hex: "1E1550")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        //Статус
                        if let status = friendStatus {
                            Text(status.displayName)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        // Аватарка
                        let avatarURL = makeFullURL(path: item.avatarUrl)
                        if let url = avatarURL {
                            KFImage(url)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 40))
                                )
                        }
                        
                        // Юзернейм и очки
                        HStack {
                            Text(item.username)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(Color(hex: "C7FF00"))
                            Spacer()
                            if let score = actualScore {
                                Text("\(abs(score))")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(score >= 0 ? Color.mint : Color.pink)
                                    .transition(.opacity)
                            } else if item.score != 0 {
                                Text("\(abs(item.score))")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(scoreColor)
                            } else {
                                Text("...")
                                    .font(.title2).fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        // Кнопка
                        if AuthStateManager.shared.sessionType == .authenticated {
                            if isLoadingFollow { ProgressView() } else { buttonView }
                        } else {
                            Text(NSLocalizedString("auth_required_for_follows", comment: ""))
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding()
                        }
                        
                        // Календарь
                        calendarSection
                            .padding(.horizontal, 16)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text(NSLocalizedString("error", comment: "")),
                message: Text(errorMessage ?? ""),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            if AuthStateManager.shared.sessionType == .authenticated {
                Task { await loadFollowStatus() }
            }
            Task { await loadActualScore() }
            Task { await loadFriendCalendar() }
        }
    }
    
    private var scoreForGradient: Int {
        actualScore ?? item.score
    }
    
    private var friendStatus: UserStatus? {
        guard let cal = friendCalendar, !cal.isEmpty else { return nil }
        var daysData: [String: DrinkLevel] = [:]
        for (key, value) in cal.days {
            switch value {
            case 1: daysData[key] = .little
            case 2: daysData[key] = .medium
            case 3: daysData[key] = .heavy
            case 4: daysData[key] = .sport
            case 5: daysData[key] = .little_sport
            case 6: daysData[key] = .medium_sport
            case 7: daysData[key] = .heavy_sport
            default: break
            }
        }
        return UserStatusManager.shared.calculateCurrentStatus(daysData: daysData).status
    }
    
    @ViewBuilder
    private var calendarSection: some View {
        if isLoadingCalendar {
            CalendarSkeletonView()
        } else if calendarNotFriends {
            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("friend_calendar_title", comment: ""))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 10) {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.system(size: 14))
                    Text(NSLocalizedString("friend_calendar_mutual_only", comment: ""))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: "2D2B55").opacity(0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )

                CalendarSkeletonView()
            }
        } else if let cal = friendCalendar {
            if cal.isEmpty {
                Text(NSLocalizedString("friend_calendar_empty", comment: ""))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(12)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("friend_calendar_title", comment: ""))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    FriendCalendarGridView(calendarData: cal.days, updatedAt: cal.updatedAt)
                }
                // Статистика друга
                FriendStatsView(days: cal.days, updatedAt: cal.updatedAt)
                    .padding(.top, 8)
            }
        }
        // Если friendCalendar == nil и нет ошибки — ничего не показываем
        // (не авторизован или загрузка ещё не началась)
    }
    
    @ViewBuilder
    private var buttonView: some View {
        switch followStatus {

        case .notFollowing:
            Button(action: { Task { await follow() } }) {
                Text(NSLocalizedString("follow_button", comment: ""))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "8B5CF6"), Color(hex: "4B3A91")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

        case .following(let isMutual):
            HStack {
                Text(NSLocalizedString(
                    isMutual ? "follow_status_mutual" : "follow_status_following",
                    comment: ""
                ))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

                Spacer()

                Menu {
                    Button(role: .destructive) {
                        Task { await unfollow() }
                    } label: {
                        Label(NSLocalizedString("unfollow_button", comment: ""), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(8)
                }
                .background(Color.clear.environment(\.colorScheme, .dark))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 20)
            .background(Color.white.opacity(0.07))
            .cornerRadius(12)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - API Calls
    
    private func loadFollowStatus() async {
        isLoadingFollow = true
        defer { isLoadingFollow = false }
        do {
            let follows = try await UserAPIService.shared.getMyFollows()
            if let found = follows.items.first(where: { $0.userId == item.userId }) {
                followStatus = .following(isMutual: found.isMutual)
            } else {
                followStatus = .notFollowing
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private func loadActualScore() async {
        print("🔍 loadActualScore: ищем userId = \(item.userId), username = \(item.username)")
        do {
            let topItems = try await UserAPIService.shared.fetchTop100()
            print("📊 Top100: \(topItems.map { "\($0.username)=\($0.score)" })")
            
            if let found = topItems.first(where: { $0.userId == item.userId }) {
                print("✅ Найден в топ100: score = \(found.score)")
                await MainActor.run { actualScore = found.score }
                return
            }
            
            print("⚠️ Не найден в топ100, ищем в bottom100...")
            let bottomItems = try await UserAPIService.shared.fetchBottom100()
            print("📊 Bottom100: \(bottomItems.map { "\($0.username)=\($0.score)" })")
            
            if let found = bottomItems.first(where: { $0.userId == item.userId }) {
                print("✅ Найден в bottom100: score = \(found.score)")
                await MainActor.run { actualScore = found.score }
            } else {
                print("❌ Пользователь не найден ни в топ ни в антитоп. item.score = \(item.score)")
            }
        } catch {
            print("❌ Ошибка loadActualScore: \(error)")
        }
    }
    
    private func loadFriendCalendar() async {
        guard AuthStateManager.shared.sessionType == .authenticated else { return }
        await MainActor.run { isLoadingCalendar = true }
        do {
            let cal = try await UserAPIService.shared.getFriendCalendar(userId: item.userId)
            await MainActor.run {
                friendCalendar = cal
                calendarNotFriends = false
                isLoadingCalendar = false
            }
        } catch UserAPIError.notFriends {
            await MainActor.run {
                calendarNotFriends = true
                isLoadingCalendar = false
            }
        } catch {
            print("❌ Календарь друга: \(error)")
            await MainActor.run { isLoadingCalendar = false }
        }
    }
    
    private func follow() async {
        do {
            let result = try await UserAPIService.shared.follow(username: item.username)
            followStatus = .following(isMutual: result.isMutual)
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            // Перезагружаем календарь — мог стать взаимным
            await loadFriendCalendar()
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }

    private func unfollow() async {
        do {
            try await UserAPIService.shared.unfollow(userId: item.userId)
            followStatus = .notFollowing
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            // Сбрасываем календарь — дружба прервана
            await MainActor.run {
                friendCalendar = nil
                calendarNotFriends = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    private var scoreColor: Color {
        item.score >= 0 ? Color.mint : Color.pink
    }
    
    private func makeFullURL(path: String?) -> URL? {
        guard let path = path else { return nil }
        if path.hasPrefix("http") { return URL(string: path) }
        let base = AppEnvironment.current.baseURL
            .replacingOccurrences(of: "/api/v1", with: "")
        return URL(string: base + path)
    }
}

private struct CalendarSkeletonView: View {
    @State private var opacity: Double = 0.4

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            ForEach(0..<4, id: \.self) { _ in
                MonthSkeletonView()
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.15
            }
        }
        .opacity(opacity)
    }
}

private struct MonthSkeletonView: View {
    var body: some View {
        VStack(spacing: 3) {
            // Заголовок месяца
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 60, height: 10)
                .padding(.top, 8)

            // Дни недели
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.4))
                        .frame(height: 7)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 2)

            // Строки дней
            ForEach(0..<6, id: \.self) { _ in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { _ in
                        Circle()
                            .fill(Color.gray.opacity(0.35))
                            .frame(maxWidth: .infinity)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gray.opacity(0.15))
        )
    }
}
