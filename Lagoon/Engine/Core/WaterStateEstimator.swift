import Foundation

/// Estimates current pool water state based on last measurement and conditions
public struct WaterStateEstimator {

    // MARK: - Main Estimation

    /// Estimate current water state
    ///
    /// - Parameters:
    ///   - input: Complete engine input
    ///   - currentDate: Current date/time for estimation
    /// - Returns: Estimated state with confidence
    public static func estimate(
        from input: PoolWaterEngineInput,
        at currentDate: Date = Date()
    ) -> (state: EstimatedWaterState, confidence: ConfidenceIndicator) {

        let lastMeasurementDate = input.lastMeasurement.timestamp
        let elapsedSeconds = currentDate.timeIntervalSince(lastMeasurementDate)
        let elapsedHours = max(0, elapsedSeconds / 3600.0)

        // 1. Estimate chlorine
        let estimatedChlorine = estimateChlorine(
            initialChlorine: input.lastMeasurement.freeChlorine_ppm,
            conditions: input.conditions,
            dosingHistory: input.dosingHistory,
            products: input.products,
            poolVolume_m3: input.poolVolume_m3,
            lastMeasurementDate: lastMeasurementDate,
            currentDate: currentDate
        )

        // 2. Estimate pH
        let estimatedPH = estimatePH(
            initialPH: input.lastMeasurement.pH,
            conditions: input.conditions,
            dosingHistory: input.dosingHistory,
            products: input.products,
            poolVolume_m3: input.poolVolume_m3,
            lastMeasurementDate: lastMeasurementDate,
            currentDate: currentDate
        )

        // 3. Calculate confidence
        let confidence = calculateConfidence(elapsedHours: elapsedHours)

        // 4. Create output
        let state = EstimatedWaterState(
            freeChlorine_ppm: estimatedChlorine,
            pH: estimatedPH,
            nowTimestampISO: ISO8601DateFormatter().string(from: currentDate)
        )

        return (state, confidence)
    }

    // MARK: - Chlorine Estimation

    private static func estimateChlorine(
        initialChlorine: Double,
        conditions: PoolConditions,
        dosingHistory: [DosingEvent],
        products: [String: ProductDefinition],
        poolVolume_m3: Double,
        lastMeasurementDate: Date,
        currentDate: Date
    ) -> Double {

        // Filter and sort chlorine dosing events chronologically
        let chlorineEvents = dosingHistory
            .filter { $0.kind == .chlorine }
            .filter { $0.timestamp > lastMeasurementDate && $0.timestamp <= currentDate }
            .sorted { $0.timestamp < $1.timestamp }

        var currentChlorine = initialChlorine
        var lastEventDate = lastMeasurementDate

        // Process each dosing event in chronological order
        for event in chlorineEvents {
            // Apply decay from last event to this event
            let hoursUntilEvent = event.timestamp.timeIntervalSince(lastEventDate) / 3600.0
            if hoursUntilEvent > 0 {
                currentChlorine = ChemistryCalculations.calculateChlorineAfterDecay(
                    initialChlorine: currentChlorine,
                    elapsedHours: hoursUntilEvent,
                    conditions: conditions
                )
            }

            // Apply dosage effect with mixing lag
            if let product = products[event.productId],
               let ppmChange = product.ppmChangePerUnit_per_m3 {

                let fullEffect = ChemistryCalculations.calculateChlorineDosageEffect(
                    amount: event.amount,
                    ppmChangePerUnit_per_m3: ppmChange,
                    poolVolume_m3: poolVolume_m3
                )

                let hoursSinceDose = currentDate.timeIntervalSince(event.timestamp) / 3600.0
                let mixedEffect = ChemistryCalculations.calculateMixedEffect(
                    fullEffect: fullEffect,
                    hoursSinceDose: hoursSinceDose
                )

                currentChlorine += mixedEffect
            }

            lastEventDate = event.timestamp
        }

        // Apply final decay from last event to current time
        let finalHours = currentDate.timeIntervalSince(lastEventDate) / 3600.0
        if finalHours > 0 {
            currentChlorine = ChemistryCalculations.calculateChlorineAfterDecay(
                initialChlorine: currentChlorine,
                elapsedHours: finalHours,
                conditions: conditions
            )
        }

        // Enforce physical bounds
        return min(max(currentChlorine, ChemistryConstants.minChlorine), ChemistryConstants.maxChlorine)
    }

    // MARK: - pH Estimation

    private static func estimatePH(
        initialPH: Double,
        conditions: PoolConditions,
        dosingHistory: [DosingEvent],
        products: [String: ProductDefinition],
        poolVolume_m3: Double,
        lastMeasurementDate: Date,
        currentDate: Date
    ) -> Double {

        // Filter and sort pH dosing events chronologically
        let phEvents = dosingHistory
            .filter { $0.kind == .phMinus || $0.kind == .phPlus }
            .filter { $0.timestamp > lastMeasurementDate && $0.timestamp <= currentDate }
            .sorted { $0.timestamp < $1.timestamp }

        var currentPH = initialPH
        var lastEventDate = lastMeasurementDate

        // Process each dosing event in chronological order
        for event in phEvents {
            // Apply drift from last event to this event
            let hoursUntilEvent = event.timestamp.timeIntervalSince(lastEventDate) / 3600.0
            if hoursUntilEvent > 0 {
                currentPH = ChemistryCalculations.calculatePHAfterDrift(
                    initialPH: currentPH,
                    elapsedHours: hoursUntilEvent,
                    conditions: conditions
                )
            }

            // Apply dosage effect with mixing lag
            if let product = products[event.productId],
               let pHChange = product.pHChangePerUnit_per_m3 {

                let fullEffect = ChemistryCalculations.calculatePHDosageEffect(
                    amount: event.amount,
                    pHChangePerUnit_per_m3: pHChange,
                    poolVolume_m3: poolVolume_m3,
                    kind: event.kind
                )

                let hoursSinceDose = currentDate.timeIntervalSince(event.timestamp) / 3600.0
                let mixedEffect = ChemistryCalculations.calculateMixedEffect(
                    fullEffect: fullEffect,
                    hoursSinceDose: hoursSinceDose
                )

                currentPH += mixedEffect
            }

            lastEventDate = event.timestamp
        }

        // Apply final drift from last event to current time
        let finalHours = currentDate.timeIntervalSince(lastEventDate) / 3600.0
        if finalHours > 0 {
            currentPH = ChemistryCalculations.calculatePHAfterDrift(
                initialPH: currentPH,
                elapsedHours: finalHours,
                conditions: conditions
            )
        }

        // Enforce physical bounds
        return min(max(currentPH, ChemistryConstants.minPH), ChemistryConstants.maxPH)
    }

    // MARK: - Confidence Calculation

    private static func calculateConfidence(elapsedHours: Double) -> ConfidenceIndicator {
        if elapsedHours < ChemistryConstants.highConfidenceThreshold {
            return ConfidenceIndicator(
                confidence: .high,
                reason: "Measurement less than 24 hours old"
            )
        } else if elapsedHours < ChemistryConstants.mediumConfidenceThreshold {
            let hours = Int(elapsedHours)
            return ConfidenceIndicator(
                confidence: .medium,
                reason: "Measurement \(hours) hours old (24-72h range)"
            )
        } else {
            let days = Int(elapsedHours / 24)
            return ConfidenceIndicator(
                confidence: .low,
                reason: "Measurement \(days) days old (>72h). Consider re-measuring."
            )
        }
    }
}
