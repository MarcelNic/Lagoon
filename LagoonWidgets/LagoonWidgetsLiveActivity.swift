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

// MARK: - Cyan Color

extension Color {
    static let robotCyan = Color(red: 0.396, green: 0.792, blue: 1.0)
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

// MARK: - Timer Arc Progress View

struct TimerArcProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 20
    var arcDepth: CGFloat = 0.9
    var foregroundColor: Color = .robotCyan
    var backgroundColor: Color = .robotCyan.opacity(0.3)

    var body: some View {
        ZStack {
            BottomArcShape(arcDepth: arcDepth)
                .stroke(backgroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            BottomArcShape(arcDepth: arcDepth)
                .trim(from: 0, to: progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - Live Activity Widget

struct LagoonWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RobotActivityAttributes.self) { context in
            // Lock Screen - max 160pt
            VStack {
                TimerArcProgressView(progress: context.state.progress)
                    .frame(height: 70)
                    .padding(.horizontal, 24)
                Spacer()
                HStack {
                    Text("Pool Roboter")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(height: 160)
            .activityBackgroundTint(.black)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        TimerArcProgressView(progress: context.state.progress)
                            .frame(height: 70)
                            .padding(.horizontal, 24)
                        Spacer()
                    }
                    .frame(height: 150)
                }
            } compactLeading: {
                Image(systemName: "figure.pool.swim")
                    .foregroundStyle(Color.robotCyan)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundStyle(.white)
            } minimal: {
                Image(systemName: "figure.pool.swim")
                    .foregroundStyle(Color.robotCyan)
            }
            .contentMargins(.bottom, 0, for: .expanded)
            .contentMargins(.top, 0, for: .expanded)
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: RobotActivityAttributes(
    startTime: .now,
    duration: 7200,
    actionTitle: "Roboter läuft"
)) {
    LagoonWidgetsLiveActivity()
} contentStates: {
    RobotActivityAttributes.ContentState(endTime: .now.addingTimeInterval(5400), progress: 0.25)
}
