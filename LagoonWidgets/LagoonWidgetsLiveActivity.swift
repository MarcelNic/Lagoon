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

// MARK: - Bottom Arc Shape (unterer Teil eines Kreises)

struct BottomArcShape: Shape {
    /// Wie tief der Bogen reicht (0.0 - 1.0, relativ zur Höhe)
    var arcDepth: CGFloat = 0.9

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start- und Endpunkt: Oben links/rechts
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = CGPoint(x: rect.width, y: 0)

        // Tiefster Punkt: Mitte, arcDepth von oben
        let bottomY = rect.height * arcDepth

        // Kreismittelpunkt und Radius berechnen
        let halfWidth = rect.width / 2
        let centerX = halfWidth

        // Formel: r² = (w/2)² + (cy)² und r = bottomY - cy
        // Aufgelöst: cy = (bottomY² - w²/4) / (2 * bottomY)
        let centerY = (bottomY * bottomY - halfWidth * halfWidth) / (2 * bottomY)
        let radius = bottomY - centerY

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
    let arcDepth: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    init(
        progress: Double,
        lineWidth: CGFloat = 20,
        arcDepth: CGFloat = 0.9,
        foregroundColor: Color = .robotCyan,
        backgroundColor: Color = .robotCyan.opacity(0.3)
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.arcDepth = arcDepth
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Background arc
            BottomArcShape(arcDepth: arcDepth)
                .stroke(backgroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

            // Progress arc
            BottomArcShape(arcDepth: arcDepth)
                .trim(from: 0, to: progress)
                .stroke(foregroundColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
                    VStack(spacing: 0) {
                        Color.clear.frame(height: 30)
                        TimerArcProgressView(
                            progress: context.state.progress,
                            lineWidth: 20,
                            arcDepth: 0.9
                        )
                        .frame(height: 70)
                        .padding(.horizontal, 24)
                        Color.clear.frame(height: 20)
                    }
                }
            } compactLeading: {
                Image("Robi")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .foregroundStyle(Color.robotCyan)
            } compactTrailing: {
                Text(timerInterval: context.attributes.startTime...context.state.endTime, countsDown: true, showsHours: true)
                    .monospacedDigit()
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            } minimal: {
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

            TimerArcProgressView(
                progress: context.state.progress,
                lineWidth: 20,
                arcDepth: 0.9,
                foregroundColor: isDarkMode ? .robotCyan : .black,
                backgroundColor: isDarkMode ? .robotCyan.opacity(0.3) : .black.opacity(0.2)
            )
            .frame(height: 80)
            .padding(.horizontal, 8)
        }
        .padding(16)
        .activityBackgroundTint(isDarkMode ? .black : Color.robotCyan)
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
