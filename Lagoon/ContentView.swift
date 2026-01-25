//
//  ContentView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPoolcare = false
    @State private var showPoolOverview = false
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(light: .white, dark: Color(hex: "0a1628")),
                        Color(light: Color(hex: "111184"), dark: Color(hex: "1a3a5c"))
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    Spacer()

                    // Live Activity Style Stacks
                    GlassEffectContainer {
                        VStack(spacing: 12) {
                            // Stack 1 - pH
                            Button {
                                // TODO: pH action
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                                        .fill(Color(light: Color.black, dark: Color.white).opacity(0.001))

                                    CircularArcProgressView(
                                        value: 0.35,
                                        idealMin: 0.35,
                                        idealMax: 0.65,
                                        color: Color(red: 0x42/255, green: 0xED/255, blue: 0xFE/255)
                                    )
                                    .padding(45)

                                    // Header & Value - konzentrische Margins (20pt zum Rand)
                                    VStack {
                                        HStack {
                                            Text("pH")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                            Spacer()
                                            Text("vor 2 Std.")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Color(red: 0x42/255, green: 0xED/255, blue: 0xFE/255))
                                        }

                                        Spacer()

                                        Text("7.2")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                    }
                                    .padding(.horizontal, 35)
                                    .padding(.vertical, 30)
                                }
                                .frame(height: 180)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 50))

                            // Stack 2 - Chlor
                            Button {
                                // TODO: Chlor action
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 50, style: .continuous)
                                        .fill(Color(light: Color.black, dark: Color.white).opacity(0.001))

                                    CircularArcProgressView(
                                        value: 0.3,
                                        idealMin: 0.2,
                                        idealMax: 0.6,
                                        color: Color(hex: "5df66d")
                                    )
                                    .padding(45)

                                    // Header & Value - konzentrische Margins (20pt zum Rand)
                                    VStack {
                                        HStack {
                                            Text("Chlor")
                                                .font(.system(size: 17, weight: .semibold))
                                                .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                            Spacer()
                                            Text("vor 5 Std.")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(Color(red: 0x42/255, green: 0xED/255, blue: 0xFE/255))
                                        }

                                        Spacer()

                                        Text("1.5")
                                            .font(.system(size: 28, weight: .bold, design: .rounded))
                                            .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                    }
                                    .padding(.horizontal, 35)
                                    .padding(.vertical, 30)
                                }
                                .frame(height: 180)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 50))
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()

                    // Bottom Bar
                    GlassEffectContainer(spacing: 12) {
                        HStack(spacing: 12) {
                            // Linker Button - Poolcare + Pool Name
                            HStack(spacing: 0) {
                                Button {
                                    showPoolcare = true
                                } label: {
                                    Image(systemName: "checklist")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                        .padding(.leading, 24)
                                        .padding(.trailing, 12)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolcare", in: namespace)

                                Rectangle()
                                    .fill(Color(light: Color.black, dark: Color.white).opacity(0.3))
                                    .frame(width: 1, height: 26)

                                Button {
                                    showPoolOverview = true
                                } label: {
                                    Text("Mein Pool")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundStyle(Color(light: Color.black, dark: Color.white))
                                        .padding(.leading, 12)
                                        .padding(.trailing, 24)
                                        .frame(height: 52)
                                }
                                .matchedTransitionSource(id: "poolOverview", in: namespace)
                            }
                            .glassEffect(.clear.interactive(), in: .capsule)

                            // Mittlerer Button - Messen
                            Button {
                                showMessenSheet = true
                            } label: {
                                Image(systemName: "testtube.2")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(light: Color.black, dark: Color.white))
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)

                            // Rechter Button - Dosieren
                            Button {
                                showDosierenSheet = true
                            } label: {
                                Image(systemName: "circle.grid.cross")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Color(light: Color.black, dark: Color.white))
                            }
                            .frame(width: 52, height: 52)
                            .glassEffect(.clear.interactive(), in: .circle)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .navigationDestination(isPresented: $showPoolcare) {
                    PoolcareView()
                        .navigationTransition(.zoom(sourceID: "poolcare", in: namespace))
                }
                .navigationDestination(isPresented: $showPoolOverview) {
                    PoolOverviewView()
                        .navigationTransition(.zoom(sourceID: "poolOverview", in: namespace))
                }
                .toolbar(.hidden, for: .navigationBar)
            }
        }
        .sheet(isPresented: $showMessenSheet) {
            MessenSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            DosierenSheet()
                .presentationDetents([.medium])
        }
    }
}

