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

            let waveColor = Color(red: 0x00/255, green: 0x23/255, blue: 0xA1/255) // #0023A1

            ZStack {
                // Wave 1 - (furthest back, most blur)
                getSinWave(interval: size.width, amplitude: 100, baseline: size.height / 2, size: size)
                    .fill(
                        waveGradient(amplitude: 100, baseline: size.height / 2, totalHeight: size.height,
                                     topColor: Color.white.opacity(0.5), bottomColor: waveColor.opacity(0.5))
                    )
                    .blur(radius: 6)
                    .offset(x: isAnimating ? -size.width : 0)
                    .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 2
                getSinWave(interval: size.width * 1.2, amplitude: 150, baseline: 50 + size.height / 2, size: size)
                    .fill(
                        waveGradient(amplitude: 150, baseline: 50 + size.height / 2, totalHeight: size.height,
                                     topColor: Color.white.opacity(0.6), bottomColor: waveColor.opacity(0.6))
                    )
                    .blur(radius: 3)
                    .offset(x: isAnimating ? -size.width * 1.2 : 0)
                    .animation(.linear(duration: 5).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 3
                getSinWave(interval: size.width * 1.5, amplitude: 50, baseline: 75 + size.height / 2, size: size)
                    .fill(
                        waveGradient(amplitude: 50, baseline: 75 + size.height / 2, totalHeight: size.height,
                                     topColor: Color.white.opacity(0.7), bottomColor: waveColor.opacity(0.7))
                    )
                    .blur(radius: 1)
                    .offset(x: isAnimating ? -size.width * 1.5 : 0)
                    .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: isAnimating)

                // Wave 4 - (frontmost, sharpest)
                getSinWave(interval: size.width * 3, amplitude: 200, baseline: 95 + size.height / 2, size: size)
                    .fill(
                        waveGradient(amplitude: 200, baseline: 95 + size.height / 2, totalHeight: size.height,
                                     topColor: Color.white, bottomColor: waveColor)
                    )
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

    private func waveGradient(amplitude: CGFloat, baseline: CGFloat, totalHeight: CGFloat, topColor: Color, bottomColor: Color) -> LinearGradient {
        // Berechne den höchsten Punkt der Welle
        let waveTop = baseline - amplitude
        // Berechne die Höhe der Shape (von Wellenspitze bis Bildschirmunterseite)
        let shapeHeight = totalHeight - waveTop
        // Der Wellenbereich (2 * amplitude) als Prozent der Shape-Höhe
        let wavePercent = min((2 * amplitude) / shapeHeight, 1.0)

        return LinearGradient(
            stops: [
                .init(color: topColor, location: 0),
                .init(color: bottomColor, location: wavePercent)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func getWaveLine(interval: CGFloat, amplitude: CGFloat, baseline: CGFloat) -> Path {
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
