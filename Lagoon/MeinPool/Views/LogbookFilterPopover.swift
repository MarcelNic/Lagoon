//
//  LogbookFilterPopover.swift
//  Lagoon
//

import SwiftUI

struct LogbookFilterPopover: View {
    @Bindable var state: MeinPoolState

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filter")
                .font(.headline)

            Toggle(isOn: $state.filterMessen) {
                Label("Messungen", systemImage: "testtube.2")
            }

            Toggle(isOn: $state.filterDosieren) {
                Label("Dosierungen", systemImage: "aqi.medium")
            }

            Toggle(isOn: $state.filterPoolpflege) {
                Label("Pflege", systemImage: "checklist")
            }
        }
        .padding()
        .frame(width: 240)
    }
}

#Preview {
    LogbookFilterPopover(state: MeinPoolState())
}
