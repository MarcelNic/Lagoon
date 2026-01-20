//
//  ChemistryColors.swift
//  Lagoon
//
//  Created by Marcel Nicaeus on 20.01.26.
//

import SwiftUI

extension Color {
    // MARK: - pH Farben

    /// pH Bar Farbe (adaptiv)
    static let phBarColor = Color(light: Color(hex: "43aef5"), dark: Color(hex: "354d82"))

    /// pH Ideal Range Farbe (adaptiv)
    static let phIdealColor = Color(light: Color(hex: "70fbf8"), dark: Color(hex: "65bbf7"))

    // MARK: - Chlor Farben

    /// Chlor Bar Farbe (adaptiv)
    static let chlorineBarColor = Color(light: Color(hex: "34c759").opacity(0.4), dark: Color(hex: "30d158").opacity(0.4))

    /// Chlor Ideal Range Farbe (adaptiv)
    static let chlorineIdealColor = Color(light: Color(hex: "5ef66d"), dark: Color(hex: "5ef66d"))

    // MARK: - Helpers

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        (r, g, b) = (int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}
