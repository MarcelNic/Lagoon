//
//  WaveView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 12.01.26.
//

import SwiftUI

struct WaveView: View {
    // Horizontale Bewegung
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0
    @State private var phase4: CGFloat = 0
    @State private var phase5: CGFloat = 0
    @State private var phase6: CGFloat = 0
    @State private var phase7: CGFloat = 0
    @State private var phase8: CGFloat = 0

    // Vertikales Wippen
    @State private var bob1: CGFloat = 0
    @State private var bob2: CGFloat = 0
    @State private var bob3: CGFloat = 0
    @State private var bob4: CGFloat = 0
    @State private var bob5: CGFloat = 0
    @State private var bob6: CGFloat = 0
    @State private var bob7: CGFloat = 0
    @State private var bob8: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Wave 1
                getWaveLine(interval: size.width * 0.8, amplitude: 40, baseline: size.height * 0.05 + bob1)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase1)

                // Wave 2
                getWaveLine(interval: size.width * 1.1, amplitude: 60, baseline: size.height * 0.2 + bob2)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase2)

                // Wave 3
                getWaveLine(interval: size.width * 0.9, amplitude: 35, baseline: size.height * 0.35 + bob3)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase3)

                // Wave 4
                getWaveLine(interval: size.width * 1.3, amplitude: 70, baseline: size.height * 0.5 + bob4)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase4)

                // Wave 5
                getWaveLine(interval: size.width * 1.0, amplitude: 50, baseline: size.height * 0.65 + bob5)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase5)

                // Wave 6
                getWaveLine(interval: size.width * 1.4, amplitude: 80, baseline: size.height * 0.8 + bob6)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase6)

                // Wave 7
                getWaveLine(interval: size.width * 1.2, amplitude: 55, baseline: size.height * 0.9 + bob7)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase7)

                // Wave 8
                getWaveLine(interval: size.width * 1.6, amplitude: 90, baseline: size.height * 1.0 + bob8)
                    .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    .blur(radius: 3)
                    .offset(x: phase8)
            }
            .onAppear {
                startAnimations(size: size)
            }
        }
    }

    private func startAnimations(size: CGSize) {
        // Horizontale Bewegungen - unterschiedliche Geschwindigkeiten
        withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
            phase1 = -size.width * 0.8
        }
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            phase2 = -size.width * 1.1
        }
        withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
            phase3 = -size.width * 0.9
        }
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            phase4 = -size.width * 1.3
        }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
            phase5 = -size.width * 1.0
        }
        withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) {
            phase6 = -size.width * 1.4
        }
        withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
            phase7 = -size.width * 1.2
        }
        withAnimation(.linear(duration: 13).repeatForever(autoreverses: false)) {
            phase8 = -size.width * 1.6
        }

        // Vertikales Wippen - unterschiedliche Rhythmen
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: true)) {
            bob1 = 12
        }
        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: true)) {
            bob2 = -15
        }
        withAnimation(.linear(duration: 3.5).repeatForever(autoreverses: true)) {
            bob3 = 10
        }
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: true)) {
            bob4 = -18
        }
        withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: true)) {
            bob5 = 14
        }
        withAnimation(.linear(duration: 4.5).repeatForever(autoreverses: true)) {
            bob6 = -20
        }
        withAnimation(.linear(duration: 3.8).repeatForever(autoreverses: true)) {
            bob7 = 16
        }
        withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
            bob8 = -22
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
