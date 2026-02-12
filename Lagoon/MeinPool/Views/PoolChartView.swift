//
//  PoolChartView.swift
//  Lagoon
//

import SwiftUI
import Charts

// MARK: - Data Models

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Pool Chart View

struct PoolChartView: View {
    let title: String
    let unit: String
    let data: [ChartDataPoint]
    let idealMin: Double?
    let idealMax: Double?
    let lineColor: Color
    let idealRangeColor: Color
    let yDomain: ClosedRange<Double>
    let timeRange: ChartTimeRange
    let showAreaFill: Bool

    @State private var selectedDate: Date?

    init(
        title: String,
        unit: String,
        data: [ChartDataPoint],
        idealMin: Double?,
        idealMax: Double?,
        lineColor: Color,
        idealRangeColor: Color,
        yDomain: ClosedRange<Double>,
        timeRange: ChartTimeRange,
        showAreaFill: Bool = false
    ) {
        self.title = title
        self.unit = unit
        self.data = data
        self.idealMin = idealMin
        self.idealMax = idealMax
        self.lineColor = lineColor
        self.idealRangeColor = idealRangeColor
        self.yDomain = yDomain
        self.timeRange = timeRange
        self.showAreaFill = showAreaFill
    }

    // Find the closest data point to the selected date
    private var selectedDataPoint: ChartDataPoint? {
        guard let selectedDate else { return nil }
        return data.min(by: {
            abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate))
        })
    }

    // Extend Y domain slightly to prevent clipping at edges
    private var extendedYDomain: ClosedRange<Double> {
        let range = yDomain.upperBound - yDomain.lowerBound
        let padding = range * 0.05 // 5% padding
        return (yDomain.lowerBound - padding)...(yDomain.upperBound + padding)
    }

    private var gridLineValues: [Double] {
        let count = 16
        let lower = extendedYDomain.lowerBound
        let upper = extendedYDomain.upperBound
        let step = (upper - lower) / Double(count)
        return (0...count).map { lower + Double($0) * step }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with selection info
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()
                
                if let selectedPoint = selectedDataPoint {
                    // Show selected point info inline (date left of value)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formattedSelectionDate(selectedPoint.timestamp))
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text(formattedValue(selectedPoint.value))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(lineColor)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                } else if let latest = data.last {
                    Text(formattedValue(latest.value))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(lineColor)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.15), value: selectedDate)

            if data.isEmpty {
                emptyChart
            } else {
                chart
            }
        }
        .padding(.vertical, 16)
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }

    // MARK: - Chart

    @ViewBuilder
    private var chart: some View {
        Chart {
            // Ideal range band (full width including prediction)
            if let idealMin, let idealMax {
                RectangleMark(
                    xStart: .value("Start", timeRange.startDate),
                    xEnd: .value("End", timeRange.endDate),
                    yStart: .value("Min", idealMin),
                    yEnd: .value("Max", idealMax)
                )
                .foregroundStyle(idealRangeColor.opacity(0.15))
            }

            // Measured data line
            ForEach(data) { point in
                LineMark(
                    x: .value("Zeit", point.timestamp),
                    y: .value("Wert", point.value),
                    series: .value("Type", "measured")
                )
                .foregroundStyle(lineColor)
                .lineStyle(StrokeStyle(lineWidth: 3))
                .interpolationMethod(.monotone)
            }

            // Area under measured curve
            if showAreaFill {
                ForEach(data) { point in
                    AreaMark(
                        x: .value("Zeit", point.timestamp),
                        y: .value("Wert", point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [lineColor.opacity(0.2), lineColor.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.monotone)
                }
            }

            // Data points
            ForEach(data) { point in
                PointMark(
                    x: .value("Zeit", point.timestamp),
                    y: .value("Wert", point.value)
                )
                .foregroundStyle(lineColor)
                .symbolSize(40)
            }

            // Selection rule line
            if let selectedPoint = selectedDataPoint {
                RuleMark(x: .value("Selected", selectedPoint.timestamp))
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 1))
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartScrollableAxes([]) // Disable chart scrolling to not interfere with page scroll
        .chartGesture { proxy in
            DragGesture(minimumDistance: 16)
                .onChanged { value in
                    // Only track if gesture is more horizontal than vertical
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                    if let date: Date = proxy.value(atX: value.location.x) {
                        selectedDate = date
                    }
                }
                .onEnded { _ in
                    selectedDate = nil
                }
        }
        .chartYScale(domain: extendedYDomain)
        .chartXScale(domain: timeRange.startDate...timeRange.endDate)
        .chartPlotStyle { plot in
            plot.clipped()
        }
        .chartLegend(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading, values: gridLineValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.secondary.opacity(0.15))
            }
            AxisMarks(position: .leading, values: .automatic(desiredCount: 8)) { value in
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text(formattedAxisValue(v))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisDesiredCount)) { value in
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formattedDate(date))
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(height: 180)
        .padding(.horizontal, 12)
    }

    // MARK: - Empty State

    private var emptyChart: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
            Text("Keine Daten")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }

    // MARK: - Formatting

    private func formattedValue(_ value: Double) -> String {
        if unit == "°C" {
            return String(format: "%.0f %@", value, unit)
        }
        if unit.isEmpty {
            return String(format: "%.1f", value)
        }
        return String(format: "%.1f %@", value, unit)
    }

    private func formattedAxisValue(_ value: Double) -> String {
        if unit == "°C" {
            return String(format: "%.0f°", value)
        }
        return String(format: "%.1f", value)
    }

    private func formattedDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.defaultDigits))
    }
    
    private func formattedSelectionDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Heute, " + date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()) + " Uhr"
        } else if calendar.isDateInYesterday(date) {
            return "Gestern, " + date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()) + " Uhr"
        } else if calendar.isDateInTomorrow(date) {
            return "Morgen, " + date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute()) + " Uhr"
        } else {
            return date.formatted(.dateTime.day().month(.defaultDigits).hour(.defaultDigits(amPM: .omitted)).minute()) + " Uhr"
        }
    }

    private var xAxisDesiredCount: Int {
        switch timeRange {
        case .threeDays: return 4
        case .sevenDays: return 5
        case .fourteenDays: return 5
        case .thirtyDays: return 6
        }
    }
}

// MARK: - Preview

#Preview {
    let now = Date()
    let calendar = Calendar.current

    let sampleData: [ChartDataPoint] = [
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: -48, to: now)!, value: 7.4),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: -36, to: now)!, value: 7.3),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: -24, to: now)!, value: 7.1),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: -12, to: now)!, value: 7.2),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!, value: 7.3),
    ]

    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                PoolChartView(
                    title: "pH-Wert",
                    unit: "",
                    data: sampleData,
                    idealMin: 7.0,
                    idealMax: 7.4,
                    lineColor: .phIdealColor,
                    idealRangeColor: .phIdealColor,
                    yDomain: 6.0...9.0,
                    timeRange: .threeDays
                )

                PoolChartView(
                    title: "Wassertemperatur",
                    unit: "°C",
                    data: [],
                    idealMin: nil,
                    idealMax: nil,
                    lineColor: .orange,
                    idealRangeColor: .clear,
                    yDomain: 10.0...40.0,
                    timeRange: .threeDays
                )
            }
            .padding(20)
        }
    }
}
