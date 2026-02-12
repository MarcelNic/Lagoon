//
//  PoolcareState.swift
//  Lagoon
//

import SwiftUI
import SwiftData
import Combine
import ActivityKit

@Observable
final class PoolcareState {

    // MARK: - Scenario Selection

    var currentScenarioId: UUID?
    var showSwitchScenarioAlert = false
    var pendingNextScenario: CareScenario?

    // MARK: - Active Timers (in-memory)

    private(set) var activeActions: [ActiveAction] = []
    private(set) var timerTick: Date = Date()

    // MARK: - Private

    private(set) var modelContext: ModelContext?
    private var notificationManager: NotificationManager?
    private var timerCancellable: AnyCancellable?
    private var robotActivity: Activity<RobotActivityAttributes>?
    private var lastLiveActivityUpdate: Date = .distantPast

    // MARK: - Initialization

    init() {
        startTimerUpdates()
    }

    deinit {
        timerCancellable?.cancel()
    }

    func configure(modelContext context: ModelContext, notificationManager: NotificationManager) {
        self.modelContext = context
        self.notificationManager = notificationManager

        // Seed default data if needed
        let descriptor = FetchDescriptor<CareScenario>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count == 0 {
            seedDefaultData()
        }

        // Select first scenario if none selected
        if currentScenarioId == nil {
            currentScenarioId = fetchScenarios().first?.id
        }
    }

    // MARK: - Scenario Management

    func fetchScenarios() -> [CareScenario] {
        guard let context = modelContext else { return [] }
        let descriptor = FetchDescriptor<CareScenario>(sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func currentScenario() -> CareScenario? {
        guard let context = modelContext, let id = currentScenarioId else { return nil }
        let descriptor = FetchDescriptor<CareScenario>(predicate: #Predicate { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    func createScenario(name: String, icon: String) -> CareScenario {
        let scenarios = fetchScenarios()
        let maxOrder = scenarios.map(\.sortOrder).max() ?? 0
        let scenario = CareScenario(name: name, icon: icon, sortOrder: maxOrder + 1, isBuiltIn: false)
        modelContext?.insert(scenario)
        try? modelContext?.save()
        return scenario
    }

    func confirmScenarioSwitch() {
        guard let next = pendingNextScenario else { return }
        currentScenarioId = next.id
        pendingNextScenario = nil
    }

    func deleteScenario(_ scenario: CareScenario) {
        modelContext?.delete(scenario)
        try? modelContext?.save()

        // If deleted scenario was active, switch to first
        if currentScenarioId == scenario.id {
            currentScenarioId = fetchScenarios().first?.id
        }
    }

    // MARK: - Task Management

    func completeTask(_ task: CareTask) {
        task.completedAt = Date()
        try? modelContext?.save()

        let taskId = task.persistentModelID
        let intervalDays = task.intervalDays
        let careTaskId = task.id

        // Cancel current reminder
        notificationManager?.cancelCareTaskReminder(taskId: careTaskId)

        // After delay: reschedule or delete
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.8))
            guard let context = self.modelContext else { return }

            // Safely re-fetch task (context.model(for:) can fault-crash if deleted)
            let fetchId = careTaskId
            var descriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == fetchId })
            descriptor.fetchLimit = 1
            guard let task = try? context.fetch(descriptor).first else { return }

            if intervalDays > 0 {
                // Reschedule: move to next due date
                task.dueDate = Calendar.current.date(byAdding: .day, value: intervalDays, to: Date())
                task.completedAt = nil
                try? context.save()

                // Schedule reminder for next occurrence
                self.notificationManager?.scheduleCareTaskReminder(task: task)
            } else {
                // One-time task: delete
                context.delete(task)
                try? context.save()
            }

