import CustomDump
import Testing

@testable import GnustoEngine

@Suite("FindActionHandler Tests")
struct FindActionHandlerTests {
    let handler = FindActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        let heldItem = Item(id: "heldItem", .name("a held thing"), .in(.player))
        let roomItem = Item(id: "roomItem", .name("a room thing"), .in(.location("room")))
        let otherItem = Item(id: "otherItem", .name("an other thing"), .in(.location("otherRoom")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [
                Location(id: "room", .name("Room")),
                Location(id: "otherRoom", .name("Other Room")),
            ],
            items: [heldItem, roomItem, otherItem]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("FIND <item> syntax works")
    func testFindSyntax() async throws {
        try await engine.execute("find heldItem")
        let output = await mockIO.flush()
        #expect(output.contains("You have it."))
    }

    @Test("LOCATE <item> syntax works")
    func testLocateSyntax() async throws {
        try await engine.execute("locate heldItem")
        let output = await mockIO.flush()
        #expect(output.contains("You have it."))
    }

    @Test("SEARCH FOR <item> syntax works")
    func testSearchForSyntax() async throws {
        let searchVerb = Verb(id: .search, synonyms: ["search"])
        let parser = StandardParser(vocabulary: Vocabulary(verbs: [searchVerb]))
        let command = try parser.parse("search for heldItem")

        // Manually create context and process to test this specific syntax
        let context = ActionContext(
            command: command,
            engine: engine,
            message: ZorkMessageProvider(engine: engine)
        )

        let result = try await handler.process(context: context)
        #expect(result.message.contains("You have it."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectIsMissing() async throws {
        try await engine.execute("find")
        let output = await mockIO.flush()
        #expect(output.contains("Find what?"))
    }

    // MARK: - Processing Testing

    @Test("Responds correctly when player is holding the item")
    func testProcessFindsHeldItem() async throws {
        try await engine.execute("find heldItem")
        let output = await mockIO.flush()
        #expect(output.contains("You have it."))
    }

    @Test("Responds correctly when item is in the current location")
    func testProcessFindsItemInLocation() async throws {
        try await engine.execute("find roomItem")
        let output = await mockIO.flush()
        #expect(output.contains("It's right here!"))
    }

    @Test("Responds correctly when item is not in scope")
    func testProcessFailsToFindItemOutOfScope() async throws {
        try await engine.execute("find otherItem")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing here."))
    }

    @Test("Responds correctly for non-existent item")
    func testProcessFailsToFindNonExistentItem() async throws {
        try await engine.execute("find unicorn")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing here."))
    }

    // MARK: - ActionID Testing

    @Test("FIND action resolves to FindActionHandler")
    func testFindActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("find thing")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is FindActionHandler)
    }
}
