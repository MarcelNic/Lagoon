//
//  VerticalTrendBar.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 13.01.26.
//

import SwiftUI

enum TrendDirection {
    case up
    case down
    case stable

    var chevronName: String {
        switch self {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .stable: return "minus"
        }
    }
}

enum ScalePosition {
    case leading
    case trailing
}

/// Data model for prediction popover
struct PredictionData {
    let estimatedValue: Double
    let confidence: ConfidenceLevel
    let confidenceReason: String
    let lastMeasuredValue: Double
    let lastMeasurementTime: Date
    let recommendation: DosingRecommendation?
    let lastDosingAmount: Double?
    let lastDosingProduct: String?
    let lastDosingTime: Date?
    let weatherTemperature: Double?
    let uvLevel: UVExposureLevel?
}

struct VerticalTrendBar: View {
    let title: String
    let value: Double
    let minValue: Double
    let maxValue: Double
    let idealMin: Double
    let idealMax: Double
    let barColor: Color
    let idealRangeColor: Color
    let trend: TrendDirection
    let unit: String
    let scalePosition: ScalePosition
    let prediction: PredictionData?
    let scalePoints: [Double]?
    var displayOverrideText: String? = nil
    var compact: Bool = false

    @State private var showPredictionPopover = false
    @Namespace private var namespace

    // Dimensionen
    private let barWidth: CGFloat = 35
    private let barHeight: CGFloat = 400
    private let markerDiameter: CGFloat = 30
    private let markerPadding: CGFloat = 2
    private let markerEndPadding: CGFloat = 1  // Abstand Marker-Rand zu Bar-Ende
    private let valuePillHeight: CGFloat = 28  // Geschätzte Höhe mit Glass Button Style
    private let titleHeight: CGFloat = 48  // Approximate height of title text
    private let titleBarSpacing: CGFloat = 20

    // Gesamtgröße des Markers inkl. Padding
    private var markerTotalSize: CGFloat {
        markerDiameter + 2 * markerPadding
    }

    // Offset vom Bar-Anfang bis zum Skala-Anfang (wo max liegt)
    // = halbe Markerhöhe + gewünschter Abstand zum Rand
    private var scaleTopOffset: CGFloat {
        markerTotalSize / 2 + markerEndPadding
    }

    // Berechnete Skala-Höhe (wo min bis max abgebildet wird)
    private var scaleHeight: CGFloat {
        barHeight - 2 * scaleTopOffset
    }

    init(
        title: String,
        value: Double,
        minValue: Double,
        maxValue: Double,
        idealMin: Double,
        idealMax: Double,
        barColor: Color,
        idealRangeColor: Color,
        trend: TrendDirection = .stable,
        unit: String = "",
        scalePosition: ScalePosition = .leading,
        prediction: PredictionData? = nil,
        scalePoints: [Double]? = nil,
        displayOverrideText: String? = nil,
        compact: Bool = false
    ) {
        self.title = title
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.idealMin = idealMin
        self.idealMax = idealMax
        self.barColor = barColor
        self.idealRangeColor = idealRangeColor
        self.trend = trend
        self.unit = unit
        self.scalePosition = scalePosition
        self.prediction = prediction
        self.scalePoints = scalePoints
        self.displayOverrideText = displayOverrideText
        self.compact = compact
    }

    private func normalizeToScale(_ v: Double) -> CGFloat {
        guard let points = scalePoints, points.count >= 2 else {
            let clamped = min(max(v, minValue), maxValue)
            return CGFloat((clamped - minValue) / (maxValue - minValue))
        }
        let clamped = min(max(v, points.first!), points.last!)
        for i in 0..<(points.count - 1) {
            if clamped <= points[i + 1] {
                let segmentFraction = (clamped - points[i]) / (points[i + 1] - points[i])
                let position = (Double(i) + segmentFraction) / Double(points.count - 1)
                return CGFloat(position)
            }
        }
        return 1.0
    }

    private var normalizedValue: CGFloat {
        normalizeToScale(value)
    }

    private var idealMinNormalized: CGFloat {
        normalizeToScale(idealMin)
    }

    private var idealMaxNormalized: CGFloat {
        normalizeToScale(idealMax)
    }

    private var markerYPosition: CGFloat {
        scaleTopOffset + (1 - normalizedValue) * scaleHeight
    }

