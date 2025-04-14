import CustomDump
import Nitfol
import Testing

struct TakeTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Take object")
    func takeObject() {
        expectNoDifference(
            nitfol.parse("take lamp"),
            ParsedCommand(verb: "take", directObject: "lamp")
        )
    }

    @Test("Take modified object")
    func takeModifiedObject() {
        expectNoDifference(
            nitfol.parse("get the rusty key"),
            ParsedCommand(verb: "get", directObject: "key", directObjectModifiers: ["rusty"])
        )
    }

    @Test("Pick up object")
    func pickUpObject() {
        expectNoDifference(
            nitfol.parse("pick up coin"),
            ParsedCommand(verb: "pick", directObject: "coin", prepositions: "up")
        )
    }

    @Test("Grab object")
    func grabObject() {
        expectNoDifference(
            nitfol.parse("grab the shiny sword"),
            ParsedCommand(verb: "grab", directObject: "sword", directObjectModifiers: ["shiny"])
        )
    }
}
