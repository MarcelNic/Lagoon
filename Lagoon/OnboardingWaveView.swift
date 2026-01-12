//
//  OnboardingWaveView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 12.01.26.
//

import SwiftUI

struct OnboardingWaveView: View {
    // Horizontale Bewegung
    @State private var phase1: CGFloat = 0
    @State private var phase2: CGFloat = 0
    @State private var phase3: CGFloat = 0
    @State private var phase4: CGFloat = 0

    // Vertikales Wippen
    @State private var bob1: CGFloat = 0
    @State private var bob2: CGFloat = 0
    @State private var bob3: CGFloat = 0
    @State private var bob4: CGFloat = 0

    let waveColor = Color(red: 0.0, green: 0.55, blue: 0.85) // Helleres Poolblau

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            ZStack {
                // Wave 1 - (furthest back, most blur) - langsam, sanftes Wippen
                getSinWave(interval: size.width, amplitude: 50, baseline: size.height / 2 + bob1, size: size)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        getSinWave(interval: size.width, amplitude: 50, baseline: size.height / 2 + bob1, size: size)
                            .fill(waveColor.opacity(0.15))
                    )
                    .blur(radius: 4)
                    .offset(x: phase1)

                // Wave 2 - etwas schneller, anderer Rhythmus
                getSinWave(interval: size.width * 1.2, amplitude: 80, baseline: 50 + size.height / 2 + bob2, size: size)
                    .fill(.thinMaterial)
                    .overlay(
                        getSinWave(interval: size.width * 1.2, amplitude: 80, baseline: 50 + size.height / 2 + bob2, size: size)
                            .fill(waveColor.opacity(0.2))
                    )
                    .blur(radius: 2)
                    .offset(x: phase2)

                // Wave 3 - mittlere Geschwindigkeit
                getSinWave(interval: size.width * 1.5, amplitude: 50, baseline: 75 + size.height / 2 + bob3, size: size)
                    .fill(.regularMaterial)
                    .overlay(
                        getSinWave(interval: size.width * 1.5, amplitude: 50, baseline: 75 + size.height / 2 + bob3, size: size)
                            .fill(waveColor.opacity(0.25))
                    )
                    .blur(radius: 1)
                    .offset(x: phase3)

                // Wave 4 - (frontmost, sharpest) - am langsamsten, majestätisch
                getSinWave(interval: size.width * 3, amplitude: 200, baseline: 95 + size.height / 2 + bob4, size: size)
                    .fill(.thickMaterial)
                    .overlay(
                        getSinWave(interval: size.width * 3, amplitude: 200, baseline: 95 + size.height / 2 + bob4, size: size)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.4), waveColor.opacity(0.35)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
                    .offset(x: phase4)
            }
            .onAppear {
                startAnimations(size: size)
            }
        }
    }

    private func startAnimations(size: CGSize) {
        // Horizontale Bewegungen - unterschiedliche Geschwindigkeiten, linear
        withAnimation(.linear(duration: 7).repeatForever(autoreverses: false)) {
            phase1 = -size.width
        }
        withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
            phase2 = -size.width * 1.2
        }
        withAnimation(.linear(duration: 11).repeatForever(autoreverses: false)) {
            phase3 = -size.width * 1.5
        }
        withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
            phase4 = -size.width * 3
        }

        // Vertikales Wippen - unterschiedliche Rhythmen, linear
        withAnimation(.linear(duration: 3.2).repeatForever(autoreverses: true)) {
            bob1 = 15
        }
        withAnimation(.linear(duration: 2.7).repeatForever(autoreverses: true)) {
            bob2 = -12
        }
        withAnimation(.linear(duration: 4.1).repeatForever(autoreverses: true)) {
            bob3 = 10
        }
        withAnimation(.linear(duration: 5.5).repeatForever(autoreverses: true)) {
            bob4 = -20
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
    OnboardingWaveView()
}
