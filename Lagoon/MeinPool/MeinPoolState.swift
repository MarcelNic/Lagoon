//
//  MeinPoolState.swift
//  Lagoon
//

import SwiftUI
import SwiftData

@Observable
final class MeinPoolState {

    // MARK: - Pool Info

    var location: String = "Stuttgart"
    var waterTemperature: String = "24 °C"
    var weather: String = "Bewölkt"

    // MARK: - Logbook Entries (combined from SwiftData)

    private(set) var entries: [LogbookEntry] = []

    // MARK: - Filter State

    var filterMessen: Bool = true
    var filterDosieren: Bool = true
    var filterPoolpflege: Bool = true

    // MARK: - Undo State

    private(set) var recentlyDeletedEntry: LogbookEntry?
    private(set) var showUndoToast: Bool = false

    // MARK: - SwiftData Context

    private var modelContext: ModelContext?

    // MARK: - Computed Properties

    var filteredEntries: [LogbookEntry] {
        entries.filter { entry in
            switch entry.type {
            case .messen: return filterMessen
            case .dosieren: return filterDosieren
            case .poolpflege: return filterPoolpflege
            }
        }
    }

    var groupedEntries: [(LogbookTimeGroup, [LogbookEntry])] {
        let calendar = Calendar.current
        let now = Date()

        var heute: [LogbookEntry] = []
        var dieseWoche: [LogbookEntry] = []
        var aelter: [LogbookEntry] = []

        for entry in filteredEntries {
            if calendar.isDateInToday(entry.timestamp) {
                heute.append(entry)
            } else if calendar.isDate(entry.timestamp, equalTo: now, toGranularity: .weekOfYear) {
                dieseWoche.append(entry)
            } else {
                aelter.append(entry)
            }
        }

        var result: [(LogbookTimeGroup, [LogbookEntry])] = []
        if !heute.isEmpty {
            result.append((.heute, heute.sorted { $0.timestamp > $1.timestamp }))
        }
        if !dieseWoche.isEmpty {
            result.append((.dieseWoche, dieseWoche.sorted { $0.timestamp > $1.timestamp }))
        }
        if !aelter.isEmpty {
            result.append((.aelter, aelter.sorted { $0.timestamp > $1.timestamp }))
        }
        return result
    }

    var activeFilterCount: Int {
        [filterMessen, filterDosieren, filterPoolpflege].filter { $0 }.count
    }

    // MARK: - Initialization

    init() {
        // Sample data for preview, will be replaced by SwiftData
    }

    // MARK: - SwiftData Integration

    /// Set the model context from environment
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadFromSwiftData()
    }

    /// Reload entries from SwiftData
    func loadFromSwiftData() {
        guard let context = modelContext else {
            // Fall back to sample data if no context
            self.entries = LogbookEntry.sampleEntries()
            return
        }

        var allEntries: [LogbookEntry] = []

        // Load measurements
        let measurementDescriptor = FetchDescriptor<Measurement>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let measurements = try? context.fetch(measurementDescriptor) {
            allEntries.append(contentsOf: measurements.map { $0.toLogbookEntry() })
        }

        // Load dosing events
        let dosingDescriptor = FetchDescriptor<DosingEventModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let dosings = try? context.fetch(dosingDescriptor) {
            allEntries.append(contentsOf: dosings.map { $0.toLogbookEntry() })
        }

        // Load care tasks
        let careTaskDescriptor = FetchDescriptor<CareTaskModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let tasks = try? context.fetch(careTaskDescriptor) {
            allEntries.append(contentsOf: tasks.map { $0.toLogbookEntry() })
        }

        // Sort all entries by timestamp (most recent first)
        self.entries = allEntries.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Methods

    func updateEntry(_ updatedEntry: LogbookEntry) {
        guard let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) else { return }
        entries[index] = updatedEntry

        // Note: In a full implementation, we would also update the corresponding SwiftData model
        // This requires tracking which model each LogbookEntry came from
    }

    func deleteEntry(_ entry: LogbookEntry) {
        recentlyDeletedEntry = entry
        entries.removeAll { $0.id == entry.id }
        showUndoToast = true

        // Note: In a full implementation, we would also delete from SwiftData

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            self.dismissUndoToast()
        }
    }

    func undoDelete() {
        guard let entry = recentlyDeletedEntry else { return }
        entries.append(entry)
        entries.sort { $0.timestamp > $1.timestamp }
        recentlyDeletedEntry = nil
        showUndoToast = false
    }

    func dismissUndoToast() {
        showUndoToast = false
        recentlyDeletedEntry = nil
    }
}
