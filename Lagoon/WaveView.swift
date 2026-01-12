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

            let waveColor = Color(red: 0.6, green: 0.9, blue: 1)

            ZStack {
                // Wave 1
                getWaveLine(interval: size.width, amplitude: 80, baseline: size.height * 0.15, size: size)
                    .stroke(waveColor.opacity(0.35), lineWidth: 1.5)
                    .offset(x: isAnimating ? -size.width : 0)
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 2
                getWaveLine(interval: size.width * 1.3, amplitude: 60, baseline: size.height * 0.35, size: size)
                    .stroke(waveColor.opacity(0.3), lineWidth: 1.5)
                    .offset(x: isAnimating ? -size.width * 1.3 : 0)
                    .animation(.linear(duration: 8).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 3
                getWaveLine(interval: size.width * 1.1, amplitude: 100, baseline: size.height * 0.55, size: size)
                    .stroke(waveColor.opacity(0.35), lineWidth: 1.5)
                    .offset(x: isAnimating ? -size.width * 1.1 : 0)
                    .animation(.linear(duration: 7).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 4
                getWaveLine(interval: size.width * 1.5, amplitude: 50, baseline: size.height * 0.75, size: size)
                    .stroke(waveColor.opacity(0.3), lineWidth: 1)
                    .offset(x: isAnimating ? -size.width * 1.5 : 0)
                    .animation(.linear(duration: 9).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 5
                getWaveLine(interval: size.width * 2, amplitude: 40, baseline: size.height * 0.9, size: size)
                    .stroke(waveColor.opacity(0.3), lineWidth: 1)
                    .offset(x: isAnimating ? -size.width * 2 : 0)
                    .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: isAnimating)
            }
            .onAppear {
                isAnimating = true
            }
        }
    }

    private func getWaveLine(interval: CGFloat, amplitude: CGFloat, baseline: CGFloat, size: CGSize) -> Path {
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
        }
    }
}

#Preview {
    WaveView()
}
