//
//  DashboardVariantBars.swift
//  Lagoon
//
//  Alternative Dashboard mit vertikalen Balken (nur zum Anschauen)
//

import SwiftUI

enum DashboardStyle: String, CaseIterable {
    case arcs = "Arcs"
    case bars = "Bars"
    case classic = "Classic"
}

struct DashboardVariantBars: View {
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPoolcare = false
    @State private var dashboardStyle: DashboardStyle = .bars
    @Namespace private var namespace

    // Farben wie bei den Arcs
    private let phColor = Color(hex: "42edfe")
    private let chlorineColor = Color(hex: "5df66d")

    var body: some View {
        NavigationStack {
            ZStack {
                // Gleicher Gradient wie Dashboard
                LinearGradient(
                    colors: [
                        Color(hex: "0a1628"),
                        Color(hex: "1a3a5c")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Segment Control oben
                    Picker("Dashboard Style", selection: $dashboardStyle) {
                        ForEach(DashboardStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 80)
                    .padding(.top, 16)

                    Spacer()

                    // Dashboard Content
                    switch dashboardStyle {
                    case .bars:
                        // Zwei vertikale Balken nebeneinander
                        GlassEffectContainer {
                            HStack(spacing: 24) {
                                VerticalBarView(
                                    title: "pH",
                                    value: 7.2,
                                    minValue: 6.8,
                                    maxValue: 8.0,
                                    idealMin: 7.2,
                                    idealMax: 7.6,
                                    color: phColor,
                                    lastMeasured: "vor 2 Std.",
                                    scaleOnRight: false
                                )

                                VerticalBarView(
                                    title: "Chlor",
                                    value: 1.5,
                                    minValue: 0,
                                    maxValue: 5,
                                    idealMin: 1.0,
                                    idealMax: 3.0,
                                    color: chlorineColor,
                                    lastMeasured: "vor 5 Std.",
                                    scaleOnRight: true
                                )
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 24)
                        }
                        .padding(.horizontal, 16)

                    case .arcs:
                        // Arc Style
                        GlassEffectContainer {
                            VStack(spacing: 12) {
                                arcButton(
                                    title: "pH",
                                    value: "7.2",
                                    lastMeasured: "vor 2 Std.",
                                    progress: 0.35,
                                    idealMin: 0.35,
                                    idealMax: 0.65,
                                    color: phColor
                                )

                                arcButton(
                                    title: "Chlor",
                                    value: "1.5",
                                    lastMeasured: "vor 5 Std.",
                                    progress: 0.3,
                                    idealMin: 0.2,
                                    idealMax: 0.6,
                                    color: chlorineColor
                                )
                            }
                        }
                        .padding(.horizontal, 16)

                    case .classic:
                        // Classic VerticalTrendBar Style
                        HStack(spacing: 60) {
                            VerticalTrendBar(
                                title: "pH",
                                value: 7.2,
                                minValue: 6.8,
                                maxValue: 8.0,
                                idealMin: 7.2,
                                idealMax: 7.6,
                                barColor: phColor.opacity(0.25),
                                idealRangeColor: phColor,
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
                                barColor: chlorineColor.opacity(0.25),
                                idealRangeColor: chlorineColor,
                                trend: .down,
                                scalePosition: .trailing,
                                prediction: nil
                            )
                        }
                    }

                    Spacer()

                    // Bottom Bar (gleich wie Dashboard)
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Button {
                                    showPoolcare = true
                                } label: {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 12)
                                        .padding(.trailing, 24)
                                        .frame(height: 52)
                                }
                            }
                            .glassEffect(.clear.interactive(), in: .capsule)

                            Button {
                                showMessenSheet = true
                            } label: {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            Button {
                                showDosierenSheet = true
                            } label: {
                                Image(systemName: "circle.grid.cross")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showPoolcare) {
                    PoolcareView()
                        .navigationTransition(.zoom(sourceID: "poolcare", in: namespace))
                }
            }
        }
    }

    // MARK: - Arc Button

    @ViewBuilder
    private func arcButton(
        title: String,
        value: String,
        lastMeasured: String,
        progress: Double,
        idealMin: Double,
        idealMax: Double,
        color: Color
    ) -> some View {
        Button {
            // Action
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 50, style: .continuous)
                    .fill(.white.opacity(0.001))

                CircularArcProgressView(
                    value: progress,
                    idealMin: idealMin,
                    idealMax: idealMax,
                    color: color
                )
                .padding(45)

                VStack {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(lastMeasured)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(color)
                    }

                    Spacer()

                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 35)
                .padding(.vertical, 30)
            }
            .frame(height: 180)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 50))
    }
}

// MARK: - Vertical Bar View

struct VerticalBarView: View {
    let title: String
    let value: Double
    let minValue: Double
    let maxValue: Double
    let idealMin: Double
    let idealMax: Double
    let color: Color
    let lastMeasured: String
    let scaleOnRight: Bool

    private let barWidth: CGFloat = 32
    private let barHeight: CGFloat = 280

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

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Text(lastMeasured)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(color)
            }

            // Balken mit Skala
            HStack(alignment: .top, spacing: 8) {
                // Skala links
                if !scaleOnRight {
                    scaleDotsView
                }

                // Vertikaler Balken
                ZStack(alignment: .bottom) {
                    // Hintergrund (abgedunkelte Version)
                    RoundedRectangle(cornerRadius: barWidth / 2)
                        .fill(color.opacity(0.25))
                        .frame(width: barWidth, height: barHeight)

                    // Ideal Range
                    GeometryReader { geo in
                        let idealHeight = (idealMaxNormalized - idealMinNormalized) * geo.size.height
                        let idealOffset = (1 - idealMaxNormalized) * geo.size.height

                        RoundedRectangle(cornerRadius: barWidth / 2)
                            .fill(color)
                            .frame(width: barWidth, height: idealHeight)
                            .offset(y: idealOffset)
                    }
                    .frame(width: barWidth, height: barHeight)

                    // Marker (aktueller Wert)
                    GeometryReader { geo in
                        let markerY = (1 - normalizedValue) * (geo.size.height - 30)

                        Circle()
                            .fill(.white)
                            .frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                            .position(x: barWidth / 2, y: markerY + 15)
                    }
                    .frame(width: barWidth, height: barHeight)
                }
                .frame(width: barWidth, height: barHeight)

                // Skala rechts
                if scaleOnRight {
                    scaleDotsView
                }
            }

            // Wert
            Text(formatValue(value))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }

    // MARK: - Skala mit Punkten

    private var scaleDotsView: some View {
        let steps = 10
        let majorInterval = 2
        let padding: CGFloat = 15  // Abstand vom Rand für Marker

        return VStack(spacing: 0) {
            ForEach(0...steps, id: \.self) { i in
                let isMajor = i % majorInterval == 0

                if i > 0 {
                    Spacer()
                }

                Circle()
                    .fill(.white.opacity(isMajor ? 0.5 : 0.25))
                    .frame(width: isMajor ? 6 : 4, height: isMajor ? 6 : 4)
            }
        }
        .frame(height: barHeight - 2 * padding)
        .padding(.vertical, padding)
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

#Preview {
    DashboardVariantBars()
}
