import CustomDump
import Nitfol
import Testing

struct DigTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Dig surface")
    func digSurface() {
        expectNoDifference(
            nitfol.parse("dig ground"),
            ParsedCommand(verb: "dig", directObject: "ground")
        )
    }

    @Test("Dig modified surface")
    func digModifiedSurface() {
        expectNoDifference(
            nitfol.parse("excavate the loose sand"),
            ParsedCommand(verb: "excavate", directObject: "sand", directObjectModifiers: ["loose"])
        )
    }

    @Test("Dig in surface")
    func digInSurface() {
        expectNoDifference(
            nitfol.parse("dig in dirt"),
            ParsedCommand(verb: "dig", directObject: "dirt", prepositions: "in")
        )
    }

    @Test("Dig surface with tool")
    func digSurfaceWithTool() {
        expectNoDifference(
            nitfol.parse("dig mound with shovel"),
            ParsedCommand(verb: "dig", directObject: "mound", prepositions: "with", indirectObject: "shovel")
        )
    }

    @Test("Dig modified surface with modified tool")
    func digModifiedSurfaceWithModifiedTool() {
        expectNoDifference(
            nitfol.parse("dig the hard earth with the rusty spade"),
            ParsedCommand(
                verb: "dig",
                directObject: "earth",
                directObjectModifiers: ["hard"],
                prepositions: "with",
                indirectObject: "spade",
                indirectObjectModifiers: ["rusty"]
            )
        )
    }

    @Test("Dig in surface with tool")
    func digInSurfaceWithTool() {
        expectNoDifference(
            nitfol.parse("dig in sand with hands"),
            ParsedCommand(
                verb: "dig",
                directObject: "sand",
                prepositions: ["in", "with"],
                indirectObject: "hands"
            )
        )
    }
}
