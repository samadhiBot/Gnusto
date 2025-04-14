import Foundation

/// Generates phrases related to toggling devices on or off.
enum Toggle: Generator {
    /// Generates a random phrase for toggling a device.
    ///
    /// Examples:
    /// - "turn the brass lantern on"
    /// - "light the torch"
    /// - "switch off the humming machine"
    /// - "extinguish candle"
    static func any() -> Phrase {
        let lightSource = lightSourceObjects.rnd
        let objectMod = Take.objectMod.rnd
        let fire = fireObject.rnd
        let device = deviceObject.rnd

        return any(
            // --- Turn On ---
            phrase( // turn the [mod] device on
                .verb(turnVerb),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(device),
                .preposition(onPrep)
            ),
            phrase( // turn device on
                .verb(turnVerb),
                .directObject(device),
                .preposition(onPrep)
            ),

            // --- Switch On ---
            phrase( // switch the [mod] device on
                .verb(switchVerb),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(device),
                .preposition(onPrep)
            ),
            phrase( // switch device on
                .verb(switchVerb),
                .directObject(device),
                .preposition(onPrep)
            ),

            // --- Light ---
            phrase( // light the [mod] device
                .verb(lightVerb),
                .modifier(objectMod),
                .directObject(lightSource)
            ),
            phrase( // light device
                .verb(lightVerb),
                .directObject(lightSource)
            ),

            // --- Double modifier light
            phrase( // light the [mod] [mod] device
                .verb(lightVerb),
                .modifier(objectMod),
                .modifier(objectMod),
                .directObject(lightSource)
            ),

            // --- Turn Off ---
            phrase( // turn the [mod] device off
                .verb(turnVerb),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(device),
                .preposition(offPrep)
            ),
            phrase( // turn device off
                .verb(turnVerb),
                .directObject(device),
                .preposition(offPrep)
            ),

            // --- Switch Off ---
            phrase( // switch the [mod] device off
                .verb(switchVerb),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(device),
                .preposition(offPrep)
            ),
            phrase( // switch device off
                .verb(switchVerb),
                .directObject(device),
                .preposition(offPrep)
            ),

            // --- Extinguish/Douse ---
            phrase( // extinguish the [mod] device
                .verb(extinguishVerb.rnd),
                .modifier(objectMod),
                .directObject(fire)
            ),
            phrase( // extinguish device
                .verb(extinguishVerb.rnd),
                .directObject(fire)
            ),

            // --- Double modifier extinguish
            phrase( // extinguish the [mod] [mod] device
                .verb(extinguishVerb.rnd),
                .modifier(objectMod),
                .modifier(objectMod),
                .directObject(fire)
            ),

            // --- Refactored Phrasal (Put Out) ---
            phrase( // put out [fire] -> Verb: put, Prep: out, DO: fire
                .verb(putVerb),
                .preposition(outPrep), // Particle immediately after verb
                .directObject(fire)
            ),
            phrase( // put [fire] out -> Verb: put, DO: fire, Prep: out
                .verb(putVerb),
                .directObject(fire),
                .preposition(outPrep) // Particle after object
            ),

            // --- Double modifier put out
            phrase( // put out [mod] [mod] [fire] -> Verb: put, Prep: out, DO: fire
                .verb(putVerb),
                .preposition(outPrep), // Particle immediately after verb
                .modifier(objectMod),
                .modifier(objectMod),
                .directObject(fire)
            )
        )
    }
}

// MARK: - Samples

extension Toggle {
    // --- Verbs ---
    static var turnVerb: String { "turn" }
    static var switchVerb: String { "switch" }
    static var lightVerb: String { "light" }
    static var extinguishVerb: [String] {
        [
            "douse",
            "extinguish",
        ]
    }

    // --- Prepositions ---
    static var onPrep: String { "on" }
    static var offPrep: String { "off" }

    // --- Objects ---
    /// Objects that can generally be toggled.
    static var deviceObject: [String] {
        lightSourceObjects + [
            "beacon",
            "button", // From Examine
            "computer",
            "console",
            "device",
            "engine",
            "fan",
            "generator",
            "heater",
            "lever", // From Examine
            "light",
            "machine", // From Examine
            "mechanism", // From Examine
            "monitor",
            "motor",
            "pump",
            "radio",
            "receiver",
            "switch",
            "terminal",
            "transmitter",
            "trap",
            "valve",
        ]
    }

    /// Objects that are primarily light sources (for "light"/"extinguish").
    static var lightSourceObjects: [String] {
        [
            "bulb",
            "candle", // From Take
            "fire",
            "fireplace",
            "flame",
            "lamp", // From Take
            "lantern", // From Take
            "light",
            "match",
            "torch", // From Take
        ]
    }

    // --- Modifiers ---
    /// Modifiers specific to devices.
    static var deviceSpecificMod: [String] {
        [
            "ancient",
            "backup",
            "blinking",
            "bright",
            "buzzing",
            "complex",
            "control",
            "dim",
            "emergency",
            "flickering",
            "glowing", // Also in Take
            "humming",
            "main",
            "noisy",
            "power",
            "pulsing",
            "quiet",
            "security",
            "simple",
            "strange",
            "whirring",
        ]
    }

    static var turnOnVerb: [String] { ["switch", "turn"] }
    static var turnOffVerb: [String] { ["switch", "turn"] } // Same as turnOn for base verb
    static var douseVerb: [String] { ["douse"] }
    static var putVerb: String { "put" }
    static var outPrep: String { "out" }

    static var fireObject: [String] {
        [
            "fire",
            "flame",
            "fireplace",
            "fire",
            "flame",
            "fireplace",
        ]
    }
}
