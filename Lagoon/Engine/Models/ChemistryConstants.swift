import Foundation

/// Physical and chemistry constants for pool calculations
public enum ChemistryConstants {

    // MARK: - Chlorine Decay

    /// Base chlorine decay rate at 20°C (per day)
    /// Approximately 5% loss per day under ideal conditions
    public static let chlorineBaseDecayRate: Double = 0.05

    /// Reference temperature for Q10 model (Celsius)
    public static let referenceTemperature: Double = 20.0

    /// Q10 coefficient - rate doubles every 10°C
    public static let q10Coefficient: Double = 2.0

    /// Cover protection factor (covers block ~70% of UV/decay factors)
    public static let coverProtectionFactor: Double = 0.3

    /// Minimum decay rate (per day) - safety bound
    public static let minDecayRate: Double = 0.01

    /// Maximum decay rate (per day) - safety bound
    public static let maxDecayRate: Double = 0.5

    // MARK: - pH Drift

    /// Base pH drift rate (pH units per day, upward)
    /// Natural upward drift due to CO2 outgassing
    public static let phBaseDriftRate: Double = 0.02

    /// Maximum pH drift rate cap (per day)
    public static let phMaxDriftRate: Double = 0.1

    /// Filter runtime maximum effect on drift (up to 50% increase)
    public static let filterRuntimeMaxEffect: Double = 0.5

    // MARK: - Mixing Lag

    /// Time constant for chemical mixing (hours)
    /// At tau, approximately 63% of effect is realized
    public static let mixingTimeConstant: Double = 2.0

    // MARK: - Confidence Thresholds (hours)

    /// Threshold for high confidence (< 24 hours)
    public static let highConfidenceThreshold: Double = 24.0

    /// Threshold for medium confidence (24-72 hours)
    public static let mediumConfidenceThreshold: Double = 72.0

    // MARK: - Physical Bounds

    /// Minimum physically possible chlorine (ppm)
    public static let minChlorine: Double = 0.0

    /// Maximum realistic chlorine for residential pool (ppm)
    public static let maxChlorine: Double = 10.0

    /// Minimum realistic pH
    public static let minPH: Double = 6.5

    /// Maximum realistic pH
    public static let maxPH: Double = 8.5
}
