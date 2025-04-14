import CustomDump
import Nitfol
import Testing

struct DropTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Drop object")
    func dropObject() {
        expectNoDifference(
            nitfol.parse("drop rock"),
            ParsedCommand(verb: "drop", directObject: "rock")
        )
    }

    @Test("Drop modified object")
    func dropModifiedObject() {
        expectNoDifference(
            nitfol.parse("drop the heavy sword"),
            ParsedCommand(verb: "drop", directObject: "sword", directObjectModifiers: ["heavy"])
        )
    }

    @Test("Put down object")
    func putDownObject() {
        expectNoDifference(
            nitfol.parse("put down potion"),
            ParsedCommand(verb: "put", directObject: "potion", prepositions: "down")
        )
    }

    @Test("Put object down (split)")
    func putObjectDown() {
        expectNoDifference(
            nitfol.parse("put the lamp down"),
            ParsedCommand(verb: "put", directObject: "lamp", prepositions: "down") // Assuming preposition captures the 'down'
        )
    }

    @Test("Drop all")
    func dropAll() {
        expectNoDifference(
            nitfol.parse("drop all"),
            ParsedCommand(verb: "drop", directObject: "all")
        )
    }

    @Test("Drop everything")
    func dropEverything() {
        expectNoDifference(
            nitfol.parse("drop everything"),
            ParsedCommand(verb: "drop", directObject: "everything")
        )
    }

    @Test("Discard object")
    func discardObject() {
        expectNoDifference(
            nitfol.parse("discard key"),
            ParsedCommand(verb: "discard", directObject: "key")
        )
    }

    @Test("Throw away object")
    func throwAwayObject() {
        expectNoDifference(
            nitfol.parse("throw away the useless trinket"),
            ParsedCommand(verb: "throw", directObject: "trinket", directObjectModifiers: ["useless"], prepositions: "away")
        )
    }

    @Test("Throw object away (split)")
    func throwObjectAway() {
        expectNoDifference(
            nitfol.parse("throw the useless trinket away"),
            ParsedCommand(verb: "throw", directObject: "trinket", directObjectModifiers: ["useless"], prepositions: "away")
        )
    }
}
