//
//  PoolcareTask.swift
//  Lagoon
//

import Foundation

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

struct PoolcareTask: Identifiable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var generatedFromActionId: UUID?

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        generatedFromActionId: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.generatedFromActionId = generatedFromActionId
    }

    var urgency: TaskUrgency {
        guard let due = dueDate else { return .future }
        let now = Date()
        let calendar = Calendar.current

        if due < now && !calendar.isDateInToday(due) { return .overdue }
        if calendar.isDateInToday(due) { return .dueToday }
        if calendar.isDate(due, equalTo: now, toGranularity: .weekOfYear) { return .upcoming }
        return .future
    }

    static func sampleTasks() -> [PoolcareTask] {
        let calendar = Calendar.current
        let now = Date()

        return [
            PoolcareTask(
                title: "Skimmer leeren",
                subtitle: "Heute fällig",
                dueDate: now
            ),
            PoolcareTask(
                title: "Wasserlinie bürsten",
                subtitle: "Wöchentlich",
                dueDate: calendar.date(byAdding: .day, value: 1, to: now)
            ),
            PoolcareTask(
                title: "Filterdruck prüfen",
                subtitle: "7 Tage seit letztem Mal",
                dueDate: calendar.date(byAdding: .day, value: 2, to: now)
            ),
            PoolcareTask(
                title: "Boden saugen",
                subtitle: "Demnächst",
                dueDate: calendar.date(byAdding: .day, value: 5, to: now)
            )
        ]
    }
}
