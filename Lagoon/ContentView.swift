//
//  ContentView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .blue, .cyan, .teal,
                    .cyan, .mint, .cyan,
                    .teal, .cyan, .blue
                ]
            )
            .ignoresSafeArea()

            VStack {
                Spacer()

                // Bottom Bar
                GlassEffectContainer(spacing: 12) {
                    HStack(spacing: 12) {
                        // Linker Button - Pool Name + Checklist
                        Button {
                            // Action
                        } label: {
                            HStack(spacing: 0) {
                                Image(systemName: "checklist")
                                    .font(.system(size: 20, weight: .semibold))

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 1, height: 26)
                                    .padding(.horizontal, 12)

                                Text("Pool Name")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .frame(height: 52)
                        }
                        .glassEffect(.clear.interactive(), in: .capsule)

                        // Mittlerer Button - Messen
                        Button {
                            // Action
                        } label: {
                            Image(systemName: "testtube.2")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 52, height: 52)
                        .glassEffect(.clear.interactive(), in: .circle)

                        // Rechter Button - Dosieren
                        Button {
                            // Action
                        } label: {
                            Image(systemName: "circle.grid.cross")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 52, height: 52)
                        .glassEffect(.clear.interactive(), in: .circle)
                    }
                }
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    ContentView()
}