            // Check if all tasks in scenario are completed → offer switch
            self.checkAllTasksCompleted()
        }
    }

    private func checkAllTasksCompleted() {
        guard let scenario = currentScenario(),
              let nextId = scenario.nextScenarioId else { return }

        let remainingTasks = scenario.tasks.filter { !$0.isCompleted }
        guard remainingTasks.isEmpty else { return }

        // Find the next scenario
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<CareScenario>(predicate: #Predicate { $0.id == nextId })
        guard let nextScenario = try? context.fetch(descriptor).first else { return }

        pendingNextScenario = nextScenario
        showSwitchScenarioAlert = true
    }

    func addTask(
        to scenario: CareScenario,
        title: String,
        dueDate: Date,
        intervalDays: Int,
        isAction: Bool = false,
        actionDurationSeconds: Double = 0,
        iconName: String? = nil,
        isCustomIcon: Bool = false,
        reminderTime: Date? = nil,
        remindAfterTimer: Bool = false
    ) {
        let task = CareTask(
            title: title,
            dueDate: dueDate,
            intervalDays: intervalDays,
            isAction: isAction,
            actionDurationSeconds: actionDurationSeconds,
            iconName: iconName,
            isCustomIcon: isCustomIcon,
            reminderTime: reminderTime,
            remindAfterTimer: remindAfterTimer
        )
        task.scenario = scenario
        modelContext?.insert(task)
        try? modelContext?.save()

        notificationManager?.scheduleCareTaskReminder(task: task)
    }

    func updateTask(
        _ task: CareTask,
        title: String? = nil,
        dueDate: Date? = nil,
        intervalDays: Int? = nil,
        actionDurationSeconds: Double? = nil,
        iconName: String? = nil,
        isCustomIcon: Bool? = nil
    ) {
        if let title { task.title = title }
        if let dueDate { task.dueDate = dueDate }
        if let intervalDays { task.intervalDays = intervalDays }
        if let actionDurationSeconds { task.actionDurationSeconds = actionDurationSeconds }
        if let iconName { task.iconName = iconName }
        if let isCustomIcon { task.isCustomIcon = isCustomIcon }
        try? modelContext?.save()

        // Reschedule notification with updated data
        if task.reminderTime != nil {
            notificationManager?.scheduleCareTaskReminder(task: task)
        } else {
            notificationManager?.cancelCareTaskReminder(taskId: task.id)
        }
    }

    func deleteTask(_ task: CareTask) {
        notificationManager?.cancelCareTaskReminder(taskId: task.id)
        modelContext?.delete(task)
        try? modelContext?.save()
    }

    // MARK: - Timer Management

    var hasActiveActions: Bool {
        !activeActions.isEmpty
    }

    func startAction(_ task: CareTask, duration: TimeInterval) {
        let action = ActiveAction(
            taskId: task.id,
            title: task.title,
            iconName: task.iconName,
            isCustomIcon: task.isCustomIcon,
            duration: duration,
            remindAfterTimer: task.remindAfterTimer
        )
        activeActions.append(action)

        // Start Live Activity for robot-like tasks
        if task.iconName == "Robi" || task.title.lowercased().contains("roboter") {
            startRobotLiveActivity(action: action)
        }
    }

    func cancelAction(_ action: ActiveAction) {
        if action.iconName == "Robi" || action.title.lowercased().contains("roboter") {
            endRobotLiveActivity()
        }
        activeActions.removeAll { $0.id == action.id }

        // Mark the underlying task as completed
        if let context = modelContext {
            let taskId = action.taskId
            var descriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == taskId })
            descriptor.fetchLimit = 1
            if let task = try? context.fetch(descriptor).first {
                completeTask(task)
            }
        }
    }

    // MARK: - Timer Updates

    private func startTimerUpdates() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.timerTick = date
                self?.checkExpiredActions()
                self?.updateRobotLiveActivityIfNeeded()
            }
    }

    private func checkExpiredActions() {
        let expired = activeActions.filter { $0.isExpired }

        for action in expired {
            if action.iconName == "Robi" || action.title.lowercased().contains("roboter") {
                endRobotLiveActivity()
            }

            // Send notification if remindAfterTimer is enabled
            if action.remindAfterTimer {
                notificationManager?.scheduleTimerExpiredNotification(
                    taskTitle: action.title,
                    taskId: action.taskId
                )
            }

            activeActions.removeAll { $0.id == action.id }
        }
    }

    // MARK: - Live Activity Management

    private func startRobotLiveActivity(action: ActiveAction) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        lastLiveActivityUpdate = .distantPast

        let attributes = RobotActivityAttributes(
            startTime: action.startTime,
            duration: action.duration,
            actionTitle: action.activeLabel
        )

        let initialState = RobotActivityAttributes.ContentState(
            endTime: action.endTime,
            progress: 0.0
        )

        do {
            robotActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: action.endTime)
            )
            LiveActivityBackgroundManager.shared.scheduleBackgroundRefresh()
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func updateRobotLiveActivityIfNeeded() {
        guard let activity = robotActivity,
              let robotAction = activeActions.first(where: {
                  $0.iconName == "Robi" || $0.title.lowercased().contains("roboter")
              }) else { return }

        let now = Date()
        guard now.timeIntervalSince(lastLiveActivityUpdate) >= 30 else { return }
        lastLiveActivityUpdate = now

        let updatedState = RobotActivityAttributes.ContentState(
            endTime: robotAction.endTime,
            progress: robotAction.progress
        )

        Task {
            await activity.update(.init(state: updatedState, staleDate: robotAction.endTime))
        }
    }

    private func endRobotLiveActivity() {
        guard let activity = robotActivity else { return }

        LiveActivityBackgroundManager.shared.cancelBackgroundRefresh()

        let finalState = RobotActivityAttributes.ContentState(
            endTime: Date(),
            progress: 1.0
        )

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        robotActivity = nil
    }

    // MARK: - Seed Default Data

    func seedDefaultData() {
        guard let context = modelContext else { return }

        let now = Date()
        let calendar = Calendar.current

        // Sommer
        let sommer = CareScenario(name: "Sommer", icon: "sun.max.fill", sortOrder: 0, isBuiltIn: true)
        context.insert(sommer)

        let sommerTasks: [(String, Int, Bool, Double, String?, Bool)] = [
            ("Roboter", 2, true, 2 * 60 * 60, "Robi", true),
            ("Rückspülen", 7, true, 3 * 60, "arrow.circlepath", false),
            ("Skimmer leeren", 1, false, 0, "basket.fill", false),
            ("Wasserlinie bürsten", 7, false, 0, "paintbrush.fill", false),
            ("Filterdruck prüfen", 7, false, 0, "gauge.with.dots.needle.50percent", false),
            ("Boden saugen", 14, false, 0, "sparkles", false),
        ]

        for (i, (title, interval, isAction, duration, icon, isCustom)) in sommerTasks.enumerated() {
            let task = CareTask(
                title: title,
                dueDate: calendar.date(byAdding: .day, value: i == 0 ? 0 : i, to: now),
                intervalDays: interval,
                isAction: isAction,
                actionDurationSeconds: duration,
                iconName: icon,
                isCustomIcon: isCustom
            )
            task.scenario = sommer
            context.insert(task)
        }

        // Winter
        let winter = CareScenario(name: "Winter", icon: "snowflake", sortOrder: 1, isBuiltIn: true)
        context.insert(winter)

        let winterTasks: [(String, Int, String)] = [
            ("Abdeckung prüfen", 7, "window.shade.closed"),
            ("Wasserstand prüfen", 30, "water.waves"),
        ]

        for (i, (title, interval, icon)) in winterTasks.enumerated() {
            let task = CareTask(
                title: title,
                dueDate: calendar.date(byAdding: .day, value: i * 7, to: now),
                intervalDays: interval,
                iconName: icon
            )
            task.scenario = winter
            context.insert(task)
        }

        // Urlaub
        let urlaub = CareScenario(name: "Urlaub", icon: "airplane", sortOrder: 2, isBuiltIn: true)
        context.insert(urlaub)

        let urlaubTasks: [(String, String)] = [
            ("Chlorwert erhöhen", "testtube.2"),
            ("pH-Wert prüfen", "drop.triangle.fill"),
            ("Abdeckung sichern", "window.shade.closed"),
            ("Pumpen-Timer einstellen", "clock.fill"),
        ]

        for (title, icon) in urlaubTasks {
            let task = CareTask(
                title: title,
                dueDate: now,
                intervalDays: 0,
                iconName: icon
            )
            task.scenario = urlaub
            context.insert(task)
        }

        // Pool Öffnen (→ Sommer)
        let oeffnen = CareScenario(name: "Pool Öffnen", icon: "door.left.hand.open", sortOrder: 3, isBuiltIn: true, nextScenarioId: sommer.id)
        context.insert(oeffnen)

        let oeffnenTasks: [(String, String)] = [
            ("Abdeckung entfernen", "window.shade.open"),
            ("Wasser auffüllen", "drop.fill"),
            ("Filteranlage starten", "power"),
            ("pH-Wert messen", "drop.triangle.fill"),
            ("Chlor-Stoßbehandlung", "testtube.2"),
            ("Boden & Wände reinigen", "sparkles"),
        ]

        for (title, icon) in oeffnenTasks {
            let task = CareTask(
                title: title,
                dueDate: now,
                intervalDays: 0,
                iconName: icon
            )
            task.scenario = oeffnen
            context.insert(task)
        }

        // Einwintern (→ Winter)
        let einwintern = CareScenario(name: "Einwintern", icon: "thermometer.snowflake", sortOrder: 4, isBuiltIn: true, nextScenarioId: winter.id)
        context.insert(einwintern)

        let einwinternTasks: [(String, String)] = [
            ("Wasserpegel absenken", "arrow.up.and.down.circle"),
            ("Leitungen entleeren", "pipe.and.drop"),
            ("Wintermittel zugeben", "flask.fill"),
            ("Filteranlage abstellen", "power"),
            ("Abdeckung anbringen", "window.shade.closed"),
            ("Skimmer sichern", "basket.fill"),
        ]

        for (title, icon) in einwinternTasks {
            let task = CareTask(
                title: title,
                dueDate: now,
                intervalDays: 0,
                iconName: icon
            )
            task.scenario = einwintern
            context.insert(task)
        }

        try? context.save()

        // Select Sommer as default
        currentScenarioId = sommer.id
    }
}
