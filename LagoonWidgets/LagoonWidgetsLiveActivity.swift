//
//  LagoonWidgetsLiveActivity.swift
//  LagoonWidgets
//
//  Created by Marcel Nicaeus on 26.01.26.
//

import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Robot Activity Attributes

struct RobotActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var endTime: Date
        var progress: Double
    }

    let startTime: Date
    let duration: TimeInterval
    let actionTitle: String
}

// MARK: - Bottom Arc Shape

struct BottomArcShape: Shape {
    var arcDepth: CGFloat = 0.9

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: rect.width, y: 0)
        let bottomY = rect.height * arcDepth

        let halfWidth = rect.width / 2
        let centerX = halfWidth
        let centerY = (bottomY * bottomY - halfWidth * halfWidth) / (2 * bottomY)
        let radius = bottomY - centerY

        let startAngle = Angle(radians: atan2(startPoint.y - centerY, startPoint.x - centerX))
        let endAngle = Angle(radians: atan2(endPoint.y - centerY, endPoint.x - centerX))

        path.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        return path
    }
}

// MARK: - Timer Arc View

struct TimerArcView: View {
    let startTime: Date
    let duration: TimeInterval
    var lineWidth: CGFloat = 20
    var arcDepth: CGFloat = 0.9

    var body: some View {
        TimelineView(.periodic(from: startTime, by: 1.0)) { timeline in
            let elapsed = timeline.date.timeIntervalSince(startTime)
            let progress = min(1.0, max(0.0, elapsed / duration))

            ArcWithDot(progress: progress, lineWidth: lineWidth, arcDepth: arcDepth)
        }
    }
}

struct ArcWithDot: View {
    let progress: Double
    let lineWidth: CGFloat
    let arcDepth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let bottomY = height * arcDepth
            let halfWidth = width / 2
            let centerX = halfWidth
            let centerY = (bottomY * bottomY - halfWidth * halfWidth) / (2 * bottomY)
            let radius = bottomY - centerY

            // Winkel für Start und Ende
            let startAngle = atan2(0 - centerY, 0 - centerX)
            let endAngle = atan2(0 - centerY, width - centerX)

            // Aktueller Winkel basierend auf Progress
            let currentAngle = startAngle + (endAngle - startAngle) * progress

            // Position auf dem Kreis
            let dotX = centerX + radius * cos(currentAngle)
            let dotY = centerY + radius * sin(currentAngle)

            ZStack {
                BottomArcShape(arcDepth: arcDepth)
                    .stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                Circle()
                    .fill(.white)
                    .frame(width: lineWidth * 0.5, height: lineWidth * 0.5)
                    .position(x: dotX, y: dotY)
            }
        }
    }
}

// MARK: - Progress Bar View

struct ProgressBarView: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(.white.opacity(0.3))

                // Progress fill
                Capsule()
                    .fill(.white)
                    .frame(width: geometry.size.width * progress)
            }
        }
    }
}

// MARK: - Live Activity Content

struct LiveActivityContent: View {
    let context: ActivityViewContext<RobotActivityAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header: Roboter links, Timer rechts
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "figure.pool.swim")
                        .font(.title3)
                    Text("Roboter")
                        .font(.headline)
                }

                Spacer()

                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            // Fortschrittsbalken
            ProgressBarView(progress: context.state.progress)
                .frame(height: 8)
        }
        .padding(16)
    }
}

// MARK: - Live Activity Widget

struct LagoonWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RobotActivityAttributes.self) { context in
            // Lock Screen
            LiveActivityContent(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded: Oben links Pool
                DynamicIslandExpandedRegion(.leading) {
                    Text("Pool")
                        .font(.headline)
                        .padding(.leading, 60)
                }

                // Expanded: Oben rechts Timer
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .font(.headline)
                        .padding(.trailing, 20)
                }

                // Expanded: Unten Arc
                DynamicIslandExpandedRegion(.bottom) {
                    TimerArcView(
                        startTime: context.attributes.startTime,
                        duration: context.attributes.duration,
                        arcDepth: 0.8
                    )
                    .frame(height: 80)
                    .padding(.horizontal, 14)
                    .padding(.top, 15)
                }
            } compactLeading: {
                Image(systemName: "figure.pool.swim")
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.caption2)
            } minimal: {
                Image(systemName: "figure.pool.swim")
            }
            .contentMargins(.bottom, 20, for: .expanded)
        }
    }
}

// MARK: - Preview

#Preview("Arc Test") {
    VStack(spacing: 20) {
        // 60 Sekunden Timer, gerade gestartet
        TimerArcView(startTime: .now, duration: 60, arcDepth: 0.8)
            .frame(height: 80)
    }
    .padding()
    .background(Color.black)
}

#Preview("Lock Screen", as: .content, using: RobotActivityAttributes(
    startTime: .now,
    duration: 7200,
    actionTitle: "Roboter läuft"
)) {
    LagoonWidgetsLiveActivity()
} contentStates: {
    RobotActivityAttributes.ContentState(endTime: .now.addingTimeInterval(5400), progress: 0.25)
}
