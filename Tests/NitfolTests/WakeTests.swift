import CustomDump
import Nitfol
import Testing

struct WakeTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Wake target")
    func wakeTarget() {
        expectNoDifference(
            nitfol.parse("wake guard"),
            ParsedCommand(verb: "wake", directObject: "guard")
        )
    }

    @Test("Wake modified target")
    func wakeModifiedTarget() {
        expectNoDifference(
            nitfol.parse("rouse the sleeping troll"),
            ParsedCommand(verb: "rouse", directObject: "troll", directObjectModifiers: ["sleeping"])
        )
    }

    @Test("Wake up")
    func wakeUp() {
        expectNoDifference(
            nitfol.parse("wake up"),
            ParsedCommand(verb: "wake", prepositions: "up")
        )
    }

    @Test("Wake up person")
    func wakeUpPerson() {
        expectNoDifference(
            nitfol.parse("wake up the guard"),
            ParsedCommand(verb: "wake", directObject: "guard", prepositions: "up")
        )
    }
}
