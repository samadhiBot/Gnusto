import Foundation

/// Generates phrases for restoring a saved game.
enum Restore: Generator {
    /// Generates a random phrase for restoring.
    ///
    /// Examples:
    /// - "restore"
    /// - "load game"
    static func any() -> Phrase {
        phrase(.verb(restoreVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Restore {
    /// Sample verbs for restoring.
    static var restoreVerb: [String] {
        [
            "restore",
            "load",
            "reload",
            "retrieve",
        ]
    }
}
