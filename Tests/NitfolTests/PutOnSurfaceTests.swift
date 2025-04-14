import CustomDump
import Nitfol
import Testing

struct PutOnSurfaceTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Put item on surface")
    func putItemOnSurface() {
        expectNoDifference(
            nitfol.parse("put book on table"),
            ParsedCommand(verb: "put", directObject: "book", prepositions: "on", indirectObject: "table")
        )
    }

    @Test("Put modified item on modified surface")
    func putModifiedItemOnModifiedSurface() {
        expectNoDifference(
            nitfol.parse("set the brass lamp onto the dusty shelf"),
            ParsedCommand(
                verb: "set",
                directObject: "lamp",
                directObjectModifiers: ["brass"],
                prepositions: "onto",
                indirectObject: "shelf",
                indirectObjectModifiers: ["dusty"]
            )
        )
    }

    @Test("Place item atop surface")
    func placeItemAtopSurface() {
        expectNoDifference(
            nitfol.parse("place statue atop pedestal"),
            ParsedCommand(verb: "place", directObject: "statue", prepositions: "atop", indirectObject: "pedestal")
        )
    }
}
