//
//  PoolIdentityCard.swift
//  Lagoon
//

import SwiftUI

struct PoolIdentityCard: View {
    let poolName: String
    let isVacationModeActive: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.pool.swim")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Color(light: Color.black, dark: Color.white))

            Text(poolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Color(light: Color.black, dark: Color.white))

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 24))
    }

    private var statusText: String {
        let vacationStatus = isVacationModeActive ? "aktiv" : "inaktiv"
        return "Sommerbetrieb · Urlaubsmodus \(vacationStatus)"
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

        PoolIdentityCard(poolName: "Mein Pool", isVacationModeActive: false)
            .padding(.horizontal, 20)
    }
}
