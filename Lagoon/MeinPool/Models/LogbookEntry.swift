//
//  LogbookEntry.swift
//  Lagoon
//

import SwiftUI

enum LogbookEntryType: String, CaseIterable, Identifiable {
    case messen = "Messung"
    case dosieren = "Dosierung"
    case poolpflege = "Pflege"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .messen: return "testtube.2"
        case .dosieren: return "aqi.medium"
        case .poolpflege: return "checklist"
        }
    }

    var color: Color {
        switch self {
        case .messen: return Color(light: Color(hex: "0AAAC6"), dark: Color(hex: "42edfe"))
        case .dosieren: return Color(light: Color(hex: "1FBF4A"), dark: Color(hex: "5df66d"))
        case .poolpflege: return .orange
        }
    }
}

struct LogbookEntry: Identifiable, Equatable {
    let id: UUID
    var type: LogbookEntryType
    var timestamp: Date
    var summary: String

    // Messen fields
    var phValue: Double?
    var chlorineValue: Double?
    var waterTemperature: Double?

    // Dosieren fields
    var product: String?
    var amount: Double?
    var unit: String?

    // Poolpflege fields
    var description: String?

    init(
        id: UUID = UUID(),
        type: LogbookEntryType,
        timestamp: Date = Date(),
        summary: String,
        phValue: Double? = nil,
        chlorineValue: Double? = nil,
        waterTemperature: Double? = nil,
        product: String? = nil,
        amount: Double? = nil,
        unit: String? = nil,
        description: String? = nil
    ) {
        self.id = id
        self.type = type
        self.timestamp = timestamp
        self.summary = summary
        self.phValue = phValue
        self.chlorineValue = chlorineValue
        self.waterTemperature = waterTemperature
        self.product = product
        self.amount = amount
        self.unit = unit
        self.description = description
    }
}

enum LogbookTimeGroup: String, CaseIterable {
    case heute = "Heute"
    case dieseWoche = "Diese Woche"
    case aelter = "Älter"
}

extension LogbookEntry {
    static func sampleEntries() -> [LogbookEntry] {
        let calendar = Calendar.current
        let now = Date()

        return [
            // Heute
            LogbookEntry(
                type: .messen,
                timestamp: calendar.date(byAdding: .hour, value: -2, to: now)!,
                summary: "pH 7,2 · Cl 1,5 mg/l",
                phValue: 7.2,
                chlorineValue: 1.5,
                waterTemperature: 24.0
            ),
            LogbookEntry(
                type: .dosieren,
                timestamp: calendar.date(byAdding: .hour, value: -5, to: now)!,
                summary: "50 g pH-Minus",
                product: "pH-Minus",
                amount: 50,
                unit: "g"
            ),
            // Diese Woche
            LogbookEntry(
                type: .poolpflege,
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                summary: "Skimmer geleert",
                description: "Skimmer geleert"
            ),
            LogbookEntry(
                type: .messen,
                timestamp: calendar.date(byAdding: .day, value: -3, to: now)!,
                summary: "pH 7,4 · Cl 1,2 mg/l",
                phValue: 7.4,
                chlorineValue: 1.2,
                waterTemperature: 23.0
            ),
            LogbookEntry(
                type: .dosieren,
                timestamp: calendar.date(byAdding: .day, value: -4, to: now)!,
                summary: "200 g Chlorgranulat",
                product: "Chlorgranulat",
                amount: 200,
                unit: "g"
            ),
            // Älter
            LogbookEntry(
                type: .poolpflege,
                timestamp: calendar.date(byAdding: .day, value: -10, to: now)!,
                summary: "Wasserlinie gebürstet",
                description: "Wasserlinie gebürstet"
            ),
            LogbookEntry(
                type: .messen,
                timestamp: calendar.date(byAdding: .day, value: -12, to: now)!,
                summary: "pH 7,6 · Cl 0,8 mg/l",
                phValue: 7.6,
                chlorineValue: 0.8,
                waterTemperature: 22.0
            )
        ]
    }
}

// MARK: - SwiftData Model Conversions

extension Measurement {
    /// Convert SwiftData Measurement to LogbookEntry
    func toLogbookEntry() -> LogbookEntry {
        LogbookEntry(
            type: .messen,
            timestamp: timestamp,
            summary: summary,
            phValue: pH,
            chlorineValue: chlorine,
            waterTemperature: waterTemperature
        )
    }
}

extension DosingEventModel {
    /// Convert SwiftData DosingEventModel to LogbookEntry
    func toLogbookEntry() -> LogbookEntry {
        let dosingUnit = UserDefaults.standard.string(forKey: "dosingUnit") ?? "gramm"
        let cupGrams = UserDefaults.standard.double(forKey: "cupGrams")
        let effectiveCupGrams = cupGrams > 0 ? cupGrams : 50.0
        let formattedAmount = DosingFormatter.format(grams: amount, unit: dosingUnit, cupGrams: effectiveCupGrams)

        return LogbookEntry(
            type: .dosieren,
            timestamp: timestamp,
            summary: "\(formattedAmount) \(productName)",
            product: productName,
            amount: amount,
            unit: unit
        )
    }
}

extension CareTaskModel {
    /// Convert SwiftData CareTaskModel to LogbookEntry
    func toLogbookEntry() -> LogbookEntry {
        LogbookEntry(
            type: .poolpflege,
            timestamp: timestamp,
            summary: summary,
            description: taskDescription
        )
    }
}
