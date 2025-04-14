import CustomDump
import Nitfol
import Testing

struct FillTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Fill container")
    func fillContainer() {
        expectNoDifference(
            nitfol.parse("fill bottle"),
            ParsedCommand(verb: "fill", directObject: "bottle")
        )
    }

    @Test("Fill container up")
    func fillContainerUp() {
        expectNoDifference(
            nitfol.parse("fill bottle up"),
            ParsedCommand(verb: "fill", directObject: "bottle", prepositions: "up")
        )
    }

    @Test("Fill modified container")
    func fillModifiedContainer() {
        expectNoDifference(
            nitfol.parse("fill the empty bucket"),
            ParsedCommand(verb: "fill", directObject: "bucket", directObjectModifiers: ["empty"])
        )
    }

    @Test("Fill container with substance")
    func fillContainerWithSubstance() {
        expectNoDifference(
            nitfol.parse("fill vial with water"),
            ParsedCommand(verb: "fill", directObject: "vial", prepositions: "with", indirectObject: "water")
        )
    }

    @Test("Fill modified container with modified substance")
    func fillModifiedContainerWithModifiedSubstance() {
        expectNoDifference(
            nitfol.parse("fill the large jug with the clear wine"),
            ParsedCommand(
                verb: "fill",
                directObject: "jug",
                directObjectModifiers: ["large"],
                prepositions: "with",
                indirectObject: "wine",
                indirectObjectModifiers: ["clear"]
            )
        )
    }

    @Test("Fill container from source")
    func fillContainerFromSource() {
        expectNoDifference(
            nitfol.parse("fill waterskin from fountain"),
            ParsedCommand(verb: "fill", directObject: "waterskin", prepositions: "from", indirectObject: "fountain")
        )
    }

    @Test("Fill modified container from modified source")
    func fillModifiedContainerFromModifiedSource() {
        expectNoDifference(
            nitfol.parse("fill the brass lamp from the oily barrel"),
            ParsedCommand(
                verb: "fill",
                directObject: "lamp",
                directObjectModifiers: ["brass"],
                prepositions: "from",
                indirectObject: "barrel",
                indirectObjectModifiers: ["oily"]
            )
        )
    }
}
