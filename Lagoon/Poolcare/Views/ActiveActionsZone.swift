//
//  ActiveActionsZone.swift
//  Lagoon
//

import SwiftUI

struct ActionIcon: View {
    let type: ActionType
    let size: CGFloat

    var body: some View {
        if type.isCustomIcon {
            Image(type.icon)
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        } else {
            Image(systemName: type.icon)
                .font(.system(size: size, weight: .semibold))
        }
    }
}

struct ActiveActionsZone: View {
    @Bindable var state: PoolcareState
    @Namespace private var actionsNamespace

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            if state.hasActiveActions {
                ForEach(state.activeActions) { action in
                    ActiveActionCard(action: action, state: state, namespace: actionsNamespace)
                }
            } else {
                HStack(spacing: 12) {
                    QuickActionButton(type: .robot, state: state, namespace: actionsNamespace)
                    QuickActionButton(type: .backwash, state: state, namespace: actionsNamespace)
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let type: ActionType
    @Bindable var state: PoolcareState
    var namespace: Namespace.ID

    var body: some View {
        Button {
            withAnimation(.smooth(duration: 0.4)) {
                state.startAction(type)
            }
        } label: {
            HStack(spacing: 10) {
                ActionIcon(type: type, size: 24)

                Text(type.title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundStyle(Color(light: Color.black, dark: Color.white))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .capsule)
        .glassEffectID(type.rawValue, in: namespace)
    }
}

struct ActiveActionCard: View {
    let action: ActiveAction
    @Bindable var state: PoolcareState
    var namespace: Namespace.ID

    var body: some View {
        HStack(spacing: 14) {
            ActionIcon(type: action.type, size: 28)
                .foregroundStyle(Color(light: Color.black, dark: Color.white))

            VStack(alignment: .leading, spacing: 2) {
                Text(action.type.activeLabel)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(light: Color.black, dark: Color.white))

                Text(formatRemainingTime(action.remainingTime))
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.6))
                    .contentTransition(.numericText())
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color(light: Color.black, dark: Color.white).opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: action.progress)
                    .stroke(Color(light: Color.black, dark: Color.white), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 32, height: 32)

            Button {
                withAnimation(.smooth(duration: 0.4)) {
                    state.cancelAction(action)
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.6))
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .glassEffect(.clear.interactive(), in: .circle)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .glassEffect(.clear, in: .capsule)
        .glassEffectID(action.type.rawValue, in: namespace)
        .id(state.timerTick)
    }

    private func formatRemainingTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
