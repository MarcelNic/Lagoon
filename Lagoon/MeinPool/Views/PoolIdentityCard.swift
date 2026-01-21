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
                .foregroundStyle(.white)

            Text(poolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)

            Text(statusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
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
            colors: [Color(hex: "0a1628"), Color(hex: "1a3a5c")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        PoolIdentityCard(poolName: "Mein Pool", isVacationModeActive: false)
            .padding(.horizontal, 20)
    }
}
