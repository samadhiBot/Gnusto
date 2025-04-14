import CustomDump
import Nitfol
import Testing

struct TouchTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Touch object")
    func touchObject() {
        expectNoDifference(
            nitfol.parse("touch stone"),
            ParsedCommand(verb: "touch", directObject: "stone")
        )
    }

    @Test("Touch modified object")
    func touchModifiedObject() {
        expectNoDifference(
            nitfol.parse("feel the smooth wall"),
            ParsedCommand(verb: "feel", directObject: "wall", directObjectModifiers: ["smooth"])
        )
    }

    @Test("Rub object")
    func rubObject() {
        expectNoDifference(
            nitfol.parse("rub lamp"),
            ParsedCommand(verb: "rub", directObject: "lamp")
        )
    }

    @Test("Pat object")
    func patObject() {
        expectNoDifference(
            nitfol.parse("pat the sleeping dog"), // Assuming dog is parsed as DO
            ParsedCommand(verb: "pat", directObject: "dog", directObjectModifiers: ["sleeping"])
        )
    }
}
