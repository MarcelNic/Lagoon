import SwiftUI

struct FirstScreen: View {
    let features = [
        OnboardingFeature(icon: "drop.fill", title: "Wasserchemie verstehen", subtitle: "pH und Chlor immer im Blick behalten", color: .blue),
        OnboardingFeature(icon: "aqi.medium", title: "Perfekte Dosierung", subtitle: "Nie mehr raten, wie viel Chemie nötig ist", color: .cyan),
        OnboardingFeature(icon: "checklist", title: "Pflege im Griff", subtitle: "Alle Aufgaben an einem Ort verwalten", color: .green),
        OnboardingFeature(icon: "cloud.sun.fill", title: "Wetter einbeziehen", subtitle: "Vorhersagen basierend auf Sonnenstunden & Regen", color: .orange),
    ]
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "water.waves")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
                    .microAnimation(delay: 0.2)

                Text("Dein Pool-Profi für die Hosentasche.")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.4)

                Text("Kristallklares Wasser, weniger Chemie, mehr Zeit zum Genießen.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .microAnimation(delay: 0.6)
            }
            .padding(.horizontal, 30)

            Spacer()

            VStack(spacing: 24) {
                ForEach(features.indices, id: \.self) { index in
                    FeatureView(feature: features[index])
                        .microAnimation(delay: 0.8 + Double(index) * 0.2)
                }
            }
            .padding(.horizontal, 30)

            Spacer()

            PrimaryButton(title: "Loslegen", action: { action() })
                .padding(.horizontal, 30)
                .microAnimation(delay: 1.8)

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
