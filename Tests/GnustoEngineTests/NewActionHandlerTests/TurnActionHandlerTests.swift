import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TurnActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'turn <item>'")
    func testSyntaxTurn() async throws {
        let handler = TurnActionHandler()
        let syntax = try handler.syntax.primary.parse("turn dial")
        #expect(syntax.verb == .turn)
        #expect(syntax.directObject == .item(id: "dial"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("turn")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn
            Turn what?
            """)
    }

    @Test("Validation fails if item is not reachable")
    func testValidationFailsIfUnreachable() async throws {
        let dial = Item(id: "dial", .name("a dial"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: dial)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn dial")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn dial
            You can’t see any dial here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Turning a dial")
    func testTurnDial() async throws {
        let dial = Item(id: "dial", .name("the dial"), .isDial, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: dial)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn dial")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn dial
            You turn the dial. It clicks into a new position.
            """)
    }

    @Test("Turning a key")
    func testTurnKey() async throws {
        let key = Item(id: "key", .name("the key"), .isKey, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: key)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn key")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn key
            You can’t just turn the key by itself. You need to use it with something.
            """)
    }

    @Test("Turning a character")
    func testTurnCharacter() async throws {
        let troll = Item(id: "troll", .name("the troll"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: troll)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("turn troll")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > turn troll
            You can’t turn the troll around like an object.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TurnActionHandler().actionID == .turn)
    }
}
