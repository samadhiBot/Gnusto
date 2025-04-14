import CustomDump
import Nitfol
import Testing

struct GoTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Go direction (cardinal)")
    func goDirectionCardinal() {
        expectNoDifference(
            nitfol.parse("go north"),
            ParsedCommand(verb: "go", prepositions: "north")
        )

        expectNoDifference(nitfol.parse("n"), ParsedCommand(verb: "n"))
        expectNoDifference(nitfol.parse("north"), ParsedCommand(verb: "north"))

        expectNoDifference(nitfol.parse("ne"), ParsedCommand(verb: "ne"))
        expectNoDifference(nitfol.parse("northeast"), ParsedCommand(verb: "northeast"))

        expectNoDifference(nitfol.parse("e"), ParsedCommand(verb: "e"))
        expectNoDifference(nitfol.parse("east"), ParsedCommand(verb: "east"))

        expectNoDifference(nitfol.parse("se"), ParsedCommand(verb: "se"))
        expectNoDifference(nitfol.parse("southeast"), ParsedCommand(verb: "southeast"))

        expectNoDifference(nitfol.parse("s"), ParsedCommand(verb: "s"))
        expectNoDifference(nitfol.parse("south"), ParsedCommand(verb: "south"))

        expectNoDifference(nitfol.parse("sw"), ParsedCommand(verb: "sw"))
        expectNoDifference(nitfol.parse("southwest"), ParsedCommand(verb: "southwest"))

        expectNoDifference(nitfol.parse("w"), ParsedCommand(verb: "w"))
        expectNoDifference(nitfol.parse("west"), ParsedCommand(verb: "west"))

        expectNoDifference(nitfol.parse("nw"), ParsedCommand(verb: "nw"))
        expectNoDifference(nitfol.parse("northwest"), ParsedCommand(verb: "northwest"))

        expectNoDifference(nitfol.parse("u"), ParsedCommand(verb: "u"))
        expectNoDifference(nitfol.parse("up"), ParsedCommand(verb: "up"))

        expectNoDifference(nitfol.parse("d"), ParsedCommand(verb: "d"))
        expectNoDifference(nitfol.parse("down"), ParsedCommand(verb: "down"))

        expectNoDifference(nitfol.parse("in"), ParsedCommand(verb: "in"))
        expectNoDifference(nitfol.parse("out"), ParsedCommand(verb: "out"))
    }

    @Test("Go direction (other)")
    func goDirectionOther() {
        expectNoDifference(
            nitfol.parse("go up"),
            ParsedCommand(verb: "go", prepositions: "up")
        )
        expectNoDifference(
            nitfol.parse("down"),
            ParsedCommand(verb: "down")
        )
    }

    @Test("Go towards direction")
    func goTowardsDirection() {
        expectNoDifference(
            nitfol.parse("walk toward the west"),
            ParsedCommand(
                verb: "walk",
                directObject: "west",
                prepositions: "toward"
            )
        )
    }

    @Test("Climb object")
    func climbObject() {
        expectNoDifference(
            nitfol.parse("climb wall"),
            ParsedCommand(verb: "climb", directObject: "wall")
        )
    }

    @Test("Climb modified object")
    func climbModifiedObject() {
        expectNoDifference(
            nitfol.parse("scurry the slimy stairs"),
            ParsedCommand(verb: "scurry", directObject: "stairs", directObjectModifiers: ["slimy"])
        )
    }

    @Test("Climb through object")
    func climbThroughObject() {
        expectNoDifference(
            nitfol.parse("crawl through the dark hole"),
            ParsedCommand(
                verb: "crawl",
                directObject: "hole",
                directObjectModifiers: ["dark"],
                prepositions: "through",
            )
        )
    }

    @Test("Cross object")
    func crossObject() {
        expectNoDifference(
            nitfol.parse("cross bridge"),
            ParsedCommand(verb: "cross", directObject: "bridge")
        )
    }

    @Test("Ford modified object")
    func fordModifiedObject() {
        expectNoDifference(
            nitfol.parse("ford the wide river"),
            ParsedCommand(verb: "ford", directObject: "river", directObjectModifiers: ["wide"])
        )
    }

    @Test("Swim")
    func swim() {
        expectNoDifference(
            nitfol.parse("swim"),
            ParsedCommand(verb: "swim")
        )
    }

    @Test("Swim in water body")
    func swimInWaterBody() {
        expectNoDifference(
            nitfol.parse("swim in lake"),
            ParsedCommand(verb: "swim", directObject: "lake", prepositions: "in")
        )
    }

    @Test("Wade across modified water body")
    func wadeAcrossModifiedWaterBody() {
        expectNoDifference(
            nitfol.parse("wade across the murky stream"),
            ParsedCommand(verb: "wade", directObject: "stream", directObjectModifiers: ["murky"], prepositions: "across")
        )
    }
}
