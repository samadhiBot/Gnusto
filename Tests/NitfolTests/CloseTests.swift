import CustomDump
import Nitfol
import Testing

struct CloseTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Close object")
    func closeObject() {
        expectNoDifference(
            nitfol.parse("close door"),
            ParsedCommand(verb: "close", directObject: "door")
        )
    }

    @Test("Close modified object")
    func closeModifiedObject() {
        expectNoDifference(
            nitfol.parse("shut the heavy chest"),
            ParsedCommand(verb: "shut", directObject: "chest", directObjectModifiers: ["heavy"])
        )
    }

    @Test("Shut window")
    func shutWindow() {
        expectNoDifference(
            nitfol.parse("shut window"),
            ParsedCommand(verb: "shut", directObject: "window")
        )
    }
}