    var body: some View {
        GlassEffectContainer {
            HStack(alignment: .top, spacing: 0) {
                // Links: Skala mit Pille-Overlay (wenn scalePosition == .leading)
                if scalePosition == .leading {
                    ZStack(alignment: .topTrailing) {
                        scaleMarks(leading: true)
                            .opacity(compact ? 0 : 1)

                        valueLabelView
                            .offset(y: markerYPosition - valuePillHeight / 2)
                            .animation(.smooth, value: value)
                            .padding(.trailing, 15)
                    }
                    .padding(.trailing, 12)
                    .padding(.top, titleHeight + titleBarSpacing)
                }

                // Titel + Bar mit Marker
                VStack(spacing: titleBarSpacing) {
                    Text(title)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
                        .fixedSize()
                        .frame(width: barWidth)
                        .opacity(compact ? 0 : 1)

                    Button {
                        // Action für Bar-Details
                    } label: {
                        ZStack(alignment: .top) {
                            // Haupt-Bar (Hintergrund)
                            RoundedRectangle(cornerRadius: barWidth / 2)
                                .fill(barColor)
                                .frame(width: barWidth, height: barHeight)

                            // Idealbereich
                            idealRangeBar

                            // Marker (aktueller Wert)
                            markerView
                                .offset(y: markerYPosition - markerTotalSize / 2)
                                .animation(.smooth, value: value)
                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: barWidth / 2))
                }

                // Rechts: Skala mit Pille-Overlay (wenn scalePosition == .trailing)
                if scalePosition == .trailing {
                    ZStack(alignment: .topLeading) {
                        scaleMarks(leading: false)
                            .opacity(compact ? 0 : 1)

                        valueLabelView
                            .offset(y: markerYPosition - valuePillHeight / 2)
                            .animation(.smooth, value: value)
                            .padding(.leading, 15)
                    }
                    .padding(.leading, 12)
                    .padding(.top, titleHeight + titleBarSpacing)
                }
            }
        }
        .animation(.smooth, value: compact)
    }

    // MARK: - Idealbereich Bar

    private var idealRangeBar: some View {
        let idealHeight = (idealMaxNormalized - idealMinNormalized) * scaleHeight
        let idealYOffset = scaleTopOffset + (1 - idealMaxNormalized) * scaleHeight

        return RoundedRectangle(cornerRadius: barWidth / 2)
            .fill(idealRangeColor)
            .frame(width: barWidth, height: idealHeight)
            .offset(y: idealYOffset)
    }

    // MARK: - Marker View

