//
//  LagoonTab.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI

enum LagoonTab: String, CaseIterable, Identifiable {
    case home = "Pool"
    case care = "Care"
    case pool = "Status"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home: return "figure.pool.swim"
        case .care: return "checklist"
        case .pool: return "list.bullet.below.rectangle"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
