//
//  ContentView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI

struct ContentView: View {
    @State private var activeTab: LagoonTab = .home
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showAddTaskSheet = false
    @State private var showSettings = false
    @State private var poolcareState = PoolcareState()
    @Namespace private var tabBarNamespace

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                HomeView(
                    showMessenSheet: $showMessenSheet,
                    showDosierenSheet: $showDosierenSheet
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .care) {
                PoolcareTabView(state: poolcareState)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .pool) {
                MeinPoolView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LagoonTabBarView()
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
        .sheet(isPresented: $showMessenSheet) {
            MessenSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            DosierenSheet()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showAddTaskSheet) {
            AddItemSheet(state: poolcareState)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSettings) {
            PoolSettingsSheet()
        }
    }

    @ViewBuilder
    private func LagoonTabBarView() -> some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                // TabBar (erweitert sich wenn weniger Action-Buttons)
                GeometryReader { geo in
                    LagoonTabBar(size: geo.size, activeTab: $activeTab) { tab in
                        VStack(spacing: 3) {
                            Image(systemName: tab.symbol)
                                .font(.title3)

                            Text(tab.rawValue)
                                .font(.system(size: 10))
                                .fontWeight(.medium)
                        }
                        .symbolVariant(.fill)
                        .frame(maxWidth: .infinity)
                    }
                    .glassEffect(.regular.interactive(), in: .capsule)
                }

                // Action-Buttons (animiert ein/aus je nach Tab)
                if activeTab == .home {
                    // Messen Button
                    Button {
                        showMessenSheet = true
                    } label: {
                        Image(systemName: "testtube.2")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("action1", in: tabBarNamespace)
                    .transition(.blurReplace)

                    // Dosieren Button
                    Button {
                        showDosierenSheet = true
                    } label: {
                        Image(systemName: "circle.grid.cross")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("action2", in: tabBarNamespace)
                    .transition(.blurReplace)
                }

                if activeTab == .care {
                    // Plus Button (Aufgabe hinzufügen)
                    Button {
                        showAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("action1", in: tabBarNamespace)
                    .transition(.blurReplace)
                }

                if activeTab == .pool {
                    // Einstellungen Button
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .glassEffectID("action1", in: tabBarNamespace)
                    .transition(.blurReplace)
                }
            }
            .animation(.smooth(duration: 0.4), value: activeTab)
        }
        .frame(height: 55)
    }
}

// MARK: - Home View

struct HomeView: View {
    @Binding var showMessenSheet: Bool
    @Binding var showDosierenSheet: Bool

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                    .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                    .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
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

                                // Header & Value
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

                                // Header & Value
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
            }
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

// MARK: - Arc Test View
struct ArcTestView: View {
    @State private var progress: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Progress: \(Int(progress * 100))%")
                .font(.headline)
                .foregroundStyle(.white)

            TestArcView(progress: progress)
                .frame(height: 100)
                .padding(.horizontal, 20)

            Slider(value: $progress, in: 0...1)
                .padding(.horizontal, 40)
        }
        .padding()
        .background(Color.black)
    }
}

struct TestArcView: View {
    let progress: Double
    let lineWidth: CGFloat = 20
    let arcDepth: CGFloat = 0.8

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let bottomY = height * arcDepth
            let halfWidth = width / 2
            let centerX = halfWidth
            let centerY = (bottomY * bottomY - halfWidth * halfWidth) / (2 * bottomY)
            let radius = bottomY - centerY

            // Winkel für Start und Ende
            let startAngle = atan2(0 - centerY, 0 - centerX)
            let endAngle = atan2(0 - centerY, width - centerX)

            // Aktueller Winkel basierend auf Progress
            let currentAngle = startAngle + (endAngle - startAngle) * progress

            // Position auf dem Kreis
            let dotX = centerX + radius * cos(currentAngle)
            let dotY = centerY + radius * sin(currentAngle)

            ZStack {
                // Arc background
                TestArcShape(arcDepth: arcDepth)
                    .stroke(.white.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))

                // Dot
                Circle()
                    .fill(.white)
                    .frame(width: 12, height: 12)
                    .position(x: dotX, y: dotY)
            }
        }
    }
}

struct TestArcShape: Shape {
    var arcDepth: CGFloat = 0.8

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let bottomY = rect.height * arcDepth
        let halfWidth = rect.width / 2
        let centerY = (bottomY * bottomY - halfWidth * halfWidth) / (2 * bottomY)
        let radius = bottomY - centerY

        let startAngle = Angle(radians: atan2(0 - centerY, 0 - halfWidth))
        let endAngle = Angle(radians: atan2(0 - centerY, rect.width - halfWidth))

        path.addArc(center: CGPoint(x: halfWidth, y: centerY), radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        return path
    }
}

#Preview("Arc Test") {
    ArcTestView()
}
