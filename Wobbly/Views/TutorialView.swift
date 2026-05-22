//
//  TutorialView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 08.01.2026.
//
import SwiftUI
import Foundation
import AuthenticationServices
import GoogleSignIn

// MARK: - Tutorial Page Model
struct TutorialPage {
    let title: String
    let description: String
    let imageName: String
    let showButton: Bool
    let isProfilePage: Bool
}

struct TutorialView: View {
    @Binding var isShowing: Bool
    @StateObject private var tutorialManager = TutorialManager()
    @State private var currentPage = 0

    private let pages = [
        TutorialPage(
            title: NSLocalizedString("tutorial_title_1", comment: ""),
            description: NSLocalizedString("tutorial_desc_1", comment: ""),
            imageName: "person.fill.questionmark",
            showButton: false,
            isProfilePage: false
        ),
        TutorialPage(
            title: NSLocalizedString("tutorial_title_2", comment: ""),
            description: NSLocalizedString("tutorial_desc_2", comment: ""),
            imageName: "wineglass.fill",
            showButton: false,
            isProfilePage: false
        ),
        TutorialPage(
            title: NSLocalizedString("tutorial_title_3", comment: ""),
            description: NSLocalizedString("tutorial_desc_3", comment: ""),
            imageName: "dumbbell.fill",
            showButton: false,
            isProfilePage: false
        ),
        TutorialPage(
            title: NSLocalizedString("tutorial_title_4", comment: ""),
            description: NSLocalizedString("tutorial_desc_4", comment: ""),
            imageName: "chart.bar.fill",
            showButton: false,
            isProfilePage: false
        ),
        TutorialPage(
            title: NSLocalizedString("tutorial_title_5", comment: ""),
            description: NSLocalizedString("tutorial_desc_5", comment: ""),
            imageName: "lock.shield.fill",
            showButton: false,
            isProfilePage: false
        ),
        TutorialPage(
            title: NSLocalizedString("tutorial_title_profile", comment: ""),
            description: "",
            imageName: "person.fill",
            showButton: true,
            isProfilePage: true
        )
    ]

    var body: some View {
        ZStack {
            // Получение гостевой сессии при необходимости
            Color.clear
                .frame(width: 0, height: 0)
                .onAppear {
                    Task {
                        if AuthStateManager.shared.accessToken == nil {
                            await AuthService.shared.restoreSession()
                        }
                    }
                }
            
            backgroundGradient.ignoresSafeArea()

            VStack(spacing: 0) {
                // Индикатор страниц
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 50)

                // Контент
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        pageView(for: index)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
    }
    
    private func pageView(for index: Int) -> some View {
        TutorialPageView(
            page: pages[index],
            isLastPage: index == pages.count - 1,
            onGetStarted: {
                tutorialManager.completeTutorial()
                UserDefaults.standard.set(true, forKey: "hasShownNamePrompt")
                withAnimation(.spring()) {
                    isShowing = false
                }
            },
            onNext: {
                withAnimation(.spring()) {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    }
                }
            },
            onRegisterSuccess: { username, userId in
            }
        )
    }
    
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "000000"),
                Color(hex: "2A1E5C"),
                Color(hex: "4B3A91")
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Tutorial Page View
struct TutorialPageView: View {
    let page: TutorialPage
    let isLastPage: Bool
    let onGetStarted: () -> Void
    let onNext: () -> Void
    let onRegisterSuccess: ((String, Int) -> Void)?

    @State private var contentAppeared = false

