import CustomDump
import Nitfol
import Testing

struct GiveTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Give item to recipient")
    func giveItemToRecipient() {
        expectNoDifference(
            nitfol.parse("give key to guard"),
            ParsedCommand(verb: "give", directObject: "key", prepositions: "to", indirectObject: "guard")
        )
    }

    @Test("Give modified item to modified recipient")
    func giveModifiedItemToModifiedRecipient() {
        expectNoDifference(
            nitfol.parse("offer the shiny coin to the greedy merchant"),
            ParsedCommand(
                verb: "offer",
                directObject: "coin",
                directObjectModifiers: ["shiny"],
                prepositions: "to",
                indirectObject: "merchant",
                indirectObjectModifiers: ["greedy"]
            )
        )
    }

    @Test("Give recipient item")
    func giveRecipientItem() {
        expectNoDifference(
            nitfol.parse("give wizard the potion"),
            ParsedCommand(verb: "give", directObject: "potion", indirectObject: "wizard")
        )
    }

    @Test("Give modified recipient modified item")
    func giveModifiedRecipientModifiedItem() {
        expectNoDifference(
            nitfol.parse("hand the old king the heavy crown"),
            ParsedCommand(
                verb: "hand",
                directObject: "crown",
                directObjectModifiers: ["heavy"],
                indirectObject: "king",
                indirectObjectModifiers: ["old"]
            )
        )
    }
}