// MARK: - Circular Arc Shape

struct CircularArcShape: Shape {
    // Wie hoch der Bogen sein soll (0.0 - 1.0, relativ zur Höhe)
    var arcHeight: CGFloat = 0.7

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Start- und Endpunkt: Unten links/rechts
        let startPoint = CGPoint(x: 0, y: rect.height)
        let endPoint = CGPoint(x: rect.width, y: rect.height)

        // Oberster Punkt: Mitte, arcHeight von oben
        let topY = rect.height * (1 - arcHeight)

        // Kreismittelpunkt und Radius berechnen
        let halfWidth = rect.width / 2

        // Formel: r² = (w/2)² + (cy - h)² und r = cy - topY
        // Aufgelöst: cy = (w²/4 + h² - topY²) / (2*(h - topY))
        let h = rect.height
        let centerY = (halfWidth * halfWidth + h * h - topY * topY) / (2 * (h - topY))
        let centerX = halfWidth
        let radius = centerY - topY

        // Winkel berechnen
        let startAngle = Angle(radians: atan2(startPoint.y - centerY, startPoint.x - centerX))
        let endAngle = Angle(radians: atan2(endPoint.y - centerY, endPoint.x - centerX))

        path.addArc(
            center: CGPoint(x: centerX, y: centerY),
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

// MARK: - Circular Arc Progress View

struct CircularArcProgressView: View {
    let value: Double      // Aktueller Wert (0.0 - 1.0)
    let idealMin: Double   // Idealbereich Start (0.0 - 1.0)
    let idealMax: Double   // Idealbereich Ende (0.0 - 1.0)
    let color: Color
    let lineWidth: CGFloat = 20
    let arcHeight: CGFloat = 0.7

    var body: some View {
        GeometryReader { geo in
            let rect = geo.frame(in: .local)

            // Gleiche Berechnung wie im Shape
            let halfWidth = rect.width / 2
            let topY = rect.height * (1 - arcHeight)
            let h = rect.height
            let centerY = (halfWidth * halfWidth + h * h - topY * topY) / (2 * (h - topY))
            let centerX = halfWidth
            let radius = centerY - topY

            // Start- und Endwinkel
            let startAngle = atan2(h - centerY, 0 - centerX)
            let endAngle = atan2(h - centerY, rect.width - centerX)

            // Winkel für Indikator (interpoliert zwischen start und end)
            let totalAngle = endAngle - startAngle
            let valueAngle = startAngle + (totalAngle * value)

            // Indikator-Position auf dem Kreis
            let indicatorX = centerX + cos(valueAngle) * radius
            let indicatorY = centerY + sin(valueAngle) * radius

            ZStack {
                // Hintergrund-Arc (abgedunkelte Version der Ideal-Range-Farbe)
                CircularArcShape(arcHeight: arcHeight)
                    .stroke(color.opacity(0.25), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Ideal-Range-Arc (mittig)
                CircularArcShape(arcHeight: arcHeight)
                    .trim(from: idealMin, to: idealMax)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Indikator-Punkt
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    .position(x: indicatorX, y: indicatorY)
            }
        }
    }
}

// MARK: - Pool Overview View

struct PoolOverviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header mit Liquid Glass
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                Spacer()

                Text("Mein Pool")
                    .font(.headline)

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            Spacer()

            Text("Pool Übersicht Inhalt")

            Spacer()
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            PoolSettingsSheet()
        }
    }
}

// MARK: - Pool Settings Sheet

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct PoolSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appearanceMode") private var appearanceMode: String = AppearanceMode.system.rawValue

    private var selectedMode: AppearanceMode {
        AppearanceMode(rawValue: appearanceMode) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Darstellung") {
                    Picker("Erscheinungsbild", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases, id: \.rawValue) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Einstellungen")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .buttonStyle(.glassProminent)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
