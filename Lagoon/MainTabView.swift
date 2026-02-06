//
//  MainTabView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI

struct MainTabView: View {
    @State private var activeTab: LagoonTab = .home
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showSettings = false
    @State private var showAddTaskSheet = false
    @State private var poolcareState = PoolcareState()
    @AppStorage("hasSeenDashboardOverlay") private var hasSeenDashboardOverlay = false
    @Namespace private var tabBarNamespace
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                DashboardTabView(
                    showMessenSheet: $showMessenSheet,
                    showDosierenSheet: $showDosierenSheet
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .care) {
                PoolcareView(state: poolcareState, showAddSheet: $showAddTaskSheet)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .pool) {
                NavigationStack {
                    MeinPoolView(showSettings: $showSettings)
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            LagoonTabBarView()
                .padding(.horizontal, 20)
                .padding(.bottom, -15)
        }
        .sheet(isPresented: $showMessenSheet) {
            MessenSheet()
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            DosierenSheet()
                .presentationDetents([.medium])
        }
        .overlay {
            if !hasSeenDashboardOverlay {
                DashboardTutorialOverlay(onDismiss: {
                    withAnimation(.smooth(duration: 0.4)) {
                        hasSeenDashboardOverlay = true
                    }
                })
            }
        }
        .onAppear {
            poolcareState.setModelContext(modelContext)
        }
    }

    // TabBar Dimensionen
    private let tabBarHeight: CGFloat = 62
    private let tabBarSpacing: CGFloat = 8  // Abstand zwischen TabBar und Buttons
    private let segmentPadding: CGFloat = 3  // Vertikaler Abstand für Concentricity
    private let segmentHorizontalPadding: CGFloat = 3  // Horizontaler Abstand (Tabs näher zusammen)

    @ViewBuilder
    private func LagoonTabBarView() -> some View {
        GlassEffectContainer(spacing: tabBarSpacing) {
            HStack(spacing: tabBarSpacing) {
                // TabBar mit Padding-Container für Concentricity
                GeometryReader { geo in
                    let innerSize = CGSize(
                        width: geo.size.width - (segmentHorizontalPadding * 2),
                        height: geo.size.height - (segmentPadding * 2)
                    )
                    LagoonTabBar(size: innerSize, activeTab: $activeTab) { tab in
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
                    .frame(width: innerSize.width, height: innerSize.height)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                }
                .glassEffect(.regular.interactive(), in: .capsule)

                // Action Button 1 (wechselt Icon je nach Tab mit blurFade)
                Button {
                    switch activeTab {
                    case .home: showMessenSheet = true
                    case .care: showAddTaskSheet = true
                    case .pool: showSettings = true
                    }
                } label: {
                    ZStack {
                        Image(systemName: "testtube.2")
                            .blurFade(activeTab == .home)
                        Image(systemName: "plus")
                            .blurFade(activeTab == .care)
                        Image(systemName: "gearshape")
                            .blurFade(activeTab == .pool)
                    }
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(light: .black, dark: .white))
                }
                .frame(width: tabBarHeight, height: tabBarHeight)
                .glassEffect(.regular.interactive(), in: .capsule)

                // Action Button 2 (nur bei Home sichtbar)
                if activeTab == .home {
                    Button {
                        showDosierenSheet = true
                    } label: {
                        Image(systemName: "aqi.medium")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: tabBarHeight, height: tabBarHeight)
                    .glassEffect(.regular.interactive(), in: .capsule)
                    .transition(.blurReplace)
                }
            }
            .animation(.smooth(duration: 0.4), value: activeTab)
        }
        .frame(height: tabBarHeight)
    }
}

// MARK: - Dashboard Tab View (ohne eigene Bottom Bar)

struct DashboardTabView: View {
    @Environment(PoolWaterState.self) private var poolWaterState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    // Sheet Bindings from MainTabView
    @Binding var showMessenSheet: Bool
    @Binding var showDosierenSheet: Bool

    @State private var showQuickMeasure = false
    @State private var quickMeasurePhase: Int = 0
    @State private var timeOffsetSelection: Int = 0

    private var anySheetPresented: Bool {
        showMessenSheet || showDosierenSheet || showQuickMeasure
    }

    private var showDosingPill: Bool {
        poolWaterState.recentDosingActive || poolWaterState.dosingNeeded
    }

    private var barScale: CGFloat {
        guard anySheetPresented else { return 1.0 }
        if showQuickMeasure {
            switch quickMeasurePhase {
            case 1: return 1.0    // dosieren – kleines sheet
            case 2: return 0.65   // bearbeiten – großes sheet
            default: return 0.80  // messen
            }
        }
        return 0.80
    }

