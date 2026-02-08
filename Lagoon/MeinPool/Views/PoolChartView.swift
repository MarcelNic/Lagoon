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
    let predictionData: [ChartDataPoint]
    let idealMin: Double?
    let idealMax: Double?
    let lineColor: Color
    let idealRangeColor: Color
    let yDomain: ClosedRange<Double>
    let timeRange: ChartTimeRange
    
    @State private var selectedDate: Date?

    init(
        title: String,
        unit: String,
        data: [ChartDataPoint],
        predictionData: [ChartDataPoint] = [],
        idealMin: Double?,
        idealMax: Double?,
        lineColor: Color,
        idealRangeColor: Color,
        yDomain: ClosedRange<Double>,
        timeRange: ChartTimeRange
    ) {
        self.title = title
        self.unit = unit
        self.data = data
        self.predictionData = predictionData
        self.idealMin = idealMin
        self.idealMax = idealMax
        self.lineColor = lineColor
        self.idealRangeColor = idealRangeColor
        self.yDomain = yDomain
        self.timeRange = timeRange
    }

    // Combined data for selection lookup
    private var allData: [ChartDataPoint] {
        data + predictionData
    }
    
    // Find the closest data point to the selected date
    private var selectedDataPoint: ChartDataPoint? {
        guard let selectedDate else { return nil }
        return allData.min(by: {
            abs($0.timestamp.timeIntervalSince(selectedDate)) < abs($1.timestamp.timeIntervalSince(selectedDate))
        })
    }
    
    // Check if selected point is a prediction
    private var isSelectedPrediction: Bool {
        guard let selectedDataPoint else { return false }
        return predictionData.contains(where: { $0.id == selectedDataPoint.id })
    }
    
    // Extend Y domain slightly to prevent clipping at edges
    private var extendedYDomain: ClosedRange<Double> {
        let range = yDomain.upperBound - yDomain.lowerBound
        let padding = range * 0.05 // 5% padding
        return (yDomain.lowerBound - padding)...(yDomain.upperBound + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title row with selection info
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()
                
                if let selectedPoint = selectedDataPoint {
                    // Show selected point info inline (date left of value)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(formattedSelectionDate(selectedPoint.timestamp))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(formattedValue(selectedPoint.value))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(isSelectedPrediction ? lineColor.opacity(0.6) : lineColor)
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

            if data.isEmpty && predictionData.isEmpty {
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
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .interpolationMethod(.catmullRom)
            }

            // Area under measured curve
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
                .interpolationMethod(.catmullRom)
            }

            // Data points
            ForEach(data) { point in
                PointMark(
                    x: .value("Zeit", point.timestamp),
                    y: .value("Wert", point.value)
                )
                .foregroundStyle(lineColor)
                .symbolSize(30)
            }

            // Prediction line (dashed)
            ForEach(predictionData) { point in
                LineMark(
                    x: .value("Zeit", point.timestamp),
                    y: .value("Wert", point.value),
                    series: .value("Type", "prediction")
                )
                .foregroundStyle(lineColor.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .interpolationMethod(.catmullRom)
            }
            
            // Selection rule line
            if let selectedPoint = selectedDataPoint {
                RuleMark(x: .value("Selected", selectedPoint.timestamp))
                    .foregroundStyle(.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartScrollableAxes([]) // Disable chart scrolling to not interfere with page scroll
        .chartGesture { proxy in
            DragGesture(minimumDistance: 0)
                .onChanged { value in
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
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
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
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
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
                .foregroundStyle(.secondary.opacity(0.5))
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
        switch timeRange {
        case .twentyFourHours:
            return date.formatted(.dateTime.hour(.defaultDigits(amPM: .omitted)).minute())
        default:
            return date.formatted(.dateTime.day().month(.defaultDigits))
        }
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
        case .twentyFourHours: return 6
        case .twoDays: return 4
        case .threeDays: return 4
        case .fiveDays: return 5
        case .tenDays: return 5
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

    let predictionData: [ChartDataPoint] = [
        ChartDataPoint(timestamp: now, value: 7.3),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: 4, to: now)!, value: 7.35),
        ChartDataPoint(timestamp: calendar.date(byAdding: .hour, value: 8, to: now)!, value: 7.4),
    ]

    ZStack {
        Color.black.ignoresSafeArea()

        ScrollView {
            VStack(spacing: 16) {
                PoolChartView(
                    title: "pH-Wert",
                    unit: "",
                    data: sampleData,
                    predictionData: predictionData,
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
