//
//  DosingEventModel.swift
//  Lagoon
//
//  SwiftData model for dosing events.
//

import SwiftData
import Foundation

@Model
final class DosingEventModel {
    var productId: String          // "chlorine", "ph_minus", "ph_plus"
    var productName: String        // Display name
    var amount: Double
    var unit: String
    var timestamp: Date

    init(
        productId: String,
        productName: String,
        amount: Double,
        unit: String = "g",
        timestamp: Date = Date()
    ) {
        self.productId = productId
        self.productName = productName
        self.amount = amount
        self.unit = unit
        self.timestamp = timestamp
    }

    // MARK: - Convert to Engine DosingEvent

    func toEngineDosingEvent() -> DosingEvent {
        DosingEvent(
            timestampISO: ISO8601DateFormatter().string(from: timestamp),
            productId: productId,
            kind: productKind,
            amount: amount,
            unit: unit
        )
    }

    // MARK: - Product Kind

    var productKind: ProductKind {
        switch productId {
        case "chlorine": return .chlorine
        case "ph_minus": return .phMinus
        case "ph_plus": return .phPlus
        default: return .chlorine
        }
    }

    // MARK: - Summary String

    var summary: String {
        "\(Int(amount)) \(unit) \(productName)"
    }
}

// MARK: - Convenience Initializers

extension DosingEventModel {
    /// Create a chlorine dosing event
    static func chlorine(amount: Double, timestamp: Date = Date()) -> DosingEventModel {
        DosingEventModel(
            productId: "chlorine",
            productName: "Chlorgranulat",
            amount: amount,
            unit: "g",
            timestamp: timestamp
        )
    }

    /// Create a pH-Minus dosing event
    static func phMinus(amount: Double, timestamp: Date = Date()) -> DosingEventModel {
        DosingEventModel(
            productId: "ph_minus",
            productName: "pH-Minus",
            amount: amount,
            unit: "g",
            timestamp: timestamp
        )
    }

    /// Create a pH-Plus dosing event
    static func phPlus(amount: Double, timestamp: Date = Date()) -> DosingEventModel {
        DosingEventModel(
            productId: "ph_plus",
            productName: "pH-Plus",
            amount: amount,
            unit: "g",
            timestamp: timestamp
        )
    }
}
