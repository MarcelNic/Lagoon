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
                .padding(.bottom, 40)

                // Button at very bottom
                Button(action: action) {
                    Text("Hallo")
                        .bold()
                        .foregroundStyle(.black)
                        .frame(height: 60)
                        .frame(maxWidth: .infinity)
                }
                .glassEffect(.regular.tint(.white).interactive(), in: .capsule)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
                .microAnimation(delay: 0.8)
            }
        }
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var isFooter: Bool = true
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .bold()
                .foregroundStyle(colorScheme == .dark ? .black : .white)
                .frame(height: 60)
                .frame(maxWidth: .infinity)
        }
        .glassEffect(.regular.tint(colorScheme == .dark ? .white : .black).interactive(), in: .capsule)
        .padding(.horizontal, 40)
        .padding(.bottom, isFooter ? 20 : 0)
    }
}

#Preview {
    FirstScreen(action: {})
}
