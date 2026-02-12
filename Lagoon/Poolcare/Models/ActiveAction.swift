//
//  ActiveAction.swift
//  Lagoon
//

import Foundation

struct ActiveAction: Identifiable, Equatable {
    let id: UUID
    let taskId: UUID           // Reference to the CareTask
    let title: String          // Display title (e.g. "Roboter läuft")
    let iconName: String?      // Icon for display
    let isCustomIcon: Bool     // true = Asset, false = SF Symbol
    let startTime: Date
    let duration: TimeInterval
    let remindAfterTimer: Bool

    init(
        id: UUID = UUID(),
        taskId: UUID,
        title: String,
        iconName: String? = nil,
        isCustomIcon: Bool = false,
        startTime: Date = Date(),
        duration: TimeInterval,
        remindAfterTimer: Bool = false
    ) {
        self.id = id
        self.taskId = taskId
        self.title = title
        self.iconName = iconName
        self.isCustomIcon = isCustomIcon
        self.startTime = startTime
        self.duration = duration
        self.remindAfterTimer = remindAfterTimer
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

    var activeLabel: String {
        "\(title) läuft"
    }
}
