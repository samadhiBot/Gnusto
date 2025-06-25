import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RemoveActionHandler Tests")
struct RemoveActionHandlerTests {
    let handler = RemoveActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var cloak: Item!
    var hat: Item!
    var boots: Item!  // Not worn

    @Before
    func setup() {
        cloak = Item(id: "cloak", .name("velvet cloak"), .isWearable, .isWorn, .in(.player))
        hat = Item(id: "hat", .name("top hat"), .isWearable, .isWorn, .in(.player))
        boots = Item(id: "boots", .name("leather boots"), .isWearable, .in(.player))  // Not worn

        game = MinimalGame(
            player: Player(in: "room"),
            items: [cloak, hat, boots]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("REMOVE <item> syntax works")
    func testRemoveSyntax() async throws {
        try await engine.execute("remove cloak")
        let output = await mockIO.flush()
        #expect(output.contains("You take off the velvet cloak."))
    }

    @Test("TAKE OFF <item> synonym works")
    func testTakeOffSyntax() async throws {
        let takeVerb = Verb(id: .take, synonyms: ["take"])
        let customVocabulary = Vocabulary(verbs: [takeVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("take off cloak")
        let output = await mockIO.flush()
        #expect(output.contains("You take off the velvet cloak."))
    }

    @Test("DOFF <item> synonym works")
    func testDoffSyntax() async throws {
        let doffVerb = Verb(id: .remove, synonyms: ["remove", "doff"])
        let customVocabulary = Vocabulary(verbs: [doffVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("doff hat")
        let output = await mockIO.flush()
        #expect(output.contains("You take off the top hat."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("remove")
        let output = await mockIO.flush()
        #expect(output.contains("Remove what?"))
    }

    @Test("Fails when item is not worn")
    func testValidationFailsWhenNotWorn() async throws {
        try await engine.execute("remove boots")
        let output = await mockIO.flush()
        #expect(output.contains("You aren’t wearing the leather boots."))
    }

    // MARK: - Processing Testing

    @Test("Removing an item clears isWorn and sets isTouched")
    func testProcessRemoveFlags() async throws {
        try await engine.update(item: "cloak") { $0.clearFlag(.isTouched) }
        var cloakState = try await engine.item("cloak")
        #expect(cloakState.hasFlag(.isWorn) == true)
        #expect(cloakState.hasFlag(.isTouched) == false)

        try await engine.execute("remove cloak")

        cloakState = try await engine.item("cloak")
        #expect(cloakState.hasFlag(.isWorn) == false)
        #expect(cloakState.hasFlag(.isTouched) == true)
    }

    @Test("REMOVE ALL works")
    func testRemoveAll() async throws {
        try await engine.execute("remove all")
        let output = await mockIO.flush()
        #expect(output.contains("You take off the velvet cloak and the top hat."))

        let cloakState = try await engine.item("cloak")
        let hatState = try await engine.item("hat")
        #expect(cloakState.hasFlag(.isWorn) == false)
        #expect(hatState.hasFlag(.isWorn) == false)
    }

    @Test("REMOVE ALL with nothing worn")
    func testRemoveAllNothingWorn() async throws {
        try await engine.update(item: "cloak") { $0.clearFlag(.isWorn) }
        try await engine.update(item: "hat") { $0.clearFlag(.isWorn) }

        try await engine.execute("remove all")
        let output = await mockIO.flush()
        #expect(output.contains("You aren’t wearing anything."))
    }

    // MARK: - ActionID Testing

    @Test("REMOVE action resolves to RemoveActionHandler")
    func testRemoveActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("remove cloak")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is RemoveActionHandler)
    }
}
