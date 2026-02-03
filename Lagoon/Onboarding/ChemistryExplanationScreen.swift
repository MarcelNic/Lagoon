import SwiftUI

struct ChemistryExplanationScreen: View {
    var action: () -> Void

    private let explanations = [
        OnboardingFeature(
            icon: "drop.fill",
            title: "pH-Wert",
            subtitle: "Bestimmt, wie sauer oder basisch dein Wasser ist. Zu hoch? Haut und Augen brennen. Zu niedrig? Chlor wirkt nicht.",
            color: .purple
        ),
        OnboardingFeature(
            icon: "bubbles.and.sparkles.fill",
            title: "Chlor",
            subtitle: "Tötet Bakterien und Algen. Zu wenig? Grünes Wasser. Zu viel? Chlorgeruch und Hautreizung.",
            color: .cyan
        ),
        OnboardingFeature(
            icon: "waveform.path.ecg",
            title: "Die App hilft",
            subtitle: "Lagoon berechnet die perfekte Dosierung basierend auf deinen Messwerten, Wetter und Poolnutzung.",
            color: .blue
        )
    ]

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 8) {
                Text("Warum Balance alles ist.")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.2)
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 28) {
                ForEach(explanations.indices, id: \.self) { index in
                    FeatureView(feature: explanations[index])
                        .microAnimation(delay: 0.4 + Double(index) * 0.25)
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            PrimaryButton(title: "Verstanden", action: action)
                .padding(.horizontal, 30)
                .microAnimation(delay: 1.2)

            Spacer()
        }
    }
}

#Preview {
    ChemistryExplanationScreen(action: {})
}
