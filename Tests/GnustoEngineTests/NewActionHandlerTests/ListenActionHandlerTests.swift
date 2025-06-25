import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ListenActionHandler Tests")
struct ListenActionHandlerTests {
    let handler = ListenActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    @Before
    func setup() {
        let rock = Item(id: "rock", .name("rock"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rock]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("LISTEN syntax works")
    func testListenSyntax() async throws {
        try await engine.execute("listen")
        let output = await mockIO.flush()
        #expect(output.contains("You hear nothing unusual."))
    }

    @Test("LISTEN TO <item> syntax works")
    func testListenToItemSyntax() async throws {
        try await engine.execute("listen to rock")
        let output = await mockIO.flush()
        #expect(output.contains("You hear nothing unusual."))
    }

    // MARK: - Processing Testing

    @Test("Processing always returns the same message")
    func testProcessReturnsConstantMessage() async throws {
        let context = ActionContext(command: Command(verb: .listen), engine: engine)
        let result = try await handler.process(context: context)
        #expect(result.message == "You hear nothing unusual.")
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("LISTEN action resolves to ListenActionHandler")
    func testListenActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("listen")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is ListenActionHandler)
    }
}
