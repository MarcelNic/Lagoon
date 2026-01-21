//
//  Scenario.swift
//  Lagoon
//

import Foundation

enum ScenarioType: String, CaseIterable {
    case vacation
    case season

    var title: String {
        switch self {
        case .vacation: return "Urlaubsmodus"
        case .season: return "Saison-Planer"
        }
    }

    var icon: String {
        switch self {
        case .vacation: return "airplane"
        case .season: return "snowflake"
        }
    }
}

enum VacationPhase: String, CaseIterable {
    case before = "Davor"
    case after = "Danach"
}

enum SeasonMode: String, CaseIterable {
    case summer = "Sommerbetrieb"
    case winter = "Winterbetrieb"
}

enum SeasonPhase: String, CaseIterable {
    case opening = "Pool öffnen"
    case closing = "Einwinterung"
}

struct ScenarioChecklistItem: Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

struct VacationScenario {
    var isActive: Bool = false
    var beforeChecklist: [ScenarioChecklistItem]
    var afterChecklist: [ScenarioChecklistItem]

    static func defaultChecklist() -> VacationScenario {
        VacationScenario(
            beforeChecklist: [
                ScenarioChecklistItem(title: "Chlorwert erhöhen"),
                ScenarioChecklistItem(title: "pH-Wert prüfen"),
                ScenarioChecklistItem(title: "Abdeckung sichern"),
                ScenarioChecklistItem(title: "Pumpen-Timer einstellen")
            ],
            afterChecklist: [
                ScenarioChecklistItem(title: "Wasserwerte messen"),
                ScenarioChecklistItem(title: "Skimmer leeren"),
                ScenarioChecklistItem(title: "Pool bürsten"),
                ScenarioChecklistItem(title: "Filter rückspülen")
            ]
        )
    }
}

struct SeasonScenario {
    var currentMode: SeasonMode = .summer
    var openingChecklist: [ScenarioChecklistItem]
    var closingChecklist: [ScenarioChecklistItem]

    static func defaultChecklist() -> SeasonScenario {
        SeasonScenario(
            openingChecklist: [
                ScenarioChecklistItem(title: "Abdeckung entfernen & reinigen"),
                ScenarioChecklistItem(title: "Pool gründlich reinigen"),
                ScenarioChecklistItem(title: "Filteranlage in Betrieb nehmen"),
                ScenarioChecklistItem(title: "Stoßchlorung durchführen"),
                ScenarioChecklistItem(title: "pH-Wert einstellen")
            ],
            closingChecklist: [
                ScenarioChecklistItem(title: "Wasserlinie senken"),
                ScenarioChecklistItem(title: "Leitungen entleeren"),
                ScenarioChecklistItem(title: "Pumpe winterfest machen"),
                ScenarioChecklistItem(title: "Wintermittel hinzufügen"),
                ScenarioChecklistItem(title: "Abdeckung aufziehen")
            ]
        )
    }
}
