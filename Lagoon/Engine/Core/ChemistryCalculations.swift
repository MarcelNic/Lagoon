import Foundation

/// Pure mathematical functions for pool chemistry calculations
/// All functions are stateless, deterministic, and testable
public enum ChemistryCalculations {

    // MARK: - Chlorine Decay

    /// Calculate chlorine concentration after exponential decay
    ///
    /// Formula: Cl(t) = Cl₀ × exp(-k_total × t)
    /// where k_total = k_base × tempFactor × uvFactor × coverFactor × batherFactor
    ///
    /// - Parameters:
    ///   - initialChlorine: Starting chlorine concentration (ppm)
    ///   - elapsedHours: Time elapsed (hours)
    ///   - conditions: Current pool conditions
    /// - Returns: Chlorine concentration after decay (ppm)
    public static func calculateChlorineAfterDecay(
        initialChlorine: Double,
        elapsedHours: Double,
        conditions: PoolConditions
    ) -> Double {
        let elapsedDays = elapsedHours / 24.0

        // 1. Temperature factor using Q10 model
        // Rate doubles every 10°C from reference (20°C)
        let tempDelta = conditions.waterTemperature_c - ChemistryConstants.referenceTemperature
        let tempFactor = pow(ChemistryConstants.q10Coefficient, tempDelta / 10.0)

        // 2. UV factor from exposure level
        let uvFactor = conditions.uvExposure.decayMultiplier

        // 3. Cover factor (cover blocks ~70% of decay factors)
        let coverFactor = conditions.poolCovered ? ChemistryConstants.coverProtectionFactor : 1.0

        // 4. Bather load factor
        let batherFactor = conditions.batherLoad.consumptionMultiplier

        // Calculate total decay rate
        let kTotal = ChemistryConstants.chlorineBaseDecayRate
            * tempFactor
            * uvFactor
            * coverFactor
            * batherFactor

        // Safety bounds: decay rate must be reasonable (1-50% per day)
        let kSafe = min(max(kTotal, ChemistryConstants.minDecayRate), ChemistryConstants.maxDecayRate)

        // Exponential decay formula
        let decayFactor = exp(-kSafe * elapsedDays)
        let result = initialChlorine * decayFactor

        // Chlorine cannot be negative
        return max(result, ChemistryConstants.minChlorine)
    }

    // MARK: - pH Drift

    /// Calculate pH after natural upward drift
    ///
    /// Formula: pH(t) = pH₀ + drift_rate × t
    /// where drift_rate includes pump/filter effect and temperature
    ///
    /// - Parameters:
    ///   - initialPH: Starting pH value
    ///   - elapsedHours: Time elapsed (hours)
    ///   - conditions: Current pool conditions
    /// - Returns: pH value after drift
    public static func calculatePHAfterDrift(
        initialPH: Double,
        elapsedHours: Double,
        conditions: PoolConditions
    ) -> Double {
        let elapsedDays = elapsedHours / 24.0

        // 1. Filter/pump effect (more agitation = more CO2 outgassing = higher pH)
        // Normalize runtime to 0-1 range
        let pumpNormalized = min(max(conditions.filterRuntime_hours_per_day / 24.0, 0.0), 1.0)
        let pumpMultiplier = 1.0 + (pumpNormalized * ChemistryConstants.filterRuntimeMaxEffect)

        // 2. Temperature effect (warmer water drifts slightly faster)
        let tempDelta = conditions.waterTemperature_c - ChemistryConstants.referenceTemperature
        let tempMultiplier = 1.0 + (tempDelta / 30.0)  // +/- ~33% change per 10°C

        // Calculate total drift rate
        let driftRate = ChemistryConstants.phBaseDriftRate
            * pumpMultiplier
            * max(tempMultiplier, 0.5)  // Don't let it go below 50%

        // Cap maximum drift to prevent unrealistic jumps
        let safeDriftRate = min(driftRate, ChemistryConstants.phMaxDriftRate)

        // Linear drift (upward)
        let result = initialPH + (safeDriftRate * elapsedDays)

        // Enforce physical bounds
        return min(max(result, ChemistryConstants.minPH), ChemistryConstants.maxPH)
    }

    // MARK: - Dosage Effects

