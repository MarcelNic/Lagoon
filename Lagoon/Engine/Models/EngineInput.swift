import Foundation

// MARK: - Main Engine Input

/// Complete input for the pool water estimation engine
public struct PoolWaterEngineInput: Codable {
    /// Pool volume in cubic meters
    public let poolVolume_m3: Double

    /// Last measurement data
    public let lastMeasurement: LastMeasurement

    /// Current environmental conditions
    public let conditions: PoolConditions

    /// History of dosing events since last measurement
    public let dosingHistory: [DosingEvent]

    /// Available products and their properties
    public let products: [String: ProductDefinition]

    /// Target ranges for water parameters
    public let targets: WaterTargets

    public init(
        poolVolume_m3: Double,
        lastMeasurement: LastMeasurement,
        conditions: PoolConditions,
        dosingHistory: [DosingEvent],
        products: [String: ProductDefinition],
        targets: WaterTargets
    ) {
        self.poolVolume_m3 = poolVolume_m3
        self.lastMeasurement = lastMeasurement
        self.conditions = conditions
        self.dosingHistory = dosingHistory
        self.products = products
        self.targets = targets
    }
}

// MARK: - Last Measurement

/// Most recent pool water measurement
public struct LastMeasurement: Codable {
    /// Free chlorine concentration in ppm (mg/L)
    public let freeChlorine_ppm: Double

    /// pH value
    public let pH: Double

    /// ISO 8601 timestamp of when measurement was taken
    public let timestampISO: String

    /// Parsed Date from timestampISO
    public var timestamp: Date {
        ISO8601DateFormatter().date(from: timestampISO) ?? Date()
    }

    public init(freeChlorine_ppm: Double, pH: Double, timestampISO: String) {
        self.freeChlorine_ppm = freeChlorine_ppm
        self.pH = pH
        self.timestampISO = timestampISO
    }
}

// MARK: - Pool Conditions

/// Current environmental and operational conditions
public struct PoolConditions: Codable {
    /// Water temperature in Celsius
    public let waterTemperature_c: Double

    /// UV exposure level
    public let uvExposure: UVExposureLevel

    /// Whether the pool is covered
    public let poolCovered: Bool

    /// Bather load since last measurement
    public let batherLoad: BatherLoadLevel

    /// Filter/pump runtime in hours per day
    public let filterRuntime_hours_per_day: Double

    public init(
        waterTemperature_c: Double,
        uvExposure: UVExposureLevel,
        poolCovered: Bool,
        batherLoad: BatherLoadLevel,
        filterRuntime_hours_per_day: Double
    ) {
        self.waterTemperature_c = waterTemperature_c
        self.uvExposure = uvExposure
        self.poolCovered = poolCovered
        self.batherLoad = batherLoad
        self.filterRuntime_hours_per_day = filterRuntime_hours_per_day
    }
}

// MARK: - UV Exposure Level

/// UV exposure intensity levels
public enum UVExposureLevel: String, Codable {
    case low
    case medium
    case high

    /// Decay rate multiplier for chlorine
    public var decayMultiplier: Double {
        switch self {
        case .low: return 1.0
        case .medium: return 1.5
        case .high: return 2.5
        }
    }
}

// MARK: - Bather Load Level

/// Pool usage levels
public enum BatherLoadLevel: String, Codable, CaseIterable {
    case none
    case normal
    case high

    /// Chlorine consumption multiplier
    public var consumptionMultiplier: Double {
        switch self {
        case .none: return 1.0
        case .normal: return 1.2
        case .high: return 1.5
        }
    }
}

// MARK: - Dosing Event

/// A single dosing event from history
public struct DosingEvent: Codable {
    /// ISO 8601 timestamp of dosing
    public let timestampISO: String

    /// Product identifier
    public let productId: String

    /// Type of chemical (chlorine, phMinus, phPlus)
    public let kind: ProductKind

    /// Amount of product added
    public let amount: Double

    /// Unit of measurement
    public let unit: String

    /// Parsed Date from timestampISO
    public var timestamp: Date {
        ISO8601DateFormatter().date(from: timestampISO) ?? Date()
    }

    public init(
        timestampISO: String,
        productId: String,
        kind: ProductKind,
        amount: Double,
        unit: String
    ) {
        self.timestampISO = timestampISO
        self.productId = productId
        self.kind = kind
        self.amount = amount
        self.unit = unit
    }
}

// MARK: - Product Kind

/// Types of pool chemicals
public enum ProductKind: String, Codable {
    case chlorine
    case phMinus = "ph_minus"
    case phPlus = "ph_plus"
}

