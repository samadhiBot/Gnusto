import CustomDump
import Nitfol
import Testing

struct PutInTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Put item in container")
    func putItemInContainer() {
        expectNoDifference(
            nitfol.parse("put coin in pouch"),
            ParsedCommand(verb: "put", directObject: "coin", prepositions: "in", indirectObject: "pouch")
        )
    }

    @Test("Put item in implied container")
    func putItemInImpliedContainer() {
        expectNoDifference(
            nitfol.parse("put coin in"),
            ParsedCommand(verb: "put", directObject: "coin", prepositions: "in")
        )

        expectNoDifference(
            nitfol.parse("put in coin"),
            ParsedCommand(verb: "put", directObject: "coin", prepositions: "in")
        )
    }

    @Test("Put modified item in modified container")
    func putModifiedItemInModifiedContainer() {
        expectNoDifference(
            nitfol.parse("insert the silver key into the rusty lock"),
            ParsedCommand(
                verb: "insert",
                directObject: "lock",
                directObjectModifiers: ["rusty"],
                prepositions: "into",
                indirectObject: "key",
                indirectObjectModifiers: ["silver"]
            )
        )
    }

    @Test("Place item inside container")
    func placeItemInsideContainer() {
        expectNoDifference(
            nitfol.parse("place scroll inside tube"),
            ParsedCommand(verb: "place", directObject: "scroll", prepositions: "inside", indirectObject: "tube")
        )
    }
}
