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

    @Namespace private var namespace

    // Dimensionen
    private let barWidth: CGFloat = 38
    private let barHeight: CGFloat = 400
    private let markerDiameter: CGFloat = 26
    private let markerPadding: CGFloat = 2

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
        scalePosition: ScalePosition = .leading
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
        barHeight - (normalizedValue * barHeight)
    }

    var body: some View {
        GlassEffectContainer {
            HStack(alignment: .top, spacing: 0) {
                // Links: Skala mit Pille-Overlay (wenn scalePosition == .leading)
                if scalePosition == .leading {
                    ZStack(alignment: .trailing) {
                        scaleMarks(leading: true)

                        valueLabelView
                            .frame(height: barHeight, alignment: .top)
                            .offset(y: markerYPosition - 15)
                            .padding(.trailing, 4)
                    }
                    .padding(.trailing, 12)
                    .padding(.top, 40 + 48)
                }

                // Titel + Bar mit Marker
                VStack(spacing: 40) {
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
                                .offset(y: markerYPosition - markerDiameter / 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .glassEffect(.clear.interactive(), in: .rect(cornerRadius: barWidth / 2))
                }

                // Rechts: Skala mit Pille-Overlay (wenn scalePosition == .trailing)
                if scalePosition == .trailing {
                    ZStack(alignment: .leading) {
                        scaleMarks(leading: false)

                        valueLabelView
                            .frame(height: barHeight, alignment: .top)
                            .offset(y: markerYPosition - 15)
                            .padding(.leading, 4)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 40 + 48)
                }
            }
        }
    }

    // MARK: - Idealbereich Bar

    private var idealRangeBar: some View {
        let idealHeight = (idealMaxNormalized - idealMinNormalized) * barHeight
        let idealYOffset = barHeight - (idealMaxNormalized * barHeight)

        return RoundedRectangle(cornerRadius: (barWidth - 6) / 2)
            .fill(.white)
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

        return VStack(spacing: 0) {
            ForEach(0...steps, id: \.self) { i in
                let isMajor = i % majorInterval == 0
                let normalizedPosition = CGFloat(steps - i) / CGFloat(steps)
                let scaleValue = minValue + Double(normalizedPosition) * (maxValue - minValue)

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

                if i < steps {
                    Spacer()
                }
            }
        }
        .frame(height: barHeight)
    }

    // MARK: - Wert Label mit Apple Intelligence Icon

    private var valueLabelView: some View {
        Button {
            // Action für Wert-Details
        } label: {
            HStack(spacing: 6) {
                // Apple Intelligence Icon links bei leading (pH)
                if scalePosition == .leading {
                    appleIntelligenceIcon
                }

                Text(formatValue(value) + (unit.isEmpty ? "" : " \(unit)"))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)

                // Apple Intelligence Icon rechts bei trailing (Cl)
                if scalePosition == .trailing {
                    appleIntelligenceIcon
                }
            }
            .frame(minWidth: 60, minHeight: 30)
        }
        .glassEffect(.regular.tint(.white).interactive(), in: .capsule)
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
                tintColor: .green,
                trend: .up,
                scalePosition: .leading
            )

            VerticalTrendBar(
                title: "Cl",
                value: 1.5,
                minValue: 0,
                maxValue: 5,
                idealMin: 1.0,
                idealMax: 3.0,
                tintColor: .blue,
                trend: .down,
                scalePosition: .trailing
            )
        }
    }
}
