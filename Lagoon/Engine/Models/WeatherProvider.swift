import Foundation

// MARK: - Weather Data

/// Weather data relevant for pool chemistry calculations
public struct WeatherData {
    /// Air/water temperature in Celsius
    public let temperature_c: Double

    /// UV index (0-11+)
    public let uvIndex: Double

    /// Mapped UV exposure level for engine
    public var uvExposure: UVExposureLevel {
        switch uvIndex {
        case 0..<3: return .low
        case 3..<6: return .medium
        default: return .high
        }
    }

    public init(temperature_c: Double, uvIndex: Double) {
        self.temperature_c = temperature_c
        self.uvIndex = uvIndex
    }
}

// MARK: - Weather Provider Protocol

/// Protocol for weather data providers
/// Implement this with WeatherKit or manual input
public protocol WeatherProvider {
    /// Fetch current weather data
    func fetchCurrentWeather() async throws -> WeatherData
}

// MARK: - Manual Weather Provider

/// Manual weather input (default implementation)
/// Use this until WeatherKit is integrated
public final class ManualWeatherProvider: WeatherProvider {
    public var temperature_c: Double
    public var uvIndex: Double

    public init(temperature_c: Double = 25.0, uvIndex: Double = 5.0) {
        self.temperature_c = temperature_c
        self.uvIndex = uvIndex
    }

    public func fetchCurrentWeather() async throws -> WeatherData {
        WeatherData(temperature_c: temperature_c, uvIndex: uvIndex)
    }

    /// Update values from UI
    public func update(temperature: Double, uvIndex: Double) {
        self.temperature_c = temperature
        self.uvIndex = uvIndex
    }
}

// MARK: - WeatherKit Provider (Placeholder)

/// Placeholder for future WeatherKit integration
/// Replace implementation when ready
/*
import WeatherKit
import CoreLocation

public final class WeatherKitProvider: WeatherProvider {
    private let weatherService = WeatherService()
    private let location: CLLocation

    public init(location: CLLocation) {
        self.location = location
    }

    public func fetchCurrentWeather() async throws -> WeatherData {
        let weather = try await weatherService.weather(for: location)
        return WeatherData(
            temperature_c: weather.currentWeather.temperature.value,
            uvIndex: Double(weather.currentWeather.uvIndex.value)
        )
    }
}
*/
