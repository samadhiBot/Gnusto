import CustomDump
import Nitfol
import Testing

struct PullTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Pull object")
    func pullObject() {
        expectNoDifference(
            nitfol.parse("pull lever"),
            ParsedCommand(verb: "pull", directObject: "lever")
        )
    }

    @Test("Pull modified object")
    func pullModifiedObject() {
        expectNoDifference(
            nitfol.parse("yank the rusty chain"),
            ParsedCommand(verb: "yank", directObject: "chain", directObjectModifiers: ["rusty"])
        )
    }

    @Test("Drag object")
    func dragObject() {
        expectNoDifference(
            nitfol.parse("drag crate"),
            ParsedCommand(verb: "drag", directObject: "crate")
        )
    }

    @Test("Carry object")
    func carryObject() {
        expectNoDifference(
            nitfol.parse("carry the heavy torch"),
            ParsedCommand(verb: "carry", directObject: "torch", directObjectModifiers: ["heavy"])
        )
    }
}
