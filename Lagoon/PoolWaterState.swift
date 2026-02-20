//
//  PoolWaterState.swift
//  Lagoon
//
//  Observable model that connects UI with the PoolWaterEngine.
//  Integrates with SwiftData for persistence.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class PoolWaterState {

    // MARK: - Last Measurement

    private(set) var lastChlorine: Double = 1.0
    private(set) var lastPH: Double = 7.2
    private(set) var lastWaterTemperature: Double = 26.0
    private(set) var lastMeasurementDate: Date = Date()

    // MARK: - Estimated State (from Engine)

    private(set) var estimatedChlorine: Double = 1.0
    private(set) var estimatedPH: Double = 7.2
    private(set) var confidence: ConfidenceLevel = .low
    private(set) var confidenceReason: String = "Keine Messung vorhanden"

    // MARK: - Dosing Recommendations (from Engine)

    private(set) var chlorineRecommendation: DosingRecommendation?
    private(set) var phRecommendation: DosingRecommendation?

    // MARK: - Trend Direction

    private(set) var chlorineTrend: TrendDirection = .stable
    private(set) var phTrend: TrendDirection = .stable

    // MARK: - Last Dosing (for status pill)

    private(set) var lastDosingTimestamp: Date?
    private(set) var lastDosingChlorineAmount: Double = 0
    private(set) var lastDosingPHAmount: Double = 0
    private(set) var lastDosingPHType: String = ""  // "pH-" or "pH+"

    var dosingNeeded: Bool {
        let clNeeded = chlorineRecommendation?.action == .dose
        let phNeeded = phRecommendation?.action == .dose
        return clNeeded || phNeeded
    }

    var recentDosingActive: Bool {
        guard let ts = lastDosingTimestamp else { return false }
        return Date().timeIntervalSince(ts) < 3600
    }

    // MARK: - Settings (cached from SwiftData or AppStorage)

    private(set) var poolVolume: Double = 50.0
    private(set) var pumpRuntime: Double = 8.0
    private(set) var hasCover: Bool = false
    private(set) var idealPHMin: Double = 7.0
    private(set) var idealPHMax: Double = 7.4
    private(set) var idealChlorineMin: Double = 0.5
    private(set) var idealChlorineMax: Double = 1.5

    // MARK: - Demo Mode

    /// True once the user has recorded at least one real measurement
    private(set) var hasFirstMeasurement: Bool = UserDefaults.standard.bool(forKey: "hasFirstMeasurement")

    /// True when no real measurement exists yet
    var isDemoMode: Bool { !hasFirstMeasurement }

    /// True while sine-wave demo values are shown, false for "--" idle state
    var demoActive: Bool = false

    // MARK: - Error State

    /// Letzte Fehlermeldung beim Speichern (nil = kein Fehler)
    var lastSaveError: String?

    // MARK: - Simulation

    /// Hours offset for time simulation (0 = now)
    var simulationOffsetHours: Double = 0.0

    // MARK: - Engine

    private let engine = PoolWaterEngine()
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: - Cached Data (avoid SwiftData fetches during simulation scrolling)

    private(set) var cachedDosingHistory: [DosingEvent] = []
    private var cachedWeatherTemperature: Double = 25.0
    private var cachedWeatherUV: UVExposureLevel = .medium
    private var cachedEngineInput: PoolWaterEngineInput?

    // MARK: - SwiftData Context

    private var modelContext: ModelContext?

    // MARK: - Initialization

    init() {
        loadSettingsFromUserDefaults()
        loadLastMeasurementFromUserDefaults()
        recalculate()
    }

    // MARK: - SwiftData Integration

    /// Set the model context from environment
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFromSwiftData()
    }

    // MARK: - Public Methods

    /// Record a new measurement and save to SwiftData
    func recordMeasurement(chlorine: Double, pH: Double, waterTemperature: Double? = nil, date: Date = Date()) {
        // Update last measurement
        lastChlorine = chlorine
        lastPH = pH
        if let waterTemperature { lastWaterTemperature = waterTemperature }
        lastMeasurementDate = date

        // Save to UserDefaults (as backup)
        saveLastMeasurementToUserDefaults()

        // Save to SwiftData
        if let context = modelContext {
            let measurement = Measurement(
                chlorine: chlorine,
                pH: pH,
                waterTemperature: waterTemperature,
                timestamp: date
            )
            context.insert(measurement)

            saveContext(context, operation: "Messung")
        }

        // Exit demo mode permanently
        if !hasFirstMeasurement {
            hasFirstMeasurement = true
            UserDefaults.standard.set(true, forKey: "hasFirstMeasurement")
            demoActive = false
        }

        // Refresh cache and recalculate
        refreshCache()
        recalculate()
    }

    /// Record a dosing event and save to SwiftData
    func recordDosing(productId: String, productName: String, amount: Double, unit: String = "g", date: Date = Date()) {
        guard amount > 0 else { return }

        if let context = modelContext {
            let dosing = DosingEventModel(
                productId: productId,
                productName: productName,
                amount: amount,
                unit: unit,
                timestamp: date
            )
            context.insert(dosing)

            saveContext(context, operation: "Dosierung")
        }

        // Update last dosing info for status pill
        lastDosingTimestamp = date
        switch productId {
        case "chlorine":
            lastDosingChlorineAmount = amount
        case "ph_minus":
            lastDosingPHAmount = amount
            lastDosingPHType = "pH-"
        case "ph_plus":
            lastDosingPHAmount = amount
            lastDosingPHType = "pH+"
        default:
            break
        }

        // Refresh cache and recalculate
        refreshCache()
        recalculate()
    }

    /// Save weather input to SwiftData
    func recordWeather(temperature: Double, uvIndex: Double, source: String = "manual", date: Date = Date()) {
        if let context = modelContext {
            let weather = WeatherInputModel(
                temperature: temperature,
                uvIndex: uvIndex,
                timestamp: date,
                source: source
            )
            context.insert(weather)

            saveContext(context, operation: "Wetter")
        }

        // Refresh cache and recalculate
        refreshCache()
        recalculate()
    }

    /// Reload settings from UserDefaults and recalculate
    func reloadSettings() {
        hasFirstMeasurement = UserDefaults.standard.bool(forKey: "hasFirstMeasurement")
        loadSettingsFromUserDefaults()
        refreshCache()
        recalculate()
    }

    private func saveContext(_ context: ModelContext, operation: String) {
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            lastSaveError = "Fehler beim Speichern (\(operation))"
            print("Error saving \(operation): \(error)")
        }
    }

    /// Refresh cached SwiftData values and rebuild engine input.
    /// Call this when underlying data changes (measurement, dosing, weather, settings).
    private func refreshCache() {
        cachedDosingHistory = loadDosingHistorySinceLastMeasurement()
        let weather = loadLatestWeather()
        cachedWeatherTemperature = weather?.temperature ?? 25.0
        cachedWeatherUV = weather?.uvExposureLevel ?? .medium

        cachedEngineInput = PoolWaterEngineInput.create(
            poolVolume_m3: poolVolume,
            lastChlorine_ppm: lastChlorine,
            lastPH: lastPH,
            lastMeasurementISO: isoFormatter.string(from: lastMeasurementDate),
            waterTemperature_c: cachedWeatherTemperature,
            uvExposure: cachedWeatherUV,
            poolCovered: hasCover,
            batherLoad: .none,
            filterRuntime: pumpRuntime,
            dosingHistory: cachedDosingHistory,
            idealRanges: WaterTargets(
                freeChlorine: ChlorineTargets(min_ppm: idealChlorineMin, max_ppm: idealChlorineMax),
                pH: PHTargets(min: idealPHMin, max: idealPHMax)
            )
        )

        // Load recent dosing events for status pill (if not already set this session)
        if lastDosingTimestamp == nil, let context = modelContext {
            let oneHourAgo = Date().addingTimeInterval(-3600)
            var descriptor = FetchDescriptor<DosingEventModel>(
                predicate: #Predicate { $0.timestamp > oneHourAgo },
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            descriptor.fetchLimit = 10
            if let events = try? context.fetch(descriptor), !events.isEmpty {
                lastDosingTimestamp = events.first?.timestamp
                for event in events {
                    switch event.productId {
                    case "chlorine":
                        lastDosingChlorineAmount = event.amount
                    case "ph_minus":
                        lastDosingPHAmount = event.amount
                        lastDosingPHType = "pH-"
                    case "ph_plus":
                        lastDosingPHAmount = event.amount
                        lastDosingPHType = "pH+"
                    default:
                        break
                    }
                }
            }
        }
    }

    /// Recalculate estimated state based on current conditions.
    /// Uses cached engine input — lightweight enough to call on every tick.
    func recalculate() {
        // Demo mode: generate fake values or idle state
        if isDemoMode {
            if demoActive {
                let t = simulationOffsetHours

                // smoothstep for 0...3h transition
                let s = min(max(t / 3.0, 0), 1)
                let ease = s * s * (3 - 2 * s)

                // pH: 7.8 → 7.2 over 3h, then very slowly rises (max ~7.45 at 48h)
                if t <= 3 {
                    estimatedPH = 7.8 - 0.6 * ease
                    phTrend = .down
                } else {
                    estimatedPH = min(7.2 + 0.005 * (t - 3), 7.5)
                    phTrend = .up
                }

                // Chlorine: 0.0 → 1.0 over 3h, then very slowly drops (min ~0.78 at 48h)
                if t <= 3 {
                    estimatedChlorine = 1.0 * ease
                    chlorineTrend = .up
                } else {
                    estimatedChlorine = max(1.0 - 0.005 * (t - 3), 0.5)
                    chlorineTrend = .down
                }

                // At exactly t=0, no trend
                if t == 0 {
                    phTrend = .stable
                    chlorineTrend = .stable
                }
            } else {
                // Idle: markers to target position
                estimatedPH = 7.4
                estimatedChlorine = 1.5
                chlorineTrend = .stable
                phTrend = .stable
            }

            chlorineRecommendation = nil
            phRecommendation = nil
            confidence = .low
            confidenceReason = "Keine Messung vorhanden"
            return
        }

        // Rebuild cache if no engine input exists yet
        if cachedEngineInput == nil {
            refreshCache()
        }

        guard let input = cachedEngineInput else { return }

        // Store previous values for trend calculation
        let previousChlorine = estimatedChlorine
        let previousPH = estimatedPH

        // Process with engine (apply simulation offset)
        let simulationDate = Date().addingTimeInterval(simulationOffsetHours * 3600)
        let output = engine.process(input, at: simulationDate)

        // Update state
        estimatedChlorine = output.estimatedState.freeChlorine_ppm
        estimatedPH = output.estimatedState.pH
        confidence = output.confidence.confidence
        confidenceReason = output.confidence.reason

        // Update recommendations
        chlorineRecommendation = output.recommendations.first { $0.parameter == .freeChlorine }
        phRecommendation = output.recommendations.first { $0.parameter == .pH }

        // Update trends
        chlorineTrend = calculateTrend(previous: previousChlorine, current: estimatedChlorine)
        phTrend = calculateTrend(previous: previousPH, current: estimatedPH)

        // Override trends for pending dosing effects (mixing not yet complete)
        overrideTrendsForPendingDosing(dosingHistory: cachedDosingHistory)
    }

    // MARK: - Prediction Data (for Popovers)

    var phPrediction: PredictionData {
        PredictionData(
            estimatedValue: estimatedPH,
            confidence: confidence,
            confidenceReason: confidenceReason,
            lastMeasuredValue: lastPH,
            lastMeasurementTime: lastMeasurementDate,
            recommendation: phRecommendation,
            lastDosingAmount: lastDosingPHAmount > 0 ? lastDosingPHAmount : nil,
            lastDosingProduct: lastDosingPHAmount > 0 ? lastDosingPHType : nil,
            lastDosingTime: lastDosingPHAmount > 0 ? lastDosingTimestamp : nil,
            weatherTemperature: cachedWeatherTemperature,
            uvLevel: cachedWeatherUV
        )
    }

    var chlorinePrediction: PredictionData {
        PredictionData(
            estimatedValue: estimatedChlorine,
            confidence: confidence,
            confidenceReason: confidenceReason,
            lastMeasuredValue: lastChlorine,
            lastMeasurementTime: lastMeasurementDate,
            recommendation: chlorineRecommendation,
            lastDosingAmount: lastDosingChlorineAmount > 0 ? lastDosingChlorineAmount : nil,
            lastDosingProduct: lastDosingChlorineAmount > 0 ? "Chlorgranulat" : nil,
            lastDosingTime: lastDosingChlorineAmount > 0 ? lastDosingTimestamp : nil,
            weatherTemperature: cachedWeatherTemperature,
            uvLevel: cachedWeatherUV
        )
    }

    // MARK: - Private Methods

    private func loadFromSwiftData() {
        guard let context = modelContext else { return }

        // Load most recent measurement
        let measurementDescriptor = FetchDescriptor<Measurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let measurements = try? context.fetch(measurementDescriptor),
           let latest = measurements.first {
            if let chlorine = latest.chlorine {
                lastChlorine = chlorine
            }
            if let pH = latest.pH {
                lastPH = pH
            }
            if let temp = latest.waterTemperature {
                lastWaterTemperature = temp
            }
            lastMeasurementDate = latest.timestamp

            // Measurements exist — ensure demo mode is off
            if !hasFirstMeasurement {
                hasFirstMeasurement = true
                UserDefaults.standard.set(true, forKey: "hasFirstMeasurement")
            }
        }

        // Load pool settings (if exists)
        let settingsDescriptor = FetchDescriptor<PoolSettings>()
        if let settings = try? context.fetch(settingsDescriptor).first {
            poolVolume = settings.poolVolume
            pumpRuntime = settings.pumpRuntime
            hasCover = settings.hasCover
            idealPHMin = settings.phMin
            idealPHMax = settings.phMax
            idealChlorineMin = settings.chlorineMin
            idealChlorineMax = settings.chlorineMax
        }

        refreshCache()
        recalculate()
    }

    private func loadDosingHistorySinceLastMeasurement() -> [DosingEvent] {
        guard let context = modelContext else { return [] }

        // Include dosings after last measurement AND still-active dosings (within 4h mixing window)
        let activeWindowStart = Date().addingTimeInterval(-4 * 3600)
        let cutoff = min(lastMeasurementDate, activeWindowStart)

        var descriptor = FetchDescriptor<DosingEventModel>(
            predicate: #Predicate { $0.timestamp > cutoff },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        descriptor.fetchLimit = 100

        guard let dosings = try? context.fetch(descriptor) else { return [] }

        return dosings.map { $0.toEngineDosingEvent() }
    }

    private func loadLatestWeather() -> WeatherInputModel? {
        guard let context = modelContext else { return nil }

        var descriptor = FetchDescriptor<WeatherInputModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = 1

        return try? context.fetch(descriptor).first
    }

    private func loadSettingsFromUserDefaults() {
        let defaults = UserDefaults.standard

        let volume = defaults.double(forKey: "poolVolume")
        if volume > 0 { poolVolume = volume }

        let runtime = defaults.double(forKey: "pumpRuntime")
        if runtime > 0 { pumpRuntime = runtime }

        hasCover = defaults.bool(forKey: "hasCover")

        let phMin = defaults.double(forKey: "phMin")
        if phMin > 0 { idealPHMin = phMin }

        let phMax = defaults.double(forKey: "phMax")
        if phMax > 0 { idealPHMax = phMax }

        let clMin = defaults.double(forKey: "chlorineMin")
        if clMin > 0 { idealChlorineMin = clMin }

        let clMax = defaults.double(forKey: "chlorineMax")
        if clMax > 0 { idealChlorineMax = clMax }
    }

    private func loadLastMeasurementFromUserDefaults() {
        let defaults = UserDefaults.standard

        let chlorine = defaults.double(forKey: "lastChlorine")
        if chlorine > 0 { lastChlorine = chlorine }

        let pH = defaults.double(forKey: "lastPH")
        if pH > 0 { lastPH = pH }

        if let date = defaults.object(forKey: "lastMeasurementDate") as? Date {
            lastMeasurementDate = date
        }
    }

    private func saveLastMeasurementToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.set(lastChlorine, forKey: "lastChlorine")
        defaults.set(lastPH, forKey: "lastPH")
        defaults.set(lastMeasurementDate, forKey: "lastMeasurementDate")
    }

    private func overrideTrendsForPendingDosing(dosingHistory: [DosingEvent]) {
        let simulationDate = Date().addingTimeInterval(simulationOffsetHours * 3600)
        let pendingEvents = dosingHistory.filter { event in
            let hoursSince = simulationDate.timeIntervalSince(event.timestamp) / 3600.0
            // Allow small negative values: dosing timestamp can be slightly in the future
            // (e.g. MeasurementDosing sets it +1s after measurement for sort ordering)
            return hoursSince > -0.01 && hoursSince < 4.0
        }

        if pendingEvents.contains(where: { $0.kind == .chlorine }) {
            chlorineTrend = .up
        }
        if pendingEvents.contains(where: { $0.kind == .phMinus }) {
            phTrend = .down
        } else if pendingEvents.contains(where: { $0.kind == .phPlus }) {
            phTrend = .up
        }
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
