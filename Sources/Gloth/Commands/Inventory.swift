import Foundation

/// Generates phrases for checking inventory.
enum Inventory: Generator {
    /// Generates a random phrase for checking inventory.
    ///
    /// Examples:
    /// - "inventory"
    /// - "i"
    static func any() -> Phrase {
        phrase(.verb(inventoryVerb.rnd))
    }
}

// MARK: - Samples

extension Inventory {
    /// Sample verbs for checking inventory.
    static var inventoryVerb: [String] {
        [
            "inventory",
            "i", // Common abbreviation
        ]
    }
}
