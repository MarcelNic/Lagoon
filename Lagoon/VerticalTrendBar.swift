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
        self.compact = compact
    }

    private var normalizedValue: CGFloat {
        let clamped = min(max(value, minValue), maxValue)
        return CGFloat((clamped - minValue) / (maxValue - minValue))
    }

    private var idealMinNormalized: CGFloat {
        CGFloat((idealMin - minValue) / (maxValue - minValue))
    }

    private var idealMaxNormalized: CGFloat {
        CGFloat((idealMax - minValue) / (maxValue - minValue))
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

    private func scaleMarks(leading: Bool) -> some View {
        let steps = 10
        let majorInterval = 2
        let labelHeight: CGFloat = 14

        return ZStack {
            ForEach(0...steps, id: \.self) { i in
                let isMajor = i % majorInterval == 0
                let normalizedPosition = CGFloat(steps - i) / CGFloat(steps)
                let scaleValue = minValue + Double(normalizedPosition) * (maxValue - minValue)
                let yPosition = scaleTopOffset + (1 - normalizedPosition) * scaleHeight - barHeight / 2

                // Check overlap with value pill
                let labelY = scaleTopOffset + (1 - normalizedPosition) * scaleHeight
                let distance = abs(markerYPosition - labelY)
                let overlapThreshold = (valuePillHeight + labelHeight) / 2
                let labelVisible = !isMajor || distance >= overlapThreshold

                HStack(spacing: 4) {
                    if leading {
                        // Wert-Label bei major ticks
                        if isMajor {
                            Text(formatValue(scaleValue))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(light: Color.black, dark: Color.white.opacity(0.6)))
                                .frame(width: 28, alignment: .trailing)
                                .opacity(labelVisible ? 1 : 0)
                        } else {
                            Color.clear
                                .frame(width: 28)
                        }

                        Rectangle()
                            .fill(Color(light: isMajor ? Color.black.opacity(0.8) : Color.black.opacity(0.4), dark: Color.white.opacity(isMajor ? 0.4 : 0.25)))
                            .frame(
                                width: isMajor ? 10 : 6,
                                height: isMajor ? 2 : 1
                            )
                    } else {
                        Rectangle()
                            .fill(Color(light: isMajor ? Color.black.opacity(0.8) : Color.black.opacity(0.4), dark: Color.white.opacity(isMajor ? 0.4 : 0.25)))
                            .frame(
                                width: isMajor ? 10 : 6,
                                height: isMajor ? 2 : 1
                            )

                        // Wert-Label bei major ticks
                        if isMajor {
                            Text(formatValue(scaleValue))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(Color(light: Color.black, dark: Color.white.opacity(0.6)))
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
            Text(formatValue(value) + (unit.isEmpty ? "" : " \(unit)"))
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

fileprivate struct PopoverHelper<Content: View>: View {
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
        VStack(alignment: .leading, spacing: 16) {
            // Header mit Titel und Apple Intelligence
            HStack {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 20))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.red, .orange, .yellow, .green, .blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("\(title) Vorhersage")
                    .font(.headline)
            }

            Divider()

            // Geschätzter Wert
            VStack(alignment: .leading, spacing: 4) {
                Text("Geschätzter aktueller Wert")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(formatValue(prediction.estimatedValue) + (unit.isEmpty ? "" : " \(unit)"))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(tintColor)

                    Image(systemName: trend.chevronName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(trendColor)
                }
            }

            // Letzte Messung
            VStack(alignment: .leading, spacing: 4) {
                Text("Letzte Messung")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack {
                    Text(formatValue(prediction.lastMeasuredValue) + (unit.isEmpty ? "" : " \(unit)"))
                        .font(.system(size: 17, weight: .medium, design: .rounded))

                    Spacer()

                    Text(relativeTimeString(from: prediction.lastMeasurementTime))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Confidence
            HStack {
                confidenceIcon
                    .font(.system(size: 14))

                Text("Konfidenz: \(confidenceText)")
                    .font(.subheadline)

                Spacer()
            }

            Text(prediction.confidenceReason)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Empfehlung (falls vorhanden)
            if let recommendation = prediction.recommendation,
               recommendation.action != .none {
                Divider()

                VStack(alignment: .leading, spacing: 4) {
                    Text("Empfehlung")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(recommendation.explanation)
                        .font(.callout)
                }
            }
        }
        .padding()
        .frame(width: 280)
    }

    // MARK: - Helpers

    private var confidenceText: String {
        switch prediction.confidence {
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        }
    }

    private var confidenceIcon: some View {
        Group {
            switch prediction.confidence {
            case .high:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            case .medium:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
            case .low:
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.red)
            }
        }
    }

    private var trendColor: Color {
        switch trend {
        case .up: return .orange
        case .down: return .blue
        case .stable: return .green
        }
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
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
                prediction: nil
            )
        }
    }
}
