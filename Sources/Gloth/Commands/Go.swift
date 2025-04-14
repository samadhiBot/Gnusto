import Foundation

enum Go: Generator {
    static func any() -> Phrase {
        any(
            phrase(
                .verb(go.rnd),
                .preposition(cardinal.rnd)
            ),
            phrase(
                .verb(go.rnd),
                .preposition(through.rnd)
            ),
            phrase(
                .verb(go.rnd),
                .preposition(toward.rnd),
                .determiner("the"),
                .indirectObject(cardinal.rnd)
            ),
            phrase(
                .verb(climb.rnd),
                .preposition(through.rnd),
                .determiner("the"),
                .modifier(goMod.rnd),
                .directObject(climbThroughable.rnd)
            ),
            phrase(
                .verb(climb.rnd),
                .determiner("the"),
                .modifier(goMod.rnd),
                .directObject(climbable.rnd)
            ),
            phrase(
                .verb(crossFordVerb.rnd),
                .determiner("the"),
                .modifier(goMod.rnd),
                .directObject(crossableObject.rnd)
            ),
            phrase(
                .verb(crossFordVerb.rnd),
                .determiner("the"),
                .directObject(crossableObject.rnd)
            ),
            phrase(
                .verb(swimVerb.rnd),
                .preposition(swimPrep.rnd),
                .modifier(goMod.rnd),
                .directObject(waterBody.rnd)
            ),
            phrase(
                .verb(swimVerb.rnd),
                .preposition(swimPrep.rnd),
                .directObject(waterBody.rnd)
            ),
            phrase(
                .verb(swimVerb.rnd)
            )
        )
    }
}

// MARK: - Samples

extension Go {
    static let anywhere: [String] = {
        direction + [
            "in",
            "out",
        ]
    }()

    static let cardinal: [String] = {
        [
            "e",
            "east",
            "n",
            "ne",
            "north",
            "northeast",
            "northwest",
            "nw",
            "s",
            "se",
            "south",
            "southeast",
            "southwest",
            "sw",
            "w",
            "west",
        ]
    }()

    static let climb: [String] = {
        [
            "climb",
            "crawl",
            "scamper",
            "scurry",
        ]
    }()

    static let climbable: [String] = {
        [
            "chimney",
            "ladder",
            "stairs",
            "tree",
            "wall",
        ]
    }()

    static let climbThroughable: [String] = {
        [
            "hatch",
            "hole",
            "opening",
            "trapdoor",
            "window",
        ]
    }()

    static let direction: [String] = {
        cardinal + through
    }()

    static let go: [String] = {
        climb + crossFordVerb + swimVerb + [
            "enter",
            "exit",
            "go",
            "hurry",
            "move",
            "run",
            "sneak",
            "sprint",
            "walk",
        ]
    }()

    static let goMod: [String] = {
        [
            "creaking",
            "dark",
            "dusty",
            "slimy",
            "terrifying",
            "unfathomable",
        ]
    }()

    static let through: [String] = {
        [
            "beneath",
            "down",
            "from",
            "over",
            "through",
            "under",
            "up",
        ]
    }()

    static let toward: [String] = {
        [
            "to",
            "toward",
        ]
    }()

    /// Verbs for crossing obstacles.
    static let crossFordVerb: [String] = {
        [
            "cross",
            "ford", // Often implies water
        ]
    }()

    /// Objects that can typically be crossed or forded.
    static let crossableObject: [String] = {
        [
            "bridge",
            "brook",
            "chasm",
            "creek",
            "gap",
            "gorge",
            "log", // As in a log bridge
            "ravine",
            "river",
            "stream",
        ]
    }()

    /// Verbs for swimming.
    static let swimVerb: [String] = {
        [
            "swim",
            "dive", // Can be used for entering water
            "wade",
            "paddle",
            "stroke", // Swimming stroke
        ]
    }()

    /// Prepositions used with swimming (across, in, through).
    static let swimPrep: [String] = {
        [
            "across",
            "in",
            "through",
        ]
    }()

    /// Bodies of water for swimming.
    static let waterBody: [String] = {
        // Combine water bodies from other lists + new ones
        Array(Set(
            Go.crossableObject.filter { ["brook", "creek", "river", "stream"].contains($0) } +
            Fill.sourceObject.filter { ["lake", "ocean", "pool", "pond", "reservoir", "river", "spring", "stream"].contains($0) } +
            [
                "channel",
                "fjord",
                "gulf",
                "lagoon",
                "loch",
                "moat",
                "sea",
                "sound", // Body of water
                "strait",
                "surf",
                "water",
            ]
        ))
    }()
}
