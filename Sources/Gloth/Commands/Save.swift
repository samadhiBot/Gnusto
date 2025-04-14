import Foundation

/// Generates phrases for saving the game state.
enum Save: Generator {
    /// Generates a random phrase for saving.
    ///
    /// Examples:
    /// - "save"
    /// - "save game"
    static func any() -> Phrase {
        phrase(.verb(saveVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Save {
    /// Sample verbs for saving.
    static var saveVerb: [String] {
        [
            "save",
            "record",
            "store",
            "backup",
        ]
    }
}