    private var recentDosingLabel: String {
        var parts: [String] = []
        if poolWaterState.lastDosingChlorineAmount > 0 {
            let formatted = DosingFormatter.format(grams: poolWaterState.lastDosingChlorineAmount, unit: dosingUnit, cupGrams: cupGrams)
                .replacingOccurrences(of: " Becher", with: "")
                .replacingOccurrences(of: " g", with: "g")
            parts.append("\(formatted) Cl")
        }
        if poolWaterState.lastDosingPHAmount > 0 {
            let formatted = DosingFormatter.format(grams: poolWaterState.lastDosingPHAmount, unit: dosingUnit, cupGrams: cupGrams)
                .replacingOccurrences(of: " Becher", with: "")
                .replacingOccurrences(of: " g", with: "g")
            parts.append("\(formatted) \(poolWaterState.lastDosingPHType)")
        }
        return parts.isEmpty ? "Dosiert" : parts.joined(separator: " ")
    }

    private var simulationTimeLabel: String {
        guard timeOffsetSelection > 0 else { return "Jetzt" }

        let calendar = Calendar.current
        let now = calendar.dateInterval(of: .hour, for: Date())?.start ?? Date()
        let targetDate = now.addingTimeInterval(Double(timeOffsetSelection) * 3600)

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = timeFormatter.string(from: targetDate)

        if calendar.isDateInToday(targetDate) {
            return timeString
        } else if calendar.isDateInTomorrow(targetDate) {
            return "Morgen, \(timeString)"
        } else {
            let dayFormatter = DateFormatter()
            dayFormatter.locale = Locale(identifier: "de_DE")
            dayFormatter.dateFormat = "EE"
            return "\(dayFormatter.string(from: targetDate)), \(timeString)"
        }
    }

    var body: some View {
        ZStack {
            AdaptiveBackgroundGradient()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 20)

                // Dashboard Content - Classic Style
                HStack(spacing: 72) {
                    VerticalTrendBar(
                        title: "pH",
                        value: poolWaterState.estimatedPH,
                        minValue: 6.8,
                        maxValue: 8.0,
                        idealMin: poolWaterState.idealPHMin,
                        idealMax: poolWaterState.idealPHMax,
                        barColor: .phBarColor,
                        idealRangeColor: .phIdealColor,
                        trend: poolWaterState.phTrend,
                        scalePosition: .leading,
                        prediction: poolWaterState.phPrediction,
                        compact: anySheetPresented
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)

                    VerticalTrendBar(
                        title: "Cl",
                        value: poolWaterState.estimatedChlorine,
                        minValue: 0,
                        maxValue: 5,
                        idealMin: poolWaterState.idealChlorineMin,
                        idealMax: poolWaterState.idealChlorineMax,
                        barColor: .chlorineBarColor,
                        idealRangeColor: .chlorineIdealColor,
                        trend: poolWaterState.chlorineTrend,
                        scalePosition: .trailing,
                        prediction: poolWaterState.chlorinePrediction,
                        compact: anySheetPresented
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scaleEffect(barScale, anchor: .top)
                .offset(y: anySheetPresented ? -80 : (showDosingPill ? -44 : -40))
                .animation(.smooth, value: anySheetPresented)
                .animation(.smooth, value: quickMeasurePhase)
                .animation(.smooth(duration: 0.35), value: showDosingPill)

                // Dosing status pill
                if poolWaterState.recentDosingActive {
                    Button { showQuickMeasure = true } label: {
                        InfoPill(
                            icon: "checkmark.circle.fill",
                            text: recentDosingLabel,
                            foregroundColor: .black
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.blurReplace.combined(with: .scale(0.8)).combined(with: .opacity))
                    .opacity(anySheetPresented ? 0 : 1)
                    .animation(.smooth, value: anySheetPresented)
                    .padding(.top, 8)
                    .offset(y: -24)
                } else if poolWaterState.dosingNeeded {
                    Button { showQuickMeasure = true } label: {
                        InfoPill(
                            icon: "exclamationmark.triangle.fill",
                            text: "Dosierung",
                            tint: Color(light: .red.opacity(0.9), dark: .red.opacity(0.5))
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.blurReplace.combined(with: .scale(0.8)).combined(with: .opacity))
                    .opacity(anySheetPresented ? 0 : 1)
                    .animation(.smooth, value: anySheetPresented)
                    .padding(.top, 8)
                    .offset(y: -24)
                }

                // Time simulation picker
                VStack(spacing: 4) {
                    Text(simulationTimeLabel)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(light: Color.black, dark: Color.white.opacity(0.6)))
                        .contentTransition(.numericText())
                        .animation(.snappy, value: timeOffsetSelection)

                    TickPicker(
                        count: 48,
                        config: TickConfig(
                            tickWidth: 1.5,
                            tickHeight: 16,
                            tickHPadding: 3,
                            activeTint: Color(light: Color.black, dark: Color.white.opacity(0.8)),
                            inActiveTint: Color(light: Color.black.opacity(0.3), dark: Color.white.opacity(0.2)),
                            alignment: .center
                        ),
                        selection: $timeOffsetSelection
                    )
                    .frame(height: 16)
                }
                .padding(.horizontal, 40)
                .padding(.top, showDosingPill ? 16 : 24)
                .opacity(anySheetPresented ? 0 : 1)
                .animation(.smooth, value: anySheetPresented)
                .animation(.smooth(duration: 0.35), value: showDosingPill)
                .onChange(of: timeOffsetSelection) { _, newValue in
                    poolWaterState.simulationOffsetHours = Double(newValue)
                    poolWaterState.recalculate()
                }

                Spacer(minLength: 30)
            }
            .animation(.smooth(duration: 0.35), value: showDosingPill)
        }
        .sheet(isPresented: $showQuickMeasure, onDismiss: { quickMeasurePhase = 0 }) {
            QuickMeasureSheet(externalPhase: $quickMeasurePhase)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openQuickMeasure)) { _ in
            showQuickMeasure = true
        }
        .onAppear {
            poolWaterState.setModelContext(modelContext)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                poolWaterState.reloadSettings()
            }
        }
    }
}

