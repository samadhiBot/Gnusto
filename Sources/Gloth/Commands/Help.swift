import Foundation

/// Generates phrases for requesting help.
enum Help: Generator {
    /// Generates a random phrase for help.
    ///
    /// Examples:
    /// - "help"
    /// - "?"
    /// - "h"
    static func any() -> Phrase {
        phrase(.verb(helpVerb.rnd))
    }
}

// MARK: - Samples

extension Help {
    /// Sample verbs/symbols for help.
    static var helpVerb: [String] {
        [
            "help",
            "?", // Common abbreviation
            "h", // Common abbreviation
            "hint",
            "info",
            "instructions",
        ]
    }
}
