//
//  LogbookZone.swift
//  Lagoon
//

import SwiftUI

struct LogbookZone: View {
    @Bindable var state: MeinPoolState
    @Binding var selectedEntry: LogbookEntry?
    @State private var showFilterPopover = false

    var body: some View {
        VStack(spacing: 0) {
            // Section header with filter button
            HStack {
                Text("Logbuch")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)

                Spacer()

                Button {
                    showFilterPopover = true
                } label: {
                    Image(systemName: filterIcon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)
                .popover(isPresented: $showFilterPopover) {
                    LogbookFilterPopover(state: state)
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Native List
            if state.filteredEntries.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(state.filteredEntries.sorted { $0.timestamp > $1.timestamp }) { entry in
                        Button {
                            selectedEntry = entry
                        } label: {
                            LogbookEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                state.deleteEntry(entry)
                            } label: {
                                Label("Löschen", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(minHeight: CGFloat(state.filteredEntries.count * 56))
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
                .foregroundStyle(.white.opacity(0.3))

            Text("Keine Einträge")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [Color(hex: "0a1628"), Color(hex: "1a3a5c")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()

        ScrollView {
            LogbookZone(state: MeinPoolState(), selectedEntry: .constant(nil))
                .padding(.horizontal, 20)
        }
    }
}
