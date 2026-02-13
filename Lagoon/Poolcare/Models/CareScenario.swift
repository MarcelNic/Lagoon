//
//  CareScenario.swift
//  Lagoon
//

import Foundation
import SwiftData

@Model
final class CareScenario {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String           // SF Symbol name
    var sortOrder: Int
    var isBuiltIn: Bool        // Sommer/Winter/Urlaub nicht löschbar
    var nextScenarioId: UUID?  // Folge-Szenario wenn alle Aufgaben erledigt
    var pausedAt: Date?        // Zeitpunkt der Pausierung (nil = aktiv)

    @Relationship(deleteRule: .cascade, inverse: \CareTask.scenario)
    var tasks: [CareTask] = []

    init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        sortOrder: Int,
        isBuiltIn: Bool = false,
        nextScenarioId: UUID? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
        self.nextScenarioId = nextScenarioId
    }

    var sortedTasks: [CareTask] {
        tasks.sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
}
