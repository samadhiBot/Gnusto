import Foundation

/// Generates phrases related to putting an item into a container.
enum PutIn: Generator {
    /// Generates a random phrase for putting an item into a container.
    ///
    /// Examples:
    /// - "put the gold coin in the leather pouch"
    /// - "insert key into lock"
    /// - "place the scroll inside the tube"
    static func any() -> Phrase {
        let container = Self.containerObject
        let item = Self.itemObject
        let containerMod = Take.objectMod
        let itemMod = Take.objectMod

        var phrases: [Phrase] = []

        // --- Base Patterns (Corrected) ---
        // Basic put item in container variations
        phrases.append(contentsOf: [
            phrase(.verb(putVerb.rnd), .modifier(itemMod.rnd), .directObject(item.rnd), .preposition(prep.rnd), .modifier(containerMod.rnd), .indirectObject(container.rnd)),
            phrase(.verb(putVerb.rnd), .directObject(item.rnd), .preposition(prep.rnd), .indirectObject(container.rnd)),
            phrase(.verb(putVerb.rnd), .modifier(itemMod.rnd), .directObject(item.rnd), .preposition(prep.rnd), .determiner("the"), .modifier(containerMod.rnd), .indirectObject(container.rnd)),
            phrase(.verb(putVerb.rnd), .directObject(item.rnd), .preposition(prep.rnd), .determiner("the"), .indirectObject(container.rnd)),
            // Double mods
            phrase(.verb(putVerb.rnd), .modifier(itemMod.rnd), .modifier(itemMod.rnd), .directObject(item.rnd), .preposition(prep.rnd), .indirectObject(container.rnd)),
            phrase(.verb(putVerb.rnd), .directObject(item.rnd), .preposition(prep.rnd), .modifier(containerMod.rnd), .modifier(containerMod.rnd), .indirectObject(container.rnd))
        ])

        // --- Targeted DO/IO Training ---
        for _ in 0..<30 { // Increased count for more variety
            let currentItem = item.rnd // Use full list
            let currentCont = container.rnd // Use full list
            let itemM1 = itemMod.maybeRnd()
            let itemM2 = (itemM1 != nil) ? itemMod.maybeRnd() : nil
            let contM1 = containerMod.maybeRnd()
            let contM2 = (contM1 != nil) ? containerMod.maybeRnd() : nil
            let currentPrep = Self.prep.rnd
            let currentVerb = Self.putVerb.rnd

            // Build components array explicitly, filtering nils
            var components: [Word] = []
            components.append(.verb(currentVerb))
            if let mod = itemM1 { components.append(.modifier(mod)) }
            if let mod = itemM2 { components.append(.modifier(mod)) }
            components.append(.directObject(currentItem))
            components.append(.preposition(currentPrep))
            if let mod = contM1 { components.append(.modifier(mod)) }
            if let mod = contM2 { components.append(.modifier(mod)) }
            components.append(.indirectObject(currentCont))

            phrases.append(Phrase(components))
        }

        return phrases.randomElement()!
    }
}

// MARK: - Samples

extension PutIn {
    /// Sample verbs for putting something in.
    static var putVerb: [String] {
        [
            "insert",
            "place",
            "put",
            "slide",
            "slip",
            "stuff",
            "tuck",
        ]
    }

    /// Sample prepositions used.
    static var prep: [String] {
        [
            "in",
            "inside",
            "into",
        ]
    }

    /// Sample items to be put in (direct objects).
    static var itemObject: [String] {
        // Generally, any takeable object
        Take.takeableObject
    }

    /// Sample containers (indirect objects).
    static var containerObject: [String] {
        // Combine containers from other generators + specifics
        Array(Set(
            Traverse.containerSpaceObject +
            Open.openableObject.filter { !["eyes", "eyelids", "mouth", "door", "window", "gate", "curtain"].contains($0) } + // Filter out non-containers from openable
            [
                "backpack",
                "bag",
                "basket",
                "bottle", // From Take
                "bowl",
                "bucket",
                "case",
                "cauldron",
                "compartment",
                "cup",
                "cylinder",
                "flask",
                "jar",
                "jug",
                "keyhole",
                "mailbox",
                "mug",
                "nest",
                "opening", // From Go/Examine/Traverse
                "pack",
                "pocket",
                "pot",
                "pouch",
                "quiver",
                "receptacle",
                "sack", // From Traverse
                "satchel",
                "scabbard",
                "sheath",
                "slot", // From Examine
                "socket",
                "tube",
                "urn",
                "vase",
                "vial",
                "wallet",
                "waterskin",
            ]
        ))
    }

    // Note: Reusing `Take.objectMod` for modifiers.
}

// Helper extension for maybe getting a random modifier
extension Array where Element == String {
    func maybeRnd() -> String? {
        Bool.random() ? self.randomElement() : nil
    }
}
