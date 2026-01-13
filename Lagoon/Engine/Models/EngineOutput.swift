import Foundation

// MARK: - Main Engine Output

/// Complete output from the pool water estimation engine
public struct PoolWaterEngineOutput: Codable {
    /// Estimated current water state
    public let estimatedState: EstimatedWaterState

    /// Confidence indicator for the estimate
    public let confidence: ConfidenceIndicator

    /// Dosing recommendations (one per parameter)
    public let recommendations: [DosingRecommendation]

    public init(
        estimatedState: EstimatedWaterState,
        confidence: ConfidenceIndicator,
        recommendations: [DosingRecommendation]
    ) {
        self.estimatedState = estimatedState
        self.confidence = confidence
        self.recommendations = recommendations
    }
}

// MARK: - Estimated Water State

/// Current estimated state of pool water
public struct EstimatedWaterState: Codable {
    /// Estimated free chlorine in ppm
    public let freeChlorine_ppm: Double

    /// Estimated pH value
    public let pH: Double

    /// ISO 8601 timestamp of this estimate
    public let nowTimestampISO: String

    public init(freeChlorine_ppm: Double, pH: Double, nowTimestampISO: String) {
        self.freeChlorine_ppm = freeChlorine_ppm
        self.pH = pH
        self.nowTimestampISO = nowTimestampISO
    }
}

// MARK: - Confidence Indicator

/// Confidence level for the estimate
public struct ConfidenceIndicator: Codable {
    /// Confidence level
    public let confidence: ConfidenceLevel

    /// Reason for this confidence level
    public let reason: String

    public init(confidence: ConfidenceLevel, reason: String) {
        self.confidence = confidence
        self.reason = reason
    }
}

// MARK: - Confidence Level

/// Confidence levels based on data age
public enum ConfidenceLevel: String, Codable {
    case high   // < 24 hours since last measurement
    case medium // 24-72 hours
    case low    // > 72 hours
}

// MARK: - Dosing Recommendation

/// Recommendation for a single parameter
public struct DosingRecommendation: Codable {
    /// Which parameter this recommendation is for
    public let parameter: WaterParameter

    /// Recommended action
    public let action: RecommendedAction

    /// Reason code explaining why
    public let reasonCode: ReasonCode

    /// Product ID to use (only if action = dose)
    public let productId: String?

    /// Amount to dose (only if action = dose)
    public let amount: Double?

    /// Unit for dosing (only if action = dose)
    public let unit: String?

    /// Target value we're aiming for
    public let targetValue: Double

    /// Human-readable explanation
    public let explanation: String

    public init(
        parameter: WaterParameter,
        action: RecommendedAction,
        reasonCode: ReasonCode,
        productId: String? = nil,
        amount: Double? = nil,
        unit: String? = nil,
        targetValue: Double,
        explanation: String
    ) {
        self.parameter = parameter
        self.action = action
        self.reasonCode = reasonCode
        self.productId = productId
        self.amount = amount
        self.unit = unit
        self.targetValue = targetValue
        self.explanation = explanation
    }
}

// MARK: - Water Parameter

/// Water parameters that can be adjusted
public enum WaterParameter: String, Codable {
    case freeChlorine
    case pH
}

// MARK: - Recommended Action

/// Possible recommended actions
public enum RecommendedAction: String, Codable {
    case none
    case dose
}

// MARK: - Reason Code

/// Reason codes for recommendations
public enum ReasonCode: String, Codable {
    case IN_RANGE
    case TOO_LOW
    case TOO_HIGH
}

// MARK: - JSON Encoding

extension PoolWaterEngineOutput {
    /// Convert output to JSON string
    public func toJSON() throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)
        return String(data: data, encoding: .utf8) ?? "{}"
    }
}
