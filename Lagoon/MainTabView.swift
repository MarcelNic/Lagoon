//
//  MainTabView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 29.01.26.
//

import SwiftUI

struct MainTabView: View {
    @State private var activeTab: LagoonTab = .home
    @State private var showMeasurementDosing = false
    @State private var showSettings = false
    @State private var showAddTaskSheet = false
    @State private var poolcareState = PoolcareState()
    @AppStorage("hasSeenDashboardOverlay") private var hasSeenDashboardOverlay = false
    @Environment(\.modelContext) private var modelContext
    @Environment(NotificationManager.self) private var notificationManager

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                DashboardTabView(showMeasurementDosing: $showMeasurementDosing)
                    .lagoonTabBarSafeAreaPadding()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .care) {
                PoolcareView(state: poolcareState, showAddSheet: $showAddTaskSheet)
                    .lagoonTabBarSafeAreaPadding()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .pool) {
                NavigationStack {
                    MeinPoolView(showSettings: $showSettings)
                }
                .lagoonTabBarSafeAreaPadding()
                .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .lagoonTabBar(
            selection: $activeTab,
            tabs: [
                LagoonTabBarTab(value: .home, title: "Wasser", systemImage: "water.waves", symbolEffect: .wiggle),
                LagoonTabBarTab(value: .care, title: "Care", systemImage: "checklist", symbolEffect: .bounce),
                LagoonTabBarTab(value: .pool, title: "Logbuch", systemImage: "chart.line.text.clipboard", symbolEffect: .wiggle),
            ],
            action: LagoonTabBarAction(systemImage: activeTab == .pool ? "gear" : "plus", accessibilityLabel: "Aktion") {
                switch activeTab {
                case .home: showMeasurementDosing = true
                case .care: showAddTaskSheet = true
                case .pool: showSettings = true
                }
            }
        )
        .onAppear {
            poolcareState.configure(modelContext: modelContext, notificationManager: notificationManager)
        }
        .onChange(of: hasSeenDashboardOverlay) { old, seen in
            if old && !seen {
                showSettings = false
                activeTab = .home
            }
        }
    }
}

// MARK: - Dashboard Tab View (ohne eigene Bottom Bar)

struct DashboardTabView: View {
    @Environment(PoolWaterState.self) private var poolWaterState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0
    @AppStorage("barStyle") private var barStyle: String = "classic"

    @AppStorage("hasSeenDashboardOverlay") private var hasSeenDashboardOverlay = false

    @Binding var showMeasurementDosing: Bool
    @State private var measurementDosingPhase: Int = 0
    @State private var timeOffsetSelection: Int = 0
    @State private var showSwipeHint = false
    @State private var demoEndTimer: Timer?
    @State private var demoTimerFired = false
    @State private var demoReleaseWork: DispatchWorkItem?
    @State private var barsShifted = false
    @State private var currentBarPhase: Int = 0
    @State private var showDosingChangeAlert = false
    @State private var showFutureDosingAlert = false
    @State private var sheetInitialPhase: MeasurementDosingSheet.Phase = .messen

    private var anySheetPresented: Bool {
        showMeasurementDosing
    }

    private var showDosingPill: Bool {
        guard !poolWaterState.isDemoMode else { return false }
        return poolWaterState.recentDosingActive || poolWaterState.dosingNeeded
    }

    private var demoDisplayText: String? {
        guard poolWaterState.isDemoMode, !poolWaterState.demoActive else { return nil }
        return "--"
    }

    private var barScale: CGFloat {
        guard barsShifted else { return 1.0 }
        switch currentBarPhase {
        case 1: return 0.85   // dosieren
        case 2: return 0.65   // bearbeiten
        default: return 0.80  // messen
        }
    }

