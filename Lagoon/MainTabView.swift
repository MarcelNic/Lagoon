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
    @State private var showAddTaskSheet = false
    @State private var showSettings = false
    @State private var poolcareState = PoolcareState()
    @Namespace private var tabBarNamespace

    var body: some View {
        TabView(selection: $activeTab) {
            Tab(value: .home) {
                DashboardTabView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }

            Tab(value: .care) {
                PoolcareTabView(state: poolcareState)
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Color(light: .black, dark: .white))
                }
                .frame(width: 52, height: 52)
                .glassEffect(.regular.interactive(), in: .circle)

                // Action Button 2 (nur bei Home sichtbar)
                if activeTab == .home {
                    Button {
                        showDosierenSheet = true
                    } label: {
                        Image(systemName: "circle.grid.cross")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                    }
                    .frame(width: 52, height: 52)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .transition(.blurReplace)
                }
            }
            .animation(.smooth(duration: 0.4), value: activeTab)
        }
        .frame(height: 55)
    }
}

// MARK: - Dashboard Tab View (ohne eigene Bottom Bar)

struct DashboardTabView: View {
    @Environment(PoolWaterState.self) private var poolWaterState
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("dosingUnit") private var dosingUnit: String = "gramm"
    @AppStorage("cupGrams") private var cupGrams: Double = 50.0

    @State private var showQuickMeasure = false
    @State private var quickMeasurePhase: Int = 0
    @State private var timeOffsetSelection: Int = 0

    private var showDosingPill: Bool {
        poolWaterState.recentDosingActive || poolWaterState.dosingNeeded
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

            VStack {
                Spacer()

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
                        compact: showQuickMeasure
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
                        compact: showQuickMeasure
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .offset(y: showDosingPill ? -12 : 0)
                .animation(.smooth(duration: 0.35), value: showDosingPill)
                .padding(.bottom, 20)

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
                .padding(.top, 20)
                .offset(y: showDosingPill ? 8 : 0)
                .animation(.smooth(duration: 0.35), value: showDosingPill)
                .onChange(of: timeOffsetSelection) { _, newValue in
                    poolWaterState.simulationOffsetHours = Double(newValue)
                    poolWaterState.recalculate()
                }

                Spacer()
            }
            .animation(.smooth(duration: 0.35), value: showDosingPill)
            .overlay(alignment: .topTrailing) {
                Button {
                    NotificationCenter.default.post(name: .openQuickMeasure, object: nil)
                } label: {
                    Image(systemName: "bell.badge")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.orange.opacity(0.7))
                }
                .padding(.trailing, 20)
                .padding(.top, 8)
            }
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

// MARK: - Poolcare Tab View

struct PoolcareTabView: View {
    @Bindable var state: PoolcareState
    @State private var showVacationSheet = false
    @State private var showSeasonSheet = false

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                stops: [
                    .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                    .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                    .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .scaleEffect(1.2)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    // Title
                    Text("Poolcare")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color(light: .black, dark: .white))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ActiveActionsZone(state: state)

                    TaskListZone(state: state)

                    ScenarioZone(
                        state: state,
                        showVacationSheet: $showVacationSheet,
                        showSeasonSheet: $showSeasonSheet
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showVacationSheet) {
            ScenarioDetailSheet(type: .vacation, state: state)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSeasonSheet) {
            ScenarioDetailSheet(type: .season, state: state)
                .presentationDetents([.medium, .large])
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

#Preview {
    MainTabView()
        .environment(PoolWaterState())
}
