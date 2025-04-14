import CustomDump
import Nitfol
import Testing

struct SearchTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Search container")
    func searchContainer() {
        expectNoDifference(
            nitfol.parse("search chest"),
            ParsedCommand(verb: "search", directObject: "chest")
        )
    }

    @Test("Search for object")
    func searchForContainer() {
        expectNoDifference(
            nitfol.parse("search for clues"),
            ParsedCommand(verb: "search", directObject: "clues", prepositions: "for")
        )
    }

    @Test("Search modified container")
    func searchModifiedContainer() {
        expectNoDifference(
            nitfol.parse("search the dusty wardrobe"),
            ParsedCommand(verb: "search", directObject: "wardrobe", directObjectModifiers: ["dusty"])
        )
    }

    @Test("Look in container")
    func lookInContainer() {
        expectNoDifference(
            nitfol.parse("look in sack"),
            ParsedCommand(verb: "look", directObject: "sack", prepositions: "in")
        )
    }

    @Test("Look in modified container")
    func lookInModifiedContainer() {
        expectNoDifference(
            nitfol.parse("look in the old box"),
            ParsedCommand(verb: "look", directObject: "box", directObjectModifiers: ["old"], prepositions: "in")
        )
    }
}
