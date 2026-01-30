//
//  OperatingModeSelector.swift
//  Lagoon
//

import SwiftUI

struct OperatingModeSelector: View {
    @Bindable var state: PoolcareState
    @Namespace private var modeNamespace

    var body: some View {
        VStack(spacing: 12) {
            // Mode Selector
            GlassEffectContainer(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(OperatingMode.allCases, id: \.self) { mode in
                        ModeButton(
                            mode: mode,
                            isSelected: state.currentMode == mode,
                            namespace: modeNamespace
                        ) {
                            withAnimation(.smooth(duration: 0.3)) {
                                state.switchMode(to: mode)
                            }
                        }
                    }
                }
                .padding(4)
                .glassEffect(.clear.interactive(), in: .capsule)
            }

            // Vacation Phase Banner (nur im Urlaubsmodus)
            if state.currentMode == .vacation {
                VacationPhaseBanner(state: state)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 0.9).combined(with: .opacity)
                    ))
            }
        }
    }
}

// MARK: - Mode Button

private struct ModeButton: View {
    let mode: OperatingMode
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(mode.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundStyle(isSelected
                ? Color(light: .black, dark: .white)
                : Color(light: .black, dark: .white).opacity(0.5)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background {
                if isSelected {
                    Capsule()
                        .fill(Color(light: .white.opacity(0.5), dark: .white.opacity(0.15)))
                        .matchedGeometryEffect(id: "modeBackground", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vacation Phase Banner

private struct VacationPhaseBanner: View {
    @Bindable var state: PoolcareState

    private var phaseText: String {
        switch state.vacationPhase {
        case .before: return "Vor Abreise"
        case .during: return "Abwesend"
        case .after: return "Nach Rückkehr"
        case nil: return ""
        }
    }

    private var actionButtonText: String? {
        switch state.vacationPhase {
        case .before: return "Abreisen"
        case .during: return "Zurückgekehrt"
        case .after: return "Fertig"
        case nil: return nil
        }
    }

    var body: some View {
        GlassEffectContainer(spacing: 0) {
            HStack {
                // Phase indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 8, height: 8)

                    Text(phaseText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(light: .black, dark: .white))
                }

                Spacer()

                // Action button
                if let buttonText = actionButtonText {
                    Button {
                        withAnimation(.smooth(duration: 0.3)) {
                            state.advanceVacationPhase()
                        }
                    } label: {
                        Text(buttonText)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color(light: .black, dark: .white))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .glassEffect(.clear.interactive(), in: .capsule)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 16))
        }
    }

    private var phaseColor: Color {
        switch state.vacationPhase {
        case .before: return .orange
        case .during: return .blue
        case .after: return .green
        case nil: return .gray
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "0443a6"), location: 0.0),
                .init(color: Color(hex: "b2e1ec"), location: 0.5),
                .init(color: Color(hex: "2fb4a0"), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        VStack {
            OperatingModeSelector(state: PoolcareState())
                .padding()
            Spacer()
        }
    }
}
