import Foundation

/// Main public interface for the Pool Water Estimation & Dosing Engine
///
/// This is a pure Swift module with no dependencies on UI or persistence.
/// All calculations are deterministic and explainable.
///
/// Usage:
/// ```swift
/// let engine = PoolWaterEngine()
/// let output = engine.process(input)
/// ```
public struct PoolWaterEngine {

    // MARK: - Initialization

    public init() {}

    // MARK: - Main Processing

    /// Process input and generate complete engine output
    ///
    /// - Parameter input: Complete engine input
    /// - Returns: Complete engine output with estimates and recommendations
    public func process(_ input: PoolWaterEngineInput) -> PoolWaterEngineOutput {
        return process(input, at: Date())
    }

    /// Process input at a specific date/time (useful for testing)
    ///
    /// - Parameters:
    ///   - input: Complete engine input
    ///   - currentDate: Date to use as "now"
    /// - Returns: Complete engine output
    public func process(
        _ input: PoolWaterEngineInput,
        at currentDate: Date
    ) -> PoolWaterEngineOutput {

        // 1. Estimate current water state
        let (estimatedState, confidence) = WaterStateEstimator.estimate(
            from: input,
            at: currentDate
        )

        // 2. Generate dosing recommendations
        let recommendations = DosingRecommender.recommend(
            for: estimatedState,
            targets: input.targets,
            products: input.products,
            poolVolume_m3: input.poolVolume_m3
        )

        // 3. Return complete output
        return PoolWaterEngineOutput(
            estimatedState: estimatedState,
            confidence: confidence,
            recommendations: recommendations
        )
    }

    // MARK: - Individual Operations (for advanced use)

    /// Estimate water state only (without recommendations)
    ///
    /// - Parameters:
    ///   - input: Engine input
    ///   - currentDate: Current date
    /// - Returns: Estimated state and confidence
    public func estimateState(
        from input: PoolWaterEngineInput,
        at currentDate: Date = Date()
    ) -> (state: EstimatedWaterState, confidence: ConfidenceIndicator) {
        return WaterStateEstimator.estimate(from: input, at: currentDate)
    }

    /// Generate recommendations for a given state
    ///
    /// - Parameters:
    ///   - state: Estimated or measured water state
    ///   - targets: Target ranges
    ///   - products: Available products
    ///   - poolVolume_m3: Pool volume
    /// - Returns: Array of recommendations
    public func recommend(
        for state: EstimatedWaterState,
        targets: WaterTargets,
        products: [String: ProductDefinition],
        poolVolume_m3: Double
    ) -> [DosingRecommendation] {
        return DosingRecommender.recommend(
            for: state,
            targets: targets,
            products: products,
            poolVolume_m3: poolVolume_m3
        )
    }
}

// MARK: - Convenience Extensions

extension PoolWaterEngineInput {

    /// Create input from individual components with sensible defaults
    /// Uses DefaultProducts (Chlor, pH-Plus, pH-Minus) automatically
    public static func create(
        poolVolume_m3: Double,
        lastChlorine_ppm: Double,
        lastPH: Double,
        lastMeasurementISO: String,
        waterTemperature_c: Double = 25.0,
        uvExposure: UVExposureLevel = .medium,
        poolCovered: Bool = false,
        batherLoad: BatherLoadLevel = .none,
        filterRuntime: Double = 8.0,
        dosingHistory: [DosingEvent] = [],
        idealRanges: WaterTargets? = nil
    ) -> PoolWaterEngineInput {

        // Default ideal ranges (target = midpoint)
        let defaultRanges = WaterTargets(
            freeChlorine: ChlorineTargets(min_ppm: 0.5, max_ppm: 1.5),
            pH: PHTargets(min: 7.0, max: 7.4)
        )

        return PoolWaterEngineInput(
            poolVolume_m3: poolVolume_m3,
            lastMeasurement: LastMeasurement(
                freeChlorine_ppm: lastChlorine_ppm,
                pH: lastPH,
                timestampISO: lastMeasurementISO
            ),
            conditions: PoolConditions(
                waterTemperature_c: waterTemperature_c,
                uvExposure: uvExposure,
                poolCovered: poolCovered,
                batherLoad: batherLoad,
                filterRuntime_hours_per_day: filterRuntime
            ),
            dosingHistory: dosingHistory,
            products: DefaultProducts.all,
            targets: idealRanges ?? defaultRanges
        )
    }

    /// Create input using a WeatherProvider for conditions
    public static func create(
        poolVolume_m3: Double,
        lastChlorine_ppm: Double,
        lastPH: Double,
        lastMeasurementISO: String,
        weather: WeatherData,
        poolCovered: Bool = false,
        batherLoad: BatherLoadLevel = .none,
        filterRuntime: Double = 8.0,
        dosingHistory: [DosingEvent] = [],
        idealRanges: WaterTargets? = nil
    ) -> PoolWaterEngineInput {

        return create(
            poolVolume_m3: poolVolume_m3,
            lastChlorine_ppm: lastChlorine_ppm,
            lastPH: lastPH,
            lastMeasurementISO: lastMeasurementISO,
            waterTemperature_c: weather.temperature_c,
            uvExposure: weather.uvExposure,
            poolCovered: poolCovered,
            batherLoad: batherLoad,
            filterRuntime: filterRuntime,
            dosingHistory: dosingHistory,
            idealRanges: idealRanges
        )
    }
}
