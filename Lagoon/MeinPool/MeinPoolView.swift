//
//  MeinPoolView.swift
//  Lagoon
//

import SwiftUI

struct MeinPoolView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("poolName") private var poolName: String = "Pool"
    @State private var meinPoolState = MeinPoolState()
    @State private var showSettings = false
    @State private var selectedEntry: LogbookEntry?

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(hex: "0a1628"),
                    Color(hex: "1a3a5c")
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    PoolIdentityCard(
                        poolName: poolName,
                        isVacationModeActive: false
                    )

                    InfoPillsRow(state: meinPoolState)

                    LogbookZone(
                        state: meinPoolState,
                        selectedEntry: $selectedEntry
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }

            // Undo toast
            if meinPoolState.showUndoToast {
                VStack {
                    Spacer()
                    UndoToast(
                        message: "Eintrag gelöscht",
                        onUndo: {
                            meinPoolState.undoDelete()
                        },
                        onDismiss: {
                            meinPoolState.dismissUndoToast()
                        }
                    )
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.snappy, value: meinPoolState.showUndoToast)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)

                Spacer()

                Text("Mein Pool")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                }
                .glassEffect(.regular.interactive(), in: .circle)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedEntry) { entry in
            LogbookEditSheet(entry: entry, state: meinPoolState)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Undo Toast

struct UndoToast: View {
    let message: String
    let onUndo: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)

            Button {
                onUndo()
            } label: {
                Text("Rückgängig")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .glassEffect(.regular, in: .capsule)
    }
}

#Preview {
    NavigationStack {
        MeinPoolView()
    }
}
