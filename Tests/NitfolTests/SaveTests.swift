import CustomDump
import Nitfol
import Testing

struct SaveTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Save")
    func save() {
        expectNoDifference(
            nitfol.parse("save"),
            ParsedCommand(verb: "save")
        )
    }
}
