//
//  PoolcareState.swift
//  Lagoon
//

import SwiftUI
import Combine
import ActivityKit

@Observable
final class PoolcareState {

    // MARK: - Zone 1: Active Actions

    private(set) var activeActions: [ActiveAction] = []
    private var timerCancellable: AnyCancellable?
    private var robotActivity: Activity<RobotActivityAttributes>?

    // MARK: - Operating Mode

    private(set) var currentMode: OperatingMode = .summer
    private(set) var vacationPhase: VacationPhase? = nil
    private(set) var previousMode: OperatingMode? = nil  // Für Rückkehr aus Urlaub

    // MARK: - Zone 2: Tasks

    private(set) var tasks: [PoolcareTask] = []

    /// Gefilterte Tasks basierend auf aktuellem Modus
    var visibleTasks: [PoolcareTask] {
        tasks.filter { $0.isVisible(in: currentMode, vacationPhase: vacationPhase) || $0.isTransitionTask }
    }

    var pendingTasks: [PoolcareTask] {
        visibleTasks
            .filter { !$0.isCompleted }
            .sorted { $0.urgency.sortOrder < $1.urgency.sortOrder }
    }

    var upcomingTasks: [PoolcareTask] {
        pendingTasks.filter { $0.urgency == .upcoming || $0.urgency == .future }
    }

    var dueTasks: [PoolcareTask] {
        pendingTasks.filter { $0.urgency == .overdue || $0.urgency == .dueToday }
    }

    var recentlyCompletedTasks: [PoolcareTask] {
        visibleTasks
            .filter { $0.isCompleted }
            .filter { task in
                guard let completedAt = task.completedAt else { return false }
                return Date().timeIntervalSince(completedAt) < 5
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // MARK: - Transition Tasks (Legacy scenario data)

    private(set) var vacationScenario: VacationScenario
    private(set) var seasonScenario: SeasonScenario

    // MARK: - Timer State

    private(set) var timerTick: Date = Date()

    // MARK: - Initialization

    init() {
        self.tasks = PoolcareTask.sampleTasks()
        self.vacationScenario = VacationScenario.defaultChecklist()
        self.seasonScenario = SeasonScenario.defaultChecklist()

        startTimerUpdates()
    }

    // MARK: - Timer Management

    private var lastLiveActivityUpdate: Date = .distantPast

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
        let expiredActions = activeActions.filter { $0.isExpired }

        for action in expiredActions {
            // End Live Activity for robot when timer expires
            if action.type == .robot {
                endRobotLiveActivity()
            }

            // Follow-Up Task erstellen (z.B. "Roboter entnehmen")
            let followUp = action.type.followUpTask
            let newTask = PoolcareTask(
                title: followUp.title,
                subtitle: followUp.subtitle,
                dueDate: Date(),
                generatedFromActionId: action.id
            )
            tasks.insert(newTask, at: 0)

            // Timer-Task wieder zur Liste hinzufügen
            let timerTask = PoolcareTask(
                title: action.type.taskTitle,
                subtitle: action.type.taskSubtitle,
                dueDate: Date(),
                actionType: action.type
            )
            tasks.append(timerTask)

            activeActions.removeAll { $0.id == action.id }
        }
    }

    // MARK: - Zone 1: Action Methods

    func startAction(_ type: ActionType, duration: TimeInterval? = nil) {
        let action = ActiveAction(type: type, duration: duration)
        activeActions.append(action)

        // Start Live Activity for robot
        if type == .robot {
            startRobotLiveActivity(action: action)
        }
    }

    func cancelAction(_ action: ActiveAction) {
        // End Live Activity if it's the robot
        if action.type == .robot {
            endRobotLiveActivity()
        }

        activeActions.removeAll { $0.id == action.id }
    }

    func startTaskAsAction(_ task: PoolcareTask, duration: TimeInterval) {
        guard let actionType = task.actionType else { return }

        // Task aus der Liste entfernen
        tasks.removeAll { $0.id == task.id }

        // Als Active Action starten
        startAction(actionType, duration: duration)
    }

    // MARK: - Live Activity Management

    private func startRobotLiveActivity(action: ActiveAction) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

        // Reset für erstes Update
        lastLiveActivityUpdate = .distantPast

        let attributes = RobotActivityAttributes(
            startTime: action.startTime,
            duration: action.duration,
            actionTitle: action.type.activeLabel
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
            print("Started robot Live Activity")

            // Schedule background refresh for Live Activity updates
            LiveActivityBackgroundManager.shared.scheduleBackgroundRefresh()
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func updateRobotLiveActivityIfNeeded() {
        guard let activity = robotActivity,
              let robotAction = activeActions.first(where: { $0.type == .robot }) else { return }

        // Nur alle 30 Sekunden aktualisieren (iOS drosselt zu häufige Updates)
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

        // Cancel background refresh since Live Activity is ending
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
            print("Ended robot Live Activity")
        }

        robotActivity = nil
    }

    var hasActiveActions: Bool {
        !activeActions.isEmpty
    }

    // MARK: - Zone 2: Task Methods

    func completeTask(_ task: PoolcareTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted = true
        tasks[index].completedAt = Date()

        let taskId = task.id
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            self.removeCompletedTask(taskId)
        }
    }

