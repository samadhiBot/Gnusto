import CustomDump
import Nitfol
import Testing

struct ReadTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Read object")
    func readObject() {
        expectNoDifference(
            nitfol.parse("read sign"),
            ParsedCommand(verb: "read", directObject: "sign")
        )
    }

    @Test("Read modified object")
    func readModifiedObject() {
        expectNoDifference(
            nitfol.parse("skim the dusty scroll"),
            ParsedCommand(verb: "skim", directObject: "scroll", directObjectModifiers: ["dusty"])
        )
    }

    @Test("Peruse object")
    func peruseObject() {
        expectNoDifference(
            nitfol.parse("peruse book"),
            ParsedCommand(verb: "peruse", directObject: "book")
        )
    }
}
