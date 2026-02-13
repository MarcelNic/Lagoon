import SwiftUI

struct CareTaskSelectionScreen: View {
    var action: () -> Void

    @AppStorage("selectedCareTasks") private var selectedCareTasksData: Data = Data()

    @State private var selectedTasks: Set<String> = []

    private let careTasks: [Chip] = [
        Chip(title: "Roboter", icon: "figure.pool.swim", color: .cyan),
        Chip(title: "Skimmer leeren", icon: "tray.fill", color: .blue),
        Chip(title: "Wasserlinie bürsten", icon: "bubbles.and.sparkles", color: .teal),
        Chip(title: "Boden saugen", icon: "water.waves", color: .indigo),
        Chip(title: "Rückspülen", icon: "arrow.trianglehead.2.clockwise.rotate.90", color: .cyan),
        Chip(title: "Filterdruck prüfen", icon: "gauge.medium", color: .orange),
        Chip(title: "Pumpenkorb leeren", icon: "basket.fill", color: .purple),
        Chip(title: "Wasserstand prüfen", icon: "ruler.fill", color: .green),
        Chip(title: "Abdeckung prüfen", icon: "shield.fill", color: .brown),
        Chip(title: "Pool bürsten", icon: "paintbrush.fill", color: .mint),
        Chip(title: "Leiter reinigen", icon: "stairs", color: .gray)
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
