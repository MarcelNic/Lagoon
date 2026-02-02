import SwiftUI

struct OnboardingFeature: Identifiable {
    var id = UUID()
    var icon: String
    var title: String
    var subtitle: String
    var color: Color
}

struct FeatureView: View {
    var feature: OnboardingFeature
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .frame(width: 45, height: 45)
                    .foregroundStyle(feature.color.opacity(0.1))
                Image(systemName: feature.icon).resizable().scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(feature.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 18).bold())
                Text(feature.subtitle)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
            Spacer()
        }
    }
}

#Preview {
    FeatureView(feature: OnboardingFeature(icon: "bell.fill", title: "Tareas ilimitadas", subtitle: "Establece recordatorios y alertas", color: .blue))
}
