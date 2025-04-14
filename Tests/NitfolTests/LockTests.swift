import CustomDump
import Nitfol
import Testing

struct LockTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Lock object")
    func lockObject() {
        expectNoDifference(
            nitfol.parse("lock door"),
            ParsedCommand(verb: "lock", directObject: "door")
        )
    }

    @Test("Lock up object")
    func lockUpObject() {
        expectNoDifference(
            nitfol.parse("lock up classroom"),
            ParsedCommand(verb: "lock", directObject: "classroom", prepositions: "up")
        )
    }

    @Test("Lock up person")
    func lockUpPerson() {
        expectNoDifference(
            nitfol.parse("lock up thief"),
            ParsedCommand(verb: "lock", directObject: "thief", prepositions: "up")
        )
    }

    @Test("Lock modified object")
    func lockModifiedObject() {
        expectNoDifference(
            nitfol.parse("lock the heavy chest"),
            ParsedCommand(verb: "lock", directObject: "chest", directObjectModifiers: ["heavy"])
        )
    }

    @Test("Lock object with key")
    func lockObjectWithKey() {
        expectNoDifference(
            nitfol.parse("lock gate with key"),
            ParsedCommand(verb: "lock", directObject: "gate", prepositions: "with", indirectObject: "key")
        )
    }

    @Test("Lock modified object with modified key")
    func lockModifiedObjectWithModifiedKey() {
        expectNoDifference(
            nitfol.parse("lock the sturdy safe with the small brass key"),
            ParsedCommand(
                verb: "lock",
                directObject: "safe",
                directObjectModifiers: ["sturdy"],
                prepositions: "with",
                indirectObject: "key",
                indirectObjectModifiers: ["small", "brass"]
            )
        )
    }
}