    private var barSheetOffset: CGFloat {
        switch currentBarPhase {
        case 1: return -110   // empfehlung
        case 2: return -100   // anpassen
        default: return -120  // messen
        }
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
        return parts.isEmpty ? "Dosiert" : parts.joined(separator: " · ")
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

                // Dashboard Content
                HStack(spacing: 72) {
                    if barStyle == "v2" {
                        VerticalTrendBarV2(
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
                            prediction: poolWaterState.isDemoMode ? nil : poolWaterState.phPrediction,
                            markerBorderColor: .phMarkerBorderColor,
                            displayOverrideText: demoDisplayText,
                            compact: barsShifted
                        )
                        .frame(maxWidth: .infinity, alignment: .trailing)

                        VerticalTrendBarV2(
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
                            prediction: poolWaterState.isDemoMode ? nil : poolWaterState.chlorinePrediction,
                            scalePoints: [0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0],
                            markerBorderColor: .chlorineMarkerBorderColor,
                            displayOverrideText: demoDisplayText,
                            compact: barsShifted
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
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
                            prediction: poolWaterState.isDemoMode ? nil : poolWaterState.phPrediction,
                            displayOverrideText: demoDisplayText,
                            compact: barsShifted
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
                            prediction: poolWaterState.isDemoMode ? nil : poolWaterState.chlorinePrediction,
                            scalePoints: [0, 0.5, 1.0, 1.5, 2.0, 3.0, 5.0],
                            displayOverrideText: demoDisplayText,
                            compact: barsShifted
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .scaleEffect(barScale, anchor: .top)
                .offset(y: barsShifted ? barSheetOffset : (showDosingPill ? -44 : -40))
                .animation(.smooth(duration: 0.35), value: showDosingPill)

                // Dosing status pill
                if poolWaterState.recentDosingActive {
                    Button { showDosingChangeAlert = true } label: {
                        InfoPill(
                            icon: "checkmark.circle.fill",
                            text: recentDosingLabel
                        )
                    }
                    .buttonStyle(.plain)
                    .transition(.blurReplace.combined(with: .scale(0.8)).combined(with: .opacity))
                    .opacity(anySheetPresented ? 0 : 1)
                    .animation(.smooth, value: anySheetPresented)
                    .padding(.top, 8)
                    .offset(y: -24)
                } else if poolWaterState.dosingNeeded {
                    Button {
                        if timeOffsetSelection > 0 {
                            showFutureDosingAlert = true
                        } else {
                            showMeasurementDosing = true
                        }
                    } label: {
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
                    .mask(
                        HStack(spacing: 0) {
                            LinearGradient(colors: [.clear, .black], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 40)
                            Color.black
                            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                                .frame(width: 40)
                        }
                    )
                }
                .padding(.horizontal, 40)
                .padding(.top, showDosingPill ? 16 : 24)
                .opacity(anySheetPresented ? 0 : 1)
                .animation(.smooth, value: anySheetPresented)
                .animation(.smooth(duration: 0.35), value: showDosingPill)
                .overlay {
                    if showSwipeHint {
                        SwipeHintView()
                            .allowsHitTesting(false)
                            .transition(.opacity)
                    }
                }
                .onChange(of: timeOffsetSelection) { _, newValue in
                    poolWaterState.simulationOffsetHours = Double(newValue)
                    poolWaterState.recalculate()

                    // Swipe hint: disappear after 15 ticks, start 5s demo-end timer
                    if !hasSeenDashboardOverlay && abs(newValue) >= 15 {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showSwipeHint = false
                        }
                        hasSeenDashboardOverlay = true
                        startDemoEndTimer()
                    }

                    // After 5s timer: detect release via debounce → end demo
                    if demoTimerFired && poolWaterState.isDemoMode && poolWaterState.demoActive {
                        demoReleaseWork?.cancel()
                        let work = DispatchWorkItem {
                            withAnimation(.smooth(duration: 0.8)) {
                                poolWaterState.demoActive = false
                                poolWaterState.recalculate()
                            }
                        }
                        demoReleaseWork = work
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
                    }
                }

                Spacer(minLength: 30)
            }
            .animation(.smooth(duration: 0.35), value: showDosingPill)
        }
        .onChange(of: showMeasurementDosing) { _, newValue in
            withAnimation(.smooth) {
                barsShifted = newValue
                if !newValue { currentBarPhase = 0 }
            }
        }
        .onChange(of: measurementDosingPhase) { _, newValue in
            withAnimation(.smooth) {
                currentBarPhase = newValue
            }
        }
        .sheet(isPresented: $showMeasurementDosing, onDismiss: {
            measurementDosingPhase = 0
            sheetInitialPhase = .messen
        }) {
            MeasurementDosingSheet(externalPhase: $measurementDosingPhase, initialPhase: sheetInitialPhase)
        }
        .alert("Jetzt dosieren?", isPresented: $showFutureDosingAlert) {
            Button("Trotzdem dosieren") { showMeasurementDosing = true }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Die Dosierung wird erst um \(simulationTimeLabel) nötig. Möchtest du trotzdem jetzt dosieren?")
        }
        .alert("Dosierung ändern?", isPresented: $showDosingChangeAlert) {
            Button("Ändern") {
                sheetInitialPhase = .bearbeiten
                measurementDosingPhase = 2
                showMeasurementDosing = true
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("Möchtest du die letzte Dosierung anpassen?")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openMeasurementDosing)) { _ in
            showMeasurementDosing = true
        }
        .onAppear {
            poolWaterState.setModelContext(modelContext)
            poolWaterState.reloadSettings()
            if poolWaterState.isDemoMode {
                if !hasSeenDashboardOverlay {
                    // Fresh after onboarding: activate demo + show swipe hint
                    poolWaterState.demoActive = true
                    demoTimerFired = false
                    demoEndTimer?.invalidate()
                    demoReleaseWork?.cancel()
                    poolWaterState.recalculate()
                    withAnimation(.easeOut(duration: 0.4).delay(0.6)) {
                        showSwipeHint = true
                    }
                }
                // Hint already seen (e.g. app restart) → stay at "--"
            }
        }
        .onDisappear {
            demoEndTimer?.invalidate()
            demoReleaseWork?.cancel()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                poolWaterState.reloadSettings()
            }
        }
        .alert("Speicherfehler", isPresented: Binding(
            get: { poolWaterState.lastSaveError != nil },
            set: { if !$0 { poolWaterState.lastSaveError = nil } }
        )) {
            Button("OK") { poolWaterState.lastSaveError = nil }
        } message: {
            Text(poolWaterState.lastSaveError ?? "")
        }
    }

    private func startDemoEndTimer() {
        demoEndTimer?.invalidate()
        demoEndTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { _ in
            Task { @MainActor in
                demoTimerFired = true
                // If not swiping, end demo after 1s
                demoReleaseWork?.cancel()
                let work = DispatchWorkItem {
                    withAnimation(.smooth(duration: 0.8)) {
                        poolWaterState.demoActive = false
                        poolWaterState.recalculate()
                    }
                }
                demoReleaseWork = work
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: work)
            }
        }
    }
}

// MARK: - Swipe Hint

private struct SwipeHintView: View {
    // Phases: idle → swipe → reset (loops via PhaseAnimator, no recursion)
    enum Phase: CaseIterable {
        case idle, swipe, pause
    }

    var body: some View {
        PhaseAnimator(Phase.allCases) { phase in
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .offset(x: phase == .swipe ? -60 : 0)
        } animation: { phase in
            switch phase {
            case .idle: .easeOut(duration: 0.25)
            case .swipe: .easeInOut(duration: 2.0)
            case .pause: .easeOut(duration: 0.8)
            }
        }
        .offset(x: 12, y: 52)
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

#Preview {
    MainTabView()
        .environment(PoolWaterState())
}
