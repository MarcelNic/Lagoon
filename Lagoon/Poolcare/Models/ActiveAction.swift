//
//  ActiveAction.swift
//  Lagoon
//

import Foundation

enum ActionType: String, CaseIterable {
    case robot
    case backwash

    var title: String {
        switch self {
        case .robot: return "Roboter starten"
        case .backwash: return "Rückspülen starten"
        }
    }

    var icon: String {
        switch self {
        case .robot: return "Robi"
        case .backwash: return "arrow.circlepath"
        }
    }

    var isCustomIcon: Bool {
        switch self {
        case .robot: return true
        case .backwash: return false
        }
    }

    var activeLabel: String {
        switch self {
        case .robot: return "Roboter läuft"
        case .backwash: return "Rückspülen läuft"
        }
    }

    var defaultDuration: TimeInterval {
        switch self {
        case .robot: return 2 * 60 * 60      // 2 Stunden
        case .backwash: return 3 * 60        // 3 Minuten
        }
    }

    var followUpTask: (title: String, subtitle: String) {
        switch self {
        case .robot: return ("Roboter entnehmen & säubern", "Timer abgelaufen")
        case .backwash: return ("Rückspülen beenden / Ventil zurückstellen", "Timer abgelaufen")
        }
    }

    var taskTitle: String {
        switch self {
        case .robot: return "Roboter"
        case .backwash: return "Rückspülen"
        }
    }

    var taskSubtitle: String {
        switch self {
        case .robot: return "2h Standard"
        case .backwash: return "3 Min Standard"
        }
    }
}

struct ActiveAction: Identifiable, Equatable {
    let id: UUID
    let type: ActionType
    let startTime: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), type: ActionType, startTime: Date = Date(), duration: TimeInterval? = nil) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.duration = duration ?? type.defaultDuration
    }

    var endTime: Date {
        startTime.addingTimeInterval(duration)
    }

    var remainingTime: TimeInterval {
        max(0, endTime.timeIntervalSince(Date()))
    }

    var isExpired: Bool {
        remainingTime <= 0
    }

    var progress: Double {
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, elapsed / duration)
    }
}
