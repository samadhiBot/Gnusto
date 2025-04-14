import Foundation

/// Generates phrases related to wearing items like clothing or armor.
enum Wear: Generator {
    /// Generates a random phrase for wearing an item.
    ///
    /// Examples:
    /// - "wear the leather boots"
    /// - "put on helmet"
    /// - "don the dusty cloak"
    /// - "put the heavy gloves on"
    static func any() -> Phrase {
        let allModifiers = Take.objectMod + clothingSpecificMod
        let clothingMod = Array(Set(allModifiers))

        return any(
            // --- Wear ---
            phrase(.verb(wearVerb.rnd), .determiner("the"), .modifier(clothingMod.rnd), .directObject(wearableObject.rnd)),
            phrase(.verb(wearVerb.rnd), .directObject(wearableObject.rnd)),

            // --- Don ---
            phrase(.verb(donVerb.rnd), .determiner("the"), .modifier(clothingMod.rnd), .directObject(wearableObject.rnd)),
            phrase(.verb(donVerb.rnd), .directObject(wearableObject.rnd)),

            // --- Refactored Phrasal (Put On) ---
            phrase( // put on [object] -> Verb: put, Prep: on, DO: object
                .verb(putVerb),
                .preposition(onPrep),
                .directObject(wearableObject.rnd)
            ),
            phrase( // put [object] on -> Verb: put, DO: object, Prep: on
                .verb(putVerb),
                .directObject(wearableObject.rnd),
                .preposition(onPrep)
            )
        )
    }
}

// MARK: - Samples

extension Wear {
    // --- Verbs ---
    static let wearVerb: [String] = ["wear"]
    static let donVerb: [String] = ["don"]
    static let putVerb: String = "put" // Added back
    static let onPrep: String = "on"
    // static let putOnVerb: String = "put on" // Removed combined verb

    // --- Objects ---
    /// Sample wearable objects.
    static let wearableObject: [String] = {
        [
            "amulet", // From Take
            "armor",
            "belt",
            "boots",
            "bracelet",
            "breastplate",
            "cap",
            "chainmail",
            "cloak",
            "coat",
            "collar",
            "crown", // From Take
            "gauntlets",
            "glasses",
            "gloves", // From Take
            "goggles",
            "greaves",
            "hat",
            "helmet", // From Take
            "hood",
            "jacket",
            "jeans",
            "jewelry",
            "mask",
            "medal",
            "necklace",
            "overalls",
            "pants",
            "pendant",
            "plate mail",
            "ring", // From Take
            "robe",
            "sandals",
            "scarf",
            "shirt",
            "shoes",
            "shorts",
            "skirt",
            "slippers",
            "socks",
            "suit",
            "sunglasses",
            "sweater",
            "trousers",
            "tunic",
            "uniform",
            "vest",
        ]
    }()

    // --- Modifiers ---
    /// Modifiers specific to clothing and wearables.
    static let clothingSpecificMod: [String] = {
        [
            "armored",
            "ceremonial",
            "clean",
            "comfortable",
            "cotton",
            "dirty",
            "drab",
            "elegant",
            "fancy",
            "fine",
            "formal",
            "fur",
            "heavy", // Also in Take
            "hooded",
            "itchy",
            "lacy",
            "leather",
            "light", // Also in Take
            "linen",
            "long", // Also in Take
            "loose",
            "padded",
            "plain",
            "quilted",
            "reinforced",
            "satin",
            "shiny",
            "silk",
            "simple", // Also in Toggle
            "studded",
            "tailored",
            "tattered",
            "thick",
            "tight",
            "velvet",
            "warm", // Also in Consume
            "waterproof",
            "worn",
            "wool",
        ]
    }()
}
