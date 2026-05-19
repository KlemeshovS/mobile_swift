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
    
    enum FollowStatus {
        case notFollowing
        case following(isMutual: Bool)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // фон (без изменений)
                LinearGradient(
                    colors: [
                        Color(hex: "1E1E2E").opacity(0.98),
                        Color(hex: "2A2A3A").opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                        
                        Text("\(abs(actualScore ?? item.score))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(actualScore != nil ? (actualScore! >= 0 ? Color.mint : Color.pink) : scoreColor)
                    }
                    .padding(.horizontal, 32)
                    
                    // Кнопка (показываем только если пользователь авторизован)
                    if AuthStateManager.shared.sessionType == .authenticated {
                        if isLoadingFollow {
                            ProgressView()
                        } else {
                            buttonView
                        }
                    } else {
                        // Гость — показываем предложение авторизоваться
                        Text(NSLocalizedString("auth_required_for_follows", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                    }
                    
                    Spacer()
                }
                .padding(.top, 10)
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
        }
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
        do {
            let topItems = try await UserAPIService.shared.fetchTop100()
            if let found = topItems.first(where: { $0.userId == item.userId }) {
                await MainActor.run { actualScore = found.score }
                return
            }
            let bottomItems = try await UserAPIService.shared.fetchBottom100()
            if let found = bottomItems.first(where: { $0.userId == item.userId }) {
                await MainActor.run { actualScore = found.score }
            }
        } catch {
            print("❌ Не удалось загрузить очки пользователя: \(error)")
        }
    }
    
    private func follow() async {
        do {
            let result = try await UserAPIService.shared.follow(username: item.username)
            followStatus = .following(isMutual: result.isMutual)
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
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
