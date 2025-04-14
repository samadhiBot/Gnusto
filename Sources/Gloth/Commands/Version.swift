import Foundation

/// Generates phrases for requesting the game version.
enum Version: Generator {
    /// Generates a random phrase for version.
    ///
    /// Examples:
    /// - "version"
    /// - "about"
    static func any() -> Phrase {
        phrase(.verb(versionVerb.randomElement()!))
    }
}

// MARK: - Samples

extension Version {
    /// Sample verbs for requesting version.
    static var versionVerb: [String] {
        [
            "version",
            "about",
            "info", // Also in Help
            "credits",
        ]
    }
}
