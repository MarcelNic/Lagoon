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
    static let phBarColor = Color(light: Color(hex: "0AAAC6").opacity(0.5), dark: Color(hex: "42edfe").opacity(0.25))

    /// pH Ideal Range Farbe
    static let phIdealColor = Color(light: Color(hex: "0AAAC6"), dark: Color(hex: "35c4d4"))

    // MARK: - Chlor Farben

    /// Chlor Bar Farbe
    static let chlorineBarColor = Color(light: Color(hex: "1FBF4A").opacity(0.5), dark: Color(hex: "5df66d").opacity(0.25))

    /// Chlor Ideal Range Farbe
    static let chlorineIdealColor = Color(light: Color(hex: "1FBF4A"), dark: Color(hex: "4ccc5a"))

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
