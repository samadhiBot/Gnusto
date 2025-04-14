import CustomDump
import Nitfol
import Testing

struct VersionTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Version")
    func version() {
        expectNoDifference(
            nitfol.parse("version"),
            ParsedCommand(verb: "version")
        )
    }

    @Test("About")
    func about() {
        expectNoDifference(
            nitfol.parse("about"),
            ParsedCommand(verb: "about")
        )
    }
}
