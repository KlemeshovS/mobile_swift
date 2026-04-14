//
//  MilestoneData.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 10.01.2026.
//

// MilestoneData.swift
import Foundation

struct MilestoneDataModel {
    let days: Int
    let icon: String
    let titleKey: String
    let previewKey: String
    let factKeys: [String]
    let fullFactKeys: [String]
}

class MilestoneData {
    static let shared = MilestoneData()
    
    // Основные майлстоуны (5 фактов, для главной)
    private let mainMilestones: [MilestoneDataModel] = [
        MilestoneDataModel(
            days: 2,
            icon: "🎉",
            titleKey: "milestone_48h",
            previewKey: "preview_2d",
            factKeys: ["fact_48h_1", "fact_48h_2", "fact_48h_3", "fact_48h_4", "fact_48h_5"],
            fullFactKeys: ["fact_48h_full_1", "fact_48h_full_2", "fact_48h_full_3", "fact_48h_full_4", "fact_48h_full_5", "fact_48h_full_6"]
        ),
        MilestoneDataModel(
            days: 3,
            icon: "🌟",
            titleKey: "milestone_3d",
            previewKey: "preview_3d",
            factKeys: ["fact_3d_1", "fact_3d_2", "fact_3d_3", "fact_3d_4", "fact_3d_5"],
            fullFactKeys: ["fact_3d_full_1", "fact_3d_full_2", "fact_3d_full_3", "fact_3d_full_4", "fact_3d_full_5", "fact_3d_full_6"]
        ),
        MilestoneDataModel(
            days: 7,
            icon: "🔥",
            titleKey: "milestone_week",
            previewKey: "preview_week",
            factKeys: ["fact_week_1", "fact_week_2", "fact_week_3", "fact_week_4", "fact_week_5"],
            fullFactKeys: ["fact_week_full_1", "fact_week_full_2", "fact_week_full_3", "fact_week_full_4", "fact_week_full_5", "fact_week_full_6"]
        ),
        MilestoneDataModel(
            days: 14,
            icon: "💪",
            titleKey: "milestone_2weeks",
            previewKey: "preview_2w",
            factKeys: ["fact_2w_1", "fact_2w_2", "fact_2w_3", "fact_2w_4", "fact_2w_5"],
            fullFactKeys: ["fact_2w_full_1", "fact_2w_full_2", "fact_2w_full_3", "fact_2w_full_4", "fact_2w_full_5", "fact_2w_full_6"]
        ),
        MilestoneDataModel(
            days: 30,
            icon: "🚀",
            titleKey: "milestone_month",
            previewKey: "preview_month",
            factKeys: ["fact_month_1", "fact_month_2", "fact_month_3", "fact_month_4", "fact_month_5"],
            fullFactKeys: ["fact_month_full_1", "fact_month_full_2", "fact_month_full_3", "fact_month_full_4", "fact_month_full_5", "fact_month_full_6"]
        ),
        MilestoneDataModel(
            days: 60,
            icon: "⚡️",
            titleKey: "milestone_2months",
            previewKey: "preview_2m",
            factKeys: ["fact_2m_1", "fact_2m_2", "fact_2m_3", "fact_2m_4", "fact_2m_5"],
            fullFactKeys: ["fact_2m_full_1", "fact_2m_full_2", "fact_2m_full_3", "fact_2m_full_4", "fact_2m_full_5", "fact_2m_full_6"]
        ),
        MilestoneDataModel(
            days: 90,
            icon: "🏆",
            titleKey: "milestone_3months",
            previewKey: "preview_3m",
            factKeys: ["fact_3m_1", "fact_3m_2", "fact_3m_3", "fact_3m_4", "fact_3m_5"],
            fullFactKeys: ["fact_3m_full_1", "fact_3m_full_2", "fact_3m_full_3", "fact_3m_full_4", "fact_3m_full_5", "fact_3m_full_6"]
        ),
        MilestoneDataModel(
            days: 180,
            icon: "✨",
            titleKey: "milestone_halfyear",
            previewKey: "preview_6m",
            factKeys: ["fact_6m_1", "fact_6m_2", "fact_6m_3", "fact_6m_4", "fact_6m_5"],
            fullFactKeys: ["fact_6m_full_1", "fact_6m_full_2", "fact_6m_full_3", "fact_6m_full_4", "fact_6m_full_5", "fact_6m_full_6"]
        ),
        MilestoneDataModel(
            days: 365,
            icon: "🎯",
            titleKey: "milestone_year",
            previewKey: "preview_year",
            factKeys: ["fact_year_1", "fact_year_2", "fact_year_3", "fact_year_4", "fact_year_5"],
            fullFactKeys: ["fact_year_full_1", "fact_year_full_2", "fact_year_full_3", "fact_year_full_4", "fact_year_full_5", "fact_year_full_6"]
        )
    ]
    
    // Публичные методы
    
    /// Получить текущий достигнутый майлстоун
    func getCurrentMilestone(soberDays: Int) -> MilestoneDataModel? {
        return mainMilestones.last { $0.days <= soberDays }
    }
    
    /// Получить следующий майлстоун
    func getNextMilestone(soberDays: Int) -> MilestoneDataModel? {
        return mainMilestones.first { $0.days > soberDays }
    }
    
    /// Получить все майлстоуны (полная версия)
    func getAllMilestones() -> [MilestoneDataModel] {
        return mainMilestones
    }
    
    /// Получить следующий майлстоун после текущего (для AllMilestonesView)
    func getNextMilestoneAfterCurrent(soberDays: Int) -> (days: Int, title: String)? {
        guard let milestone = getNextMilestone(soberDays: soberDays) else { return nil }
        return (milestone.days, NSLocalizedString(milestone.titleKey, comment: ""))
    }
    
    /// Получить превью для определенного количества дней
    func getPreviewForDays(_ days: Int) -> String {
        let key: String
        switch days {
        case 2: key = "preview_2d"
        case 3: key = "preview_3d"
        case 7: key = "preview_week"
        case 14: key = "preview_2w"
        case 30: key = "preview_month"
        case 60: key = "preview_2m"
        case 90: key = "preview_3m"
        case 180: key = "preview_6m"
        case 365: key = "preview_year"
        default: key = "preview_default"
        }
        return NSLocalizedString(key, comment: "")
    }
    
    /// Получить локализованные факты для майлстоуна
    func getLocalizedFacts(for milestone: MilestoneDataModel, isFullVersion: Bool = false) -> [String] {
        let keys = isFullVersion ? milestone.fullFactKeys : milestone.factKeys
        return keys.map { NSLocalizedString($0, comment: "") }
    }
    
    /// Получить локализованный заголовок
    func getLocalizedTitle(for milestone: MilestoneDataModel) -> String {
        return NSLocalizedString(milestone.titleKey, comment: "")
    }
}
