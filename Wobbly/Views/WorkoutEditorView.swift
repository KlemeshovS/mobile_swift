//
//  WorkoutEditorView.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 01.06.26.
//

import SwiftUI

struct WorkoutEditorView: View {
    let dayKey: String
    let workout: WorkoutData?
    let onSave: (WorkoutData) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var activityName: String
    @State private var durationMinutes: String
    @State private var durationSeconds: String
    @State private var distanceKm: String
    @State private var calories: String

    init(dayKey: String, workout: WorkoutData?, onSave: @escaping (WorkoutData) -> Void) {
        self.dayKey = dayKey
        self.workout = workout
        self.onSave = onSave

        _activityName = State(initialValue: workout?.activityName ?? "")
        let totalSec = Int(workout?.durationSeconds ?? 0)
        _durationMinutes = State(initialValue: "\((totalSec % 3600) / 60)")
        _durationSeconds = State(initialValue: "\(totalSec % 60)")
        if let d = workout?.distanceMeters, d > 0 {
            _distanceKm = State(initialValue: String(format: "%.2f", d / 1000))
        } else {
            _distanceKm = State(initialValue: "")
        }
        if let c = workout?.calories, c > 0 {
            _calories = State(initialValue: String(format: "%.0f", c))
        } else {
            _calories = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "1E1E2E").ignoresSafeArea()

                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("workout_type_label", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        TextField(NSLocalizedString("workout_type_placeholder", comment: ""), text: $activityName)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("workout_duration_label", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        HStack(spacing: 10) {
                            HStack {
                                TextField("0", text: $durationMinutes)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                Text(NSLocalizedString("workout_min", comment: ""))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            HStack {
                                TextField("0", text: $durationSeconds)
                                    .keyboardType(.numberPad)
                                    .padding(12)
                                    .background(Color.white.opacity(0.1))
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                Text(NSLocalizedString("workout_sec", comment: ""))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("workout_distance_label", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        TextField("0.0", text: $distanceKm)
                            .keyboardType(.decimalPad)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("workout_calories_label", comment: ""))
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                        TextField("0", text: $calories)
                            .keyboardType(.numberPad)
                            .padding(12)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Button(action: save) {
                        Text(NSLocalizedString("workout_save_button", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(hex: "C7FF00"))
                            .cornerRadius(12)
                    }
                    Button(action: {
                        WorkoutDataStorage.shared.delete(for: dayKey)
                        onSave(WorkoutData(activityName: "", durationSeconds: 0, distanceMeters: nil, calories: nil))
                        dismiss()
                    }) {
                        Text(NSLocalizedString("workout_delete_button", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.red.opacity(0.15))
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .navigationTitle(NSLocalizedString("workout_title", comment: ""))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        let mins = Double(durationMinutes) ?? 0
        let secs = Double(durationSeconds) ?? 0
        let totalSecs = mins * 60 + secs
        let distM = (Double(distanceKm.replacingOccurrences(of: ",", with: ".")) ?? 0) * 1000
        let cal = Double(calories) ?? 0

        let data = WorkoutData(
            activityName: activityName.isEmpty ? NSLocalizedString("workout_default_name", comment: "") : activityName,
            durationSeconds: totalSecs,
            distanceMeters: distM > 0 ? distM : nil,
            calories: cal > 0 ? cal : nil
        )
        WorkoutDataStorage.shared.save(data, for: dayKey)
        onSave(data)
        dismiss()
    }
}
