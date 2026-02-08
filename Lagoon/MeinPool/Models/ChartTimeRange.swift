//
//  ChartTimeRange.swift
//  Lagoon
//

import Foundation

enum ChartTimeRange: String, CaseIterable, Identifiable {
    case twentyFourHours = "24H"
    case twoDays = "2D"
    case threeDays = "3D"
    case fiveDays = "5D"
    case tenDays = "10D"

    var id: String { rawValue }

    /// Number of days the range covers
    private var days: Int {
        switch self {
        case .twentyFourHours: return 1
        case .twoDays: return 2
        case .threeDays: return 3
        case .fiveDays: return 5
        case .tenDays: return 10
        }
    }

    /// Start of the range: midnight N-1 days ago
    var startDate: Date {
        let calendar = Calendar.current
        let todayMidnight = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: -(days - 1), to: todayMidnight)!
    }

    /// End of the range: midnight tonight
    var endDate: Date {
        let calendar = Calendar.current
        let todayMidnight = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: todayMidnight)!
    }
}
