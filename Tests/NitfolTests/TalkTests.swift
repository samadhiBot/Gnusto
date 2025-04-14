import CustomDump
import Nitfol
import Testing

struct TalkTests {
    let nitfol: Nitfol

    init() throws {
        nitfol = try Nitfol()
    }

    @Test("Talk to recipient")
    func talkToRecipient() {
        expectNoDifference(
            nitfol.parse("talk to guard"),
            ParsedCommand(verb: "talk", directObject: "guard", prepositions: "to")
        )
    }

    @Test("Talk to modified recipient")
    func talkToModifiedRecipient() {
        expectNoDifference(
            nitfol.parse("speak to the old wizard"),
            ParsedCommand(verb: "speak", directObject: "wizard", directObjectModifiers: ["old"], prepositions: "to")
        )
    }

    @Test("Ask recipient about topic")
    func askRecipientAboutTopic() {
        expectNoDifference(
            nitfol.parse("ask merchant about key"),
            ParsedCommand(verb: "ask", directObject: "merchant", prepositions: "about", indirectObject: "key")
        )
    }

    @Test("Ask modified recipient about modified topic")
    func askModifiedRecipientAboutModifiedTopic() {
        expectNoDifference(
            nitfol.parse("ask the strange beggar about the lost amulet"),
            ParsedCommand(
                verb: "ask",
                directObject: "beggar",
                directObjectModifiers: ["strange"],
                prepositions: "about",
                indirectObject: "amulet",
                indirectObjectModifiers: ["lost"]
            )
        )
    }

    @Test("Tell recipient about topic")
    func tellRecipientAboutTopic() {
        expectNoDifference(
            nitfol.parse("tell king about dragon"),
            ParsedCommand(verb: "tell", directObject: "king", prepositions: "about", indirectObject: "dragon")
        )
    }

    @Test("Say phrase")
    func sayPhrase() {
        expectNoDifference(
            nitfol.parse("say hello"),
            ParsedCommand(verb: "say", directObject: "hello")
        )
    }

    @Test("Say phrase to recipient")
    func sayPhraseToRecipient() {
        expectNoDifference(
            nitfol.parse("say password to troll"),
            ParsedCommand(verb: "say", directObject: "password", prepositions: "to", indirectObject: "troll")
        )
    }
}
