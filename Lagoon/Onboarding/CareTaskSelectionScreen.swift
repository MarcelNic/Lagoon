import SwiftUI

struct CareTaskSelectionScreen: View {
    var action: () -> Void

    @AppStorage("selectedCareTasks") private var selectedCareTasksData: Data = Data()

    @State private var selectedTasks: Set<String> = []

    private let careTasks: [Chip] = [
        Chip(title: "Roboter", icon: "figure.pool.swim", color: .cyan),
        Chip(title: "Skimmer leeren", icon: "tray.fill", color: .blue),
        Chip(title: "Rückspülen", icon: "arrow.trianglehead.2.clockwise.rotate.90", color: .cyan),
        Chip(title: "Käschern", icon: "leaf.fill", color: .teal),
        Chip(title: "Wasser nachfüllen", icon: "spigot.fill", color: .blue),
    ]

    var body: some View {
        SelectionView(
            chips: careTasks,
            title: "Deine Aufgaben.",
            subtitle: "Weitere Aufgaben können später hinzugefügt werden.",
            buttonTitle: "Fertigstellen",
            preselectedTitles: [],
            action: {
                saveTasks()
                action()
            },
            onSelectionChange: { selected in
                selectedTasks = Set(selected)
            }
        )
    }

    private func saveTasks() {
        let tasksToSave = Array(selectedTasks)
        if let encoded = try? JSONEncoder().encode(tasksToSave) {
            selectedCareTasksData = encoded
        }
    }
}

#Preview {
    CareTaskSelectionScreen(action: {})
}
