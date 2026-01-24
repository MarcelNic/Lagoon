//
//  TaskListZone.swift
//  Lagoon
//

import SwiftUI

struct TaskListZone: View {
    @Bindable var state: PoolcareState

    var body: some View {
        VStack(spacing: 0) {
            // Section header
            HStack {
                Text("Aufgaben")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.5))
                    .textCase(.uppercase)

                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Task list
            GlassEffectContainer {
                VStack(spacing: 0) {
                    // Recently completed
                    ForEach(state.recentlyCompletedTasks) { task in
                        TaskRowView(task: task, state: state, isCompleted: true)
                            .transition(.asymmetric(
                                insertion: .identity,
                                removal: .opacity.combined(with: .move(edge: .trailing))
                            ))

                        if task.id != state.recentlyCompletedTasks.last?.id {
                            Divider()
                                .background(Color(light: Color.black, dark: Color.white).opacity(0.1))
                        }
                    }

                    // Due tasks
                    ForEach(state.dueTasks) { task in
                        if !state.recentlyCompletedTasks.isEmpty || task.id != state.dueTasks.first?.id {
                            Divider()
                                .background(Color(light: Color.black, dark: Color.white).opacity(0.1))
                        }
                        TaskRowView(task: task, state: state)
                    }

                    // Divider for upcoming
                    if !state.upcomingTasks.isEmpty && !state.dueTasks.isEmpty {
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Color(light: Color.black, dark: Color.white).opacity(0.15))
                                .frame(height: 1)

                            Text("Demnächst")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.4))

                            Rectangle()
                                .fill(Color(light: Color.black, dark: Color.white).opacity(0.15))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 8)
                    }

                    // Upcoming tasks
                    ForEach(state.upcomingTasks) { task in
                        if state.dueTasks.isEmpty && task.id != state.upcomingTasks.first?.id {
                            Divider()
                                .background(Color(light: Color.black, dark: Color.white).opacity(0.1))
                        }
                        TaskRowView(task: task, state: state, isDimmed: true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 20))
            }
        }
    }
}
