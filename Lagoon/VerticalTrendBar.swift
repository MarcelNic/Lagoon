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
    let tintColor: Color
    let trend: TrendDirection
    let unit: String
    let scalePosition: ScalePosition
    let prediction: PredictionData?

    @State private var showPredictionPopover = false
    @Namespace private var namespace

    // Dimensionen
    private let barWidth: CGFloat = 44
    private let barHeight: CGFloat = 400
    private let markerDiameter: CGFloat = 34
    private let markerPadding: CGFloat = 2
    private let markerEndPadding: CGFloat = 5  // Abstand Marker-Rand zu Bar-Ende
    private let valuePillHeight: CGFloat = 28  // Geschätzte Höhe mit Glass Button Style
    private let titleHeight: CGFloat = 48  // Approximate height of title text
    private let titleBarSpacing: CGFloat = 40

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
        tintColor: Color,
        trend: TrendDirection = .stable,
        unit: String = "",
        scalePosition: ScalePosition = .leading,
        prediction: PredictionData? = nil
    ) {
        self.title = title
        self.value = value
        self.minValue = minValue
        self.maxValue = maxValue
        self.idealMin = idealMin
        self.idealMax = idealMax
        self.tintColor = tintColor
        self.trend = trend
        self.unit = unit
        self.scalePosition = scalePosition
        self.prediction = prediction
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

                        valueLabelView
                            .offset(y: markerYPosition - valuePillHeight / 2)
                            .padding(.trailing, 4)
                    }
                    .padding(.trailing, 12)
                    .padding(.top, titleHeight + titleBarSpacing)
                }

                // Titel + Bar mit Marker
                VStack(spacing: titleBarSpacing) {
                    Text(title)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .fixedSize()

                    Button {
                        // Action für Bar-Details
                    } label: {
                        ZStack(alignment: .top) {
                            // Haupt-Bar (Hintergrund)
                            RoundedRectangle(cornerRadius: barWidth / 2)
                                .fill(.clear)
                                .frame(width: barWidth, height: barHeight)

                            // Idealbereich
                            idealRangeBar

                            // Marker (aktueller Wert)
                            markerView
                                .offset(y: markerYPosition - markerTotalSize / 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: barWidth / 2))
                }

                // Rechts: Skala mit Pille-Overlay (wenn scalePosition == .trailing)
                if scalePosition == .trailing {
                    ZStack(alignment: .topLeading) {
                        scaleMarks(leading: false)

                        valueLabelView
                            .offset(y: markerYPosition - valuePillHeight / 2)
                            .padding(.leading, 4)
                    }
                    .padding(.leading, 12)
                    .padding(.top, titleHeight + titleBarSpacing)
                }
            }
        }
    }

    // MARK: - Idealbereich Bar

    private var idealRangeBar: some View {
        let idealHeight = (idealMaxNormalized - idealMinNormalized) * scaleHeight
        let idealYOffset = scaleTopOffset + (1 - idealMaxNormalized) * scaleHeight

        return RoundedRectangle(cornerRadius: (barWidth - 6) / 2)
            .fill(.white.opacity(0.6))
            .frame(width: barWidth - 6, height: idealHeight)
            .offset(y: idealYOffset)
    }

    // MARK: - Marker View

    private var markerView: some View {
        ZStack {
            Circle()
                .frame(width: markerDiameter, height: markerDiameter)
                .glassEffect(.regular.tint(tintColor), in: .circle)

            Image(systemName: trend.chevronName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
        .padding(markerPadding)
    }

    // MARK: - Skala Markierungen

    private func scaleMarks(leading: Bool) -> some View {
        let steps = 10
        let majorInterval = 2

        return ZStack {
            ForEach(0...steps, id: \.self) { i in
                let isMajor = i % majorInterval == 0
                let normalizedPosition = CGFloat(steps - i) / CGFloat(steps)
                let scaleValue = minValue + Double(normalizedPosition) * (maxValue - minValue)
                let yPosition = scaleTopOffset + (1 - normalizedPosition) * scaleHeight - barHeight / 2

                HStack(spacing: 4) {
                    if leading {
                        // Wert-Label bei major ticks
                        if isMajor {
                            Text(formatValue(scaleValue))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 28, alignment: .trailing)
                        } else {
                            Color.clear
                                .frame(width: 28)
                        }

                        Rectangle()
                            .fill(.white.opacity(isMajor ? 0.4 : 0.25))
                            .frame(
                                width: isMajor ? 10 : 6,
                                height: isMajor ? 2 : 1
                            )
                    } else {
                        Rectangle()
                            .fill(.white.opacity(isMajor ? 0.4 : 0.25))
                            .frame(
                                width: isMajor ? 10 : 6,
                                height: isMajor ? 2 : 1
                            )

                        // Wert-Label bei major ticks
                        if isMajor {
                            Text(formatValue(scaleValue))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.6))
                                .frame(width: 28, alignment: .leading)
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
    }

    // MARK: - Wert Label mit Apple Intelligence Icon

    private var valueLabelView: some View {
        Button {
            if prediction != nil {
                showPredictionPopover = true
            }
        } label: {
            HStack(spacing: 2) {
                // Apple Intelligence Icon links bei leading (pH)
                if scalePosition == .leading && prediction != nil {
                    appleIntelligenceIcon
                }

                Text(formatValue(value) + (unit.isEmpty ? "" : " \(unit)"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))

                // Apple Intelligence Icon rechts bei trailing (Cl)
                if scalePosition == .trailing && prediction != nil {
                    appleIntelligenceIcon
                }
            }
            .padding(.horizontal, 4)
            .matchedTransitionSource(id: "PREDICTION_\(title)", in: namespace)
        }
        .buttonStyle(.glass(.clear.tint(.white).interactive()))
        .fixedSize()
        .popover(isPresented: $showPredictionPopover) {
            if let prediction = prediction {
                PopoverHelper {
                    PredictionPopoverContent(
                        title: title,
                        prediction: prediction,
                        tintColor: tintColor,
                        unit: unit,
                        trend: trend
                    )
                }
                .navigationTransition(.zoom(sourceID: "PREDICTION_\(title)", in: namespace))
            }
        }
    }

    private var appleIntelligenceIcon: some View {
        Image(systemName: "apple.intelligence")
            .font(.system(size: 14))
            .foregroundStyle(
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
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
                tintColor: .phColor,
                trend: .up,
                scalePosition: .leading,
                prediction: PredictionData(
                    estimatedValue: 7.2,
                    confidence: .high,
                    confidenceReason: "Messung vor 4 Stunden, stabile Bedingungen",
                    lastMeasuredValue: 7.1,
                    lastMeasurementTime: Date().addingTimeInterval(-4 * 3600),
                    recommendation: nil
                )
            )

            VerticalTrendBar(
                title: "Cl",
                value: 1.5,
                minValue: 0,
                maxValue: 5,
                idealMin: 1.0,
                idealMax: 3.0,
                tintColor: .chlorineColor,
                trend: .down,
                scalePosition: .trailing,
                prediction: PredictionData(
                    estimatedValue: 1.5,
                    confidence: .medium,
                    confidenceReason: "Messung vor 28 Stunden, hohe UV-Belastung",
                    lastMeasuredValue: 2.0,
                    lastMeasurementTime: Date().addingTimeInterval(-28 * 3600),
                    recommendation: DosingRecommendation(
                        parameter: .freeChlorine,
                        action: .dose,
                        reasonCode: .TOO_LOW,
                        productId: "chlor",
                        amount: 50,
                        unit: "g",
                        targetValue: 1.5,
                        explanation: "Chlorgehalt sinkt. 50g Chlorgranulat hinzufügen."
                    )
                )
            )
        }
    }
}
