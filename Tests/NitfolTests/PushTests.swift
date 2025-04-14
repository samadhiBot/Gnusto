import CustomDump
import Nitfol
import Testing

struct PushTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Push object")
    func pushObject() {
        expectNoDifference(
            nitfol.parse("push boulder"),
            ParsedCommand(verb: "push", directObject: "boulder")
        )
    }

    @Test("Push in object")
    func pushInObject() {
        expectNoDifference(
            nitfol.parse("push in keycard"),
            ParsedCommand(verb: "push", directObject: "keycard", prepositions: "in")
        )
    }

    @Test("Push object in")
    func pushObjectIn() {
        expectNoDifference(
            nitfol.parse("push keycard in"),
            ParsedCommand(verb: "push", directObject: "keycard", prepositions: "in")
        )
    }

    @Test("Push modified object")
    func pushModifiedObject() {
        expectNoDifference(
            nitfol.parse("shove the large crate"),
            ParsedCommand(verb: "shove", directObject: "crate", directObjectModifiers: ["large"])
        )
    }

    @Test("Press object")
    func pressObject() {
        expectNoDifference(
            nitfol.parse("press button"),
            ParsedCommand(verb: "press", directObject: "button")
        )
    }
}
