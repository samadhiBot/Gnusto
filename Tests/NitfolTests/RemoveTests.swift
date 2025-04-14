import CustomDump
import Nitfol
import Testing

struct RemoveTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Remove object")
    func removeObject() {
        expectNoDifference(
            nitfol.parse("remove hat"),
            ParsedCommand(verb: "remove", directObject: "hat")
        )
    }

    @Test("Pull out object")
    func pullOutObject() {
        expectNoDifference(
            nitfol.parse("pull out sword"),
            ParsedCommand(verb: "pull", directObject: "sword", prepositions: "out")
        )
    }

    @Test("Pull object out")
    func pullObjectOut() {
        expectNoDifference(
            nitfol.parse("pull sword out"),
            ParsedCommand(verb: "pull", directObject: "sword", prepositions: "out")
        )
    }

    @Test("Remove modified object")
    func removeModifiedObject() {
        expectNoDifference(
            nitfol.parse("remove the leather boots"),
            ParsedCommand(verb: "remove", directObject: "boots", directObjectModifiers: ["leather"])
        )
    }

    @Test("Take off object")
    func takeOffObject() {
        expectNoDifference(
            nitfol.parse("take off helmet"),
            ParsedCommand(verb: "take", directObject: "helmet", prepositions: "off")
        )
    }

    @Test("Take object off (split)")
    func takeObjectOff() {
        expectNoDifference(
            nitfol.parse("take the dusty cloak off"),
            ParsedCommand(verb: "take", directObject: "cloak", directObjectModifiers: ["dusty"], prepositions: "off")
        )
    }
}
