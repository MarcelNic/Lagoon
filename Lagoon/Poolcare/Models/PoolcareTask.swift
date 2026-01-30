//
//  PoolcareTask.swift
//  Lagoon
//

import Foundation

// MARK: - Task Visibility

enum TaskVisibility {
    case always              // Immer sichtbar (außer Urlaub)
    case summerOnly          // Nur im Sommerbetrieb
    case winterOnly          // Nur im Winterbetrieb
    case vacationBefore      // Urlaub: Vor Abreise
    case vacationAfter       // Urlaub: Nach Rückkehr

    func isVisible(in mode: OperatingMode, vacationPhase: VacationPhase?) -> Bool {
        switch self {
        case .always:
            return mode != .vacation
        case .summerOnly:
            return mode == .summer
        case .winterOnly:
            return mode == .winter
        case .vacationBefore:
            return mode == .vacation && vacationPhase == .before
        case .vacationAfter:
            return mode == .vacation && vacationPhase == .after
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

struct PoolcareTask: Identifiable, Equatable {
    let id: UUID
    var title: String
    var subtitle: String
    var isCompleted: Bool
    var completedAt: Date?
    var dueDate: Date?
    var generatedFromActionId: UUID?
    var actionType: ActionType?  // Timer-Tasks (Roboter, Rückspülen)
    var visibility: TaskVisibility  // Sichtbarkeit je nach Modus
    var isTransitionTask: Bool  // Einmalige Übergangs-Tasks

    init(
        id: UUID = UUID(),
        title: String,
        subtitle: String,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        dueDate: Date? = nil,
        generatedFromActionId: UUID? = nil,
        actionType: ActionType? = nil,
        visibility: TaskVisibility = .always,
        isTransitionTask: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.dueDate = dueDate
        self.generatedFromActionId = generatedFromActionId
        self.actionType = actionType
        self.visibility = visibility
        self.isTransitionTask = isTransitionTask
    }

    func isVisible(in mode: OperatingMode, vacationPhase: VacationPhase?) -> Bool {
        visibility.isVisible(in: mode, vacationPhase: vacationPhase)
    }

    var isTimerTask: Bool {
        actionType != nil
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
            // MARK: - Sommerbetrieb Tasks

            // Timer-Tasks (nur Sommer)
            PoolcareTask(
                title: "Roboter",
                subtitle: "2h Standard",
                dueDate: now,
                actionType: .robot,
                visibility: .summerOnly
            ),
            PoolcareTask(
                title: "Rückspülen",
                subtitle: "3 Min Standard",
                dueDate: now,
                actionType: .backwash,
                visibility: .summerOnly
            ),

            // Normale Tasks (immer sichtbar außer Urlaub)
            PoolcareTask(
                title: "Skimmer leeren",
                subtitle: "Heute fällig",
                dueDate: now,
                visibility: .always
            ),
            PoolcareTask(
                title: "Wasserlinie bürsten",
                subtitle: "Wöchentlich",
                dueDate: calendar.date(byAdding: .day, value: 1, to: now),
                visibility: .always
            ),
            PoolcareTask(
                title: "Filterdruck prüfen",
                subtitle: "7 Tage seit letztem Mal",
                dueDate: calendar.date(byAdding: .day, value: 2, to: now),
                visibility: .always
            ),
            PoolcareTask(
                title: "Boden saugen",
                subtitle: "Demnächst",
                dueDate: calendar.date(byAdding: .day, value: 5, to: now),
                visibility: .summerOnly
            ),

            // MARK: - Winterbetrieb Tasks

            PoolcareTask(
                title: "Abdeckung prüfen",
                subtitle: "Wöchentlich",
                dueDate: calendar.date(byAdding: .day, value: 7, to: now),
                visibility: .winterOnly
            ),
            PoolcareTask(
                title: "Wasserstand prüfen",
                subtitle: "Monatlich",
                dueDate: calendar.date(byAdding: .month, value: 1, to: now),
                visibility: .winterOnly
            )
        ]
    }
}
