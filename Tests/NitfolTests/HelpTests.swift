import CustomDump
import Nitfol
import Testing

struct HelpTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Help")
    func help() {
        expectNoDifference(
            nitfol.parse("help"),
            ParsedCommand(verb: "help")
        )
    }

    @Test("H (abbreviation)")
    func hAbbreviation() {
        expectNoDifference(
            nitfol.parse("h"),
            ParsedCommand(verb: "h")
        )
    }

    @Test("Question Mark (abbreviation)")
    func questionMarkAbbreviation() {
        expectNoDifference(
            nitfol.parse("?"),
            ParsedCommand(verb: "?")
        )
    }
}