// MARK: - Product Definition

/// Definition of a dosing product
public struct ProductDefinition: Codable {
    /// Type of chemical
    public let kind: ProductKind

    /// Unit of measurement (g, ml, etc.)
    public let unit: String

    /// For chlorine: ppm change per unit per m3
    public let ppmChangePerUnit_per_m3: Double?

    /// For pH products: pH change per unit per m3
    public let pHChangePerUnit_per_m3: Double?

    public init(
        kind: ProductKind,
        unit: String,
        ppmChangePerUnit_per_m3: Double? = nil,
        pHChangePerUnit_per_m3: Double? = nil
    ) {
        self.kind = kind
        self.unit = unit
        self.ppmChangePerUnit_per_m3 = ppmChangePerUnit_per_m3
        self.pHChangePerUnit_per_m3 = pHChangePerUnit_per_m3
    }
}

// MARK: - Water Targets

/// Target ranges for water parameters
public struct WaterTargets: Codable {
    /// Chlorine targets
    public let freeChlorine: ChlorineTargets

    /// pH targets
    public let pH: PHTargets

    public init(freeChlorine: ChlorineTargets, pH: PHTargets) {
        self.freeChlorine = freeChlorine
        self.pH = pH
    }
}

// MARK: - Chlorine Targets

/// Chlorine ideal range (target is calculated as midpoint)
public struct ChlorineTargets: Codable {
    public let min_ppm: Double
    public let max_ppm: Double

    /// Target is the midpoint of the ideal range
    public var target_ppm: Double {
        (min_ppm + max_ppm) / 2.0
    }

    public init(min_ppm: Double, max_ppm: Double) {
        self.min_ppm = min_ppm
        self.max_ppm = max_ppm
    }
}

// MARK: - pH Targets

/// pH ideal range (target is calculated as midpoint)
public struct PHTargets: Codable {
    public let min: Double
    public let max: Double

    /// Target is the midpoint of the ideal range
    public var target: Double {
        (min + max) / 2.0
    }

    public init(min: Double, max: Double) {
        self.min = min
        self.max = max
    }
}

// MARK: - Input Validation

extension PoolWaterEngineInput {
    /// Returns a copy with values clamped to physically meaningful ranges
    public func validated() -> PoolWaterEngineInput {
        PoolWaterEngineInput(
            poolVolume_m3: Swift.max(0.1, poolVolume_m3),
            lastMeasurement: LastMeasurement(
                freeChlorine_ppm: Swift.min(Swift.max(lastMeasurement.freeChlorine_ppm, 0), 10),
                pH: Swift.min(Swift.max(lastMeasurement.pH, 0), 14),
                timestampISO: lastMeasurement.timestampISO
            ),
            conditions: PoolConditions(
                waterTemperature_c: Swift.min(Swift.max(conditions.waterTemperature_c, 0), 50),
                uvExposure: conditions.uvExposure,
                poolCovered: conditions.poolCovered,
                batherLoad: conditions.batherLoad,
                filterRuntime_hours_per_day: Swift.min(Swift.max(conditions.filterRuntime_hours_per_day, 0), 24)
            ),
            dosingHistory: dosingHistory,
            products: products,
            targets: targets
        )
    }
}

// MARK: - Default Products

/// Standard pool chemicals with typical effectiveness values
public enum DefaultProducts {
    /// Chlorine granules (Calcium hypochlorite or similar)
    /// Typical: 1g per m³ raises chlorine by ~1 ppm
    public static let chlorine = ProductDefinition(
        kind: .chlorine,
        unit: "g",
        ppmChangePerUnit_per_m3: 1.0,
        pHChangePerUnit_per_m3: nil
    )

    /// pH-Minus (Sodium bisulfate or similar)
    /// Typical: 10g per m³ lowers pH by ~0.1
    public static let phMinus = ProductDefinition(
        kind: .phMinus,
        unit: "g",
        ppmChangePerUnit_per_m3: nil,
        pHChangePerUnit_per_m3: 0.01
    )

    /// pH-Plus (Sodium carbonate or similar)
    /// Typical: 10g per m³ raises pH by ~0.1
    public static let phPlus = ProductDefinition(
        kind: .phPlus,
        unit: "g",
        ppmChangePerUnit_per_m3: nil,
        pHChangePerUnit_per_m3: 0.01
    )

    /// All default products as a dictionary for engine input
    public static var all: [String: ProductDefinition] {
        [
            "chlorine": chlorine,
            "ph_minus": phMinus,
            "ph_plus": phPlus
        ]
    }
}
