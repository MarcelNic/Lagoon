//
//  PoolcareView.swift
//  Lagoon
//

import SwiftUI
import SwiftData

struct PoolcareView: View {
    @Bindable var state: PoolcareState
    @Binding var showAddSheet: Bool
    @State private var editingTask: CareTask?
    @State private var showNewScenarioSheet = false

    private var scenario: CareScenario? {
        state.currentScenario()
    }

    private var sortedTasks: [CareTask] {
        scenario?.sortedTasks ?? []
    }

    var body: some View {
        NavigationStack {
            List {
                // Active Timers
                if state.hasActiveActions {
                    Section {
                        ForEach(state.activeActions) { action in
                            ActiveActionRow(action: action, state: state)
                        }
                    }
                }

                // Task List
                Section {
                    ForEach(sortedTasks) { task in
                        if task.isAction {
                            ActionTaskRow(task: task, state: state)
                                .contextMenu {
                                    taskContextMenu(for: task)
                                }
                        } else {
                            RegularTaskRow(task: task, state: state)
                                .contextMenu {
                                    taskContextMenu(for: task)
                                }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                AdaptiveBackgroundGradient()
                    .ignoresSafeArea()
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ScenarioPill(state: state, showNewScenarioSheet: $showNewScenarioSheet)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet(state: state)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(task: task, state: state)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showNewScenarioSheet) {
                NewScenarioSheet(state: state)
                    .presentationDetents([.medium])
            }
        }
    }

    @ViewBuilder
    private func taskContextMenu(for task: CareTask) -> some View {
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

// MARK: - Scenario Pill

private struct ScenarioPill: View {
    @Bindable var state: PoolcareState
    @Binding var showNewScenarioSheet: Bool
    @Query(sort: \CareScenario.sortOrder) private var scenarios: [CareScenario]

    private var currentScenario: CareScenario? {
        scenarios.first { $0.id == state.currentScenarioId }
    }

    var body: some View {
        Menu {
            Picker(selection: $state.currentScenarioId) {
                ForEach(scenarios) { scenario in
                    Label(scenario.name, systemImage: scenario.icon)
                        .tag(scenario.id as UUID?)
                }
            } label: {
                EmptyView()
            }
            .pickerStyle(.inline)

            Divider()

            Button {
                showNewScenarioSheet = true
            } label: {
                Label("Neues Szenario...", systemImage: "plus")
            }
        } label: {
            Label(
                currentScenario?.name ?? "Szenario",
                systemImage: currentScenario?.icon ?? "list.bullet"
            )
            .font(.subheadline.weight(.medium))
        }
        .menuStyle(.button)
        .buttonStyle(.glass)
    }
}

// MARK: - Regular Task Row

private struct RegularTaskRow: View {
    let task: CareTask
    @Bindable var state: PoolcareState

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation {
                    state.completeTask(task)
                }
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? Color.green : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                Text(task.subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(task.isCompleted ? .secondary : subtitleColor)
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
    @State private var showTimerPicker = false

    var body: some View {
        HStack(spacing: 12) {
            TaskIconView(iconName: task.iconName, isCustomIcon: task.isCustomIcon, size: 22)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)

                Text(task.subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showTimerPicker = true
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showTimerPicker) {
            TimerPickerSheet(
                title: task.title,
                iconName: task.iconName,
                isCustomIcon: task.isCustomIcon,
                defaultDuration: task.actionDurationSeconds
            ) { duration in
                withAnimation {
                    state.startAction(task, duration: duration)
                }
            }
            .presentationDetents([.medium])
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
            Image(systemName: "checkmark.circle")
                .font(.system(size: size))
        }
    }
}

// MARK: - Timer Picker Sheet

struct TimerPickerSheet: View {
    let title: String
    let iconName: String?
    let isCustomIcon: Bool
    let defaultDuration: Double
    let onStart: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int

    init(
        title: String,
        iconName: String?,
        isCustomIcon: Bool,
        defaultDuration: Double,
        onStart: @escaping (TimeInterval) -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isCustomIcon = isCustomIcon
        self.defaultDuration = defaultDuration
        self.onStart = onStart
        let secs = Int(defaultDuration)
        _hours = State(initialValue: secs / 3600)
        _minutes = State(initialValue: (secs % 3600) / 60)
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    TaskIconView(iconName: iconName, isCustomIcon: isCustomIcon, size: 44)
                        .foregroundStyle(.tint)
                    Text(title)
                        .font(.title3.weight(.semibold))
                }
                .padding(.top)

                HStack(spacing: 0) {
                    Picker("Stunden", selection: $hours) {
                        ForEach(0..<24) { Text("\($0) h").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    Picker("Minuten", selection: $minutes) {
                        ForEach(0..<60) { Text("\($0) m").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }
                .frame(height: 150)

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onStart(totalSeconds)
                    dismiss()
                } label: {
                    Text("Starten")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(totalSeconds == 0)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Add Item Sheet

private struct AddItemSheet: View {
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var itemType: ItemType = .task
    @State private var title = ""
    @State private var dueDate = Date()
    @State private var intervalDays = 0
    @State private var actionDuration: Double = 3600
    @State private var actionHours = 1
    @State private var actionMinutes = 0

    enum ItemType: String, CaseIterable {
        case task = "Aufgabe"
        case action = "Aktion"
    }

    private let intervalOptions: [(String, Int)] = [
        ("Einmalig", 0),
        ("Täglich", 1),
        ("Alle 2 Tage", 2),
        ("Wöchentlich", 7),
        ("Alle 2 Wochen", 14),
        ("Monatlich", 30),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Typ", selection: $itemType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal)
                }

                Section {
                    TextField("Titel", text: $title)
                }

                Section("Fälligkeit") {
                    DatePicker("Fällig ab", selection: $dueDate, displayedComponents: .date)

                    Picker("Intervall", selection: $intervalDays) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }

                if itemType == .action {
                    Section("Timer-Dauer") {
                        HStack(spacing: 0) {
                            Picker("Stunden", selection: $actionHours) {
                                ForEach(0..<24) { Text("\($0) h").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)

                            Picker("Minuten", selection: $actionMinutes) {
                                ForEach(0..<60) { Text("\($0) m").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(itemType == .task ? "Neue Aufgabe" : "Neue Aktion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Hinzufügen") {
                        addItem()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        guard let scenario = state.currentScenario() else { return }
        let duration = Double(actionHours * 3600 + actionMinutes * 60)

        state.addTask(
            to: scenario,
            title: title,
            dueDate: dueDate,
            intervalDays: intervalDays,
            isAction: itemType == .action,
            actionDurationSeconds: itemType == .action ? duration : 0
        )
    }
}

// MARK: - Edit Task Sheet

private struct EditTaskSheet: View {
    let task: CareTask
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var dueDate: Date
    @State private var intervalDays: Int
    @State private var actionHours: Int
    @State private var actionMinutes: Int

    private let intervalOptions: [(String, Int)] = [
        ("Einmalig", 0),
        ("Täglich", 1),
        ("Alle 2 Tage", 2),
        ("Wöchentlich", 7),
        ("Alle 2 Wochen", 14),
        ("Monatlich", 30),
    ]

    init(task: CareTask, state: PoolcareState) {
        self.task = task
        self.state = state
        _title = State(initialValue: task.title)
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _intervalDays = State(initialValue: task.intervalDays)
        let secs = Int(task.actionDurationSeconds)
        _actionHours = State(initialValue: secs / 3600)
        _actionMinutes = State(initialValue: (secs % 3600) / 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Titel", text: $title)
                }

                Section("Fälligkeit") {
                    DatePicker("Fällig am", selection: $dueDate, displayedComponents: .date)

                    Picker("Intervall", selection: $intervalDays) {
                        ForEach(intervalOptions, id: \.1) { option in
                            Text(option.0).tag(option.1)
                        }
                    }
                }

                if task.isAction {
                    Section("Timer-Dauer") {
                        HStack(spacing: 0) {
                            Picker("Stunden", selection: $actionHours) {
                                ForEach(0..<24) { Text("\($0) h").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)

                            Picker("Minuten", selection: $actionMinutes) {
                                ForEach(0..<60) { Text("\($0) m").tag($0) }
                            }
                            .pickerStyle(.wheel)
                            .frame(width: 100)
                        }
                        .frame(height: 120)
                        .frame(maxWidth: .infinity)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        state.deleteTask(task)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Aufgabe löschen")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        saveChanges()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let duration = Double(actionHours * 3600 + actionMinutes * 60)
        state.updateTask(
            task,
            title: title,
            dueDate: dueDate,
            intervalDays: intervalDays,
            actionDurationSeconds: task.isAction ? duration : nil
        )
    }
}

// MARK: - New Scenario Sheet

private struct NewScenarioSheet: View {
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedIcon = "leaf.fill"

    private let iconOptions = [
        "leaf.fill", "flame.fill", "drop.fill", "sparkles",
        "star.fill", "heart.fill", "bolt.fill", "moon.fill",
        "cloud.fill", "wind", "thermometer.medium", "wrench.fill",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                }

                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Button {
                                selectedIcon = icon
                            } label: {
                                Image(systemName: icon)
                                    .font(.title2)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                                    .background {
                                        if selectedIcon == icon {
                                            Circle()
                                                .fill(.tint)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Neues Szenario")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Erstellen") {
                        let scenario = state.createScenario(name: name, icon: selectedIcon)
                        state.currentScenarioId = scenario.id
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    PoolcareView(state: PoolcareState(), showAddSheet: .constant(false))
        .modelContainer(for: [CareScenario.self, CareTask.self], inMemory: true)
}
