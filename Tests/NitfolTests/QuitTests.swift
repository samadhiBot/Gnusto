import CustomDump
import Nitfol
import Testing

struct QuitTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Quit")
    func quit() {
        expectNoDifference(
            nitfol.parse("quit"),
            ParsedCommand(verb: "quit")
        )
    }

    @Test("Exit")
    func exit() {
        expectNoDifference(
            nitfol.parse("exit"),
            ParsedCommand(verb: "exit")
        )
    }
}
