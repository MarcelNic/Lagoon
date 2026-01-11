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
            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    .blue, .cyan, .teal,
                    .cyan, .mint, .cyan,
                    .teal, .cyan, .blue
                ]
            )
            .ignoresSafeArea()

            VStack {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.white)
                Text("Hello, world!")
                    .foregroundStyle(.white)
            }
            .padding()
        }
    }
}

#Preview {
    ContentView()
}
