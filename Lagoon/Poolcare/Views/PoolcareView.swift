//
//  PoolcareView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

enum TaskFilter: String, CaseIterable {
    case all = "Alle"
    case today = "Heute"
    case completed = "Erledigte"
}

struct PoolcareView: View {
    @Bindable var state: PoolcareState
    @Binding var showAddSheet: Bool
    @Query(sort: \CareScenario.sortOrder) private var scenarios: [CareScenario]
    @State private var editingTask: CareTask?
    @State private var showNewScenarioSheet = false
    @State private var showEditScenarioSheet = false
    @State private var taskFilter: TaskFilter = .all

    private var scenario: CareScenario? {
        state.currentScenario()
    }

    private var sortedTasks: [CareTask] {
        let tasks = scenario?.sortedTasks ?? []
        switch taskFilter {
        case .all:
            return tasks.filter { !$0.isCompleted }
        case .today:
            return tasks.filter { !$0.isCompleted && $0.urgency <= .dueToday }
        case .completed:
            return tasks.filter { $0.isCompleted }
        }
    }

    private var filterIcon: String {
        switch taskFilter {
        case .all: "line.3.horizontal.decrease"
        case .today: "calendar"
        case .completed: "checkmark.circle"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Active Timers
                    if state.hasActiveActions {
                        VStack(spacing: 0) {
                            ForEach(state.activeActions) { action in
                                ActiveActionRow(action: action, state: state)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 14)
                                if action.id != state.activeActions.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .glassEffect(.clear, in: .capsule)
                    }

                    // Task List
                    if sortedTasks.isEmpty {
                        ContentUnavailableView(
                            taskFilter == .today ? "Keine Aufgaben heute" : "Keine erledigten Aufgaben",
                            systemImage: taskFilter == .today ? "calendar" : "checkmark.circle",
                            description: Text(taskFilter == .today ? "Für heute steht nichts an." : "Noch keine Aufgaben erledigt.")
                        )
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(sortedTasks) { task in
                                Group {
                                    if task.isAction {
                                        ActionTaskRow(task: task, state: state)
                                    } else {
                                        RegularTaskRow(task: task, state: state)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    taskContextMenu(for: task)
                                }
                                .transition(.move(edge: .top).combined(with: .opacity))
                                if task.id != sortedTasks.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
                        .animation(.smooth, value: sortedTasks.map(\.id))
                        .glassEffect(.clear, in: .rect(cornerRadius: 24))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .scrollContentBackground(.hidden)
            .background {
                AdaptiveBackgroundGradient()
                    .ignoresSafeArea()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        ForEach(scenarios) { s in
                            Button {
                                state.requestScenarioSwitch(to: s)
                            } label: {
                                Label(s.name, systemImage: s.icon)
                            }
                        }
                        Divider()
                        Button {
                            showEditScenarioSheet = true
                        } label: {
                            Label("Bearbeiten", systemImage: "pencil")
                        }
                        Button {
                            showNewScenarioSheet = true
                        } label: {
                            Label("Neues Szenario", systemImage: "plus")
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.up.chevron.down")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text(scenario?.name ?? "Szenario")
                        }
                    }
                    .buttonStyle(.glass)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(TaskFilter.allCases, id: \.self) { option in
                            Button {
                                taskFilter = option
                            } label: {
                                Label(
                                    option.rawValue,
                                    systemImage: option == .all ? "line.3.horizontal.decrease"
                                        : option == .today ? "calendar"
                                        : "checkmark.circle"
                                )
                            }
                        }
                    } label: {
                        Image(systemName: filterIcon)
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet(state: state)
            }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(task: task, state: state)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showNewScenarioSheet) {
                NewScenarioSheet(state: state, scenarios: scenarios)
                    .presentationDetents([.large])
            }
            .sheet(isPresented: $showEditScenarioSheet) {
                if let scenario {
                    EditScenarioSheet(scenario: scenario, state: state, scenarios: scenarios)
                        .presentationDetents([.large])
                }
            }
            .onAppear {
                state.ensureData()
            }
            .alert(
                "Alle Aufgaben erledigt",
                isPresented: $state.showSwitchScenarioAlert,
                presenting: state.pendingNextScenario
            ) { next in
                Button("Zu \"\(next.name)\" wechseln") {
                    state.confirmScenarioSwitch()
                }
                Button("Abbrechen", role: .cancel) { }
            } message: { next in
                Text("Möchtest du jetzt zu \"\(next.name)\" wechseln?")
            }
            .alert(
                "Szenario wechseln",
                isPresented: $state.showPauseAlert,
                presenting: state.pendingSwitchScenario
            ) { next in
                Button("Unterbrechen") {
                    state.switchScenario(to: next, pauseOld: true)
                    state.pendingSwitchScenario = nil
                }
                Button("Weiterlaufen lassen") {
                    state.switchScenario(to: next, pauseOld: false)
                    state.pendingSwitchScenario = nil
                }
                Button("Abbrechen", role: .cancel) {
                    state.pendingSwitchScenario = nil
                }
            } message: { _ in
                let name = scenario?.name ?? "aktuelles Szenario"
                Text("Benachrichtigungen werden auf das neue Szenario umgestellt. Sollen die Intervalle von \"\(name)\" unterbrochen werden? Dann wird beim Zurückwechseln nichts überfällig.")
            }
        }
    }

    @ViewBuilder
    private func taskContextMenu(for task: CareTask) -> some View {
        Button {
            withAnimation {
                state.completeTask(task)
            }
        } label: {
            Label("Erledigt", systemImage: "checkmark.circle")
        }

        Button {
            editingTask = task
        } label: {
            Label("Bearbeiten", systemImage: "pencil")
        }

        Button(role: .destructive) {
            withAnimation {
                state.deleteTask(task)
            }
        } label: {
            Label("Löschen", systemImage: "trash")
        }
    }
}

// MARK: - Regular Task Row

private struct RegularTaskRow: View {
    let task: CareTask
    @Bindable var state: PoolcareState

    private var isCompleting: Bool {
        state.completingTaskIds.contains(task.id)
    }

    private var showCompleted: Bool {
        task.isCompleted || isCompleting
    }

    var body: some View {
        HStack(spacing: 12) {
            Button {
                guard !isCompleting else { return }
                state.completeTask(task)
            } label: {
                Image(systemName: showCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(showCompleted ? Color.green : Color.secondary.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace.byLayer))
                    .animation(.smooth, value: showCompleted)
            }
            .buttonStyle(.plain)

            TaskIconView(iconName: task.iconName, isCustomIcon: task.isCustomIcon, size: 22)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(showCompleted)
                    .foregroundStyle(showCompleted ? .secondary : .primary)

                Text(task.subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(showCompleted ? .secondary : subtitleColor)
            }

            Spacer()
        }
    }

    private var subtitleColor: Color {
        switch task.urgency {
        case .overdue: return .red
        case .dueToday: return .orange
        case .upcoming, .future: return .secondary
        }
    }
}

// MARK: - Action Task Row

private struct ActionTaskRow: View {
    let task: CareTask
    @Bindable var state: PoolcareState

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    state.startAction(task, duration: task.actionDurationSeconds)
                }
            } label: {
                Image(systemName: "play.circle")
                    .font(.title2)
                    .foregroundStyle(Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            TaskIconView(iconName: task.iconName, isCustomIcon: task.isCustomIcon, size: 22)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)

                Text(task.subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Active Action Row

private struct ActiveActionRow: View {
    let action: ActiveAction
    @Bindable var state: PoolcareState

    var body: some View {
        HStack(spacing: 12) {
            TaskIconView(iconName: action.iconName, isCustomIcon: action.isCustomIcon, size: 24)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(action.activeLabel)
                    .font(.body.weight(.medium))

                Text(formatTime(action.remainingTime))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            Spacer()

            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: action.progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 28, height: 28)

            Button(role: .destructive) {
                withAnimation { state.cancelAction(action) }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .id(state.timerTick)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Task Icon View

struct TaskIconView: View {
    let iconName: String?
    let isCustomIcon: Bool
    let size: CGFloat

    var body: some View {
        if let iconName {
            if isCustomIcon {
                Image(iconName)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                Image(systemName: iconName)
                    .font(.system(size: size))
            }
        } else {
            Image(systemName: "water.waves")
                .font(.system(size: size))
        }
    }
}

// MARK: - Task Icon Constants

let customTaskIconNames: Set<String> = ["Robi"]

let taskIconOptions = [
    // Reihe 1: Wasser & Chemie
    "drop.fill", "water.waves", "testtube.2", "flask.fill", "bubbles.and.sparkles",
    // Reihe 2: Reinigung & Pflege
    "paintbrush.fill", "leaf.fill", "arrow.up.trash", "xmark.bin.fill", "figure.pool.swim",
    // Reihe 3: Technik & Wartung
    "gearshape.fill", "screwdriver.fill", "fuel.filter.water", "spigot.fill", "pipe.and.drop",
    // Reihe 4: Geräte & Steuerung
    "fan.fill", "power", "lightbulb.fill", "bolt.circle.fill", "gauge.with.dots.needle.50percent",
    // Reihe 5: Wetter & Umgebung
    "thermometer.medium", "flame.fill", "sun.max.fill", "snowflake", "aqi.medium",
    // Reihe 6: Abläufe & Allgemein
    "arrow.counterclockwise.circle", "arrow.up.and.down.circle", "water.waves.and.arrow.trianglehead.down", "clock.fill", "cloud.bolt.rain.fill",
    // Reihe 7 (mit Robi = 6): Status & Abdeckung
    "checkmark.circle", "basket.fill", "figure.hunting", "rectangle.lefthalf.inset.filled", "rectangle.inset.filled",
]

#Preview {
    PoolcareView(state: PoolcareState(), showAddSheet: .constant(false))
        .modelContainer(for: [CareScenario.self, CareTask.self], inMemory: true)
}
