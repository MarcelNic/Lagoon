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

// MARK: - Circular Arc Shape

struct CircularArcShape: Shape {
    var arcHeight: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let startPoint = CGPoint(x: 0, y: rect.height)
        let endPoint = CGPoint(x: rect.width, y: rect.height)
        let topY = rect.height * (1 - arcHeight)

        let halfWidth = rect.width / 2
        let h = rect.height
        let centerY = (halfWidth * halfWidth + h * h - topY * topY) / (2 * (h - topY))
        let centerX = halfWidth
        let radius = centerY - topY

        let startAngle = Angle(radians: atan2(startPoint.y - centerY, startPoint.x - centerX))
        let endAngle = Angle(radians: atan2(endPoint.y - centerY, endPoint.x - centerX))

        path.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

// MARK: - Timer Arc Progress View

struct TimerArcProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let arcHeight: CGFloat
    let tintColor: Color

    init(progress: Double, lineWidth: CGFloat = 8, arcHeight: CGFloat = 0.7, tintColor: Color = .cyan) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.arcHeight = arcHeight
        self.tintColor = tintColor
    }

    var body: some View {
        ZStack {
            // Background arc
            CircularArcShape(arcHeight: arcHeight)
                .stroke(tintColor.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress arc
            CircularArcShape(arcHeight: arcHeight)
                .trim(from: 0, to: progress)
                .stroke(tintColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - Live Activity Configuration

struct LagoonWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RobotActivityAttributes.self) { context in
            // Lock Screen / Banner Presentation
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded presentation
                DynamicIslandExpandedRegion(.center) {
                    ExpandedCenterView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Robi icon
                Image("Robi")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.cyan)
            } compactTrailing: {
                // Countdown timer
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 50)
            } minimal: {
                // Mini Robi icon
                Image("Robi")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.cyan)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    let context: ActivityViewContext<RobotActivityAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Robi Icon
            Image("Robi")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 44, height: 44)
                .foregroundStyle(.cyan)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.actionTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                // Timer with arc
                HStack(spacing: 12) {
                    TimerArcProgressView(
                        progress: context.state.progress,
                        lineWidth: 6,
                        arcHeight: 0.6,
                        tintColor: .cyan
                    )
                    .frame(width: 60, height: 36)

                    Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                        .monospacedDigit()
                        .font(.system(size: 20, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                }
            }

            Spacer()
        }
        .padding(16)
        .activityBackgroundTint(.black.opacity(0.5))
    }
}

// MARK: - Dynamic Island Expanded Views

struct ExpandedCenterView: View {
    let context: ActivityViewContext<RobotActivityAttributes>

    var body: some View {
        VStack(spacing: 8) {
            // Arc Progress
            TimerArcProgressView(
                progress: context.state.progress,
                lineWidth: 6,
                arcHeight: 0.65,
                tintColor: .cyan
            )
            .frame(width: 120, height: 50)

            // Timer
            Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                .monospacedDigit()
                .font(.system(size: 28, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
    }
}

struct ExpandedBottomView: View {
    let context: ActivityViewContext<RobotActivityAttributes>

    var body: some View {
        HStack {
            // Robi Icon + Title
            Image("Robi")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(.cyan)

            Text(context.attributes.actionTitle)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: RobotActivityAttributes(
    startTime: .now,
    duration: 2 * 60 * 60,
    actionTitle: "Roboter läuft"
)) {
    LagoonWidgetsLiveActivity()
} contentStates: {
    RobotActivityAttributes.ContentState(
        endTime: .now.addingTimeInterval(5400),
        progress: 0.25
    )
}
