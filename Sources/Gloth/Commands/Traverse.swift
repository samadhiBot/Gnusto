import Foundation

/// Generates phrases related to traversing objects (entering, exiting, boarding, climbing on/under).
enum Traverse: Generator {
    /// Generates a random phrase for traversing an object.
    ///
    /// Examples:
    /// - "board the ship"
    /// - "enter the dark cave"
    /// - "climb into the crate"
    /// - "get out of the pit"
    /// - "step onto the platform"
    /// - "climb under the table"
    static func any() -> Phrase {
        let traversableModifiers = Array(Set(Take.objectMod + Go.goMod + Examine.scenery.compactMap { $0 }))
        let objectMod = traversableModifiers.rnd
        let container = PutIn.containerObject.rnd
        let specificObject = traversableObject.rnd
        let specificWater = waterBody.rnd
        let specificSurface = surfaceObject.rnd
        let specificBoardable = boardableEnterableObject.rnd
        let specificUnderObject = underObject.rnd

        return any(
            // --- Board/Enter ---
            phrase(
                .verb(boardEnterVerb.rnd),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(specificBoardable)
            ),
            phrase(
                .verb(boardEnterVerb.rnd),
                .directObject(specificBoardable)
            ),

            // --- Exit/Leave ---
            phrase(
                .verb(exitLeaveVerb.rnd),
                .determiner("the"),
                .modifier(objectMod),
                .directObject(specificBoardable)
            ),
            phrase(
                .verb(exitLeaveVerb.rnd),
                .directObject(specificBoardable)
            ),

            // --- Climb/Get Into ---
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(intoPrep.rnd),
                .determiner("the"),
                .modifier(objectMod),
                .indirectObject(container)
            ),
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(intoPrep.rnd),
                .indirectObject(container)
            ),

