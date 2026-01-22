//
//  CareTaskModel.swift
//  Lagoon
//
//  SwiftData model for pool care tasks (maintenance activities).
//

import SwiftData
import Foundation

@Model
final class CareTaskModel {
    var taskName: String
    var taskDescription: String?
    var timestamp: Date

    init(
        taskName: String,
        taskDescription: String? = nil,
        timestamp: Date = Date()
    ) {
        self.taskName = taskName
        self.taskDescription = taskDescription
        self.timestamp = timestamp
    }

    // MARK: - Summary String

    var summary: String {
        taskName
    }
}

// MARK: - Common Care Tasks

extension CareTaskModel {
    /// Predefined task names for quick selection
    static let commonTasks = [
        "Skimmer geleert",
        "Filter rückgespült",
        "Wasserlinie gebürstet",
        "Boden gesaugt",
        "Abdeckung gereinigt",
        "Pumpenkorb geleert",
        "Wasserstand korrigiert"
    ]
}
