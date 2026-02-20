//
//  DosingFormatter.swift
//  Lagoon
//

import Foundation

struct DosingFormatter {
    /// Number of ticks for becher mode (0 to 10 cups)
    static let cupTickCount = 24

    static func format(grams: Double, unit: String, cupGrams: Double) -> String {
        if unit == "becher" && cupGrams > 0 {
            let cups = grams / cupGrams
            return "\(formatCups(cups)) Bch."
        }
        return String(format: "%.0f g", grams)
    }

    /// Returns only the numeric amount (e.g. "120" or "2 1/2")
    static func formatAmount(grams: Double, unit: String, cupGrams: Double) -> String {
        if unit == "becher" && cupGrams > 0 {
            return formatCups(grams / cupGrams)
        }
        return String(format: "%.0f", grams)
    }

    /// Returns only the unit label (e.g. "Gramm" or "Becher")
    static func formatUnit(unit: String) -> String {
        unit == "becher" ? "Becher" : "Gramm"
    }

    private static func formatCups(_ cups: Double) -> String {
        let whole = Int(cups)
        let quarters = Int(((cups - Double(whole)) * 4).rounded())

        switch quarters {
        case 0:
            return "\(whole)"
        case 1:
            return whole > 0 ? "\(whole) 1/4" : "1/4"
        case 2:
            return whole > 0 ? "\(whole) 1/2" : "1/2"
        case 3:
            return whole > 0 ? "\(whole) 3/4" : "3/4"
        default:
            return "\(whole + 1)"
        }
    }

    /// Convert a becher tick index to cups.
    /// Indices 0–8: quarter steps (0, 0.25, 0.5, … 2.0)
    /// Indices 9–24: half steps (2.5, 3.0, … 10.0)
    static func cupTickToCups(_ index: Int) -> Double {
        if index <= 8 {
            return Double(index) * 0.25
        } else {
            return 2.0 + Double(index - 8) * 0.5
        }
    }

    /// Convert cups to the nearest becher tick index
    static func cupsToCupTick(_ cups: Double) -> Int {
        if cups <= 2.0 {
            return min(8, max(0, Int((cups / 0.25).rounded())))
        } else {
            return min(cupTickCount, max(8, 8 + Int(((cups - 2.0) / 0.5).rounded())))
        }
    }

    /// Convert a becher tick index to grams
    static func cupTickToGrams(_ index: Int, cupGrams: Double) -> Double {
        cupTickToCups(index) * cupGrams
    }

    /// Convert grams to the nearest becher tick index
    static func gramsToCupTick(_ grams: Double, cupGrams: Double) -> Int {
        guard cupGrams > 0 else { return 0 }
        return cupsToCupTick(grams / cupGrams)
    }
}
