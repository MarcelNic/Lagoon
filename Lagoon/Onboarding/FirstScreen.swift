import SwiftUI

struct FirstScreen: View {
    let features = [
        OnboardingFeature(icon: "magnifyingglass", title: "Find new activities", subtitle: "Discover fresh ideas that spark your interest", color: .blue),
        OnboardingFeature(icon: "figure.mind.and.body", title: "Stay calm and mindful", subtitle: "Find new activities that spark your interest", color: .green),
        OnboardingFeature(icon: "lightbulb.fill", title: "Boost your creativity", subtitle: "Stay calm and mindful while exploring habits", color: .orange),
        OnboardingFeature(icon: "trophy.fill", title: "Build lasting routines", subtitle: "Boost your creativity with daily inspiration", color: .purple),
    ]
    var action: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Spacer()
            Image(systemName: "water.waves")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
                .microAnimation(delay: 0.2)
            Spacer()
            VStack(spacing: 36) {
                ForEach(features.indices, id: \.self) { index in
                    FeatureView(feature: features[index])
                        .microAnimation(delay: 0.4 + Double(index) * 0.3)
                }
            }
            Spacer()
            PrimaryButton(title: "Continue", action: { action() })
                .microAnimation(delay: 1.5)
            Spacer()
        }.padding(.horizontal, 30)
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