            // --- Climb/Get Out Of ---
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(outOfPrep.rnd),
                .determiner("the"),
                .modifier(objectMod),
                .indirectObject(container)
            ),
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(outOfPrep.rnd),
                .indirectObject(container)
            ),

            // --- Climb/Step Onto ---
            phrase(
                .verb(climbStepVerb.rnd),
                .preposition(ontoPrep.rnd),
                .determiner("the"),
                .modifier(objectMod),
                .indirectObject(specificSurface)
            ),
            phrase(
                .verb(climbStepVerb.rnd),
                .preposition(ontoPrep.rnd),
                .indirectObject(specificSurface)
            ),

            // --- Climb/Get Under ---
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(underPrep),
                .determiner("the"),
                .modifier(objectMod),
                .indirectObject(specificUnderObject)
            ),
            phrase(
                .verb(climbGetVerb.rnd),
                .preposition(underPrep),
                .indirectObject(specificUnderObject)
            ),

            // --- Added Specific Object/Water Usage ---
            phrase(
                .verb(crossVerb.rnd),
                .directObject(specificObject)
            ),
            phrase(
                .verb(crossVerb.rnd),
                .directObject(specificWater)
            ),
            phrase(
                .verb(swimVerb.rnd),
                .preposition("in"),
                .directObject(specificWater)
            ),
            phrase(
                .verb(swimVerb.rnd),
                .preposition("across"),
                .directObject(specificWater)
            ),

            // --- Refactored Phrasal ---
            phrase(
                .verb(climbVerb.rnd),
                .preposition(aboardPrep),
                .indirectObject(specificBoardable)
            ),
            phrase(
                .verb(climbVerb.rnd),
                .indirectObject(specificBoardable),
                .preposition(aboardPrep)
            ),
            phrase(
                .verb(climbVerb.rnd),
                .preposition(intoPrep.rnd),
                .indirectObject(container)
            ),
            phrase(
                .verb(climbVerb.rnd),
                .indirectObject(container),
                .preposition(intoPrep.rnd)
            ),
            phrase(
                .verb(getVerb),
                .preposition("out"),
                .preposition(outOfPrep.last!),
                .indirectObject(container)
            ),
            phrase(
                .verb(getVerb),
                .indirectObject(container),
                .preposition("out"),
                .preposition(outOfPrep.last!)
            ),
            phrase(
                .verb(stepVerb),
                .preposition(ontoPrep.rnd),
                .indirectObject(specificSurface)
            ),
            phrase(
                .verb(stepVerb),
                .indirectObject(specificSurface),
                .preposition(ontoPrep.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Traverse {
    // --- Verbs ---
    static let boardEnterVerb: [String] = ["board", "enter"]
    static let exitLeaveVerb: [String] = ["exit", "leave"]
    static let climbGetVerb: [String] = ["climb", "get", "crawl", "squeeze"]
    static let climbStepVerb: [String] = ["climb", "step", "jump", "hop"]
    static let climbVerb: [String] = ["climb", "ascend", "descend"]
    static let getVerb: String = "get"
    static let stepVerb: String = "step"
    static let crossVerb: [String] = ["cross", "ford", "traverse"]
    static let swimVerb: [String] = ["swim", "wade"]

    // --- Prepositions ---
    static let intoPrep: [String] = ["in", "into"]
    static let outOfPrep: [String] = ["out", "out of"]
    static let ontoPrep: [String] = ["on", "onto"]
    static let underPrep: String = "under"
    static let prepDirection: [String] = ["up", "down", "through", "across", "over", "under"]
    static let aboardPrep: String = "aboard"

    // --- Objects ---

    /// General objects that can be traversed in some way (climbing, crossing)
    static let traversableObject: [String] = {
        [
            "beam", "bridge", "branch", "ladder", "log", "plank", "rope", "stairs", "vine", "wall"
        ]
    }()

    /// Objects typically boarded or entered (vehicles, large structures).
    static let boardableEnterableObject: [String] = {
        [
            "boat",
            "building",
            "cabin",
            "car",
            "carriage",
            "cart",
            "castle",
            "cave",
            "chamber",
            "chariot",
            "coach",
            "craft",
            "elevator",
            "helicopter",
            "house",
            "hut",
            "plane",
            "room",
            "ship",
            "shuttle",
            "stagecoach",
            "submarine",
            "taxi",
            "temple",
            "tent",
            "tower",
            "train",
            "truck",
            "tunnel",
            "van",
            "vehicle",
            "wagon",
            "zeppelin",
        ]
    }()

    /// Objects typically containers or confined spaces to get into/out of.
    static let containerSpaceObject: [String] = {
        [
            "barrel",
            "bin",
            "box",
            "bunker",
            "cabinet", // From Examine
            "capsule",
            "closet",
            "coffin",
            "compartment", // From PutIn
            "crate",
            "crevice", // From Go
            "crypt",
            "cubbyhole",
            "cupboard", // From Examine
            "dumpster",
            "hamper",
            "hole", // From Go/Examine/Dig
            "hollow",
            "locker", // From PutIn
            "manhole",
            "niche",
            "opening", // From Go/Examine
            "pit", // From Dig
            "pod",
            "recess",
            "safe", // From Lock
            "sarcophagus",
            "shed",
            "trunk", // From PutIn
            "tube", // From PutIn
            "tunnel", // Also boardable
            "vault", // From Lock/PutIn
            "vent",
        ]
    }()

    /// Bodies of water.
    static let waterBody: [String] = {
        [
            "channel",
            "fjord",
            "gulf",
            "lagoon",
            "lake", // From Fill
            "loch",
            "moat",
            "ocean", // From Fill
            "pool", // From Fill/Examine
            "pond", // From Fill
            "puddle",
            "reservoir", // From Fill
            "river", // From Go/Fill
            "sea",
            "sound",
            "spring", // From Fill
            "strait",
            "stream", // From Go/Fill
            "swamp",
            "torrent",
            "waterfall",
            "well", // From Fill
        ]
    }()

    /// Surfaces that can be stepped onto.
    static let surfaceObject: [String] = {
        [
            "altar",
            "balcony",
            "bank", // From Dig
            "bed", // From PutOnSurface
            "block", // From PutOnSurface
            "boardwalk",
            "boulder",
            "carpet",
            "catwalk",
            "chair",
            "counter", // From PutOnSurface
            "dais",
            "deck",
            "dock",
            "floor", // From Examine/Dig
            "footstool",
            "ground", // From Examine/Dig
            "island",
            "ledge", // From Go
            "lilypad",
            "mound", // From Dig
            "pallet",
            "path", // From Dig
            "patio",
            "pedestal",
            "pier",
            "platform",
            "raft",
            "ramp",
            "rock", // From Examine/Dig
            "roof",
            "rug",
            "scaffolding",
            "shelf",
            "slab", // From Read
            "stage",
            "stairs", // Also traversableObject
            "step",
            "stone", // From Read
            "stool",
            "stump",
            "table", // From Examine
            "terrace",
            "throne",
            "tile",
            "walkway",
        ]
    }()

    /// Objects that can be gone under.
    static let underObject: [String] = {
        [
            "archway",
            "awning",
            "balcony", // Also surface
            "bed", // Also surface
            "bench", // Also surface
            "bleachers",
            "boardwalk", // Also surface
            "bridge", // Also traversableObject
            "bush",
            "car", // Also boardable
            "cart", // Also boardable
            "catwalk", // Also surface
            "ceiling",
            "chair", // Also surface
            "counter", // Also surface
            "desk", // Also surface
            "dock", // Also surface
            "eaves",
            "ledge", // Also surface
            "overhang",
            "pier", // Also surface
            "platform", // Also surface
            "porch",
            "scaffolding", // Also surface
            "shelf", // Also surface
            "stairs", // Also surface/traversableObject
            "stool", // Also surface
            "table", // Also surface
            "truck", // Also boardable
            "wagon", // Also boardable
        ]
    }()
}
