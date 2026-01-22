//
//  PoolSettings.swift
//  Lagoon
//
//  SwiftData model for pool configuration.
//

import SwiftData
import Foundation

@Model
final class PoolSettings {
    var poolName: String
    var poolVolume: Double         // m³
    var hasCover: Bool
    var pumpRuntime: Double        // Stunden/Tag

    // Chemistry targets
    var phMin: Double
    var phMax: Double
    var chlorineMin: Double
    var chlorineMax: Double

    // Metadata
    var createdAt: Date
    var updatedAt: Date

    init(
        poolName: String = "Mein Pool",
        poolVolume: Double = 50.0,
        hasCover: Bool = false,
        pumpRuntime: Double = 8.0,
        phMin: Double = 7.0,
        phMax: Double = 7.4,
        chlorineMin: Double = 0.5,
        chlorineMax: Double = 1.5
    ) {
        self.poolName = poolName
        self.poolVolume = poolVolume
        self.hasCover = hasCover
        self.pumpRuntime = pumpRuntime
        self.phMin = phMin
        self.phMax = phMax
        self.chlorineMin = chlorineMin
        self.chlorineMax = chlorineMax
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Computed Properties

    var phTarget: Double {
        (phMin + phMax) / 2.0
    }

    var chlorineTarget: Double {
        (chlorineMin + chlorineMax) / 2.0
    }
}
