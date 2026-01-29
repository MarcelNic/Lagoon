//
//  InfoPillsRow.swift
//  Lagoon
//

import SwiftUI

struct InfoPillsRow: View {
    @Bindable var state: MeinPoolState

    var body: some View {
        GlassEffectContainer(spacing: 8) {
            HStack(spacing: 8) {
                InfoPill(icon: "location.fill", text: state.location)
                InfoPill(icon: "thermometer.medium", text: state.waterTemperature)
                InfoPill(icon: "cloud.fill", text: state.weather)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct InfoPill: View {
    @Environment(\.colorScheme) private var colorScheme

    let icon: String?
    let text: String
    var tint: Color? = nil
    var foregroundColor: Color = .white
    var shimmer: Bool = false
    var shimmerColor: Color = .green

    @State private var isShimmering: Bool = false

    init(icon: String, text: String, tint: Color? = nil, foregroundColor: Color = .white) {
        self.icon = icon
        self.text = text
        self.tint = tint
        self.foregroundColor = foregroundColor
        self.shimmer = false
        self.shimmerColor = .green
    }

    init(text: String, tint: Color? = nil, foregroundColor: Color = .white, shimmer: Bool = false, shimmerColor: Color = .green) {
        self.icon = nil
        self.text = text
        self.tint = tint
        self.foregroundColor = foregroundColor
        self.shimmer = shimmer
        self.shimmerColor = shimmerColor
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .medium))
            }
            Text(text)
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(foregroundColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background {
            if shimmer {
                shimmerBackground
            }
        }
        .glassEffect(
            glassStyle,
            in: .capsule
        )
    }

    @ViewBuilder
    private var shimmerBackground: some View {
        let shape = Capsule()
        let clearColors: [Color] = Array(repeating: .clear, count: 3)

        shape
            .stroke(
                shimmerColor.gradient,
                style: .init(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
            )
            .mask {
                shape
                    .fill(AngularGradient(
                        colors: clearColors + [Color.white] + clearColors,
                        center: .center,
                        angle: .init(degrees: isShimmering ? 360 : 0)
                    ))
            }
            .padding(-1.25)
            .blur(radius: 1.5)
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    isShimmering = true
                }
            }
            .onDisappear {
                isShimmering = false
            }
    }

    private var glassStyle: Glass {
        if let tint = tint {
            return .clear.tint(tint).interactive()
        } else {
            return .clear.interactive()
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            stops: [
                .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        InfoPillsRow(state: MeinPoolState())
            .padding(.horizontal, 20)
    }
}
