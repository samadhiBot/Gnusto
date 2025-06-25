import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PressActionHandler Tests")
struct PressActionHandlerTests {
    let handler = PressActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var button: Item!
    var rock: Item!

    @Before
    func setup() {
        button = Item(id: "button", .name("red button"), .isPressable, .in(.location("room")))
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [button, rock]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("PRESS <item> syntax works")
    func testPressSyntax() async throws {
        try await engine.execute("press button")
        let output = await mockIO.flush()
        #expect(output.contains("You press the red button."))
    }

    @Test("PUSH <item> synonym works")
    func testPushSyntax() async throws {
        // This tests the synonym resolution within the PressActionHandler
        try await engine.execute("push button")
        let output = await mockIO.flush()
        #expect(output.contains("You press the red button."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("press")
        let output = await mockIO.flush()
        #expect(output.contains("Press what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "button") { $0.parent = .location("otherRoom") }
        try await engine.execute("press button")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Pressing a non-pressable item fails")
    func testProcessPressNonPressable() async throws {
        try await engine.execute("press rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't press the heavy rock."))
    }

    @Test("Pressing an item touches it")
    func testProcessPressTouchesItem() async throws {
        try await engine.update(item: "button") { $0.clearFlag(.isTouched) }
        var buttonState = try await engine.item("button")
        #expect(buttonState.hasFlag(.isTouched) == false)

        try await engine.execute("press button")

        buttonState = try await engine.item("button")
        #expect(buttonState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("PRESS action resolves to PressActionHandler")
    func testPressActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("press button")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is PressActionHandler)
    }
}
