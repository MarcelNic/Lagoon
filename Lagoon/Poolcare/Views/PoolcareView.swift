//
//  PoolcareView.swift
//  Lagoon
//

import SwiftUI

struct PoolcareView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var poolcareState = PoolcareState()
    @State private var showVacationSheet = false
    @State private var showSeasonSheet = false
    @State private var showAddSheet = false

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
            .scaleEffect(1.2)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    ActiveActionsZone(state: poolcareState)

                    TaskListZone(state: poolcareState)

                    ScenarioZone(
                        state: poolcareState,
                        showVacationSheet: $showVacationSheet,
                        showSeasonSheet: $showSeasonSheet
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
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

                Text("Poolcare")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Button {
                    showAddSheet = true
                } label: {
                    Image(systemName: "plus")
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
        .sheet(isPresented: $showVacationSheet) {
            ScenarioDetailSheet(type: .vacation, state: poolcareState)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showSeasonSheet) {
            ScenarioDetailSheet(type: .season, state: poolcareState)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showAddSheet) {
            AddItemSheet(state: poolcareState)
                .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    NavigationStack {
        PoolcareView()
    }
}
