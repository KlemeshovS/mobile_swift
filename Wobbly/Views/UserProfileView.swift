//
//  UserProfileView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on [Date].
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn

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
                                    showError(message: error.localizedDescription)
                                }
                            }
                        case .failure(let error):
                            showError(message: error.localizedDescription)
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
                await MainActor.run {
                    showError(message: error.localizedDescription)
                }
            }
        }
    }
  
    private func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}
