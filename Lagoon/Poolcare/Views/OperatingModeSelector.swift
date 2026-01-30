//
//  OperatingModeSelector.swift
//  Lagoon
//

import SwiftUI

struct OperatingModeSelector: View {
    @Bindable var state: PoolcareState
    @Namespace private var modeNamespace

    var body: some View {
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
