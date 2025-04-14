import CustomDump
import Nitfol
import Testing

struct SmellTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Smell object")
    func smellObject() {
        expectNoDifference(
            nitfol.parse("smell flower"),
            ParsedCommand(verb: "smell", directObject: "flower")
        )
    }

    @Test("sniff object")
    func sniffObject() {
        expectNoDifference(
            nitfol.parse("sniff flower"),
            ParsedCommand(verb: "sniff", directObject: "flower")
        )
    }

    @Test("Smell modified object")
    func smellModifiedObject() {
        expectNoDifference(
            nitfol.parse("sniff the strange potion"),
            ParsedCommand(verb: "sniff", directObject: "potion", directObjectModifiers: ["strange"])
        )
    }

    @Test("Smell general")
    func smellGeneral() {
        expectNoDifference(
            nitfol.parse("smell air"),
            ParsedCommand(verb: "smell", directObject: "air")
        )
    }
}
