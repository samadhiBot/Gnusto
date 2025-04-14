import Foundation

/// Generates phrases for quitting the game.
enum Quit: Generator {
    /// Generates a random phrase for quitting.
    ///
    /// Examples:
    /// - "quit"
    /// - "exit game"
    static func any() -> Phrase {
        phrase(.verb(quitVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Quit {
    /// Sample verbs for quitting.
    static var quitVerb: [String] {
        [
            "quit",
            "exit", // Also in Go, but context is different
            "stop",
            "end",
            "bye", // Also in Talk
            "goodbye", // Also in Talk
            "abort",
            "terminate",
        ]
    }
}
