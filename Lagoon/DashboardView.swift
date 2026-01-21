//
//  DashboardView.swift
//  Lagoon
//

import SwiftUI

struct DashboardView: View {
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPoolcare = false
    @State private var showMeinPool = false
    @Namespace private var namespace

    private let phColor = Color(hex: "42edfe")
    private let chlorineColor = Color(hex: "5df66d")

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "0a1628"),
                        Color(hex: "1a3a5c")
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack {
                    Spacer()

                    // Dashboard Content - Classic Style
                    HStack(spacing: 60) {
                        VerticalTrendBar(
                            title: "pH",
                            value: 7.2,
                            minValue: 6.8,
                            maxValue: 8.0,
                            idealMin: 7.2,
                            idealMax: 7.6,
                            barColor: phColor.opacity(0.25),
                            idealRangeColor: phColor,
                            trend: .up,
                            scalePosition: .leading,
                            prediction: nil
                        )

                        VerticalTrendBar(
                            title: "Cl",
                            value: 1.5,
                            minValue: 0,
                            maxValue: 5,
                            idealMin: 1.0,
                            idealMax: 3.0,
                            barColor: chlorineColor.opacity(0.25),
                            idealRangeColor: chlorineColor,
                            trend: .down,
                            scalePosition: .trailing,
                            prediction: nil
                        )
                    }

                    Spacer()

                    // Bottom Bar
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            HStack(spacing: 0) {
                                Button {
                                    showPoolcare = true
                                } label: {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                    showMeinPool = true
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(.white)
                                        .padding(.leading, 12)
                                        .padding(.trailing, 24)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "meinPool", in: namespace)
                            }
                            .glassEffect(.clear.interactive(), in: .capsule)

                            Button {
                                showMessenSheet = true
                            } label: {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            Button {
                                showDosierenSheet = true
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
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(isPresented: $showPoolcare) {
                    PoolcareView()
                        .navigationTransition(.zoom(sourceID: "poolcare", in: namespace))
                }
                .navigationDestination(isPresented: $showMeinPool) {
                    MeinPoolView()
                        .navigationTransition(.zoom(sourceID: "meinPool", in: namespace))
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
