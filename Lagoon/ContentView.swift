//
//  ContentView.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 11.01.26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0xAF/255, green: 0xB9/255, blue: 0xFC/255), location: 0),    // #AFB9FC oben
                    .init(color: Color(red: 0xFF/255, green: 0xC9/255, blue: 0xAA/255), location: 0.5),  // #FFC9AA mitte
                    .init(color: Color(red: 0xFF/255, green: 0xC9/255, blue: 0xAA/255), location: 1)     // #FFC9AA unten
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            WaveView()
                .ignoresSafeArea()

            VStack {
                Image(systemName: "drop.fill")
                    .imageScale(.large)
                    .foregroundStyle(.white)
                Text("Lagoon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
