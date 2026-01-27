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

    // MARK: - Zone 2: Tasks

    private(set) var tasks: [PoolcareTask] = []

    var pendingTasks: [PoolcareTask] {
        tasks
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
        tasks
            .filter { $0.isCompleted }
            .filter { task in
                guard let completedAt = task.completedAt else { return false }
                return Date().timeIntervalSince(completedAt) < 5
            }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // MARK: - Zone 3: Scenarios

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

    private func startTimerUpdates() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                self?.timerTick = date
                self?.checkExpiredActions()
                self?.updateRobotLiveActivity()
            }
    }

    private func checkExpiredActions() {
        let expiredActions = activeActions.filter { $0.isExpired }

        for action in expiredActions {
            // End Live Activity for robot when timer expires
            if action.type == .robot {
                endRobotLiveActivity()
            }

            let followUp = action.type.followUpTask
            let newTask = PoolcareTask(
                title: followUp.title,
                subtitle: followUp.subtitle,
                dueDate: Date(),
                generatedFromActionId: action.id
            )
            tasks.insert(newTask, at: 0)

            activeActions.removeAll { $0.id == action.id }
        }
    }

    // MARK: - Zone 1: Action Methods

    func startAction(_ type: ActionType) {
        let action = ActiveAction(type: type)
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

    // MARK: - Live Activity Management

    private func startRobotLiveActivity(action: ActiveAction) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities are not enabled")
            return
        }

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
        } catch {
            print("Failed to start Live Activity: \(error)")
        }
    }

    private func updateRobotLiveActivity() {
        guard let activity = robotActivity,
              let robotAction = activeActions.first(where: { $0.type == .robot }) else { return }

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

    // MARK: - Zone 3: Scenario Methods

    func toggleVacationMode() {
        vacationScenario.isActive.toggle()
    }

    func toggleVacationItem(_ item: ScenarioChecklistItem, in phase: VacationPhase) {
        switch phase {
        case .before:
            if let index = vacationScenario.beforeChecklist.firstIndex(where: { $0.id == item.id }) {
                vacationScenario.beforeChecklist[index].isCompleted.toggle()
            }
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
