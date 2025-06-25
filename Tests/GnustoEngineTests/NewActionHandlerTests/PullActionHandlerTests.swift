import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PullActionHandler Tests")
struct PullActionHandlerTests {
    let handler = PullActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rope: Item!
    var rock: Item!

    @Before
    func setup() {
        rope = Item(id: "rope", .name("long rope"), .isPullable, .in(.location("room")))
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rope, rock]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("PULL <item> syntax works")
    func testPullSyntax() async throws {
        try await engine.execute("pull rope")
        let output = await mockIO.flush()
        #expect(output.contains("You pull the long rope."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("pull")
        let output = await mockIO.flush()
        #expect(output.contains("Pull what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "rope") { $0.parent = .location("otherRoom") }
        try await engine.execute("pull rope")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Pulling a non-pullable item fails")
    func testProcessPullNonPullable() async throws {
        try await engine.execute("pull rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t pull the heavy rock."))
    }

    @Test("Pulling an item touches it")
    func testProcessPullTouchesItem() async throws {
        try await engine.update(item: "rope") { $0.clearFlag(.isTouched) }
        var ropeState = try await engine.item("rope")
        #expect(ropeState.hasFlag(.isTouched) == false)

        try await engine.execute("pull rope")

        ropeState = try await engine.item("rope")
        #expect(ropeState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("PULL action resolves to PullActionHandler")
    func testPullActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("pull rope")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is PullActionHandler)
    }
}