    private var markerView: some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: markerDiameter, height: markerDiameter)

            Image(systemName: "chevron.up")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .opacity(trend == .up ? 1 : 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .opacity(trend == .down ? 1 : 0)

            Image(systemName: "minus")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black)
                .opacity(trend == .stable ? 1 : 0)
        }
        .padding(markerPadding)
    }

    // MARK: - Skala Markierungen

    private var scaleTicks: [(id: Int, value: Double, isMajor: Bool)] {
        if let points = scalePoints, points.count >= 2 {
            var ticks: [(id: Int, value: Double, isMajor: Bool)] = []
            var id = 0
            for i in 0..<points.count {
                ticks.append((id: id, value: points[i], isMajor: true))
                id += 1
                if i < points.count - 1 {
                    let mid = (points[i] + points[i + 1]) / 2
                    ticks.append((id: id, value: mid, isMajor: false))
                    id += 1
                }
            }
            return ticks
        }

        let range = maxValue - minValue
        let rawStep = range / 10.0
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude

        let minorStep: Double
        if normalized <= 1.5 { minorStep = magnitude }
        else if normalized <= 3.5 { minorStep = 2.0 * magnitude }
        else if normalized <= 7.5 { minorStep = 5.0 * magnitude }
        else { minorStep = 10.0 * magnitude }

        let majorStep = minorStep * 2
        let count = Int(round(range / minorStep))

        return (0...count).map { i in
            let value = minValue + Double(i) * minorStep
            let remainder = abs(value.remainder(dividingBy: majorStep))
            let isMajor = remainder < minorStep * 0.1
            return (id: i, value: value, isMajor: isMajor)
        }
    }

    private func scaleMarks(leading: Bool) -> some View {
        let ticks = scaleTicks
        let labelHeight: CGFloat = 14

        return ZStack {
            ForEach(ticks, id: \.id) { tick in
                let normalizedPosition = normalizeToScale(tick.value)
                let yPosition = scaleTopOffset + (1 - normalizedPosition) * scaleHeight - barHeight / 2

                // Check overlap with value pill
                let labelY = scaleTopOffset + (1 - normalizedPosition) * scaleHeight
                let distance = abs(markerYPosition - labelY)
                let overlapThreshold = (valuePillHeight + labelHeight) / 2
                let labelVisible = !tick.isMajor || distance >= overlapThreshold

                HStack(spacing: 4) {
                    if leading {
                        // Wert-Label bei major ticks
                        if tick.isMajor {
                            Text(formatValue(tick.value))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(light: Color(white: 0.35), dark: Color.white.opacity(0.6)))
                                .frame(width: 28, alignment: .trailing)
                                .opacity(labelVisible ? 1 : 0)
                        } else {
                            Color.clear
                                .frame(width: 28)
                        }

                        Rectangle()
                            .fill(Color(light: tick.isMajor ? Color(white: 0.35) : Color(white: 0.5), dark: Color.white.opacity(tick.isMajor ? 0.4 : 0.25)))
                            .frame(
                                width: tick.isMajor ? 10 : 6,
                                height: tick.isMajor ? 2 : 1
                            )
                    } else {
                        Rectangle()
                            .fill(Color(light: tick.isMajor ? Color(white: 0.35) : Color(white: 0.5), dark: Color.white.opacity(tick.isMajor ? 0.4 : 0.25)))
                            .frame(
                                width: tick.isMajor ? 10 : 6,
                                height: tick.isMajor ? 2 : 1
                            )

                        // Wert-Label bei major ticks
                        if tick.isMajor {
                            Text(formatValue(tick.value))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(light: Color(white: 0.35), dark: Color.white.opacity(0.6)))
                                .frame(width: 28, alignment: .leading)
                                .opacity(labelVisible ? 1 : 0)
                        } else {
                            Color.clear
                                .frame(width: 28)
                        }
                    }
                }
                .offset(y: yPosition)
            }
        }
        .frame(height: barHeight)
        .animation(.smooth, value: normalizedValue)
    }

    // MARK: - Wert Label mit Schimmer-Effekt

    private var valueLabelView: some View {
        Button {
            if prediction != nil {
                showPredictionPopover = true
            }
        } label: {
            Text(displayOverrideText ?? (formatValue(value) + (unit.isEmpty ? "" : " \(unit)")))
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
                .padding(.horizontal, 4)
                .matchedTransitionSource(id: "PREDICTION_\(title)", in: namespace)
        }
        .buttonStyle(.glass(.clear.interactive()))
        .fixedSize()
        .popover(isPresented: $showPredictionPopover) {
            if let prediction = prediction {
                PopoverHelper {
                    PredictionPopoverContent(
                        title: title,
                        prediction: prediction,
                        tintColor: idealRangeColor,
                        unit: unit,
                        trend: trend
                    )
                }
                .navigationTransition(.zoom(sourceID: "PREDICTION_\(title)", in: namespace))
            }
        }
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Popover Helper (für Zoom-Transition)

struct PopoverHelper<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var isVisible: Bool = false

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(0.1))
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    isVisible = true
                }
            }
            .presentationCompactAdaptation(.popover)
    }
}

// MARK: - Prediction Popover Content

struct PredictionPopoverContent: View {
    let title: String
    let prediction: PredictionData
    let tintColor: Color
    let unit: String
    let trend: TrendDirection

