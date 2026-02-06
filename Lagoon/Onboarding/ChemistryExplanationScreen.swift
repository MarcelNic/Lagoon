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
                    label: "pH",
                    labelColor: Color.phIdealColor,
                    boldText: "Bestimmt, wie gut Chlor wirken kann.",
                    text: "Bei zu hohem pH sinkt die Wirksamkeit um bis zu ~60 %."
                )

                ExplanationRow(
                    label: "Cl",
                    labelColor: Color.chlorineIdealColor,
                    boldText: "Desinfiziert das Wasser.",
                    text: "Wirkt es effizient, braucht man weniger davon, was Geruch und Reizungen reduziert."
                )

                ExplanationRow(
                    label: "",
                    labelColor: .blue,
                    boldText: "Verknüpft pH und Chlor.",
                    text: "Erkennt Trends und berechnet eine konkrete Dosierempfehlung für deinen Zielbereich.",
                    useAppIcon: true
                )
            }
            .padding(.horizontal, 30)
            .microAnimation(delay: 0.6)

            Spacer()

            PrimaryButton(title: "Verstanden", action: action)
                .microAnimation(delay: 1.0)
        }
    }
}

// MARK: - Balance Visual

struct BalanceVisualView: View {
    @State private var tilt: Double = -4

    var body: some View {
        VStack(spacing: 0) {
            // Beam with labels
            ZStack {
                // Beam
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 240, height: 6)

                // pH (left)
                Text("pH")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.phIdealColor)
                    .offset(x: -80, y: -20)

                // Cl (right)
                Text("Cl")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.chlorineIdealColor)
                    .offset(x: 80, y: -20)
            }
            .rotationEffect(.degrees(tilt))
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: tilt)

            // Fulcrum circle
            Circle()
                .fill(.secondary.opacity(0.25))
                .frame(width: 20, height: 20)
                .offset(y: -3)
        }
        .onAppear {
            tilt = 4
        }
    }
}

// MARK: - Explanation Row

struct ExplanationRow: View {
    let label: String
    let labelColor: Color
    let boldText: String
    let text: String
    var useAppIcon: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if useAppIcon {
                // App icon representation with Lagoon-style water drop
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.8), Color.cyan.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    Image(systemName: "drop.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
            } else {
                // Centered label in a colored circle
                ZStack {
                    Circle()
                        .fill(labelColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Text(label)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(labelColor)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(boldText)
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