// MARK: - Adaptive Background Gradient

struct AdaptiveBackgroundGradient: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if colorScheme == .dark {
            // Dark Mode: Dark teal to black gradient
            LinearGradient(
                colors: [Color(hex: "1a3a4a"), .black],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            // Light Mode: Soft blue gradient
            LinearGradient(
                colors: [Color(hex: "b8e2f4"), Color(hex: "fefefe")],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Blur Fade Extension

extension View {
    @ViewBuilder
    func blurFade(_ isActive: Bool) -> some View {
        self
            .blur(radius: isActive ? 0 : 10)
            .opacity(isActive ? 1 : 0)
            .animation(.smooth(duration: 0.35), value: isActive)
    }
}

// MARK: - Dashboard Tutorial Overlay

struct DashboardTutorialOverlay: View {
    var onDismiss: () -> Void
    @State private var currentStep = 0
    private let totalSteps = 4

    private var stepIcon: String {
        switch currentStep {
        case 0: "chart.bar.fill"
        case 1: "hand.tap.fill"
        case 2: "slider.horizontal.3"
        default: "checkmark.circle.fill"
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: "Die Balken"
        case 1: "Werte antippen"
        case 2: "Zeitleiste"
        default: "Alles bereit!"
        }
    }

    private var stepDescription: String {
        switch currentStep {
        case 0: "Die Balken zeigen pH und Chlor. Der farbige Bereich markiert den Idealbereich."
        case 1: "Tippe auf den aktuellen Wert für Details und Dosierempfehlungen."
        case 2: "Schiebe die Zeitleiste, um die Wasserwerte in der Zukunft zu simulieren."
        default: "Dein Dashboard ist bereit. Viel Spaß mit Lagoon!"
        }
    }

    private var isLastStep: Bool {
        currentStep == totalSteps - 1
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    if isLastStep {
                        onDismiss()
                    } else {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentStep += 1
                        }
                    }
                }

            VStack(spacing: 20) {
                Image(systemName: stepIcon)
                    .font(.system(size: 48))
                    .foregroundStyle(isLastStep ? .green : .white.opacity(0.9))
                    .contentTransition(.symbolEffect(.replace))

                Text(stepTitle)
                    .font(.system(size: 26, weight: .bold))

                Text(stepDescription)
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 50)

                if isLastStep {
                    Button {
                        onDismiss()
                    } label: {
                        Text("Los geht's")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white.opacity(0.2))
                    .padding(.top, 8)
                } else {
                    // Step indicator dots
                    HStack(spacing: 8) {
                        ForEach(0..<totalSteps - 1, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? .white : .white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, 8)

                    Text("Tippe, um fortzufahren")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .padding(30)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 40)
            .foregroundStyle(.white)
        }
        .transition(.opacity)
    }
}

#Preview {
    MainTabView()
        .environment(PoolWaterState())
}
