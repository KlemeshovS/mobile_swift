//
//  WobblyWidgetIntent.swift
//  Wobbly
//
//  Created by Evgeniy Voynov on 31.05.26.
//

import AppIntents
import WidgetKit

enum WidgetDisplayMode: String, AppEnum {
    case stats = "stats"
    case calendar = "calendar"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Режим отображения")
    static var caseDisplayRepresentations: [WidgetDisplayMode: DisplayRepresentation] = [
        .stats: DisplayRepresentation(title: "Дни и высота"),
        .calendar: DisplayRepresentation(title: "Календарь месяца")
    ]
}

struct WobblyWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Настройка виджета"
    static var description = IntentDescription("Выберите что показывать в виджете")

    @Parameter(title: "Режим", default: .stats)
    var displayMode: WidgetDisplayMode
}
