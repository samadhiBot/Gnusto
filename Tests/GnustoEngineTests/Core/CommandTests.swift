import Testing
@testable import GnustoEngine

@Suite("Command Struct Tests")
struct CommandTests {

    // --- Test Setup ---
    let verbGo: VerbID = "go"
    let verbTake: VerbID = "take"
    let verbPut: VerbID = "put"

    let itemLantern: ItemID = "lantern"
    let itemCase: ItemID = "case"

    let modsShiny = ["shiny"]
    let modsBrass = ["brass"]
    let prepIn = "in"

    // --- Tests ---

    @Test("Command Initialization - Verb Only")
    func testCommandInitVerbOnly() throws {
        let raw = "north"
        let command = Command(verbID: verbGo, rawInput: raw)

        #expect(command.verbID == verbGo)
        #expect(command.directObject == nil)
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.preposition == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Command Initialization - Verb + Direct Object")
    func testCommandInitVerbDirect() throws {
        let raw = "take lantern"
        let command = Command(verbID: verbTake, directObject: .item(itemLantern), rawInput: raw)

        #expect(command.verbID == verbTake)
        #expect(command.directObject == .item(itemLantern))
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.preposition == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Command Initialization - Verb + Direct Object + Modifiers")
    func testCommandInitVerbDirectMods() throws {
        let raw = "take shiny lantern"
        let command = Command(verbID: verbTake, directObject: .item(itemLantern), directObjectModifiers: modsShiny, rawInput: raw)

        #expect(command.verbID == verbTake)
        #expect(command.directObject == .item(itemLantern))
        #expect(command.directObjectModifiers == modsShiny)
        #expect(command.indirectObject == nil)
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.preposition == nil)
        #expect(command.rawInput == raw)
    }

    @Test("Command Initialization - Verb + Direct + Preposition + Indirect")
    func testCommandInitVerbDirectPrepIndirect() throws {
        let raw = "put lantern in case"
        let command = Command(
            verbID: verbPut,
            directObject: .item(itemLantern),
            indirectObject: .item(itemCase),
            preposition: prepIn,
            rawInput: raw
        )

        #expect(command.verbID == verbPut)
        #expect(command.directObject == .item(itemLantern))
        #expect(command.directObjectModifiers.isEmpty)
        #expect(command.indirectObject == .item(itemCase))
        #expect(command.indirectObjectModifiers.isEmpty)
        #expect(command.preposition == prepIn)
        #expect(command.rawInput == raw)
    }

    @Test("Command Initialization - Full Complexity")
    func testCommandInitFull() throws {
        let raw = "put shiny lantern in brass case"
        let command = Command(
            verbID: verbPut,
            directObject: .item(itemLantern),
            directObjectModifiers: modsShiny,
            indirectObject: .item(itemCase),
            indirectObjectModifiers: modsBrass,
            preposition: prepIn,
            rawInput: raw
        )

        #expect(command.verbID == verbPut)
        #expect(command.directObject == .item(itemLantern))
        #expect(command.directObjectModifiers == modsShiny)
        #expect(command.indirectObject == .item(itemCase))
        #expect(command.indirectObjectModifiers == modsBrass)
        #expect(command.preposition == prepIn)
        #expect(command.rawInput == raw)
    }

    @Test("Command Value Semantics")
    func testCommandValueSemantics() throws {
        // Since all properties are `let`, Command is implicitly immutable after creation.
        // We just test that assignment creates a true copy.
        let command1 = Command(verbID: verbTake, directObject: .item(itemLantern), rawInput: "take lantern")
        let command2 = command1 // Creates a copy

        // There's nothing mutable to change in command2, but we verify the copy has the same values.
        #expect(command1.verbID == command2.verbID)
        #expect(command1.directObject == command2.directObject)
        #expect(command1.rawInput == command2.rawInput)

        // If Command becomes mutable later, expand this test.
    }
}
