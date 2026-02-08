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
            ScrollView {
                VStack(spacing: 16) {
                    // Active Timers
                    if state.hasActiveActions {
                        VStack(spacing: 0) {
                            ForEach(state.activeActions) { action in
                                ActiveActionRow(action: action, state: state)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                if action.id != state.activeActions.last?.id {
                                    Divider()
                                        .padding(.leading, 20)
                                }
                            }
                        }
                        .glassEffect(.clear, in: .capsule)
                    }

                    // Task List
                    if !sortedTasks.isEmpty {
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
                                .contextMenu {
                                    taskContextMenu(for: task)
                                }
                                if task.id != sortedTasks.last?.id {
                                    Divider()
                                        .padding(.leading, 16)
                                }
                            }
                        }
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
            .safeAreaInset(edge: .top, spacing: 0) {
                ScenarioPill(state: state, showNewScenarioSheet: $showNewScenarioSheet)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            .sheet(isPresented: $showAddSheet) {
                AddItemSheet(state: state)
            }
            .sheet(item: $editingTask) { task in
                EditTaskSheet(task: task, state: state)
                    .presentationDetents([.large])
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
            ForEach(scenarios) { scenario in
                Button {
                    state.currentScenarioId = scenario.id
                } label: {
                    Label(
                        scenario.id == state.currentScenarioId
                            ? "\(scenario.name)  ✓"
                            : scenario.name,
                        systemImage: scenario.icon
                    )
                }
            }

            Divider()

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
                Text(currentScenario?.name ?? "Szenario")
            }
            .font(.body.weight(.medium))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
        }
        .menuStyle(.button)
        .buttonStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .glassEffect(.clear.interactive(), in: .capsule)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
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
    @State private var selectedIcon = "checkmark.circle"
    @State private var dueDate = Date()
    @State private var intervalDays = 0
    @State private var reminderEnabled = true
    @State private var reminderTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var remindAfterTimer = true
    @State private var showSymbolPicker = false
    @State private var currentDetent: PresentationDetent = .large
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
                    HStack(spacing: 12) {
                        Button {
                            showSymbolPicker = true
                        } label: {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(.tint)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)

                        TextField("Name", text: $title)
                    }
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

                Section("Erinnerung") {
                    Toggle("Erinnern", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if itemType == .action {
                        Toggle("Nach Timer-Ablauf", isOn: $remindAfterTimer)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .presentationDetents([.medium, .large], selection: $currentDetent)
            .onChange(of: itemType) { _, newValue in
                withAnimation {
                    currentDetent = newValue == .action ? .large : .medium
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .principal) {
                    Picker("Typ", selection: $itemType) {
                        ForEach(ItemType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addItem()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .clipShape(Circle())
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPickerSheet(selectedIcon: $selectedIcon)
                    .presentationDetents([.medium])
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
            actionDurationSeconds: itemType == .action ? duration : 0,
            iconName: selectedIcon,
            reminderTime: reminderEnabled ? reminderTime : nil,
            remindAfterTimer: itemType == .action ? remindAfterTimer : false
        )
    }
}

// MARK: - Symbol Picker Sheet

private struct SymbolPickerSheet: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    private let symbols = [
        "checkmark.circle", "drop.fill", "water.waves",
        "thermometer.medium", "sun.max.fill", "snowflake",
        "wind", "cloud.fill", "leaf.fill", "flame.fill",
        "wrench.fill", "gearshape.fill", "paintbrush.fill",
        "sparkles", "arrow.circlepath", "testtube.2",
        "clock.fill", "bell.fill", "star.fill", "bolt.fill",
        "eye", "gauge.with.dots.needle.bottom.50percent",
        "figure.pool.swim", "slider.horizontal.3",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                    ForEach(symbols, id: \.self) { symbol in
                        Button {
                            selectedIcon = symbol
                            dismiss()
                        } label: {
                            Image(systemName: symbol)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .foregroundStyle(selectedIcon == symbol ? .white : .primary)
                                .background {
                                    if selectedIcon == symbol {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.tint)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Symbol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

// MARK: - Edit Task Sheet

private struct EditTaskSheet: View {
    let task: CareTask
    @Bindable var state: PoolcareState
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var selectedIcon: String
    @State private var dueDate: Date
    @State private var intervalDays: Int
    @State private var reminderEnabled: Bool
    @State private var reminderTime: Date
    @State private var remindAfterTimer: Bool
    @State private var actionHours: Int
    @State private var actionMinutes: Int
    @State private var showSymbolPicker = false

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
        _selectedIcon = State(initialValue: task.iconName ?? "checkmark.circle")
        _dueDate = State(initialValue: task.dueDate ?? Date())
        _intervalDays = State(initialValue: task.intervalDays)
        _reminderEnabled = State(initialValue: task.reminderTime != nil)
        _reminderTime = State(initialValue: task.reminderTime ?? {
            var c = DateComponents()
            c.hour = 9; c.minute = 0
            return Calendar.current.date(from: c) ?? Date()
        }())
        _remindAfterTimer = State(initialValue: task.remindAfterTimer)
        let secs = Int(task.actionDurationSeconds)
        _actionHours = State(initialValue: secs / 3600)
        _actionMinutes = State(initialValue: (secs % 3600) / 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Button {
                            showSymbolPicker = true
                        } label: {
                            Image(systemName: selectedIcon)
                                .font(.title2)
                                .foregroundStyle(.tint)
                                .frame(width: 32, height: 32)
                        }
                        .buttonStyle(.plain)

                        TextField("Name", text: $title)
                    }
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

                Section("Erinnerung") {
                    Toggle("Erinnern", isOn: $reminderEnabled)
                    if reminderEnabled {
                        DatePicker("Uhrzeit", selection: $reminderTime, displayedComponents: .hourAndMinute)
                    }
                    if task.isAction {
                        Toggle("Nach Timer-Ablauf", isOn: $remindAfterTimer)
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
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveChanges()
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .clipShape(Circle())
                    .disabled(title.isEmpty)
                }
            }
            .sheet(isPresented: $showSymbolPicker) {
                SymbolPickerSheet(selectedIcon: $selectedIcon)
                    .presentationDetents([.medium])
            }
        }
    }

    private func saveChanges() {
        let duration = Double(actionHours * 3600 + actionMinutes * 60)
        task.iconName = selectedIcon
        task.isCustomIcon = false
        task.reminderTime = reminderEnabled ? reminderTime : nil
        task.remindAfterTimer = task.isAction ? remindAfterTimer : false
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
