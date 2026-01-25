//
//  LogbookZone.swift
//  Lagoon
//

import SwiftUI

struct LogbookSection: View {
    @Bindable var state: MeinPoolState
    @Binding var selectedEntry: LogbookEntry?

    private var sortedEntries: [LogbookEntry] {
        state.filteredEntries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        Section {
            if state.filteredEntries.isEmpty {
                emptyState
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            } else {
                ForEach(Array(sortedEntries.enumerated()), id: \.element.id) { index, entry in
                    Button {
                        selectedEntry = entry
                    } label: {
                        LogbookEntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            state.deleteEntry(entry)
                        } label: {
                            Label("Löschen", systemImage: "trash")
                        }
                    }
                    .listRowBackground(
                        RoundedCornerBackground(
                            isFirst: index == 0,
                            isLast: index == sortedEntries.count - 1
                        )
                    )
                    .listRowSeparator(.hidden)
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
        } header: {
            HStack {
                Text("Logbuch")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.5))
                    .textCase(.uppercase)

                Spacer()

                Menu {
                    Button {
                        state.filterMessen.toggle()
                    } label: {
                        Label("Messungen", systemImage: state.filterMessen ? "checkmark" : "")
                    }

                    Button {
                        state.filterDosieren.toggle()
                    } label: {
                        Label("Dosierungen", systemImage: state.filterDosieren ? "checkmark" : "")
                    }

                    Button {
                        state.filterPoolpflege.toggle()
                    } label: {
                        Label("Pflege", systemImage: state.filterPoolpflege ? "checkmark" : "")
                    }
                } label: {
                    Image(systemName: filterIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.clear.interactive(), in: .circle)
            }
            .padding(.horizontal, 4)
            .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
        }
    }

    private var filterIcon: String {
        state.activeFilterCount < 3 ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease"
    }

    @ViewBuilder
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.3))

            Text("Keine Einträge")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(light: Color.black, dark: Color.white).opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Rounded Corner Background

struct RoundedCornerBackground: View {
    let isFirst: Bool
    let isLast: Bool

    private let cornerRadius: CGFloat = 16

    private var shape: UnevenRoundedRectangle {
        .rect(
            topLeadingRadius: isFirst ? cornerRadius : 0,
            bottomLeadingRadius: isLast ? cornerRadius : 0,
            bottomTrailingRadius: isLast ? cornerRadius : 0,
            topTrailingRadius: isFirst ? cornerRadius : 0
        )
    }

    var body: some View {
        Rectangle()
            .fill(.clear)
            .glassEffect(.clear.interactive(), in: shape)
            .overlay(alignment: .bottom) {
                if !isLast {
                    Divider()
                        .background(Color(light: Color.black, dark: Color.white).opacity(0.15))
                        .padding(.leading, 42)
                }
            }
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [
                Color(light: .white, dark: Color(hex: "0a1628")),
                Color(light: Color(hex: "111184"), dark: Color(hex: "1a3a5c"))
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        List {
            LogbookSection(state: MeinPoolState(), selectedEntry: .constant(nil))
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
}
