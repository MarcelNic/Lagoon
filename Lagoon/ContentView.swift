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
                colors: [
                    Color(red: 0xAF/255, green: 0xB9/255, blue: 0xFC/255), // #AFB9FC oben
                    Color(red: 0xFE/255, green: 0xDF/255, blue: 0xCE/255)  // #FEDFCE mitte/unten
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
