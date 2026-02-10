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

    var startDate: Date {
        switch self {
        case .twentyFourHours:
            return Date().addingTimeInterval(-24 * 3600)
        default:
            let calendar = Calendar.current
            let todayMidnight = calendar.startOfDay(for: Date())
            return calendar.date(byAdding: .day, value: -(days - 1), to: todayMidnight)!
        }
    }

    var endDate: Date {
        switch self {
        case .twentyFourHours:
            return Date()
        default:
            let calendar = Calendar.current
            let todayMidnight = calendar.startOfDay(for: Date())
            return calendar.date(byAdding: .day, value: 1, to: todayMidnight)!
        }
    }
}
