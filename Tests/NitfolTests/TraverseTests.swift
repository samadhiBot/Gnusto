import CustomDump
import Nitfol
import Testing

struct TraverseTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Board object")
    func boardObject() {
        expectNoDifference(
            nitfol.parse("board ship"),
            ParsedCommand(verb: "board", directObject: "ship")
        )
    }

    @Test("Enter modified object")
    func enterModifiedObject() {
        expectNoDifference(
            nitfol.parse("enter the dark cave"),
            ParsedCommand(verb: "enter", directObject: "cave", directObjectModifiers: ["dark"])
        )
    }

    @Test("Exit object")
    func exitObject() {
        expectNoDifference(
            nitfol.parse("exit building"),
            ParsedCommand(verb: "exit", directObject: "building")
        )
    }

    @Test("Climb aboard object")
    func climbAboardObject() {
        expectNoDifference(
            nitfol.parse("climb aboard the ship"),
            ParsedCommand(verb: "climb", directObject: "ship", prepositions: "aboard")
        )
    }

    @Test("Climb into object")
    func climbIntoObject() {
        expectNoDifference(
            nitfol.parse("climb into crate"),
            ParsedCommand(verb: "climb", directObject: "crate", prepositions: "into")
        )
    }

    @Test("Get out of modified object")
    func getOutOfModifiedObject() {
        expectNoDifference(
            nitfol.parse("get out of the deep pit"),
            ParsedCommand(
                verb: "get",
                directObject: "pit",
                directObjectModifiers: ["deep"],
                prepositions: ["out", "of"]
            )
        )
    }

    @Test("Step onto object")
    func stepOntoObject() {
        expectNoDifference(
            nitfol.parse("step onto platform"),
            ParsedCommand(verb: "step", directObject: "platform", prepositions: "onto")
        )
    }

    @Test("Climb under modified object")
    func climbUnderModifiedObject() {
        expectNoDifference(
            nitfol.parse("climb under the dusty table"),
            ParsedCommand(
                verb: "climb",
                directObject: "table",
                directObjectModifiers: ["dusty"],
                prepositions: "under"
            )
        )
    }
}
