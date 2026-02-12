//
//  TimerPickerSheet.swift
//  Lagoon
//

import SwiftUI

struct TimerPickerSheet: View {
    let title: String
    let iconName: String?
    let isCustomIcon: Bool
    let defaultDuration: Double
    let onStart: (TimeInterval) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hours: Int
    @State private var minutes: Int

    init(
        title: String,
        iconName: String?,
        isCustomIcon: Bool,
        defaultDuration: Double,
        onStart: @escaping (TimeInterval) -> Void
    ) {
        self.title = title
        self.iconName = iconName
        self.isCustomIcon = isCustomIcon
        self.defaultDuration = defaultDuration
        self.onStart = onStart
        let secs = Int(defaultDuration)
        _hours = State(initialValue: secs / 3600)
        _minutes = State(initialValue: (secs % 3600) / 60)
    }

    private var totalSeconds: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    TaskIconView(iconName: iconName, isCustomIcon: isCustomIcon, size: 44)
                        .foregroundStyle(.tint)
                    Text(title)
                        .font(.title3.weight(.semibold))
                }
                .padding(.top)

                HStack(spacing: 0) {
                    Picker("Stunden", selection: $hours) {
                        ForEach(0..<24) { Text("\($0) h").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    Picker("Minuten", selection: $minutes) {
                        ForEach(0..<60) { Text("\($0) m").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }
                .frame(height: 150)

                Spacer()
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onStart(totalSeconds)
                    dismiss()
                } label: {
                    Text("Starten")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(totalSeconds == 0)
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
}
