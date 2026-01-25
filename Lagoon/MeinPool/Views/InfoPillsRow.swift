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
    @Environment(\.colorScheme) private var colorScheme

    let icon: String
    let text: String
    var tint: Color? = nil

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(Color.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .glassEffect(
            glassStyle,
            in: .capsule
        )
    }

    private var glassStyle: Glass {
        if let tint = tint {
            return .clear.tint(tint).interactive()
        } else {
            return .clear.interactive()
        }
    }
}

#Preview {
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

        InfoPillsRow(state: MeinPoolState())
            .padding(.horizontal, 20)
    }
}
