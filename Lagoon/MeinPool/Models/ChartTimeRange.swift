//
//  ChartTimeRange.swift
//  Lagoon
//

import Foundation

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case threeDays = "3D"
    case sevenDays = "7D"
    case fourteenDays = "14D"
    case thirtyDays = "30D"

    var id: String { rawValue }

    /// Number of days the range covers
    private var days: Int {
        switch self {
        case .threeDays: return 3
        case .sevenDays: return 7
        case .fourteenDays: return 14
        case .thirtyDays: return 30
        }
    }

    var startDate: Date {
        let calendar = Calendar.current
        let todayMidnight = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(days - 1), to: todayMidnight)!
    }

    var endDate: Date {
        Date()
    }
}
