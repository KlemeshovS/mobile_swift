//
//  AchievementModelTests.swift
//  WobblyTests
//

import Testing
import Foundation
@testable import Wobbly

struct AchievementModelTests {

    @Test func drinkingStreakIsDrinking() {
        let a = Achievement(id: "drink_3", title: "t", description: "d", type: .drinkingStreak(requiredDays: 3))
        #expect(a.isDrinking)
    }

    @Test func soberStreakIsNotDrinking() {
        let a = Achievement(id: "sober_7", title: "t", description: "d", type: .soberStreak(requiredDays: 7))
        #expect(!a.isDrinking)
    }

    @Test func drinkingDaysInYearIsDrinking() {
        let a = Achievement(id: "drink_days_year_100", title: "t", description: "d", type: .drinkingDaysInYear(requiredCount: 100))
        #expect(a.isDrinking)
    }

    @Test func drinkingLevelDaysInYearIsDrinkingForEveryLevel() {
        for level: DrinkLevel in [.little, .medium, .heavy] {
            let a = Achievement(id: "drink_\(level.rawValue)_days_year_50", title: "t", description: "d",
                                 type: .drinkingLevelDaysInYear(level: level, requiredCount: 50))
            #expect(a.isDrinking)
        }
    }

    @Test func drinkingLevelDaysInYearImageNamesAreMapped() {
        let ids = [
            "drink_little_days_year_50", "drink_little_days_year_100",
            "drink_medium_days_year_50", "drink_medium_days_year_100",
            "drink_heavy_days_year_50", "drink_heavy_days_year_100",
        ]
        for id in ids {
            let a = Achievement(id: id, title: "t", description: "d",
                                 type: .drinkingLevelDaysInYear(level: .little, requiredCount: 50))
            #expect(a.imageName == "achievement_\(id)")
        }
    }

    @Test func drinkingLevelDaysInYearCodableRoundTripPreservesLevelAndCount() throws {
        let original = Achievement(id: "drink_heavy_days_year_50", title: "t", description: "d",
                                    type: .drinkingLevelDaysInYear(level: .heavy, requiredCount: 50))
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)

        guard case .drinkingLevelDaysInYear(let level, let count) = decoded.type else {
            Issue.record("Expected drinkingLevelDaysInYear type after decoding")
            return
        }
        #expect(level == .heavy)
        #expect(count == 50)
    }

    @Test func drinkingLevelDaysInYearStringRoundTrips() throws {
        let type = AchievementType.drinkingLevelDaysInYear(level: .medium, requiredCount: 100)
        let restored = try AchievementType.from(string: type.toString())
        guard case .drinkingLevelDaysInYear(let level, let count) = restored else {
            Issue.record("Expected drinkingLevelDaysInYear type after round-trip")
            return
        }
        #expect(level == .medium)
        #expect(count == 100)
    }

    @Test func negativeMilestoneIsDrinking() {
        let a = Achievement(id: "milestone_202_negative", title: "t", description: "d", type: .milestone(target: 202, isNegative: true))
        #expect(a.isDrinking)
        #expect(a.isNegativeMilestone)
        #expect(a.milestoneTarget == 202)
    }

    @Test func positiveMilestoneIsNotDrinking() {
        let a = Achievement(id: "milestone_146", title: "t", description: "d", type: .milestone(target: 146, isNegative: false))
        #expect(!a.isDrinking)
        #expect(!a.isNegativeMilestone)
        #expect(a.milestoneTarget == 146)
    }

    @Test func nonMilestoneHasNoMilestoneTarget() {
        let a = Achievement(id: "sober_7", title: "t", description: "d", type: .soberStreak(requiredDays: 7))
        #expect(a.milestoneTarget == nil)
        #expect(!a.isNegativeMilestone)
    }

    @Test func imageNameMapsKnownIds() {
        let a = Achievement(id: "sober_30", title: "t", description: "d", type: .soberStreak(requiredDays: 30))
        #expect(a.imageName == "achievement_sober_30")
    }

    @Test func imageNameFallsBackForUnknownId() {
        let a = Achievement(id: "totally_made_up_id", title: "t", description: "d", type: .leftReview)
        #expect(a.imageName == "achievement_default")
    }

    // AchievementType.toString()/from(string:) — легаси-формат, используемый для
    // обратной совместимости при декодировании старых сохранённых данных.
    @Test func achievementTypeStringRoundTripsForEveryCase() throws {
        let cases: [AchievementType] = [
            .soberStreak(requiredDays: 7),
            .drinkingStreak(requiredDays: 3),
            .sportCount(period: .last180Days, requiredCount: 50),
            .uniqueEvent(eventType: .sportNewYear),
            .milestone(target: 202, isNegative: true),
            .milestone(target: 146, isNegative: false),
            .soberDaysInYear(requiredCount: 100),
            .drinkingDaysInYear(requiredCount: 200),
            .drinkingLevelDaysInYear(level: .little, requiredCount: 50),
            .soberMonth(month: 12),
            .leftReview,
            .noHangoverStreak(requiredDays: 90),
        ]

        for type in cases {
            let restored = try AchievementType.from(string: type.toString())
            #expect(restored.toString() == type.toString())
        }
    }

    @Test func achievementCodableRoundTripPreservesMilestoneData() throws {
        let original = Achievement(
            id: "milestone_11022_negative",
            title: "Mariana Trench",
            description: "desc",
            type: .milestone(target: 11022, isNegative: true),
            isUnlocked: true
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.isUnlocked == original.isUnlocked)
        #expect(decoded.milestoneTarget == 11022)
        #expect(decoded.isNegativeMilestone == true)
    }

    @Test func achievementCodableRoundTripPreservesSportCountData() throws {
        let original = Achievement(
            id: "sport_50_half_year",
            title: "t",
            description: "d",
            type: .sportCount(period: .last180Days, requiredCount: 50)
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Achievement.self, from: data)

        guard case .sportCount(let period, let count) = decoded.type else {
            Issue.record("Expected sportCount type after decoding")
            return
        }
        #expect(period.daysCount == 180)
        #expect(count == 50)
    }
}
