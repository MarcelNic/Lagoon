//
//  LogbookListView.swift
//  Lagoon
//

import SwiftUI

struct LogbookListView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var state: MeinPoolState

    @State private var entryToEdit: LogbookEntry?
    @State private var showMessenSheet = false
    @State private var showDosierenSheet = false
    @State private var showPflegeSheet = false

    private var sortedEntries: [LogbookEntry] {
        state.entries.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            ForEach(sortedEntries) { entry in
                Button {
                    entryToEdit = entry
                    switch entry.type {
                    case .messen: showMessenSheet = true
                    case .dosieren: showDosierenSheet = true
                    case .poolpflege: showPflegeSheet = true
                    }
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
            }
        }
        .contentMargins(.bottom, 80)
        .listStyle(.insetGrouped)
        .navigationTitle("Einträge")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showMessenSheet) {
            EditMessenSheet(entry: entryToEdit, state: state)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showDosierenSheet) {
            EditDosierenSheet(entry: entryToEdit, state: state)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showPflegeSheet) {
            if let entry = entryToEdit {
                LogbookEditSheet(entry: entry, state: state)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

#Preview {
    NavigationStack {
        LogbookListView(state: MeinPoolState())
    }
}
