import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookUnderActionHandler Tests")
struct LookUnderActionHandlerTests {
    let handler = LookUnderActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rug: Item!

    @Before
    func setup() {
        rug = Item(id: "rug", .name("persian rug"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rug]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("LOOK UNDER <item> syntax works")
    func testLookUnderSyntax() async throws {
        try await engine.execute("look under rug")
        let output = await mockIO.flush()
        #expect(output.contains("You find nothing of interest under the persian rug."))
    }

    @Test("PEEK UNDER <item> synonym works")
    func testPeekUnderSyntax() async throws {
        let peekVerb = Verb(id: .look, synonyms: ["look", "peek"])
        let customVocabulary = Vocabulary(verbs: [peekVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("peek under rug")
        let output = await mockIO.flush()
        #expect(output.contains("You find nothing of interest under the persian rug."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("look under")
        let output = await mockIO.flush()
        #expect(output.contains("Look under what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "rug") { $0.parent = .location("otherRoom") }
        try await engine.execute("look under rug")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Looking under an item touches it")
    func testProcessLookUnderTouchesItem() async throws {
        try await engine.update(item: "rug") { $0.clearFlag(.isTouched) }
        var rugState = try await engine.item("rug")
        #expect(rugState.hasFlag(.isTouched) == false)

        try await engine.execute("look under rug")

        rugState = try await engine.item("rug")
        #expect(rugState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("LOOK UNDER action resolves to LookUnderActionHandler")
    func testLookUnderActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("look under rug")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is LookUnderActionHandler)
    }
}
