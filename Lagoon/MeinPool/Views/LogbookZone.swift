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
        VStack(spacing: 0) {
            // Section header
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
            .padding(.bottom, 12)

            // Logbook entries
            if state.filteredEntries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(sortedEntries) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            LogbookEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    state.deleteEntry(entry)
                                }
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.visible)
                        .listRowSeparatorTint(Color(light: Color.black, dark: Color.white).opacity(0.1))
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: CGFloat(sortedEntries.count) * 61)
                .clipShape(.rect(cornerRadius: 20))
                .glassEffect(.clear, in: .rect(cornerRadius: 20))
            }
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
        .glassEffect(.clear, in: .rect(cornerRadius: 20))
    }
}

#Preview {
    ZStack {
        LinearGradient(
            stops: [
                .init(color: Color(light: Color(hex: "0443a6"), dark: Color(hex: "0a1628")), location: 0.0),
                .init(color: Color(light: Color(hex: "b2e1ec"), dark: Color(hex: "1a3a5c")), location: 0.5),
                .init(color: Color(light: Color(hex: "2fb4a0"), dark: Color(hex: "1a3a5c")), location: 1.0)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
            LogbookSection(state: MeinPoolState(), selectedEntry: .constant(nil))
                .padding(20)
        }
    }
}
