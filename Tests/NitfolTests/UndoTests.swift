import CustomDump
import Nitfol
import Testing

struct UndoTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Undo")
    func undo() {
        expectNoDifference(
            nitfol.parse("undo"),
            ParsedCommand(verb: "undo")
        )
    }
}
