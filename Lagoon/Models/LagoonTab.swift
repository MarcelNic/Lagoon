//
//  LagoonTab.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI

enum LagoonTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case care = "Care"
    case pool = "Pool"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .home: return "house"
        case .care: return "checklist"
        case .pool: return "drop"
        }
    }

    var index: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }
}
