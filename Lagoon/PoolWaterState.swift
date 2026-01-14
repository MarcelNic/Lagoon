//
//  PoolWaterState.swift
//  Lagoon
//
//  Observable model that connects UI with the PoolWaterEngine.
//  Reads settings from AppStorage and calculates estimated water state.
//

import SwiftUI

@Observable
final class PoolWaterState {

    // MARK: - Last Measurement (stored in AppStorage via wrapper)

    private(set) var lastChlorine: Double = 1.0
    private(set) var lastPH: Double = 7.2
    private(set) var lastMeasurementDate: Date = Date()

    // MARK: - Estimated State (from Engine)

    private(set) var estimatedChlorine: Double = 1.0
    private(set) var estimatedPH: Double = 7.2
    private(set) var confidence: ConfidenceLevel = .low
    private(set) var confidenceReason: String = "Keine Messung vorhanden"

    // MARK: - Trend Direction

    private(set) var chlorineTrend: TrendDirection = .stable
    private(set) var phTrend: TrendDirection = .stable

    // MARK: - Engine

    private let engine = PoolWaterEngine()

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let lastChlorine = "lastChlorine"
        static let lastPH = "lastPH"
        static let lastMeasurementDate = "lastMeasurementDate"
    }

    // MARK: - Initialization

    init() {
        loadLastMeasurement()
        recalculate()
    }

    // MARK: - Public Methods

    /// Record a new measurement and recalculate estimates
    func recordMeasurement(chlorine: Double, pH: Double, date: Date = Date()) {
        // Store previous values for trend calculation
        let previousChlorine = estimatedChlorine
        let previousPH = estimatedPH

        // Update last measurement
        lastChlorine = chlorine
        lastPH = pH
        lastMeasurementDate = date

        // Save to UserDefaults
        saveLastMeasurement()

        // Recalculate
        recalculate()

        // Calculate trends
        chlorineTrend = calculateTrend(previous: previousChlorine, current: estimatedChlorine)
        phTrend = calculateTrend(previous: previousPH, current: estimatedPH)
    }

    /// Recalculate estimated state based on current conditions
    func recalculate() {
        // Read settings from AppStorage via UserDefaults
        let defaults = UserDefaults.standard

        let poolVolume = defaults.double(forKey: "poolVolume")
        let pumpRuntime = defaults.double(forKey: "pumpRuntime")
        let hasCover = defaults.bool(forKey: "hasCover")

        // Chemistry settings
        let phMin = defaults.double(forKey: "phMin")
        let phMax = defaults.double(forKey: "phMax")
        let chlorineMin = defaults.double(forKey: "chlorineMin")
        let chlorineMax = defaults.double(forKey: "chlorineMax")

        // Use defaults if not set
        let volume = poolVolume > 0 ? poolVolume : 50.0
        let runtime = pumpRuntime > 0 ? pumpRuntime : 8.0
        let phMinVal = phMin > 0 ? phMin : 7.0
        let phMaxVal = phMax > 0 ? phMax : 7.4
        let clMinVal = chlorineMin > 0 ? chlorineMin : 0.5
        let clMaxVal = chlorineMax > 0 ? chlorineMax : 1.5

        // Create engine input
        let input = PoolWaterEngineInput.create(
            poolVolume_m3: volume,
            lastChlorine_ppm: lastChlorine,
            lastPH: lastPH,
            lastMeasurementISO: ISO8601DateFormatter().string(from: lastMeasurementDate),
            waterTemperature_c: 25.0, // TODO: Get from weather/manual input
            uvExposure: .medium,       // TODO: Get from weather
            poolCovered: hasCover,
            batherLoad: .none,         // TODO: Get from recent input
            filterRuntime: runtime,
            dosingHistory: [],         // TODO: Load from SwiftData
            idealRanges: WaterTargets(
                freeChlorine: ChlorineTargets(min_ppm: clMinVal, max_ppm: clMaxVal),
                pH: PHTargets(min: phMinVal, max: phMaxVal)
            )
        )

        // Process with engine
        let output = engine.process(input)

        // Update state
        estimatedChlorine = output.estimatedState.freeChlorine_ppm
        estimatedPH = output.estimatedState.pH
        confidence = output.confidence.confidence
        confidenceReason = output.confidence.reason
    }

    // MARK: - Ideal Ranges (for UI)

    var idealPHMin: Double {
        let val = UserDefaults.standard.double(forKey: "phMin")
        return val > 0 ? val : 7.0
    }

    var idealPHMax: Double {
        let val = UserDefaults.standard.double(forKey: "phMax")
        return val > 0 ? val : 7.4
    }

    var idealChlorineMin: Double {
        let val = UserDefaults.standard.double(forKey: "chlorineMin")
        return val > 0 ? val : 0.5
    }

    var idealChlorineMax: Double {
        let val = UserDefaults.standard.double(forKey: "chlorineMax")
        return val > 0 ? val : 1.5
    }

    // MARK: - Private Methods

    private func loadLastMeasurement() {
        let defaults = UserDefaults.standard

        if let date = defaults.object(forKey: Keys.lastMeasurementDate) as? Date {
            lastMeasurementDate = date
        }

        let chlorine = defaults.double(forKey: Keys.lastChlorine)
        if chlorine > 0 {
            lastChlorine = chlorine
        }

        let pH = defaults.double(forKey: Keys.lastPH)
        if pH > 0 {
            lastPH = pH
        }
    }

    private func saveLastMeasurement() {
        let defaults = UserDefaults.standard
        defaults.set(lastChlorine, forKey: Keys.lastChlorine)
        defaults.set(lastPH, forKey: Keys.lastPH)
        defaults.set(lastMeasurementDate, forKey: Keys.lastMeasurementDate)
    }

    private func calculateTrend(previous: Double, current: Double) -> TrendDirection {
        let threshold = 0.05
        let diff = current - previous

        if diff > threshold {
            return .up
        } else if diff < -threshold {
            return .down
        } else {
            return .stable
        }
    }
}
