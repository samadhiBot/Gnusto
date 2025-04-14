import Foundation

/// Generates phrases for waiting.
enum Wait: Generator {
    /// Generates a random phrase for waiting.
    ///
    /// Examples:
    /// - "wait"
    /// - "z"
    static func any() -> Phrase {
        phrase(.verb(waitVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Wait {
    /// Sample verbs for waiting.
    static var waitVerb: [String] {
        [
            "wait",
            "z", // Common abbreviation
            "pause",
            "delay",
            "stay",
            "hold on",
        ]
    }
}
