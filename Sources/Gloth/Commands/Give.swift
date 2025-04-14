import Foundation

/// Generates phrases related to giving an item to a recipient.
enum Give: Generator {
    /// Generates a random phrase for giving an item.
    ///
    /// Examples:
    /// - "give the rusty key to the guard"
    /// - "offer the elf bread"
    /// - "present the king with the ancient crown"
    static func any() -> Phrase {
        // Reuse modifiers from Take
        let itemMod = Take.objectMod
        let recipientMod = Attack.enemyMod // Reuse enemy mods for recipients

        return any(
            // --- Give [Item] To [Recipient] ---
            phrase( // give the [mod] item to the [mod] recipient
                .verb(giveVerb.rnd),
                .determiner("the"),
                .modifier(itemMod.rnd),
                .directObject(itemToGive.rnd),
                .preposition(toPrep),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .indirectObject(recipient.rnd)
            ),
            phrase( // give item to recipient
                .verb(giveVerb.rnd),
                .directObject(itemToGive.rnd),
                .preposition(toPrep),
                .indirectObject(recipient.rnd)
            ),

            // --- Offer/Present (often implies recipient is target) ---
            phrase( // offer/present the [mod] item to the [mod] recipient
                .verb(offerPresentVerb.rnd),
                .determiner("the"),
                .modifier(itemMod.rnd),
                .directObject(itemToGive.rnd),
                .preposition(toPrep),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .indirectObject(recipient.rnd)
            ),
            phrase( // offer/present item to recipient
                .verb(offerPresentVerb.rnd),
                .directObject(itemToGive.rnd),
                .preposition(toPrep),
                .indirectObject(recipient.rnd)
            ),

            // --- Give [Recipient] [Item] (Added for test failure) ---
            phrase( // give the [mod] recipient the [mod] item
                .verb(giveVerb.rnd),
                .determiner("the"),
                .modifier(recipientMod.rnd),
                .indirectObject(recipient.rnd), // Recipient first -> IO
                .determiner("the"),
                .modifier(itemMod.rnd),
                .directObject(itemToGive.rnd) // Item second -> DO
            ),
            phrase( // give recipient item
                .verb(giveVerb.rnd),
                .indirectObject(recipient.rnd),
                .directObject(itemToGive.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Give {
    /// Sample verbs for giving.
    static let giveVerb: [String] = ["give", "hand", "offer", "present"]
    static let offerPresentVerb: [String] = ["offer", "present"]

    /// Sample prepositions used.
    static let toPrep: String = "to"

    /// Sample items to be given (direct objects).
    static let itemToGive: [String] = {
        // Generally, any takeable object
        Take.takeableObject
    }()

    /// Sample recipients (indirect objects).
    static let recipient: [String] = {
        // Combine enemies and potentially friendly NPCs
        Array(Set(
            Attack.enemy + // Reuse enemies
            [
                "beggar",
                "child",
                "citizen",
                "clerk",
                "dwarf",
                "fairy",
                "farmer",
                "fisherman",
                "ghost",
                "gnome",
                "god",
                "goddess",
                "guard",
                "guide",
                "hermit",
                "king",
                "knight",
                "librarian",
                "mage",
                "man",
                "merchant",
                "monk",
                "mystic",
                "noble",
                "nymph",
                "oracle",
                "peasant",
                "priest",
                "princess",
                "prisoner",
                "prophet",
                "queen",
                "sage",
                "scholar",
                "sentry",
                "servant",
                "shopkeeper",
                "soldier",
                "spirit",
                "stranger",
                "villager",
                "wanderer",
                "warrior",
                "woman",
                "wizard", // Also in enemy
            ]
        ))
    }()

    /// Reuse enemy modifiers for recipient
    static let recipientMod: [String] = {
        Attack.enemyMod
    }()

    /// Reuse general object modifiers
    static let itemMod: [String] = {
        Take.objectMod
    }()

    /// Reuse any takeable object
    static let item: [String] = {
        Take.takeableObject
    }()
}
