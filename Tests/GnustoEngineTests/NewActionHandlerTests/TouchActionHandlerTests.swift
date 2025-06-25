import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TouchActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'touch <item>'")
    func testSyntaxTouch() async throws {
        let handler = TouchActionHandler()
        let syntax = try handler.syntax.primary.parse("touch rock")
        #expect(syntax.verb == .touch)
        #expect(syntax.directObject == .item(id: "rock"))
    }

    @Test("Syntax for 'feel <item>'")
    func testSyntaxFeel() async throws {
        let handler = TouchActionHandler()
        let syntax = try handler.syntax.primary.parse("feel rock")
        #expect(syntax.verb == .touch)
        #expect(syntax.directObject == .item(id: "rock"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("touch")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch
            Touch what?
            """)
    }

    @Test("Validation fails if item is not reachable")
    func testValidationFailsIfUnreachable() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("touch rock")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch rock
            You can’t see any rock here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Touching an item sets isTouched flag")
    func testTouchItem() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("touch rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > touch rock
            You feel nothing special.
            """)

        let finalRock = try await engine.item("rock")
        #expect(finalRock.hasFlag(.isTouched))
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TouchActionHandler().actionID == .touch)
    }
}