    /// Calculate chlorine level change from dosage
    ///
    /// Formula: ppmChange = amount × ppmChangePerUnit_per_m3 / poolVolume_m3
    ///
    /// - Parameters:
    ///   - amount: Amount of product added (in product units)
    ///   - ppmChangePerUnit_per_m3: Product's ppm change per unit per m³
    ///   - poolVolume_m3: Pool volume in cubic meters
    /// - Returns: Change in chlorine level (ppm)
    public static func calculateChlorineDosageEffect(
        amount: Double,
        ppmChangePerUnit_per_m3: Double,
        poolVolume_m3: Double
    ) -> Double {
        guard poolVolume_m3 > 0, ppmChangePerUnit_per_m3 > 0 else { return 0.0 }

        // Linear effect: amount × rate / volume
        return amount * ppmChangePerUnit_per_m3 / poolVolume_m3
    }

    /// Calculate pH change from dosage
    ///
    /// - Parameters:
    ///   - amount: Amount of product added (in product units)
    ///   - pHChangePerUnit_per_m3: Product's pH change per unit per m³
    ///   - poolVolume_m3: Pool volume in cubic meters
    ///   - kind: Type of product (phMinus or phPlus)
    /// - Returns: Change in pH (negative for phMinus, positive for phPlus)
    public static func calculatePHDosageEffect(
        amount: Double,
        pHChangePerUnit_per_m3: Double,
        poolVolume_m3: Double,
        kind: ProductKind
    ) -> Double {
        guard poolVolume_m3 > 0, pHChangePerUnit_per_m3 > 0 else { return 0.0 }

        let baseEffect = amount * pHChangePerUnit_per_m3 / poolVolume_m3

        // phMinus decreases pH, phPlus increases pH
        switch kind {
        case .phMinus:
            return -abs(baseEffect)
        case .phPlus:
            return abs(baseEffect)
        case .chlorine:
            return 0.0  // Chlorine doesn't directly affect pH
        }
    }

    // MARK: - Mixing Lag

    /// Calculate mixing progress using exponential approach
    ///
    /// Formula: effect = dosageEffect × (1 - exp(-timeSinceDose / τ))
    /// where τ = 2 hours
    ///
    /// At τ (2 hours), ~63% of the effect is realized
    /// At 2τ (4 hours), ~86% is realized
    /// At 3τ (6 hours), ~95% is realized
    ///
    /// - Parameters:
    ///   - fullEffect: Full dosage effect when fully mixed
    ///   - hoursSinceDose: Time since dosage was added (hours)
    /// - Returns: Current realized effect
    public static func calculateMixedEffect(
        fullEffect: Double,
        hoursSinceDose: Double
    ) -> Double {
        guard hoursSinceDose >= 0 else { return 0.0 }

        let mixingFactor = 1.0 - exp(-hoursSinceDose / ChemistryConstants.mixingTimeConstant)
        return fullEffect * mixingFactor
    }

    // MARK: - Reverse Dosage Calculations

    /// Calculate required dosage to reach target chlorine
    ///
    /// Formula: amount = (targetPpm - currentPpm) × poolVolume_m3 / ppmChangePerUnit_per_m3
    ///
    /// - Parameters:
    ///   - currentChlorine: Current chlorine level (ppm)
    ///   - targetChlorine: Target chlorine level (ppm)
    ///   - poolVolume_m3: Pool volume in cubic meters
    ///   - ppmChangePerUnit_per_m3: Product's effectiveness
    /// - Returns: Required dosage amount (in product units)
    public static func calculateRequiredChlorineDosage(
        currentChlorine: Double,
        targetChlorine: Double,
        poolVolume_m3: Double,
        ppmChangePerUnit_per_m3: Double
    ) -> Double {
        guard ppmChangePerUnit_per_m3 > 0, poolVolume_m3 > 0 else { return 0.0 }

        let requiredIncrease = max(0, targetChlorine - currentChlorine)
        return requiredIncrease * poolVolume_m3 / ppmChangePerUnit_per_m3
    }

    /// Calculate required dosage to reach target pH
    ///
    /// - Parameters:
    ///   - currentPH: Current pH level
    ///   - targetPH: Target pH level
    ///   - poolVolume_m3: Pool volume in cubic meters
    ///   - pHChangePerUnit_per_m3: Product's effectiveness
    /// - Returns: Required dosage amount (always positive, in product units)
    public static func calculateRequiredPHDosage(
        currentPH: Double,
        targetPH: Double,
        poolVolume_m3: Double,
        pHChangePerUnit_per_m3: Double
    ) -> Double {
        guard pHChangePerUnit_per_m3 > 0, poolVolume_m3 > 0 else { return 0.0 }

        let requiredChange = abs(targetPH - currentPH)
        return requiredChange * poolVolume_m3 / pHChangePerUnit_per_m3
    }
}
