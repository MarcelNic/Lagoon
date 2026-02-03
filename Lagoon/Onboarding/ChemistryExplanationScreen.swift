import SwiftUI

struct ChemistryExplanationScreen: View {
    var action: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Text("Warum Balance wichtig ist.")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
                .microAnimation(delay: 0.2)
                .padding(.horizontal, 30)

            Spacer()

            // Visual: Balance/Seesaw
            BalanceVisualView()
                .frame(height: 120)
                .padding(.horizontal, 30)
                .microAnimation(delay: 0.4)

            Spacer()

            // Explanation Text
            VStack(alignment: .leading, spacing: 20) {
                ExplanationRow(
                    icon: "drop.fill",
                    iconColor: .purple,
                    title: "Der pH-Wert: Das Fundament.",
                    text: "Steigt er über 7.8, verliert dein Chlor 60% seiner Wirkung."
                )

                ExplanationRow(
                    icon: "bubbles.and.sparkles.fill",
                    iconColor: .cyan,
                    title: "Das Chlor: Der Wächter.",
                    text: "Schützt vor Bakterien – aber nur, wenn der pH-Wert stimmt."
                )

                ExplanationRow(
                    icon: "waveform.path.ecg",
                    iconColor: .blue,
                    title: "Die App:",
                    text: "Analysiert deine Werte und berechnet exakt die nötige Dosierung."
                )
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.6)

            Spacer()

            PrimaryButton(title: "Verstanden", action: action)
                .padding(.horizontal, 30)
                .microAnimation(delay: 1.0)

            Spacer()
        }
    }
}

// MARK: - Balance Visual

struct BalanceVisualView: View {
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height

            ZStack {
                // Fulcrum (triangle base)
                Path { path in
                    let triangleHeight: CGFloat = 20
                    let triangleWidth: CGFloat = 30
                    let centerX = width / 2
                    let bottomY = height - 10

                    path.move(to: CGPoint(x: centerX, y: bottomY - triangleHeight))
                    path.addLine(to: CGPoint(x: centerX - triangleWidth / 2, y: bottomY))
                    path.addLine(to: CGPoint(x: centerX + triangleWidth / 2, y: bottomY))
                    path.closeSubpath()
                }
                .fill(.secondary.opacity(0.3))

                // Seesaw beam
                let beamY = height - 35
                let tilt: Double = animate ? 0 : 3

                ZStack {
                    // Beam
                    Capsule()
                        .fill(.secondary.opacity(0.2))
                        .frame(width: width * 0.85, height: 8)

                    // pH side (left)
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.purple.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Text("pH")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.purple)
                        }
                    }
                    .offset(x: -width * 0.3)

                    // Chlor side (right)
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(.cyan.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Text("Cl")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.cyan)
                        }
                    }
                    .offset(x: width * 0.3)
                }
                .rotationEffect(.degrees(tilt), anchor: .center)
                .position(x: width / 2, y: beamY)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            }
        }
        .onAppear {
            animate = true
        }
    }
}

// MARK: - Explanation Row

struct ExplanationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ChemistryExplanationScreen(action: {})
}
