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
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -90, to: Date()) ?? Date()

        // Load measurements (last 90 days, max 200)
        var measurementDescriptor = FetchDescriptor<Measurement>(
            predicate: #Predicate { $0.timestamp > cutoffDate },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        measurementDescriptor.fetchLimit = 200
        if let measurements = try? context.fetch(measurementDescriptor) {
            allEntries.append(contentsOf: measurements.map { $0.toLogbookEntry() })
        }

        // Load dosing events (last 90 days, max 200)
        var dosingDescriptor = FetchDescriptor<DosingEventModel>(
            predicate: #Predicate { $0.timestamp > cutoffDate },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        dosingDescriptor.fetchLimit = 200
        if let dosings = try? context.fetch(dosingDescriptor) {
            let dosingUnit = UserDefaults.standard.string(forKey: "dosingUnit") ?? "gramm"
            let cupGrams = UserDefaults.standard.double(forKey: "cupGrams")
            let effectiveCupGrams = cupGrams > 0 ? cupGrams : 50.0

            // Group by exact timestamp — simultaneous dosings (pH + Chlor) share the same timestamp
            let grouped = Dictionary(grouping: dosings, by: { $0.timestamp })
            for (timestamp, group) in grouped {
                let items = group.map { d in
                    DosingItem(productId: d.productId, productName: d.productName, amount: d.amount, unit: d.unit)
                }
                let summaryParts = items.map { item in
                    "\(item.shortName) \(DosingFormatter.format(grams: item.amount, unit: dosingUnit, cupGrams: effectiveCupGrams))"
                }
                let entry = LogbookEntry(
                    type: .dosieren,
                    timestamp: timestamp,
                    summary: summaryParts.joined(separator: " · "),
                    dosings: items
                )
                allEntries.append(entry)
            }
        }

        // Load care tasks (last 90 days, max 200)
        var careTaskDescriptor = FetchDescriptor<CareTaskModel>(
            predicate: #Predicate { $0.timestamp > cutoffDate },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        careTaskDescriptor.fetchLimit = 200
        if let tasks = try? context.fetch(careTaskDescriptor) {
            allEntries.append(contentsOf: tasks.map { $0.toLogbookEntry() })
        }

        // Sort all entries by timestamp (most recent first)
        self.entries = allEntries.sorted { $0.timestamp > $1.timestamp }
    }

    // MARK: - Chart Data

    func phChartData(in range: ChartTimeRange) -> [ChartDataPoint] {
        chartData(in: range, keyPath: \.phValue)
    }

    func chlorineChartData(in range: ChartTimeRange) -> [ChartDataPoint] {
        chartData(in: range, keyPath: \.chlorineValue)
    }

    func temperatureChartData(in range: ChartTimeRange) -> [ChartDataPoint] {
        chartData(in: range, keyPath: \.waterTemperature)
    }

    /// Build chart data with a carry-forward point at the range start
    private func chartData(in range: ChartTimeRange, keyPath: KeyPath<LogbookEntry, Double?>) -> [ChartDataPoint] {
        let measurements = entries
            .filter { $0.type == .messen && $0[keyPath: keyPath] != nil }
            .sorted { $0.timestamp < $1.timestamp }

        var points: [ChartDataPoint] = []

        // Find the last measurement before the range to anchor the line at the left edge
        let lastBefore = measurements.last { $0.timestamp < range.startDate }
        if let anchor = lastBefore, let value = anchor[keyPath: keyPath] {
            points.append(ChartDataPoint(timestamp: range.startDate, value: value))
        }

        // Add all measurements within the range
        for entry in measurements where entry.timestamp >= range.startDate {
            if let value = entry[keyPath: keyPath] {
                points.append(ChartDataPoint(timestamp: entry.timestamp, value: value))
            }
        }

        return points
    }

    // MARK: - Methods

    func updateEntry(_ updatedEntry: LogbookEntry) {
        guard let index = entries.firstIndex(where: { $0.id == updatedEntry.id }) else { return }
        entries[index] = updatedEntry

        if updatedEntry.type == .dosieren {
            updateDosingInSwiftData(updatedEntry)
        }
    }

    private func updateDosingInSwiftData(_ entry: LogbookEntry) {
        guard let context = modelContext else { return }
        let timestamp = entry.timestamp
        let descriptor = FetchDescriptor<DosingEventModel>(
            predicate: #Predicate { $0.timestamp == timestamp }
        )
        guard let models = try? context.fetch(descriptor) else { return }
        for item in entry.dosings {
            if let match = models.first(where: { $0.productId == item.productId }) {
                match.amount = item.amount
                match.productId = item.productId
                match.productName = item.productName
            }
        }
        try? context.save()
    }

    func deleteEntry(_ entry: LogbookEntry) {
        entries.removeAll { $0.id == entry.id }
        deleteFromSwiftData(entry)
    }

    private func deleteFromSwiftData(_ entry: LogbookEntry) {
        guard let context = modelContext else { return }

        let timestamp = entry.timestamp

        switch entry.type {
        case .messen:
            let descriptor = FetchDescriptor<Measurement>(
                predicate: #Predicate { $0.timestamp == timestamp }
            )
            if let match = try? context.fetch(descriptor).first {
                context.delete(match)
            }
        case .dosieren:
            let descriptor = FetchDescriptor<DosingEventModel>(
                predicate: #Predicate { $0.timestamp == timestamp }
            )
            if let matches = try? context.fetch(descriptor) {
                matches.forEach { context.delete($0) }
            }
        case .poolpflege:
            let descriptor = FetchDescriptor<CareTaskModel>(
                predicate: #Predicate { $0.timestamp == timestamp }
            )
            if let match = try? context.fetch(descriptor).first {
                context.delete(match)
            }
        }

        try? context.save()
    }

}
