import Foundation

/// Generates phrases for undoing the last action.
enum Undo: Generator {
    /// Generates a random phrase for undoing.
    ///
    /// Examples:
    /// - "undo"
    /// - "revert"
    static func any() -> Phrase {
        phrase(.verb(undoVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Undo {
    /// Sample verbs for undoing.
    static var undoVerb: [String] {
        [
            "undo",
            "revert",
            "back",
            "oops", // Common informal
        ]
    }
}
