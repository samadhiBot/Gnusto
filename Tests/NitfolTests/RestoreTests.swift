import CustomDump
import Nitfol
import Testing

struct RestoreTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Restore")
    func restore() {
        expectNoDifference(
            nitfol.parse("restore"),
            ParsedCommand(verb: "restore")
        )
    }

    @Test("Load")
    func load() {
        expectNoDifference(
            nitfol.parse("load"),
            ParsedCommand(verb: "load")
        )
    }
}
