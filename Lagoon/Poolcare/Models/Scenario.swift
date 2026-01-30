//
//  Scenario.swift
//  Lagoon
//

import Foundation

// MARK: - Operating Mode

enum OperatingMode: String, CaseIterable {
    case summer = "Sommer"
    case winter = "Winter"
    case vacation = "Urlaub"

    var icon: String {
        switch self {
        case .summer: return "sun.max.fill"
        case .winter: return "snowflake"
        case .vacation: return "airplane"
        }
    }

    var description: String {
        switch self {
        case .summer: return "Normaler Poolbetrieb"
        case .winter: return "Pool winterfest"
        case .vacation: return "Abwesend"
        }
    }
}

enum VacationPhase: String, CaseIterable {
    case before = "Vor Abreise"
    case during = "Abwesend"
    case after = "Nach Rückkehr"
}

// MARK: - Legacy Types (kept for reference)

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
