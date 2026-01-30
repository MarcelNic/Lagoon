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
    @State private var showTimerPicker = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon/Button je nach Task-Typ
            if task.isTimerTask {
                // Timer-Task: Play-Button mit Icon
                Button {
                    showTimerPicker = true
                } label: {
                    if let actionType = task.actionType {
                        ActionIcon(type: actionType, size: 22)
                            .foregroundStyle(Color(light: Color.black, dark: Color.white))
                    }
                }
                .buttonStyle(.plain)
            } else {
                // Normale Task: Checkbox
                Button {
                    withAnimation(.snappy) {
                        state.completeTask(task)
                    }
                } label: {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 22, weight: .regular))
                        .foregroundStyle(isCompleted ? .green : Color(light: Color.black, dark: Color.white).opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(isCompleted)
            }

            // Title and subtitle
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(isCompleted ? Color(light: Color.black, dark: Color.white).opacity(0.4) : Color(light: Color.black, dark: Color.white))
                    .strikethrough(isCompleted, color: Color(light: Color.black, dark: Color.white).opacity(0.4))

                Text(task.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(subtitleColor)
            }

            Spacer()

            // Actions
            if task.isTimerTask {
                // Timer-Task: Play-Button
                Button {
                    showTimerPicker = true
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.6))
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .glassEffect(.clear.interactive(), in: .circle)
            } else if !isCompleted && !isDimmed {
                // Normale Task: Postpone
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
        .sheet(isPresented: $showTimerPicker) {
            if let actionType = task.actionType {
                TimerPickerSheet(type: actionType) { duration in
                    withAnimation(.smooth(duration: 0.4)) {
                        state.startTaskAsAction(task, duration: duration)
                    }
                }
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    private var subtitleColor: Color {
        if isCompleted { return Color(light: Color.black, dark: Color.white).opacity(0.3) }
        if task.isTimerTask { return Color(light: Color.black, dark: Color.white).opacity(0.5) }

        switch task.urgency {
        case .overdue: return .red
        case .dueToday: return .orange
        case .upcoming, .future: return Color(light: Color.black, dark: Color.white).opacity(0.5)
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
                .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.6))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .glassEffect(.clear.interactive(), in: .capsule)
    }
}
