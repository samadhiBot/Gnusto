import CustomDump
import Nitfol
import Testing

struct ExamineTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Examine object")
    func examineObject() {
        expectNoDifference(
            nitfol.parse("examine scroll"),
            ParsedCommand(verb: "examine", directObject: "scroll")
        )
    }

    @Test("Examine modified object")
    func examineModifiedObject() {
        expectNoDifference(
            nitfol.parse("inspect the wooden door"),
            ParsedCommand(verb: "inspect", directObject: "door", directObjectModifiers: ["wooden"])
        )
    }

    @Test("Look at object")
    func lookAtObject() {
        expectNoDifference(
            nitfol.parse("look at chest"),
            ParsedCommand(verb: "look", directObject: "chest", prepositions: "at")
        )
    }

    @Test("Look at modified object")
    func lookAtModifiedObject() {
        expectNoDifference(
            nitfol.parse("look at the strange symbol"),
            ParsedCommand(verb: "look", directObject: "symbol", directObjectModifiers: ["strange"], prepositions: "at")
        )
    }

    @Test("X object (abbreviation)")
    func xObject() {
        expectNoDifference(
            nitfol.parse("x lamp"),
            ParsedCommand(verb: "x", directObject: "lamp")
        )
    }

    @Test("Describe object")
    func describeObject() {
        expectNoDifference(
            nitfol.parse("describe statue"),
            ParsedCommand(verb: "describe", directObject: "statue")
        )
    }

    @Test("Look under object")
    func lookUnderObject() {
        expectNoDifference(
            nitfol.parse("look under table"),
            ParsedCommand(verb: "look", directObject: "table", prepositions: "under")
        )
    }

    @Test("Look under modified object")
    func lookUnderModifiedObject() {
        expectNoDifference(
            nitfol.parse("look under the dusty bed"),
            ParsedCommand(verb: "look", directObject: "bed", directObjectModifiers: ["dusty"], prepositions: "under")
        )
    }
}
