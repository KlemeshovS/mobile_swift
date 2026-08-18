//
//  CreateBetView.swift
//  Wobbly
//
//  Флоу заключения пари: друг → тип → срок → подтверждение.
//

import SwiftUI

struct CreateBetView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var friends: [FollowModel] = []
    @State private var isLoadingFriends = true
    @State private var friendsError: String?

    @State private var selectedFriend: FollowModel?
    @State private var selectedType: BetType = .sobriety
    @State private var durationMode: BetDurationMode = .period
    @State private var selectedDurationDays: Int = 14
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()

    @State private var isSubmitting = false
    @State private var submitError: String?

    private let durationPresets: [(days: Int, labelKey: String)] = [
        (7, "bet_duration_1_week"),
        (14, "bet_duration_2_weeks"),
        (30, "bet_duration_1_month"),
        (60, "bet_duration_2_months"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(hex: "1A1830"), Color(hex: "2D2B55")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        friendPicker
                        typePicker
                        durationPicker

                        if let submitError = submitError {
                            Text(submitError)
                                .font(.system(size: 13))
                                .foregroundColor(Color(hex: "FF0072"))
                        }

                        submitButton
                    }
                    .padding(16)
                }
            }
            .navigationTitle(NSLocalizedString("bets_create_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(NSLocalizedString("cancel", comment: "")) { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .navigationViewStyle(.stack)
        .task { await loadFriends() }
    }

    // MARK: - Friend picker

    private var friendPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(NSLocalizedString("bets_create_pick_friend", comment: ""))

            if isLoadingFriends {
                ProgressView().tint(.white)
            } else if let friendsError = friendsError {
                Text(friendsError).font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
            } else if friends.isEmpty {
                Text(NSLocalizedString("bets_create_no_friends", comment: ""))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(friends) { friend in
                            friendChip(friend)
                        }
                    }
                }
            }
        }
    }

    private func friendChip(_ friend: FollowModel) -> some View {
        let isSelected = selectedFriend?.userId == friend.userId
        return Button {
            selectedFriend = friend
        } label: {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Text(String(friend.username.prefix(1)).uppercased())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    )
                    .overlay(
                        Circle().stroke(isSelected ? Color(hex: "8B5CF6") : .clear, lineWidth: 3)
                    )
                Text(friend.username)
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    .lineLimit(1)
                    .frame(width: 64)
            }
        }
    }

    // MARK: - Type picker

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(NSLocalizedString("bets_create_pick_type", comment: ""))

            VStack(spacing: 8) {
                ForEach(BetType.allCases, id: \.self) { type in
                    typeRow(type)
                }
            }
        }
    }

    private func typeRow(_ type: BetType) -> some View {
        let isSelected = selectedType == type
        return Button {
            selectedType = type
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(type.localizedTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? Color(hex: "8B5CF6") : .white.opacity(0.3))
                }
                if isSelected {
                    Text(type.conditionDescription)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.white.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color(hex: "8B5CF6") : Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }

    // MARK: - Duration picker

    private var durationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(NSLocalizedString("bets_create_pick_duration", comment: ""))

            Picker("", selection: $durationMode) {
                Text(NSLocalizedString("bet_duration_mode_period", comment: "")).tag(BetDurationMode.period)
                Text(NSLocalizedString("bet_duration_mode_date", comment: "")).tag(BetDurationMode.fixedDate)
            }
            .pickerStyle(.segmented)

            if durationMode == .period {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(durationPresets, id: \.days) { preset in
                        durationChip(days: preset.days, label: NSLocalizedString(preset.labelKey, comment: ""))
                    }
                }
            } else {
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: Calendar.current.date(byAdding: .day, value: 1, to: Date())!...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .colorScheme(.dark)
                .accentColor(Color(hex: "8B5CF6"))
            }
        }
    }

    private func durationChip(days: Int, label: String) -> some View {
        let isSelected = selectedDurationDays == days
        return Button {
            selectedDurationDays = days
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color(hex: "8B5CF6").opacity(0.3) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? Color(hex: "8B5CF6") : Color.white.opacity(0.1), lineWidth: 1)
                )
        }
    }

    // MARK: - Submit

    private var canSubmit: Bool {
        selectedFriend != nil && !isSubmitting
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            if isSubmitting {
                ProgressView().tint(Color(hex: "2D2B55"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .cornerRadius(14)
            } else {
                Text(NSLocalizedString("bets_create_submit", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2B55"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canSubmit ? Color.white : Color.white.opacity(0.3))
                    .cornerRadius(14)
            }
        }
        .disabled(!canSubmit)
    }

    private func loadFriends() async {
        isLoadingFriends = true
        do {
            let response = try await UserAPIService.shared.getMyFriends()
            friends = response.items
        } catch {
            friendsError = NSLocalizedString("bets_create_friends_load_error", comment: "")
        }
        isLoadingFriends = false
    }

    private func submit() async {
        guard let friend = selectedFriend else { return }
        isSubmitting = true
        submitError = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let targetEndDate = durationMode == .fixedDate ? formatter.string(from: selectedDate) : nil

        do {
            _ = try await BetsManager.shared.createBet(
                opponentUserId: friend.userId,
                betType: selectedType,
                durationMode: durationMode,
                durationDays: durationMode == .period ? selectedDurationDays : nil,
                targetEndDate: targetEndDate
            )
            dismiss()
        } catch {
            submitError = (error as? UserAPIError)?.errorDescription ?? NSLocalizedString("bets_create_generic_error", comment: "")
        }
        isSubmitting = false
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.5))
            .textCase(.uppercase)
    }
}
