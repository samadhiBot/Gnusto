import Foundation

/// Generates phrases related to reading items.
enum Read: Generator {
    /// Generates a random phrase for reading an item.
    ///
    /// Examples:
    /// - "read the dusty scroll"
    /// - "skim the old book"
    /// - "peruse sign"
    static func any() -> Phrase {
        // Reuse modifiers from Take
        let itemMod = Take.objectMod

        return any(
            phrase( // verb the [mod] object
                .verb(readVerb.rnd),
                .determiner("the"),
                .modifier(itemMod.rnd),
                .directObject(readableObject.rnd)
            ),
            phrase( // verb object
                .verb(readVerb.rnd),
                .directObject(readableObject.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Read {
    /// Sample verbs for reading.
    static var readVerb: [String] {
        [
            "read",
            "peruse",
            "scan",
            "skim",
            "study",
        ]
    }

    /// Sample objects that can be read.
    static var readableObject: [String] {
        // Combine readable objects from other generators + specifics
        Array(Set(
            Take.takeableObject.filter { ["book", "letter", "map", "note", "paper", "scroll", "tablet"].contains($0) } +
            Examine.scenery.filter { ["inscription", "label", "list", "message", "plaque", "poster", "sign", "tablet", "warning", "writing"].contains($0) } +
            [
                // Specific additions
                "computer screen",
                "diary",
                "document",
                "email",
                "engraving",
                "epitaph",
                "file",
                "graffiti",
                "headline",
                "instructions",
                "journal",
                "ledger",
                "log",
                "magazine",
                "manual",
                "manuscript",
                "monitor", // From Toggle
                "newspaper",
                "notice",
                "page",
                "pamphlet",
                "passage", // Text passage
                "recipe",
                "report",
                "runes", // From Examine
                "screen",
                "signage",
                "slab", // Could have writing
                "stone", // Could have writing
                "symbol", // From Examine
                "terminal", // From Toggle
                "text",
                "tome",
                "website", // If applicable
            ]
        ))
    }

    // Note: Reusing `Take.objectMod` for modifiers.
}