    var body: some View {
        if page.isProfilePage {
            TutorialProfileView(
                onNext: onNext,
                isLastPage: isLastPage,
                onGetStarted: onGetStarted,
                onRegisterSuccess: onRegisterSuccess
            )
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    contentAppeared = true
                }
            }
        } else {
            VStack(spacing: 40) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8B5CF6").opacity(0.3),
                                    Color(hex: "4B3A91").opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 160, height: 160)

                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "4B3A91")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: page.imageName)
                        .font(.system(size: 45, weight: .regular))
                        .foregroundColor(.white)
                }
                .scaleEffect(contentAppeared ? 1.0 : 0.8)
                .opacity(contentAppeared ? 1.0 : 0.0)

                VStack(spacing: 20) {
                    Text(page.title)
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .scaleEffect(contentAppeared ? 1.0 : 0.9)
                        .opacity(contentAppeared ? 1.0 : 0.0)

                    Text(page.description)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 20)
                        .scaleEffect(contentAppeared ? 1.0 : 0.9)
                        .opacity(contentAppeared ? 1.0 : 0.0)
                }

                Spacer()

                if page.showButton {
                    Button(action: {
                        HapticManager.shared.impact(.medium)
                        onGetStarted()
                    }) {
                        HStack {
                            Text(NSLocalizedString("tutorial_start_suffering_button", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [Color(hex: "EFFFB6"), Color(hex: "C7FF00")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .cornerRadius(isLastPage ? 12 : 25)
                        .shadow(color: Color(hex: "C7FF00").opacity(0.3), radius: 10, x: 0, y: 5)
                    }
                    .scaleEffect(contentAppeared ? 1.0 : 0.9)
                    .opacity(contentAppeared ? 1.0 : 0.0)
                } else {
                    Button(action: {
                        HapticManager.shared.impact(.light)
                        onNext()
                    }) {
                        HStack {
                            Text(NSLocalizedString("tutorial_next_button", comment: ""))
                                .font(.system(size: 18, weight: .bold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(isLastPage ? 12 : 25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .scaleEffect(contentAppeared ? 1.0 : 0.9)
                    .opacity(contentAppeared ? 1.0 : 0.0)
                }

                Spacer().frame(height: 50)
            }
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    contentAppeared = true
                }
            }
        }
    }
}

// MARK: - Tutorial Profile View (обновлённая версия)
struct TutorialProfileView: View {
    let onNext: () -> Void
    let isLastPage: Bool
    let onGetStarted: () -> Void
    let onRegisterSuccess: ((String, Int) -> Void)?
    
    @State private var userName: String = ""
    @State private var participateInRanking: Bool = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var keyboardHeight: CGFloat = 0
    
    @State private var sessionType: SessionType = .guest
    @State private var isLoading = true
    @State private var currentUsername: String? = nil
    @State private var validationError: String?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                Spacer(minLength: 20)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6").opacity(0.3), Color(hex: "4B3A91").opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "8B5CF6"), Color(hex: "4B3A91")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                }
                
                Text(NSLocalizedString("tutorial_title_profile", comment: ""))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(NSLocalizedString("tutorial_desc_profile", comment: ""))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 20)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    if sessionType == .guest {
                        guestView
                    } else {
                        authenticatedView
                    }
                }
                
                Spacer(minLength: keyboardHeight)
            }
            .padding(.vertical, 20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            loadSessionAndUserData()
            setupKeyboardNotifications()
        }
        .onDisappear {
            removeKeyboardNotifications()
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text(NSLocalizedString("error", comment: "")),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var guestView: some View {
        VStack(spacing: 20) {
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
                                        loadSessionAndUserData()
                                    }
                                } catch {
                                    showError = true
                                    errorMessage = error.localizedDescription
                                }
                            }
                        case .failure(let error):
                            showError = true
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .cornerRadius(12)
            .padding(.horizontal, 40)
            
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
                .frame(height: 50)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)                
            
            // Skip button
            Button(action: {
                onGetStarted()
            }) {
                Text(NSLocalizedString("skip_button", comment: ""))
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.top, 10)
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: 20) {
            if currentUsername == nil || currentUsername!.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("user_name_label", comment: ""))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("", text: $userName)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .cornerRadius(10)
                        .foregroundColor(.black)
                        .disabled(isSaving)
                        .onChange(of: userName) { newValue in
                            if newValue.count > 20 {
                                userName = String(newValue.prefix(20))
                            }
                            validationError = nil
                        }
                    
                    if let error = validationError {
                        Text(error)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                }
                .padding(.horizontal, 40)
                
                Toggle(isOn: $participateInRanking) {
                    Text(NSLocalizedString("user_ranking_toggle", comment: ""))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "8B5CF6")))
                .disabled(isSaving)
                .padding(.horizontal, 40)
                
                Button(action: validateAndSave) {
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
                .padding(.horizontal, 40)
            } else {
                VStack(spacing: 12) {
                    Text("\(NSLocalizedString("welcome_back", comment: "")) \(currentUsername!)!")
                        .font(.title3)
                        .foregroundColor(Color(hex: "C7FF00"))
                    
                    Button(action: onGetStarted) {
                        Text(NSLocalizedString("tutorial_start_suffering_button", comment: ""))
                            .font(.headline)
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
                }
            }
        }
    }
    
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            showError = true
            errorMessage = "Cannot present Google Sign-In"
            return
        }
        Task {
            do {
                try await AuthService.shared.signInWithGoogle(presentingViewController: rootVC)
                await MainActor.run {
                    loadSessionAndUserData()
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func loadSessionAndUserData() {
        isLoading = true
        sessionType = AuthStateManager.shared.sessionType
        if sessionType == .authenticated {
            Task {
                do {
                    let session = try await UserAPIService.shared.getSession()
                    await MainActor.run {
                        currentUsername = session.username
                        if let name = session.username, !name.isEmpty {
                            userName = name
                        } else {
                            userName = ""
                        }
                        participateInRanking = session.participateInRating
                        isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
        } else {
            isLoading = false
        }
    }
    
    private func validateAndSave() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            validationError = NSLocalizedString("error_username_empty", comment: "")
            return
        }
        guard !trimmed.contains(" ") else {
            validationError = NSLocalizedString("error_username_contains_space", comment: "")
            return
        }
        guard trimmed.count >= 3 else {
            validationError = NSLocalizedString("error_username_too_short", comment: "")
            return
        }
        guard trimmed.count <= 20 else {
            validationError = NSLocalizedString("error_username_too_long", comment: "")
            return
        }
        
        let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        if trimmed.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            validationError = NSLocalizedString("error_username_invalid_characters", comment: "")
            return
        }
        
        validationError = nil
        saveAndComplete()
    }
    
    private func saveAndComplete() {
        let trimmed = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if participateInRanking {
            isSaving = true
            Task {
                do {
                    let profile = try await UserAPIService.shared.updateMyProfile(
                        username: trimmed,
                        participateInRating: true
                    )
                    await MainActor.run {
                        UserDefaults.standard.set(trimmed, forKey: "userName")
                        UserDefaults.standard.set(true, forKey: "userParticipateInRating")
                        onRegisterSuccess?(trimmed, profile.id)
                        isSaving = false
                        onGetStarted()
                    }
                } catch UserAPIError.usernameAlreadyExists {
                    await MainActor.run {
                        validationError = NSLocalizedString("error_username_already_exists", comment: "")
                        isSaving = false
                    }
                } catch {
                    await MainActor.run {
                        validationError = error.localizedDescription
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
                        isSaving = false
                        onGetStarted()
                    }
                } catch {
                    await MainActor.run {
                        validationError = error.localizedDescription
                        isSaving = false
                    }
                }
            }
        }
    }
    
    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
    
    private func removeKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView(isShowing: .constant(true))
    }
}
