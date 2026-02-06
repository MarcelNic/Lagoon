//
//  CareTask.swift
//  Lagoon
//

import Foundation
import SwiftData

@Model
final class CareTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var dueDate: Date?
    var intervalDays: Int       // 0 = einmalig, 1 = täglich, 7 = wöchentlich, etc.
    var isAction: Bool          // Timer-Aufgabe (Roboter, Rückspülen)
    var actionDurationSeconds: Double  // Default-Timer in Sekunden
    var iconName: String?       // Icon Name (z.B. "Robi" oder SF Symbol)
    var isCustomIcon: Bool      // true = Asset, false = SF Symbol
    var completedAt: Date?      // nil = noch offen
    var scenario: CareScenario?

    init(
        id: UUID = UUID(),
        title: String,
        dueDate: Date? = nil,
        intervalDays: Int = 0,
        isAction: Bool = false,
        actionDurationSeconds: Double = 0,
        iconName: String? = nil,
        isCustomIcon: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.intervalDays = intervalDays
        self.isAction = isAction
        self.actionDurationSeconds = actionDurationSeconds
        self.iconName = iconName
        self.isCustomIcon = isCustomIcon
        self.completedAt = completedAt
    }

    // MARK: - Computed Properties

    var isCompleted: Bool {
        completedAt != nil
    }

    var urgency: TaskUrgency {
        guard let due = dueDate else { return .future }
        let calendar = Calendar.current

        if due < Date() && !calendar.isDateInToday(due) { return .overdue }
        if calendar.isDateInToday(due) { return .dueToday }
        if calendar.isDate(due, equalTo: Date(), toGranularity: .weekOfYear) { return .upcoming }
        return .future
    }

    var subtitleText: String {
        if let completedAt {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = Locale(identifier: "de_DE")
            formatter.unitsStyle = .full
            return "Erledigt \(formatter.localizedString(for: completedAt, relativeTo: Date()))"
        }

        guard let due = dueDate else {
            return intervalLabel
        }

        let calendar = Calendar.current

        if calendar.isDateInYesterday(due) || due < Date() {
            return "Überfällig"
        }
        if calendar.isDateInToday(due) {
            return "Heute fällig"
        }
        if calendar.isDateInTomorrow(due) {
            return "Morgen"
        }

        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: due)).day ?? 0
        if days <= 7 {
            return "In \(days) Tagen"
        }

        return intervalLabel
    }

    var intervalLabel: String {
        switch intervalDays {
        case 0: return "Einmalig"
        case 1: return "Täglich"
        case 2: return "Alle 2 Tage"
        case 7: return "Wöchentlich"
        case 14: return "Alle 2 Wochen"
        case 30: return "Monatlich"
        default: return "Alle \(intervalDays) Tage"
        }
    }
}

// MARK: - Task Urgency

enum TaskUrgency: Comparable {
    case overdue
    case dueToday
    case upcoming
    case future

    var sortOrder: Int {
        switch self {
        case .overdue: return 0
        case .dueToday: return 1
        case .upcoming: return 2
        case .future: return 3
        }
    }
}