    private func removeCompletedTask(_ id: UUID) {
        tasks.removeAll { $0.id == id && $0.isCompleted }
    }

    func postponeTask(_ task: PoolcareTask, days: Int) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let newDue = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        tasks[index].dueDate = newDue
        tasks[index].subtitle = days == 0 ? "Verschoben auf heute" : "Verschoben auf morgen"
    }

    func addTask(title: String, subtitle: String) {
        let dueDate: Date?
        switch subtitle {
        case "Heute fällig":
            dueDate = Date()
        case "Morgen fällig":
            dueDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case "Wöchentlich":
            dueDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        case "Monatlich":
            dueDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        default:
            dueDate = Date()
        }

        let newTask = PoolcareTask(
            title: title,
            subtitle: subtitle,
            dueDate: dueDate
        )
        tasks.insert(newTask, at: 0)
    }

    // MARK: - Operating Mode Methods

    func switchMode(to newMode: OperatingMode) {
        let oldMode = currentMode

        // Gleicher Modus = nichts tun
        guard newMode != oldMode else { return }

        // Alte Transition-Tasks entfernen
        tasks.removeAll { $0.isTransitionTask }

        // Bei Wechsel zu Urlaub: vorherigen Modus speichern
        if newMode == .vacation {
            previousMode = oldMode
            vacationPhase = .before
            addVacationBeforeTasks()
        } else {
            // Bei Wechsel aus Urlaub zurück
            if oldMode == .vacation {
                vacationPhase = nil
                previousMode = nil
            }

            // Übergangs-Tasks hinzufügen
            if oldMode == .summer && newMode == .winter {
                addSummerToWinterTransitionTasks()
            } else if oldMode == .winter && newMode == .summer {
                addWinterToSummerTransitionTasks()
            }
        }

        currentMode = newMode
    }

    func advanceVacationPhase() {
        guard currentMode == .vacation else { return }

        switch vacationPhase {
        case .before:
            vacationPhase = .during
            // Vor-Abreise-Tasks entfernen
            tasks.removeAll { $0.visibility == .vacationBefore }
        case .during:
            vacationPhase = .after
            addVacationAfterTasks()
        case .after:
            // Zurück zum vorherigen Modus
            let returnMode = previousMode ?? .summer
            vacationPhase = nil
            previousMode = nil
            tasks.removeAll { $0.visibility == .vacationAfter }
            currentMode = returnMode
        case nil:
            break
        }
    }

    // MARK: - Transition Task Generators

    private func addSummerToWinterTransitionTasks() {
        let transitionTasks = [
            PoolcareTask(title: "Skimmer entleeren", subtitle: "Einwinterung", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Leitungen entleeren", subtitle: "Einwinterung", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Wintermittel hinzufügen", subtitle: "Einwinterung", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Abdeckung montieren", subtitle: "Einwinterung", dueDate: Date(), isTransitionTask: true)
        ]
        tasks.insert(contentsOf: transitionTasks, at: 0)
    }

    private func addWinterToSummerTransitionTasks() {
        let transitionTasks = [
            PoolcareTask(title: "Abdeckung entfernen", subtitle: "Saisonstart", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Pool gründlich reinigen", subtitle: "Saisonstart", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Filteranlage starten", subtitle: "Saisonstart", dueDate: Date(), isTransitionTask: true),
            PoolcareTask(title: "Stoßchlorung durchführen", subtitle: "Saisonstart", dueDate: Date(), isTransitionTask: true)
        ]
        tasks.insert(contentsOf: transitionTasks, at: 0)
    }

    private func addVacationBeforeTasks() {
        let vacationTasks = [
            PoolcareTask(title: "Chlorwert erhöhen", subtitle: "Vor Abreise", dueDate: Date(), visibility: .vacationBefore),
            PoolcareTask(title: "pH-Wert prüfen", subtitle: "Vor Abreise", dueDate: Date(), visibility: .vacationBefore),
            PoolcareTask(title: "Abdeckung sichern", subtitle: "Vor Abreise", dueDate: Date(), visibility: .vacationBefore),
            PoolcareTask(title: "Pumpen-Timer einstellen", subtitle: "Vor Abreise", dueDate: Date(), visibility: .vacationBefore)
        ]
        tasks.insert(contentsOf: vacationTasks, at: 0)
    }

    private func addVacationAfterTasks() {
        let returnTasks = [
            PoolcareTask(title: "Wasserwerte messen", subtitle: "Nach Rückkehr", dueDate: Date(), visibility: .vacationAfter),
            PoolcareTask(title: "Skimmer leeren", subtitle: "Nach Rückkehr", dueDate: Date(), visibility: .vacationAfter),
            PoolcareTask(title: "Pool bürsten", subtitle: "Nach Rückkehr", dueDate: Date(), visibility: .vacationAfter),
            PoolcareTask(title: "Filter rückspülen", subtitle: "Nach Rückkehr", dueDate: Date(), visibility: .vacationAfter)
        ]
        tasks.insert(contentsOf: returnTasks, at: 0)
    }

    // MARK: - Legacy Scenario Methods (kept for compatibility)

    func toggleVacationMode() {
        vacationScenario.isActive.toggle()
    }

    func toggleVacationItem(_ item: ScenarioChecklistItem, in phase: VacationPhase) {
        switch phase {
        case .before:
            if let index = vacationScenario.beforeChecklist.firstIndex(where: { $0.id == item.id }) {
                vacationScenario.beforeChecklist[index].isCompleted.toggle()
            }
        case .during:
            break
        case .after:
            if let index = vacationScenario.afterChecklist.firstIndex(where: { $0.id == item.id }) {
                vacationScenario.afterChecklist[index].isCompleted.toggle()
            }
        }
    }

    func toggleSeasonMode() {
        seasonScenario.currentMode = seasonScenario.currentMode == .summer ? .winter : .summer
    }

    func toggleSeasonItem(_ item: ScenarioChecklistItem, in phase: SeasonPhase) {
        switch phase {
        case .opening:
            if let index = seasonScenario.openingChecklist.firstIndex(where: { $0.id == item.id }) {
                seasonScenario.openingChecklist[index].isCompleted.toggle()
            }
        case .closing:
            if let index = seasonScenario.closingChecklist.firstIndex(where: { $0.id == item.id }) {
                seasonScenario.closingChecklist[index].isCompleted.toggle()
            }
        }
    }
}
