//
//  TaskRowView.swift
//  Lagoon
//

import SwiftUI

struct TaskRowView: View {
    let task: PoolcareTask
    @Bindable var state: PoolcareState
    var isCompleted: Bool = false
    var isDimmed: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.snappy) {
                    state.completeTask(task)
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(isCompleted ? .green : .white.opacity(0.4))
            }
            .buttonStyle(.plain)
            .disabled(isCompleted)

            // Title and subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isCompleted ? .white.opacity(0.4) : .white)
                    .strikethrough(isCompleted, color: .white.opacity(0.4))

                Text(task.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(subtitleColor)
            }

            Spacer()

            // Postpone actions
            if !isCompleted && !isDimmed {
                HStack(spacing: 6) {
                    PostponeButton(title: "Später") {
                        withAnimation(.snappy) {
                            state.postponeTask(task, days: 1)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .opacity(isDimmed ? 0.5 : 1.0)
    }

    private var subtitleColor: Color {
        if isCompleted { return .white.opacity(0.3) }

        switch task.urgency {
        case .overdue: return .red
        case .dueToday: return .orange
        case .upcoming, .future: return .white.opacity(0.5)
        }
    }
}

struct PostponeButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .capsule)
    }
}