    var body: some View {
        VStack(spacing: 20) {
            // Header
            headerView

            // Hero: Wert + Trend + Confidence
            heroValueSection

            // Einflussfaktoren
            factorsSection

            // Empfehlung (falls vorhanden)
            if let recommendation = prediction.recommendation,
               recommendation.action != .none {
                recommendationCard(recommendation)
            }

        }
        .padding(20)
        .frame(width: 280)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 8) {
            Text("\(title) Vorhersage")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Hero Value

    private var heroValueSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formatValue(prediction.estimatedValue))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(tintColor)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundStyle(tintColor.opacity(0.6))
                }
            }

            // Trend + Konfidenz als Text
            HStack(spacing: 8) {
                Label(trendText, systemImage: trend.chevronName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(trendColor)

                Text("·")
                    .foregroundStyle(.quaternary)

                Text("Konfidenz: \(confidenceText)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var trendText: String {
        switch trend {
        case .up: return "Steigend"
        case .down: return "Sinkend"
        case .stable: return "Stabil"
        }
    }

    // MARK: - Factors Section

    private var factorsSection: some View {
        VStack(spacing: 0) {
            // Letzte Messung
            factorRow(
                icon: "testtube.2",
                label: "Letzte Messung",
                value: formatValue(prediction.lastMeasuredValue) + (unit.isEmpty ? "" : " \(unit)"),
                detail: relativeTimeString(from: prediction.lastMeasurementTime)
            )

            Divider().padding(.leading, 32)

            // Letzte Dosierung
            if let amount = prediction.lastDosingAmount,
               let product = prediction.lastDosingProduct,
               let time = prediction.lastDosingTime {
                factorRow(
                    icon: "eyedropper",
                    label: "Letzte Dosierung",
                    value: "\(formatDoseAmount(amount)) g \(product)",
                    detail: relativeTimeString(from: time)
                )

                Divider().padding(.leading, 32)
            }

            // Wetter & Auswirkung
            if let temp = prediction.weatherTemperature,
               let uv = prediction.uvLevel {
                factorRow(
                    icon: "sun.max",
                    label: "\(String(format: "%.0f", temp)) °C · UV \(uvLabel(uv))",
                    value: weatherImpact(uv: uv, temp: temp),
                    detail: nil
                )
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.primary.opacity(0.04))
        }
    }

    private func factorRow(icon: String, label: String, value: String, detail: String?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                HStack(spacing: 4) {
                    Text(value)
                        .font(.caption.weight(.medium))
                    if let detail {
                        Text("· \(detail)")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func uvLabel(_ uv: UVExposureLevel) -> String {
        switch uv {
        case .low: return "Niedrig"
        case .medium: return "Mittel"
        case .high: return "Hoch"
        }
    }

    private func weatherImpact(uv: UVExposureLevel, temp: Double) -> String {
        if title == "pH" {
            if temp > 28 {
                return "Wärme beschleunigt pH-Anstieg"
            } else {
                return "Geringer Einfluss auf pH"
            }
        } else {
            // Chlor
            switch uv {
            case .high:
                return "Starker Chlorabbau durch UV"
            case .medium:
                return "Mäßiger Chlorabbau"
            case .low:
                return "Langsamer Chlorabbau"
            }
        }
    }

    // MARK: - Recommendation Card

    private func recommendationCard(_ recommendation: DosingRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: recommendationIcon(for: recommendation))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tintColor)

                Text("Empfehlung")
                    .font(.subheadline.weight(.semibold))
            }

            Text(recommendation.explanation)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            if let amount = recommendation.amount,
               let doseUnit = recommendation.unit {
                HStack(spacing: 6) {
                    Text("~\(formatDoseAmount(amount)) \(doseUnit)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(tintColor)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)

                    Text("Ziel: \(formatValue(recommendation.targetValue))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(tintColor.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(tintColor.opacity(0.15), lineWidth: 1)
                }
        }
    }

    // MARK: - Helpers

    private var confidenceText: String {
        switch prediction.confidence {
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        }
    }

    private var trendColor: Color {
        switch trend {
        case .up: return .orange
        case .down: return .blue
        case .stable: return .green
        }
    }

    private func recommendationIcon(for recommendation: DosingRecommendation) -> String {
        switch recommendation.reasonCode {
        case .TOO_LOW: return "arrow.down.circle.fill"
        case .TOO_HIGH: return "arrow.up.circle.fill"
        case .IN_RANGE: return "checkmark.circle.fill"
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }

    private func formatDoseAmount(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        } else if value * 10 == (value * 10).rounded() {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)
        }
    }

    private func relativeTimeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ],
            colors: [
                .blue, .cyan, .teal,
                .cyan, .mint, .cyan,
                .teal, .cyan, .blue
            ]
        )
        .ignoresSafeArea()

        HStack(spacing: 60) {
            VerticalTrendBar(
                title: "pH",
                value: 7.2,
                minValue: 6.8,
                maxValue: 8.0,
                idealMin: 7.2,
                idealMax: 7.6,
                barColor: .phBarColor,
                idealRangeColor: .phIdealColor,
                trend: .up,
                scalePosition: .leading,
                prediction: nil
            )

            VerticalTrendBar(
                title: "Cl",
                value: 1.5,
                minValue: 0,
                maxValue: 5,
                idealMin: 1.0,
                idealMax: 3.0,
                barColor: .chlorineBarColor,
                idealRangeColor: .chlorineIdealColor,
                trend: .down,
                scalePosition: .trailing,
                prediction: nil,
                scalePoints: [0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0]
            )
        }
    }
}
