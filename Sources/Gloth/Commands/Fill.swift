import Foundation

/// Generates phrases related to filling containers.
enum Fill: Generator {
    /// Generates a random phrase for filling a container.
    ///
    /// Examples:
    /// - "fill the empty bottle"
    /// - "fill bucket with murky water"
    /// - "fill the vial from the glowing pool"
    static func any() -> Phrase {
        let container = Self.fillableContainer
        let substance = Self.substance
        let source = Self.sourceObject
        let containerMod = Take.objectMod
        let substanceMod = Take.objectMod
        let sourceMod = Take.objectMod

        return any(
            phrase(.verb(fillVerb), .modifier(containerMod.rnd), .directObject(container.rnd)),
            phrase(.verb(fillVerb), .directObject(container.rnd)),
            phrase(.verb(fillVerb), .directObject(container.rnd), .preposition(withPrep), .directObject(substance.rnd)),
            phrase(.verb(fillVerb), .directObject(container.rnd), .preposition(fromPrep), .directObject(source.rnd)),
            phrase(.verb(fillVerb), .modifier(containerMod.rnd), .directObject(container.rnd), .preposition(withPrep), .modifier(substanceMod.rnd), .indirectObject(substance.rnd)),
            phrase(.verb(fillVerb), .modifier(containerMod.rnd), .directObject(container.rnd), .preposition(fromPrep), .modifier(sourceMod.rnd), .indirectObject(source.rnd)),
            phrase( // fill [mod1] [mod2] container
                .verb(fillVerb),
                .modifier(containerMod.rnd),
                .modifier(containerMod.rnd),
                .directObject(container.rnd)
            ),
            phrase( // fill container with [mod1] [mod2] substance
                .verb(fillVerb),
                .directObject(container.rnd),
                .preposition(withPrep),
                .modifier(substanceMod.rnd),
                .modifier(substanceMod.rnd),
                .indirectObject(substance.rnd)
            ),
            phrase( // fill container from [mod1] [mod2] source
                .verb(fillVerb),
                .directObject(container.rnd),
                .preposition(fromPrep),
                .modifier(sourceMod.rnd),
                .modifier(sourceMod.rnd),
                .indirectObject(source.rnd)
            ),
            phrase( // fill up [mod1] [mod2] container
                .verb(fillVerb),
                .preposition(upPrep),
                .modifier(containerMod.rnd),
                .modifier(containerMod.rnd),
                .directObject(container.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Fill {
    /// Sample verbs for filling.
    static let fillVerb: String = "fill"

    /// Sample prepositions used.
    static let withPrep: String = "with"
    static let fromPrep: String = "from"
    static let upPrep: String = "up"

    /// Sample containers that can be filled (direct objects).
    static let fillableContainer: [String] = {
        // Filter container-like objects from PutIn
        PutIn.containerObject.filter { ![
            // Exclude things that aren't typically "filled" in IF
            "backpack", "bag", "basket", "briefcase", "case", "compartment",
            "drawer", "envelope", "keyhole", "locker", "mailbox", "nest",
            "opening", "pack", "pocket", "portfolio", "pouch", "purse",
            "quiver", "receptacle", "sack", "satchel", "scabbard", "sheath",
            "slot", "socket", "trunk", "urn", "vault", "wallet", "wardrobe"
        ].contains($0) }
    }()

    /// Sample substances used for filling.
    static let substance: [String] = {
        Array(Set(
            Consume.drinkObject + // Most drinks can be used to fill
            Dig.diggableSurface.filter { ["sand", "dirt", "gravel", "ash", "earth", "mud", "snow"].contains($0) } + // Some diggable materials
            [
                "acid",
                "blood",
                "chemicals",
                "dust",
                "elixir", // From Take/Consume
                "fuel",
                "gasoline",
                "grain",
                "gunpowder",
                "honey",
                "ink",
                "lava",
                "mercury",
                "nectar", // From Consume
                "oil", // From Burn
                "paint",
                "powder",
                "salt",
                "sap",
                "sludge",
                "solvent",
                "spice",
                "sugar",
                "syrup",
                "tar",
            ]
        ))
    }()

    /// Sample sources from which containers can be filled.
    static let sourceObject: [String] = {
        [
            "barrel", // From Traverse
            "basin",
            "brook", // From Go
            "bucket", // From PutIn
            "cistern",
            "creek", // From Go
            "dispenser",
            "faucet",
            "fountain", // From Examine
            "hose",
            "keg",
            "lake",
            "ocean",
            "pipe", // From Traverse
            "pool", // From Examine
            "pond",
            "pump", // From Toggle
            "reservoir",
            "river", // From Go
            "sink",
            "spigot",
            "spring",
            "stream", // From Go
            "tank",
            "tap",
            "trough",
            "vat",
            "well",
        ]
    }()

    // Note: Reusing `Take.objectMod` for modifiers.
}
