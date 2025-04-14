import CustomDump
import Nitfol
import Testing

struct ThrowTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Throw object")
    func throwObject() {
        expectNoDifference(
            nitfol.parse("throw rock"),
            ParsedCommand(verb: "throw", directObject: "rock")
        )
    }

    @Test("Throw modified object")
    func throwModifiedObject() {
        expectNoDifference(
            nitfol.parse("toss the sharp knife"),
            ParsedCommand(verb: "toss", directObject: "knife", directObjectModifiers: ["sharp"])
        )
    }

    @Test("Throw object at target")
    func throwObjectAtTarget() {
        expectNoDifference(
            nitfol.parse("throw stone at troll"),
            ParsedCommand(verb: "throw", directObject: "stone", prepositions: "at", indirectObject: "troll")
        )
    }

    @Test("Throw modified object at modified target")
    func throwModifiedObjectAtModifiedTarget() {
        expectNoDifference(
            nitfol.parse("hurl the heavy axe at the charging orc"),
            ParsedCommand(
                verb: "hurl",
                directObject: "axe",
                directObjectModifiers: ["heavy"],
                prepositions: "at",
                indirectObject: "orc",
                indirectObjectModifiers: ["charging"]
            )
        )
    }

    @Test("Throw object direction")
    func throwObjectDirection() {
        expectNoDifference(
            nitfol.parse("throw spear north"),
            // Assuming direction is IO, no preposition
            ParsedCommand(verb: "throw", directObject: "spear", prepositions: "north")
        )
    }
}
