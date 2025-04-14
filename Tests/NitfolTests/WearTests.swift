import CustomDump
import Nitfol
import Testing

struct WearTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Wear object")
    func wearObject() {
        expectNoDifference(
            nitfol.parse("wear boots"),
            ParsedCommand(verb: "wear", directObject: "boots")
        )
    }

    @Test("Wear modified object")
    func wearModifiedObject() {
        expectNoDifference(
            nitfol.parse("wear the leather helmet"),
            ParsedCommand(verb: "wear", directObject: "helmet", directObjectModifiers: ["leather"])
        )
    }

    @Test("Put on object")
    func putOnObject() {
        expectNoDifference(
            nitfol.parse("put on cloak"),
            ParsedCommand(verb: "put", directObject: "cloak", prepositions: "on")
        )
    }

    @Test("Don object")
    func donObject() {
        expectNoDifference(
            nitfol.parse("don the fine robe"),
            ParsedCommand(verb: "don", directObject: "robe", directObjectModifiers: ["fine"])
        )
    }

    @Test("Put object on (split)")
    func putObjectOn() {
        expectNoDifference(
            nitfol.parse("put the heavy gloves on"),
            ParsedCommand(verb: "put", directObject: "gloves", directObjectModifiers: ["heavy"], prepositions: "on")
        )
    }
}
