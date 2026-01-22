//
//  InfoPillsRow.swift
//  Lagoon
//

import SwiftUI

struct InfoPillsRow: View {
    @Bindable var state: MeinPoolState

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                InfoPill(icon: "location.fill", text: state.location)
                InfoPill(icon: "thermometer.medium", text: state.waterTemperature)
                InfoPill(icon: "cloud.fill", text: state.weather)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.white.opacity(0.8))
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(.clear.interactive(), in: .capsule)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a1628"), Color(hex: "1a3a5c")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        InfoPillsRow(state: MeinPoolState())
            .padding(.horizontal, 20)
    }
}
