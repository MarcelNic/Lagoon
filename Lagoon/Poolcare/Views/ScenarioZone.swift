//
//  ScenarioZone.swift
//  Lagoon
//

import SwiftUI

struct ScenarioZone: View {
    @Bindable var state: PoolcareState
    @Binding var showVacationSheet: Bool
    @Binding var showSeasonSheet: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("Szenarien")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            GlassEffectContainer(spacing: 12) {
                HStack(spacing: 12) {
                    ScenarioButton(
                        icon: "airplane",
                        title: "Urlaub",
                        status: state.vacationScenario.isActive ? "Aktiv" : "Inaktiv",
                        isActive: state.vacationScenario.isActive
                    ) {
                        showVacationSheet = true
                    }

                    ScenarioButton(
                        icon: "snowflake",
                        title: "Saison",
                        status: state.seasonScenario.currentMode == .summer ? "Sommer" : "Winter",
                        isActive: false
                    ) {
                        showSeasonSheet = true
                    }
                }
            }
        }
    }
}

struct ScenarioButton: View {
    let icon: String
    let title: String
    let status: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.white)

                    Text(status)
                        .font(.system(size: 12))
                        .foregroundStyle(isActive ? .green : .white.opacity(0.5))
                }

                Spacer()

                if isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .capsule)
    }
}
