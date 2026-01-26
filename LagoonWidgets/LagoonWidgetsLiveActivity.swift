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
    static let robotCyan = Color(red: 0.396, green: 0.792, blue: 1.0) // #65CAFF
}

// MARK: - Time Formatting

/// Formats remaining time as "H:MM" without seconds
func formatRemainingTime(until endTime: Date) -> String {
    let remaining = max(0, endTime.timeIntervalSinceNow)
    let hours = Int(remaining) / 3600
    let minutes = (Int(remaining) % 3600) / 60
    return "\(hours):\(String(format: "%02d", minutes))"
}

// MARK: - Circular Arc Shape (180° flipped - opens downward, same geometry as Dashboard)

struct CircularArcShape: Shape {
    var arcHeight: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start- und Endpunkt: Oben links/rechts (gespiegelt vom Dashboard)
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: rect.width, y: 0)

        // Unterster Punkt: Mitte, arcHeight von unten
        let bottomY = rect.height * arcHeight

        // Kreismittelpunkt und Radius berechnen (gleiche Formel wie Dashboard, gespiegelt)
        let halfWidth = rect.width / 2

        // Formel angepasst für nach unten öffnenden Bogen
        let centerY = (halfWidth * halfWidth + bottomY * bottomY) / (2 * bottomY)
        let centerX = halfWidth
        let radius = centerY

        // Winkel berechnen
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
    let lineWidth: CGFloat
    let arcHeight: CGFloat

    init(progress: Double, lineWidth: CGFloat = 14, arcHeight: CGFloat = 0.7) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.arcHeight = arcHeight
    }

    var body: some View {
        ZStack {
            // Background arc
            CircularArcShape(arcHeight: arcHeight)
                .stroke(Color.robotCyan.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress arc
            CircularArcShape(arcHeight: arcHeight)
                .trim(from: 0, to: progress)
                .stroke(Color.robotCyan, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
                DynamicIslandExpandedRegion(.leading) {
                    Text("Pool Roboter")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true, showsHours: true)
                        .monospacedDigit()
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.robotCyan)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerArcProgressView(
                        progress: context.state.progress,
                        lineWidth: 14,
                        arcHeight: 0.7
                    )
                    .frame(height: 70)
                    .padding(.horizontal, 24)
                }
            } compactLeading: {
                // Robi icon
                Image("Robi")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.robotCyan)
            } compactTrailing: {
                // Time in H:MM format (no seconds)
                Text(formatRemainingTime(until: context.state.endTime))
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } minimal: {
                // Robi icon only
                Image("Robi")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.robotCyan)
            }
        }
    }
}

// MARK: - Lock Screen View

struct LockScreenView: View {
    @Environment(\.colorScheme) var colorScheme
    let context: ActivityViewContext<RobotActivityAttributes>

    private var isDarkMode: Bool { colorScheme == .dark }

    var body: some View {
        VStack(spacing: 12) {
            // Header: Title left, Time right
            HStack {
                Text("Pool Roboter")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isDarkMode ? .white : .black)

                Spacer()

                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true, showsHours: true)
                    .monospacedDigit()
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(isDarkMode ? Color.robotCyan : .black)
            }

            // Arc progress
            LockScreenArcView(progress: context.state.progress, isDarkMode: isDarkMode)
                .frame(height: 80)
                .padding(.horizontal, 8)
        }
        .padding(16)
        .activityBackgroundTint(isDarkMode ? .black : Color.robotCyan)
    }
}

// Separate arc for Lock Screen with color scheme support
struct LockScreenArcView: View {
    let progress: Double
    let isDarkMode: Bool
    let lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            CircularArcShape(arcHeight: 0.7)
                .stroke(
                    isDarkMode ? Color.robotCyan.opacity(0.3) : Color.black.opacity(0.2),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )

            CircularArcShape(arcHeight: 0.7)
                .trim(from: 0, to: progress)
                .stroke(
                    isDarkMode ? Color.robotCyan : Color.black,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
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
