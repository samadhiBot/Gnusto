import CustomDump
import Nitfol
import Testing

struct WaitTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Wait")
    func wait() {
        expectNoDifference(
            nitfol.parse("wait"),
            ParsedCommand(verb: "wait")
        )
    }

    @Test("Z (abbreviation)")
    func zAbbreviation() {
        expectNoDifference(
            nitfol.parse("z"),
            ParsedCommand(verb: "z")
        )
    }
}
