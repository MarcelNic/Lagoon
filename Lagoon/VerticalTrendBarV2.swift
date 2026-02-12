//
//  VerticalTrendBarV2.swift
//  Lagoon
//
//  Experimental bar style – wider bars, no ideal range overlay,
//  colored marker with value label.
//

import SwiftUI

struct VerticalTrendBarV2: View {
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
    let markerBorderColorLight: Color
    let markerBorderColorDark: Color
    var compact: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var showPredictionPopover = false
    @Namespace private var namespace

    // Dimensionen
    private let barWidth: CGFloat = 65
    private let barHeight: CGFloat = 400
    private let markerDiameter: CGFloat = 56
    private let markerPadding: CGFloat = 2
    private let markerEndPadding: CGFloat = 1
    private let titleHeight: CGFloat = 48
    private let titleBarSpacing: CGFloat = 20

    private var markerTotalHeight: CGFloat {
        markerDiameter + 2 * markerPadding
    }

    private var scaleTopOffset: CGFloat {
        markerTotalHeight / 2 + markerEndPadding
    }

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
        markerBorderColorLight: Color = .white,
        markerBorderColorDark: Color = .white,
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
        self.markerBorderColorLight = markerBorderColorLight
        self.markerBorderColorDark = markerBorderColorDark
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

    private var markerYPosition: CGFloat {
        scaleTopOffset + (1 - normalizedValue) * scaleHeight
    }

