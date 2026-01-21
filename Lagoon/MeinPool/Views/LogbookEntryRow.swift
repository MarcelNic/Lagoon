//
//  LogbookEntryRow.swift
//  Lagoon
//

import SwiftUI

struct LogbookEntryRow: View {
    let entry: LogbookEntry

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: entry.type.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(entry.type.color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.rawValue)
                    .font(.system(size: 16, weight: .medium))

                Text(entry.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(relativeTime)
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }

    private var relativeTime: String {
        let calendar = Calendar.current
        let now = Date()

        if calendar.isDateInToday(entry.timestamp) {
            let hours = calendar.dateComponents([.hour], from: entry.timestamp, to: now).hour ?? 0
            if hours < 1 {
                return "gerade eben"
            } else if hours == 1 {
                return "vor 1 Std."
            } else {
                return "vor \(hours) Std."
            }
        } else if calendar.isDateInYesterday(entry.timestamp) {
            return "gestern"
        } else {
            let days = calendar.dateComponents([.day], from: entry.timestamp, to: now).day ?? 0
            if days < 7 {
                return "vor \(days) Tagen"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "d. MMM"
                formatter.locale = Locale(identifier: "de_DE")
                return formatter.string(from: entry.timestamp)
            }
        }
    }
}

#Preview {
    List {
        Section("Heute") {
            LogbookEntryRow(entry: LogbookEntry.sampleEntries()[0])
            LogbookEntryRow(entry: LogbookEntry.sampleEntries()[1])
        }
        Section("Diese Woche") {
            LogbookEntryRow(entry: LogbookEntry.sampleEntries()[2])
        }
    }
    .listStyle(.insetGrouped)
}
