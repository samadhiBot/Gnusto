import CustomDump
import Testing

@testable import Gnusto

@Suite("Wear/PutOn Parser Tests")
struct WearParserTests {
    let parser: CommandParser

    init() throws {
        // Initialize the parser (might need world/vocabulary if synonyms are complex)
        parser = try CommandParser()
    }

    // Helper to get UserInput from parsed Action
    func getUserInput(
        from action: Action,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> UserInput {
        guard case .command(let userInput) = action else {
            throw TestFailure("Expected .command action, got \(action)")
        }
        return userInput
    }

    @Test("wear cloak")
    func wearCloak() throws {
        let input = try getUserInput(from: parser.parse("wear cloak"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "cloak")
    }

    @Test("put on cloak")
    func putOnCloak() throws {
        let input = try getUserInput(from: parser.parse("put on cloak"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.prepositions == ["on"])
    }

    @Test("put cloak on")
    func putCloakOn() throws {
        let input = try getUserInput(from: parser.parse("put cloak on"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.prepositions == ["on"])
    }

    @Test("put the cloak on")
    func putTheCloakOn() throws {
        let input = try getUserInput(from: parser.parse("put the cloak on"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.prepositions == ["on"])
    }

    // These tests check parsing of "put X on Y", which is ambiguous.
    // Does it mean Wear X, or Put X onto Y (surface)?
    // The parser (Nitfol) might make a guess or require the handler to disambiguate.
    // Assuming parser treats this as PutIn for now.
    @Test("put the cloak on me")
    func putTheCloakOnMe() throws {
        let input = try getUserInput(from: parser.parse("put the cloak on me"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.indirectObject == "me")
        #expect(input.prepositions == ["on"])
    }

    @Test("put the cloak on myself")
    func putTheCloakOnMyself() throws {
        let input = try getUserInput(from: parser.parse("put the cloak on myself"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.indirectObject == "myself")
        #expect(input.prepositions == ["on"])
    }

    @Test("put the cloak on self")
    func putTheCloakOnSelf() throws {
        let input = try getUserInput(from: parser.parse("put the cloak on self"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.indirectObject == "self")
        #expect(input.prepositions == ["on"])
    }

    @Test("put cloak on table")
    func putCloakOnTable() throws {
        let input = try getUserInput(from: parser.parse("put cloak on table"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.indirectObject == "table")
        #expect(input.prepositions == ["on"])
    }

    @Test("put the cloak on the table")
    func putTheCloakOnTheTable() throws {
        let input = try getUserInput(from: parser.parse("put the cloak on the table"))
        #expect(input.verb == "put")
        #expect(input.directObject == "cloak")
        #expect(input.indirectObject == "table") // Assumes parser filters "the"
        #expect(input.prepositions == ["on"])
    }

    @Test("wear robe")
    func wearRobe() throws {
        let input = try getUserInput(from: parser.parse("wear robe"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "robe")
    }

    @Test("wear the robe")
    func wearTheRobe() throws {
        let input = try getUserInput(from: parser.parse("wear the robe"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "robe")
    }

    @Test("wear velvet cloak")
    func wearVelvetCloak() throws {
        let input = try getUserInput(from: parser.parse("wear velvet cloak"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "cloak")
        #expect(input.directObjectModifiers == ["velvet"])
    }

    @Test("wear the cloak")
    func wearTheCloak() throws {
        let input = try getUserInput(from: parser.parse("wear the cloak"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "cloak")
    }

    @Test("wear the velvet cloak")
    func wearTheVelvetCloak() throws {
        let input = try getUserInput(from: parser.parse("wear the velvet cloak"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "cloak")
        #expect(input.directObjectModifiers == ["velvet"])
    }

    @Test("wear the velvety cloak")
    func wearTheVelvetyCloak() throws {
        let input = try getUserInput(from: parser.parse("wear the velvety cloak"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "cloak")
        #expect(input.directObjectModifiers == ["velvety"])
    }

    @Test("wear command without object")
    func wearCommandWithoutObject() throws {
        let input = try getUserInput(from: parser.parse("wear"))
        #expect(input.verb == "wear")
        #expect(input.directObject == nil)
    }

    @Test("wear hat")
    func wearHat() throws {
        let input = try getUserInput(from: parser.parse("wear hat"))
        #expect(input.verb == "wear")
        #expect(input.directObject == "hat")
    }
}
