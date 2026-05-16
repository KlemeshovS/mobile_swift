//
//  UserProfileView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import Kingfisher

struct UserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let onClose: (() -> Void)?
    let onRegisterSuccess: ((String, Int) -> Void)?
    let onDisappear: (() -> Void)?
    let daysData: [String: DrinkLevel]
    let onDeleteAccount: (() -> Void)?

    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var userName: String = ""
    @State private var participateInRanking: Bool = true
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    @State private var sessionType: SessionType = .guest
    @State private var isLoading = true
    @State private var currentUsername: String? = nil
    @State private var isEditingName = false
    @State private var tempName = ""
    @State private var editErrorMessage: String?
    
    @State private var avatarLocalImage: UIImage?
    @State private var avatarUrl: String? = nil
    
    @State private var showDeleteConfirmation = false
    
    @State private var myFollows: [FollowModel] = []
    @State private var myFollowers: [FollowModel] = []
    @State private var isLoadingFollows = false
    @State private var selectedFollowUser: FollowModel? = nil

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "1E1E2E").opacity(0.98),
                        Color(hex: "2A2A3A").opacity(0.98)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            if sessionType == .guest {
                                guestView
                            } else {
                                authenticatedView
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("user_profile_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onClose?()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if sessionType == .authenticated, onDeleteAccount != nil {
                        Menu {
                            Button(role: .destructive) {
                                showDeleteConfirmation = true
                            } label: {
                                Label(NSLocalizedString("delete_account", comment: ""), systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .overlay(
            Group {
                if showDeleteConfirmation {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { showDeleteConfirmation = false }
                    
                    VStack(spacing: 20) {
                        Text(NSLocalizedString("delete_account_confirmation_title", comment: ""))
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(NSLocalizedString("delete_account_confirmation_message", comment: ""))
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Button(NSLocalizedString("delete_account_confirm", comment: "")) {
                            showDeleteConfirmation = false
                            onDeleteAccount?()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .tint(.red)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 30)
                }
            }
        )
        .onAppear {
            Task {
                await loadSessionAndUserData()
                loadAvatarFromDisk()
            }
        }
        .onDisappear {
            onDisappear?()
        }
        .onReceive(NotificationCenter.default.publisher(for: .followStatusChanged)) { _ in
            Task { await loadFollowData() }
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text(NSLocalizedString("error", comment: "")),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $isEditingName) {
            editNameSheet
        }
        .sheet(item: $selectedFollowUser) { follow in
            PublicUserProfileView(follow: follow)
        }
    }
    
    // MARK: - Guest View
    private var guestView: some View {
        VStack(spacing: 24) {
            Circle()
                .fill(Color(hex: "8B5CF6").opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                )
            
            Text(NSLocalizedString("profile_guest_title", comment: ""))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(NSLocalizedString("profile_guest_message", comment: ""))
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        
       
            // Apple Sign In
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    Task {
                        switch result {
                        case .success(let authResults):
                            if let credential = authResults.credential as? ASAuthorizationAppleIDCredential {
                                do {
                                    try await AuthService.shared.signInWithApple(credential: credential)
                                    await MainActor.run {
                                        Task { await loadSessionAndUserData() }
                                        onRegisterSuccess?(currentUsername ?? "", AuthStateManager.shared.userId ?? 0)
                                    }
                                } catch {
                                    if !isCancelledError(error) {
                                        showError(message: error.localizedDescription)
                                    }
                                }
                            }
                        case .failure(let error):
                            if !isCancelledError(error) {
                                showError(message: error.localizedDescription)
                            }
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(12)
            
            // Google Sign In
            Button(action: signInWithGoogle) {
                HStack {
                    Image("google_logo")
                        .resizable()
                        .frame(width: 22, height: 22)
                    Text(NSLocalizedString("google_sign_in_button", comment: ""))
                        .font(.system(size: 19, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .frame(height: 50)
            .cornerRadius(12)
            
            // Skip button
            Button(action: {
                onClose?()
            }) {
                Text(NSLocalizedString("skip_button", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top)
        }
    }
    
    // MARK: - Работа с аватаром
    
    private func saveAvatarLocally(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        let filename = getAvatarFilePath()
        do {
            try data.write(to: filename)
            print("✅ Аватар сохранён: \(filename)")
        } catch {
            print("❌ Ошибка сохранения аватара: \(error)")
        }
    }

    private func loadAvatarFromDisk() {
        let filename = getAvatarFilePath()
        if FileManager.default.fileExists(atPath: filename.path),
           let data = try? Data(contentsOf: filename),
           let image = UIImage(data: data) {
            avatarLocalImage = image
        }
    }

    private func getAvatarFilePath() -> URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("user_avatar.jpg")
    }
    
    private func deleteAvatarFile() {
        let filename = getAvatarFilePath()
        if FileManager.default.fileExists(atPath: filename.path) {
            try? FileManager.default.removeItem(at: filename)
            print("🗑️ Файл аватара удалён")
        }
    }
    
    private func uploadAvatarToServer(_ image: UIImage) async {
        let resized = resizeImage(image, maxDimension: 1024)
        guard let jpegData = resized.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            let profile = try await UserAPIService.shared.uploadAvatar(imageData: jpegData, mimeType: "image/jpeg")
            await MainActor.run {
                self.avatarUrl = profile.avatarUrl
            }
        } catch {
            await MainActor.run {
                showError(message: "Не удалось загрузить аватар: \(error.localizedDescription)")
            }
        }
    }

    private func deleteAvatarFromServer() async {
        do {
            let profile = try await UserAPIService.shared.deleteAvatar()
            await MainActor.run {
                self.avatarUrl = nil
                deleteAvatarFile()
            }
        } catch {
            await MainActor.run {
                showError(message: "Не удалось удалить аватар: \(error.localizedDescription)")
                loadAvatarFromDisk()
            }
        }
    }
    
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat = 1024) -> UIImage {
        let size = image.size
        let widthRatio = maxDimension / size.width
        let heightRatio = maxDimension / size.height
        let scale = min(widthRatio, heightRatio)
        guard scale < 1 else { return image }
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image
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
    
    // MARK: - Authenticated View
    private var authenticatedView: some View {
        VStack(spacing: 24) {
            // Avatar
            AvatarView(
                imageUrl: makeFullURL(path: avatarUrl),
                localImage: $avatarLocalImage,
                size: 100,
                editable: true,
                onImageChanged: { image in
                    if let image = image {
                        saveAvatarLocally(image)
                        Task {
                            await uploadAvatarToServer(image)
                        }
                    } else {
                        Task {
                            await deleteAvatarFromServer()
                        }
                    }
                }
            )
            
            // Username row
            HStack {
                if let name = currentUsername, !name.isEmpty {
                    Text(name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "C7FF00"))
                    Button(action: {
                        tempName = name
                        isEditingName = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    Text(NSLocalizedString("profile_default_title", comment: ""))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            
            if currentUsername == nil || currentUsername!.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("user_name_label", comment: ""))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .foregroundColor(.black)
                        .accentColor(.blue)
                        .background(Color.white)
                        .cornerRadius(8)
                        .disabled(isSaving)
                        .onChange(of: userName) { newValue in
                            if newValue.count > 20 {
                                userName = String(newValue.prefix(20))
                            }
                        }
                }
            }
            
            // Participate toggle
            Toggle(isOn: $participateInRanking) {
                Text(NSLocalizedString("user_ranking_toggle", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
            .disabled(isSaving)
            .onChange(of: participateInRanking) { newValue in
                if currentUsername?.isEmpty == false {
                    Task {
                        await updateRatingOnly(newValue)
                    }
                }
            }
            
            StatRow(
                icon: "trophy.fill",
                title: NSLocalizedString("menu_achievements_title", comment: ""),
                value: "\(unlockedAchievementsCount)/\(totalAchievementsCount)"
            )
            
            // MARK: - Мои подписки
            VStack(alignment: .leading, spacing: 0) {
                // Заголовок плашки
                HStack {
                    Text(NSLocalizedString("your_friends_title", comment: ""))
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    if !myFollows.isEmpty {
                        Text("\(myFollows.count)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))

                if isLoadingFollows {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Spacer()
                    }
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.04))
                } else if myFollows.isEmpty {
                    VStack(spacing: 6) {
                        Text(NSLocalizedString("friends_empty_title", comment: "Нет подписок"))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        Text(NSLocalizedString("friends_empty_hint", comment: "Перейдите в рейтинг, чтобы подписаться"))
                            .font(.caption)
                            .foregroundColor(Color(hex: "C7FF00").opacity(0.7))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white.opacity(0.04))
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(myFollows.enumerated()), id: \.element.id) { index, follow in
                            HStack(spacing: 12) {
                                // Аватар
                                let avatarURL = makeFullURL(path: follow.avatarUrl)
                                if let url = avatarURL {
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
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.system(size: 16))
                                        )
                                }

                                Button(action: { selectedFollowUser = follow }) {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(follow.username)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(.white)
                                        if follow.isMutual {
                                            Text(NSLocalizedString("user_is_friend", comment: ""))
                                                .font(.caption2)
                                                .foregroundColor(Color(hex: "C7FF00"))
                                        }
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                if follow.isMutual {
                                    Image(systemName: "person.2.fill")
                                        .foregroundColor(Color(hex: "C7FF00"))
                                        .font(.system(size: 13))
                                }

                                Button(NSLocalizedString("remove_friend_button", comment: "")) {
                                    Task { await unfollowUser(userId: follow.userId) }
                                }
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))

                            if index < myFollows.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 64)
                            }
                        }
                    }
                }
            }
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // MARK: - Подписчики (кто на меня, но я не в ответ)
            if !pendingFollowers.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    // Заголовок плашки
                    HStack {
                        Text(NSLocalizedString("followers_pending_title", comment: "Подписаны на меня"))
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(pendingFollowers.count)")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.08))

                    VStack(spacing: 0) {
                        ForEach(Array(pendingFollowers.enumerated()), id: \.element.id) { index, follower in
                            HStack(spacing: 12) {
                                let avatarURL = makeFullURL(path: follower.avatarUrl)
                                if let url = avatarURL {
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
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.system(size: 16))
                                        )
                                }

                                Button(action: { selectedFollowUser = follower }) {
                                    Text(follower.username)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                Button(NSLocalizedString("follow_button", comment: "Подписаться")) {
                                    Task { await followBack(username: follower.username) }
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(hex: "8B5CF6"))
                                .cornerRadius(7)
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.04))

                            if index < pendingFollowers.count - 1 {
                                Divider()
                                    .background(Color.white.opacity(0.08))
                                    .padding(.leading, 64)
                            }
                        }
                    }
                }
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            
            // Save button (only if no name yet)
            if currentUsername == nil || currentUsername!.isEmpty {
                Button(action: saveUserData) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    } else {
                        Text(NSLocalizedString("save_button", comment: ""))
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
                }
                .disabled(isSaving)
            }
        }
    }
    
    // Подписчики, на которых я ещё не подписан в ответ
    private var pendingFollowers: [FollowModel] {
        myFollowers.filter { follower in
            !myFollows.contains(where: { $0.userId == follower.userId })
        }
    }
    
    private var unlockedAchievementsCount: Int {
        return NewAchievementManager.shared.loadUnlockedAchievements().filter { $0.isUnlocked }.count
    }
    
    private var totalAchievementsCount: Int {
        return NewAchievementManager.shared.getAllAchievements().count
    }
    
    private func validateAndSaveEditedName() {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            editErrorMessage = NSLocalizedString("error_username_empty", comment: "")
            return
        }
        guard !trimmed.contains(" ") else {
            editErrorMessage = NSLocalizedString("error_username_contains_space", comment: "")
            return
        }
        guard trimmed.count >= 3 else {
            editErrorMessage = NSLocalizedString("error_username_too_short", comment: "")
            return
        }
        guard trimmed.count <= 20 else {
            editErrorMessage = NSLocalizedString("error_username_too_long", comment: "")
            return
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        if trimmed.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            editErrorMessage = NSLocalizedString("error_username_invalid_characters", comment: "")
            return
        }
        
        editErrorMessage = nil
        saveEditedName()
    }
    
    // Edit name sheet
    private var editNameSheet: some View {
        NavigationView {
            VStack(spacing: 12) {
                TextField(NSLocalizedString("user_name_label", comment: ""), text: $tempName)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(10)
                    .foregroundColor(.black)
                    .onChange(of: tempName) { newValue in
                        if newValue.count > 20 {
                            tempName = String(newValue.prefix(20))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                
                if let error = editErrorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 30)
                }
                
                Spacer()
            }
            .navigationTitle(NSLocalizedString("edit_username_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("save_button", comment: "")) {
                        validateAndSaveEditedName()
                    }
                }
            }
        }
        .presentationDetents([.height(220)])
        .onAppear {
            editErrorMessage = nil
        }
    }
    
    // MARK: - Data loading
    private func loadSessionAndUserData() async {
        isLoading = true
        if AuthStateManager.shared.accessToken == nil {
            await AuthService.shared.restoreSession()
        }
        sessionType = AuthStateManager.shared.sessionType
        if sessionType == .authenticated {
            await loadUserDataFromServer()
        } else {
            await MainActor.run { isLoading = false }
        }
    }
    
    private func loadUserDataFromServer() async {
        do {
            let session = try await UserAPIService.shared.getSession()
            await MainActor.run {
                currentUsername = session.username
                if let name = session.username, !name.isEmpty {
                    userName = name
                    participateInRanking = session.participateInRating
                } else {
                    userName = ""
                    participateInRanking = true
                }
                avatarUrl = session.avatarUrl
                isLoading = false
                // Загружаем друзей
                Task { await loadFollowData() }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                showError(message: error.localizedDescription)
            }
        }
    }
    
    private func saveUserData() {
        if participateInRanking {
            let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                errorMessage = NSLocalizedString("error_username_empty", comment: "")
                showErrorAlert = true
                return
            }
            guard !trimmed.contains(" ") else {
                errorMessage = NSLocalizedString("error_username_contains_space", comment: "")
                showErrorAlert = true
                return
            }
            guard trimmed.count >= 3 else {
                errorMessage = NSLocalizedString("error_username_too_short", comment: "")
                showErrorAlert = true
                return
            }
            guard trimmed.count <= 20 else {
                errorMessage = NSLocalizedString("error_username_too_long", comment: "")
                showErrorAlert = true
                return
            }

            isSaving = true
            Task {
                do {
                    let profile = try await UserAPIService.shared.updateMyProfile(
                        username: trimmed,
                        participateInRating: true
                    )
                    await MainActor.run {
                        UserDefaults.standard.set(trimmed, forKey: "userName")
                        UserDefaults.standard.set(profile.id, forKey: "userId")
                        UserDefaults.standard.set(true, forKey: "userParticipateInRating")
                        currentUsername = trimmed
                        isSaving = false
                        onRegisterSuccess?(trimmed, profile.id)
                        HapticManager.shared.impact(.light)
                        onClose?()
                    }
                } catch UserAPIError.usernameAlreadyExists {
                    await MainActor.run {
                        errorMessage = NSLocalizedString("error_username_already_exists", comment: "")
                        showErrorAlert = true
                        isSaving = false
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                        isSaving = false
                    }
                }
            }
        } else {
            isSaving = true
            Task {
                do {
                    _ = try await UserAPIService.shared.updateMyRating(participateInRating: false)
                    await MainActor.run {
                        UserDefaults.standard.set(false, forKey: "userParticipateInRating")
                        currentUsername = nil
                        userName = ""
                        isSaving = false
                        HapticManager.shared.impact(.light)
                        onClose?()
                    }
                } catch {
                    await MainActor.run {
                        errorMessage = error.localizedDescription
                        showErrorAlert = true
                        isSaving = false
                    }
                }
            }
        }
    }
    
    private func updateRatingOnly(_ participate: Bool) async {
        do {
            _ = try await UserAPIService.shared.updateMyRating(participateInRating: participate)
            await MainActor.run {
                UserDefaults.standard.set(participate, forKey: "userParticipateInRating")
            }
        } catch UserAPIError.authRequiredForRating, UserAPIError.guestCannotEnableRating {
            await MainActor.run {
                participateInRanking = false
                showError(message: NSLocalizedString("error_auth_required_for_rating", comment: ""))
            }
        } catch {
            await MainActor.run {
                participateInRanking.toggle()
            }
        }
    }
    
    private func saveEditedName() {
        let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            showError(message: NSLocalizedString("error_username_empty", comment: ""))
            return
        }
        guard !trimmed.contains(" ") else {
            showError(message: NSLocalizedString("error_username_contains_space", comment: ""))
            return
        }
        guard trimmed.count >= 3 else {
            showError(message: NSLocalizedString("error_username_too_short", comment: ""))
            return
        }
        guard trimmed.count <= 20 else {
            showError(message: NSLocalizedString("error_username_too_long", comment: ""))
            return
        }
        
        isSaving = true
        Task {
            do {
                let profile = try await UserAPIService.shared.updateMyProfile(
                    username: trimmed,
                    participateInRating: participateInRanking
                )
                await MainActor.run {
                    UserDefaults.standard.set(trimmed, forKey: "userName")
                    currentUsername = trimmed
                    isSaving = false
                    isEditingName = false
                    onRegisterSuccess?(trimmed, profile.id)
                }
            } catch UserAPIError.usernameAlreadyExists {
                await MainActor.run {
                    showError(message: NSLocalizedString("error_username_already_exists", comment: ""))
                    isSaving = false
                }
            } catch {
                await MainActor.run {
                    showError(message: error.localizedDescription)
                    isSaving = false
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        Task {
            do {
                try await AuthService.shared.signInWithGoogle(presentingViewController: rootVC)
                await MainActor.run {
                    Task { await loadSessionAndUserData() }
                }
            } catch {
                if !isCancelledError(error) {
                    await MainActor.run {
                        showError(message: error.localizedDescription)
                    }
                }
            }
        }
    }
  
    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    private func isCancelledError(_ error: Error) -> Bool {
        // Apple Sign In cancel
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            return true
        }
        // Google Sign In cancel (код -5)
        let nsError = error as NSError
        if nsError.domain == "com.google.GIDSignIn" && nsError.code == -5 {
            return true
        }
        return false
    }
    
    // MARK: - Friends

    private func loadFollowData() async {
        guard sessionType == .authenticated else { return }
        await MainActor.run { isLoadingFollows = true }
        defer { Task { await MainActor.run { isLoadingFollows = false } } }
        do {
            async let followsResp = UserAPIService.shared.getMyFollows()
            async let followersResp = UserAPIService.shared.getMyFollowers()
            let (follows, followers) = try await (followsResp, followersResp)
            await MainActor.run {
                myFollows = follows.items
                myFollowers = followers.items
            }
        } catch {
            print("❌ Ошибка загрузки подписок: \(error)")
        }
    }

    private func unfollowUser(userId: Int) async {
        do {
            try await UserAPIService.shared.unfollow(userId: userId)
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            await loadFollowData()
        } catch {
            await MainActor.run { showError(message: error.localizedDescription) }
        }
    }

    private func followBack(username: String) async {
        do {
            _ = try await UserAPIService.shared.follow(username: username)
            NotificationCenter.default.post(name: .followStatusChanged, object: nil)
            await loadFollowData()
        } catch {
            await MainActor.run { showError(message: error.localizedDescription) }
        }
    }
    
}
