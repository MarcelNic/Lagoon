//
//  WaveView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 12.01.26.
//

import SwiftUI

struct WaveView: View {
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Wave 1 - dark blue
                getSinWave(interval: size.width, amplitude: 100, baseline: size.height / 2, size: size)
                    .fill(Color(red: 0.2, green: 0.4, blue: 0.7).opacity(0.4))
                    .offset(x: isAnimating ? -size.width : 0)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 2 - light blue
                getSinWave(interval: size.width * 1.2, amplitude: 150, baseline: 50 + size.height / 2, size: size)
                    .fill(Color(red: 0.3, green: 0.6, blue: 1).opacity(0.4))
                    .offset(x: isAnimating ? -size.width * 1.2 : 0)
                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 3 - cyan
                getSinWave(interval: size.width * 1.5, amplitude: 50, baseline: 75 + size.height / 2, size: size)
                    .fill(Color(red: 0.6, green: 0.9, blue: 1).opacity(0.4))
                    .offset(x: isAnimating ? -size.width * 1.5 : 0)
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 4 - subtle dark
                getSinWave(interval: size.width * 3, amplitude: 200, baseline: 95 + size.height / 2, size: size)
                    .fill(Color.black.opacity(0.15))
                    .offset(x: isAnimating ? -size.width * 3 : 0)
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }

    private func getSinWave(interval: CGFloat, amplitude: CGFloat, baseline: CGFloat, size: CGSize) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: baseline))

            path.addCurve(
                to: CGPoint(x: interval, y: baseline),
                control1: CGPoint(x: interval * 0.35, y: amplitude + baseline),
                control2: CGPoint(x: interval * 0.65, y: -amplitude + baseline)
            )

            path.addCurve(
                to: CGPoint(x: 2 * interval, y: baseline),
                control1: CGPoint(x: interval * 1.35, y: amplitude + baseline),
                control2: CGPoint(x: interval * 1.65, y: -amplitude + baseline)
            )

            // Close the path to the bottom
            path.addLine(to: CGPoint(x: 2 * interval, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
            path.closeSubpath()
        }
    }
}

#Preview {
    WaveView()
}
