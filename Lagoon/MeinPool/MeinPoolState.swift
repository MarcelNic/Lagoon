//
//  MeinPoolState.swift
//  Lagoon
//

import SwiftUI

@Observable
final class MeinPoolState {

    // MARK: - Pool Info

    var location: String = "Stuttgart"
    var waterTemperature: String = "24 °C"
    var weather: String = "Bewölkt"

    // MARK: - Logbook Entries

    private(set) var entries: [LogbookEntry] = []

    // MARK: - Filter State

    var filterMessen: Bool = true
    var filterDosieren: Bool = true
    var filterPoolpflege: Bool = true

    // MARK: - Undo State

    private(set) var recentlyDeletedEntry: LogbookEntry?
    private(set) var showUndoToast: Bool = false

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
        self.entries = LogbookEntry.sampleEntries()
    }

    // MARK: - Methods

    func updateEntry(_ updatedEntry: LogbookEntry) {
        guard let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) else { return }
        entries[index] = updatedEntry
    }

    func deleteEntry(_ entry: LogbookEntry) {
        recentlyDeletedEntry = entry
        entries.removeAll { $0.id == entry.id }
        showUndoToast = true

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
