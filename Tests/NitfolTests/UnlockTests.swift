import CustomDump
import Nitfol
import Testing

struct UnlockTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Unlock object")
    func unlockObject() {
        expectNoDifference(
            nitfol.parse("unlock door"),
            ParsedCommand(verb: "unlock", directObject: "door")
        )
    }

    @Test("Unlock modified object")
    func unlockModifiedObject() {
        expectNoDifference(
            nitfol.parse("unlock the heavy chest"),
            ParsedCommand(verb: "unlock", directObject: "chest", directObjectModifiers: ["heavy"])
        )
    }

    @Test("Unlock object with key")
    func unlockObjectWithKey() {
        expectNoDifference(
            nitfol.parse("unlock gate with key"),
            ParsedCommand(verb: "unlock", directObject: "gate", prepositions: "with", indirectObject: "key")
        )
    }

    @Test("Unlock modified object with modified key")
    func unlockModifiedObjectWithModifiedKey() {
        expectNoDifference(
            nitfol.parse("unlock the sturdy safe with the small brass key"),
            ParsedCommand(
                verb: "unlock",
                directObject: "safe",
                directObjectModifiers: ["sturdy"],
                prepositions: "with",
                indirectObject: "key",
                indirectObjectModifiers: ["small", "brass"]
            )
        )
    }
}
