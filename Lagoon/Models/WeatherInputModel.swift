//
//  WeatherInputModel.swift
//  Lagoon
//
//  SwiftData model for weather input data.
//  Prepared for both manual input and future WeatherKit integration.
//

import SwiftData
import Foundation

@Model
final class WeatherInputModel {
    var temperature: Double        // °C
    var uvIndex: Double            // 0-11
    var timestamp: Date
    var source: String             // "manual" or "weatherkit"

    init(
        temperature: Double,
        uvIndex: Double,
        timestamp: Date = Date(),
        source: String = "manual"
    ) {
        self.temperature = temperature
        self.uvIndex = uvIndex
        self.timestamp = timestamp
        self.source = source
    }

    // MARK: - UV Exposure Level (for Engine)

    var uvExposureLevel: UVExposureLevel {
        switch uvIndex {
        case 0..<3:
            return .low
        case 3..<6:
            return .medium
        default:
            return .high
        }
    }

    // MARK: - Convert to Engine WeatherData

    func toWeatherData() -> WeatherData {
        WeatherData(
            temperature_c: temperature,
            uvIndex: uvIndex
        )
    }
}

// MARK: - Convenience Methods

extension WeatherInputModel {
    /// Check if the weather data is still recent (within last 4 hours)
    var isRecent: Bool {
        let fourHoursAgo = Calendar.current.date(byAdding: .hour, value: -4, to: Date()) ?? Date()
        return timestamp > fourHoursAgo
    }

    /// Human-readable UV description
    var uvDescription: String {
        switch uvIndex {
        case 0..<3:
            return "Niedrig"
        case 3..<6:
            return "Mittel"
        case 6..<8:
            return "Hoch"
        default:
            return "Sehr hoch"
        }
    }
}
