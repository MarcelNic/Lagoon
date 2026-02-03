import SwiftUI

struct FirstScreen: View {
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                Image(systemName: "water.waves")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .microAnimation(delay: 0.2)

                Text("Willkommen bei Lagoon")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.4)

                Text("Kristallklares Wasser, weniger Chemie und perfekte Dosierung.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.6)
            }
            .padding(.horizontal, 30)

            Spacer()
            Spacer()

            PrimaryButton(title: "Hallo", action: { action() })
                .padding(.horizontal, 30)
                .microAnimation(delay: 0.8)

            Spacer()
        }
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .bold()
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(.DL, in: Capsule())
                .tint(.LD)
        }
    }
}

#Preview {
    FirstScreen(action: {})
}