    var body: some View {
        GlassEffectContainer {
            HStack(alignment: .top, spacing: 0) {
                if scalePosition == .leading {
                    scaleMarks(leading: true)
                        .opacity(compact ? 0 : 1)
                        .padding(.trailing, 12)
                        .padding(.top, titleHeight + titleBarSpacing)
                }

                VStack(spacing: titleBarSpacing) {
                    Text(title)
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
                        .fixedSize()
                        .frame(width: barWidth)
                        .opacity(compact ? 0 : 1)

                    Button {
                        if prediction != nil {
                            showPredictionPopover = true
                        }
                    } label: {
                        ZStack(alignment: .top) {
                            // Haupt-Bar (Hintergrund)
                            RoundedRectangle(cornerRadius: barWidth / 2)
                                .fill(Color(light: barColor.opacity(0.8), dark: barColor.opacity(0.5)))
                                .frame(width: barWidth, height: barHeight)

                            // Marker-Kreis (nur visuell, ohne Text)
                            markerCircle
                                .offset(y: markerYPosition - markerTotalHeight / 2)
                                .animation(.smooth, value: value)

                            // Wert-Label (getrennt, eigene Animation)
                            markerLabel
                                .offset(y: markerYPosition - markerTotalHeight / 2)
                                .animation(.smooth, value: value)

                            // Trend-Chevron (über oder unter dem Marker)
                            if trend != .stable {
                                Image(systemName: trend == .up ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(idealRangeColor)
                                    .offset(y: trend == .up
                                        ? markerYPosition - markerTotalHeight / 2 - 18
                                        : markerYPosition + markerTotalHeight / 2 + 4)
                                    .animation(.smooth, value: value)
                            }

                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: barWidth / 2))
                    .matchedTransitionSource(id: "PREDICTION_V2_\(title)", in: namespace)
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
                            .navigationTransition(.zoom(sourceID: "PREDICTION_V2_\(title)", in: namespace))
                        }
                    }
                }

                if scalePosition == .trailing {
                    scaleMarks(leading: false)
                        .opacity(compact ? 0 : 1)
                        .padding(.leading, 12)
                        .padding(.top, titleHeight + titleBarSpacing)
                }
            }
        }
        .animation(.smooth, value: compact)
    }

    // MARK: - Marker Circle (nur Kreis, kein Text)

    private var markerBorderColor: Color {
        colorScheme == .dark ? markerBorderColorDark : markerBorderColorLight
    }

    private var markerCircle: some View {
        Circle()
            .fill(idealRangeColor)
            .frame(width: markerDiameter, height: markerDiameter)
            .overlay {
                Circle()
                    .stroke(
                        AngularGradient(
                            stops: [
                                .init(color: markerBorderColor.opacity(0.6), location: 0.0),    // top (12 o'clock)
                                .init(color: markerBorderColor.opacity(1.0), location: 0.125),  // top-right (1:30)
                                .init(color: markerBorderColor.opacity(0.2), location: 0.375),  // bottom-right (4:30)
                                .init(color: markerBorderColor.opacity(1.0), location: 0.625),  // bottom-left (7:30)
                                .init(color: markerBorderColor.opacity(0.2), location: 0.875),  // top-left (10:30)
                                .init(color: markerBorderColor.opacity(0.6), location: 1.0),    // back to top
                            ],
                            center: .center
                        ),
                        lineWidth: 1
                    )
                    .padding(0.5)
            }
            .padding(markerPadding)
    }

    // MARK: - Marker Label (getrennt für saubere Animation)

    private var markerLabel: some View {
        Text(formatValue(value))
            .font(.system(size: 18, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .contentTransition(.numericText())
            .animation(.smooth, value: value)
            .frame(width: markerDiameter + 2 * markerPadding, height: markerDiameter + 2 * markerPadding)
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
                    for j in 1...4 {
                        let frac = Double(j) / 5.0
                        let v = points[i] + frac * (points[i + 1] - points[i])
                        ticks.append((id: id, value: v, isMajor: false))
                        id += 1
                    }
                }
            }
            return ticks
        }

        let range = maxValue - minValue
        let rawStep = range / 5.0
        let magnitude = pow(10, floor(log10(rawStep)))
        let normalized = rawStep / magnitude

        let majorStep: Double
        if normalized <= 1.5 { majorStep = magnitude }
        else if normalized <= 3.5 { majorStep = 2.0 * magnitude }
        else if normalized <= 7.5 { majorStep = 5.0 * magnitude }
        else { majorStep = 10.0 * magnitude }

        let majorCount = Int(round(range / majorStep))
        var ticks: [(id: Int, value: Double, isMajor: Bool)] = []
        var id = 0
        for i in 0...majorCount {
            let majorValue = minValue + Double(i) * majorStep
            ticks.append((id: id, value: majorValue, isMajor: true))
            id += 1
            if i < majorCount {
                for j in 1...4 {
                    let frac = Double(j) / 5.0
                    let v = majorValue + frac * majorStep
                    ticks.append((id: id, value: v, isMajor: false))
                    id += 1
                }
            }
        }
        return ticks
    }

    private func scaleMarks(leading: Bool) -> some View {
        let ticks = scaleTicks

        return ZStack {
            ForEach(ticks, id: \.id) { tick in
                let normalizedPosition = normalizeToScale(tick.value)
                let yPosition = scaleTopOffset + (1 - normalizedPosition) * scaleHeight - barHeight / 2
                let inIdealRange = tick.value >= idealMin && tick.value <= idealMax
                let tickColor: Color = inIdealRange ? idealRangeColor : Color(light: tick.isMajor ? Color(white: 0.35) : Color(white: 0.5), dark: Color.white.opacity(tick.isMajor ? 0.4 : 0.25))
                let labelColor: Color = inIdealRange ? idealRangeColor : Color(light: Color(white: 0.35), dark: Color.white.opacity(0.6))

                HStack(spacing: 4) {
                    if leading {
                        if tick.isMajor {
                            Text(formatValue(tick.value))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(labelColor)
                                .frame(width: 28, alignment: .trailing)
                        } else {
                            Color.clear
                                .frame(width: 28)
                        }

                        Rectangle()
                            .fill(tickColor)
                            .frame(
                                width: tick.isMajor ? 10 : 6,
                                height: tick.isMajor ? 2 : 1
                            )
                            .frame(width: 10, alignment: .trailing)
                    } else {
                        Rectangle()
                            .fill(tickColor)
                            .frame(
                                width: tick.isMajor ? 10 : 6,
                                height: tick.isMajor ? 2 : 1
                            )
                            .frame(width: 10, alignment: .leading)

                        if tick.isMajor {
                            Text(formatValue(tick.value))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundStyle(labelColor)
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
        .animation(.smooth, value: normalizedValue)
    }

    // MARK: - Helpers

    private func formatValue(_ value: Double) -> String {
        String(format: "%.1f", value)
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
            VerticalTrendBarV2(
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
                prediction: nil,
                markerBorderColorLight: Color(hex: "a0ffff"),
                markerBorderColorDark: Color(hex: "1083a6")
            )

            VerticalTrendBarV2(
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
                scalePoints: [0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0],
                markerBorderColorLight: Color(hex: "a8ffe2"),
                markerBorderColorDark: Color(hex: "19877b")
            )
        }
    }
}
