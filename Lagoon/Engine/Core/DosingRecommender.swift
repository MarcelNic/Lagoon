import Foundation

/// Generates dosing recommendations based on estimated water state
public struct DosingRecommender {

    // MARK: - Main Recommendation

    /// Generate recommendations for all parameters
    ///
    /// - Parameters:
    ///   - estimatedState: Current estimated water state
    ///   - targets: Target ranges
    ///   - products: Available products
    ///   - poolVolume_m3: Pool volume
    /// - Returns: Array of recommendations (one per parameter)
    public static func recommend(
        for estimatedState: EstimatedWaterState,
        targets: WaterTargets,
        products: [String: ProductDefinition],
        poolVolume_m3: Double
    ) -> [DosingRecommendation] {

        var recommendations: [DosingRecommendation] = []

        // Chlorine recommendation
        let chlorineRec = recommendChlorine(
            currentChlorine: estimatedState.freeChlorine_ppm,
            targets: targets.freeChlorine,
            products: products,
            poolVolume_m3: poolVolume_m3
        )
        recommendations.append(chlorineRec)

        // pH recommendation
        let phRec = recommendPH(
            currentPH: estimatedState.pH,
            targets: targets.pH,
            products: products,
            poolVolume_m3: poolVolume_m3
        )
        recommendations.append(phRec)

        return recommendations
    }

    // MARK: - Chlorine Recommendation

    private static func recommendChlorine(
        currentChlorine: Double,
        targets: ChlorineTargets,
        products: [String: ProductDefinition],
        poolVolume_m3: Double
    ) -> DosingRecommendation {

        // Check if in range
        if currentChlorine >= targets.min_ppm && currentChlorine <= targets.max_ppm {
            return DosingRecommendation(
                parameter: .freeChlorine,
                action: .none,
                reasonCode: .IN_RANGE,
                productId: nil,
                amount: nil,
                unit: nil,
                targetValue: targets.target_ppm,
                explanation: "Chlorine level (\(formatValue(currentChlorine)) ppm) is within target range (\(formatValue(targets.min_ppm))-\(formatValue(targets.max_ppm)) ppm)."
            )
        }

        // Determine if too low or too high
        let isTooLow = currentChlorine < targets.min_ppm

        // For too high chlorine, we don't dose - just wait for natural decay
        if !isTooLow {
            return DosingRecommendation(
                parameter: .freeChlorine,
                action: .none,
                reasonCode: .TOO_HIGH,
                productId: nil,
                amount: nil,
                unit: nil,
                targetValue: targets.target_ppm,
                explanation: "Chlorine level (\(formatValue(currentChlorine)) ppm) is above target (\(formatValue(targets.max_ppm)) ppm). Allow natural decay."
            )
        }

        // Chlorine is too low - find chlorine product and calculate dosage
        guard let (productId, product) = products.first(where: { $0.value.kind == .chlorine }),
              let ppmChange = product.ppmChangePerUnit_per_m3 else {
            return DosingRecommendation(
                parameter: .freeChlorine,
                action: .dose,
                reasonCode: .TOO_LOW,
                productId: nil,
                amount: nil,
                unit: nil,
                targetValue: targets.target_ppm,
                explanation: "Chlorine is low (\(formatValue(currentChlorine)) ppm) but no chlorine product configured."
            )
        }

        // Calculate dosage
        let dosage = ChemistryCalculations.calculateRequiredChlorineDosage(
            currentChlorine: currentChlorine,
            targetChlorine: targets.target_ppm,
            poolVolume_m3: poolVolume_m3,
            ppmChangePerUnit_per_m3: ppmChange
        )

        return DosingRecommendation(
            parameter: .freeChlorine,
            action: .dose,
            reasonCode: .TOO_LOW,
            productId: productId,
            amount: roundDosage(dosage),
            unit: product.unit,
            targetValue: targets.target_ppm,
            explanation: "Chlorine level (\(formatValue(currentChlorine)) ppm) is below minimum (\(formatValue(targets.min_ppm)) ppm). Dose to reach target \(formatValue(targets.target_ppm)) ppm."
        )
    }

    // MARK: - pH Recommendation

    private static func recommendPH(
        currentPH: Double,
        targets: PHTargets,
        products: [String: ProductDefinition],
        poolVolume_m3: Double
    ) -> DosingRecommendation {

        // Check if in range
        if currentPH >= targets.min && currentPH <= targets.max {
            return DosingRecommendation(
                parameter: .pH,
                action: .none,
                reasonCode: .IN_RANGE,
                productId: nil,
                amount: nil,
                unit: nil,
                targetValue: targets.target,
                explanation: "pH level (\(formatValue(currentPH))) is within target range (\(formatValue(targets.min))-\(formatValue(targets.max)))."
            )
        }

        // Determine direction and product kind needed
        let isTooLow = currentPH < targets.min
        let reasonCode: ReasonCode = isTooLow ? .TOO_LOW : .TOO_HIGH
        let targetKind: ProductKind = isTooLow ? .phPlus : .phMinus

        // Find appropriate pH product
        guard let (productId, product) = products.first(where: { $0.value.kind == targetKind }),
              let pHChange = product.pHChangePerUnit_per_m3 else {

            let productName = isTooLow ? "pH-Plus" : "pH-Minus"
            return DosingRecommendation(
                parameter: .pH,
                action: .dose,
                reasonCode: reasonCode,
                productId: nil,
                amount: nil,
                unit: nil,
                targetValue: targets.target,
                explanation: "pH is \(isTooLow ? "low" : "high") (\(formatValue(currentPH))) but no \(productName) product configured."
            )
        }

        // Calculate dosage
        let dosage = ChemistryCalculations.calculateRequiredPHDosage(
            currentPH: currentPH,
            targetPH: targets.target,
            poolVolume_m3: poolVolume_m3,
            pHChangePerUnit_per_m3: pHChange
        )

        let action = isTooLow ? "raise" : "lower"
        let productName = isTooLow ? "pH-Plus" : "pH-Minus"
        let bound = isTooLow ? targets.min : targets.max

        return DosingRecommendation(
            parameter: .pH,
            action: .dose,
            reasonCode: reasonCode,
            productId: productId,
            amount: roundDosage(dosage),
            unit: product.unit,
            targetValue: targets.target,
            explanation: "pH level (\(formatValue(currentPH))) is \(isTooLow ? "below" : "above") \(formatValue(bound)). Add \(productName) to \(action) pH to \(formatValue(targets.target))."
        )
    }

    // MARK: - Helpers

    /// Round dosage to practical amounts
    private static func roundDosage(_ amount: Double) -> Double {
        // Round to nearest 10 for amounts > 100, nearest 5 for smaller
        if amount > 100 {
            return (amount / 10.0).rounded() * 10.0
        } else if amount > 0 {
            return (amount / 5.0).rounded() * 5.0
        } else {
            return 0.0
        }
    }

    /// Format a numeric value for display
    private static func formatValue(_ value: Double) -> String {
        return String(format: "%.1f", value)
    }
}
