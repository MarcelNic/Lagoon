import SwiftUI

struct FirstScreen: View {
    var action: () -> Void

    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()

            // Glowing waves
            GlowingWavesView()
                .frame(height: 250)
                .offset(y: -80)
                .microAnimation(delay: 0.2)

            VStack {
                Spacer()

                // Text at bottom
                VStack(spacing: 16) {
                    Text("Willkommen bei Lagoon")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .microAnimation(delay: 0.4)

                    Text("Kristallklares Wasser, weniger Chemie und perfekte Dosierung.")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .microAnimation(delay: 0.6)
                }
                .padding(.horizontal, 30)

                Spacer()
                    .frame(height: 30)

                // Button at very bottom
                PrimaryButton(title: "Hallo", action: { action() })
                    .padding(.horizontal, 30)
                    .microAnimation(delay: 0.8)

                Spacer()
                    .frame(height: 50)
            }
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
