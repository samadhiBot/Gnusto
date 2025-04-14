import CustomDump
import Nitfol
import Testing

struct BurnTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Burn object")
    func burnObject() {
        expectNoDifference(
            nitfol.parse("burn scroll"),
            ParsedCommand(verb: "burn", directObject: "scroll")
        )
    }

    @Test("Burn modified object")
    func burnModifiedObject() {
        expectNoDifference(
            nitfol.parse("ignite the dry leaves"),
            ParsedCommand(verb: "ignite", directObject: "leaves", directObjectModifiers: ["dry"])
        )
    }

    @Test("Torch modified object")
    func torchModifiedObject() {
        expectNoDifference(
            nitfol.parse("torch the wooden effigy"),
            ParsedCommand(verb: "torch", directObject: "effigy", directObjectModifiers: ["wooden"])
        )
    }

    @Test("Incinerate object")
    func incinerateObject() {
        expectNoDifference(
            nitfol.parse("incinerate paper"),
            ParsedCommand(verb: "incinerate", directObject: "paper")
        )
    }
}
