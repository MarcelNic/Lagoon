import SwiftUI

/// Final onboarding screen that shows a transparent overlay while the Dashboard is visible behind.
struct DashboardOverlayScreen: View {
    var onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Dein Dashboard")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 16) {
                    DashboardHintRow(
                        icon: "chart.line.uptrend.xyaxis",
                        text: "Oben: Aktuelle Wasserwerte und Trends"
                    )

                    DashboardHintRow(
                        icon: "bolt.fill",
                        text: "Mitte: Schnelle Aktionen für Messen und Dosieren"
                    )

                    DashboardHintRow(
                        icon: "rectangle.3.offgrid",
                        text: "Unten: Navigation zu Home, Aufgaben und Logbuch"
                    )
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))

                PrimaryButton(title: "Los geht's", action: onComplete)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 28)
            .foregroundStyle(.white)
        }
    }
}

struct DashboardHintRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .frame(width: 28)
                .foregroundStyle(.white.opacity(0.9))
            Text(text)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

#Preview {
    DashboardOverlayScreen(onComplete: {})
        .background(
            LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
}
