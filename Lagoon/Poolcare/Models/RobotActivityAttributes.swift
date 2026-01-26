//
//  RobotActivityAttributes.swift
//  Lagoon
//
//  Shared between main app and widget extension
//

import ActivityKit
import Foundation

struct RobotActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var progress: Double
    }

    let startTime: Date
    let duration: TimeInterval
    let actionTitle: String
}
