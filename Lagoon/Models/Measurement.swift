//
//  Measurement.swift
//  Lagoon
//
//  SwiftData model for pool water measurements.
//

import SwiftData
import Foundation

@Model
final class Measurement {
    var chlorine: Double?          // ppm
    var pH: Double?
    var waterTemperature: Double?  // °C
    var timestamp: Date

    init(
        chlorine: Double? = nil,
        pH: Double? = nil,
        waterTemperature: Double? = nil,
        timestamp: Date = Date()
    ) {
        self.chlorine = chlorine
        self.pH = pH
        self.waterTemperature = waterTemperature
        self.timestamp = timestamp
    }

    // MARK: - Convenience Initializer

    convenience init(chlorine: Double, pH: Double, timestamp: Date = Date()) {
        self.init(chlorine: chlorine, pH: pH, waterTemperature: nil, timestamp: timestamp)
    }

    // MARK: - Summary String

    var summary: String {
        var parts: [String] = []

        if let pH = pH {
            parts.append("pH \(String(format: "%.1f", pH))")
        }
        if let chlorine = chlorine {
            parts.append("Cl \(String(format: "%.1f", chlorine)) mg/l")
        }

        return parts.joined(separator: " · ")
    }
}
