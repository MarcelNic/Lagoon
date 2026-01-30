//
//  OperatingModeSelector.swift
//  Lagoon
//

import SwiftUI

struct OperatingModeSelector: View {
    @Bindable var state: PoolcareState

    var body: some View {
        Picker("Modus", selection: Binding(
            get: { state.currentMode },
            set: { newMode in
                withAnimation(.smooth(duration: 0.3)) {
                    state.switchMode(to: newMode)
                }
            }
        )) {
            ForEach(OperatingMode.allCases, id: \.self) { mode in
                Label(mode.rawValue, systemImage: mode.icon)
                    .tag(mode)
            }
        }
        .pickerStyle(.segmented)
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
