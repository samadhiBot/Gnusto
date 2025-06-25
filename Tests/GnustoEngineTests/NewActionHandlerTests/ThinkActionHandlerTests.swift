import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct ThinkActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'think about <topic>'")
    func testSyntaxThinkAbout() async throws {
        let handler = ThinkActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.think)) })!
            .parse("think about sword")
        #expect(syntax.verb == .think)
        #expect(syntax.directObject == .item(id: "sword"))
    }

    @Test("Syntax for 'consider <topic>'")
    func testSyntaxConsider() async throws {
        let handler = ThinkActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.verb(.consider)) })!
            .parse("consider sword")
        #expect(syntax.verb == .think)
        #expect(syntax.directObject == .item(id: "sword"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("think")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think
            Think about what?
            """)
    }

    @Test("Validation fails for unreachable item")
    func testValidationFailsForUnreachableItem() async throws {
        let sword = Item(id: "sword", .name("a sword"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("think about sword")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about sword
            You can’t see any sword here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Thinking about an item")
    func testThinkAboutItem() async throws {
        let sword = Item(id: "sword", .name("a sword"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("think about sword")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about sword
            You contemplate the sword for a bit, but nothing fruitful comes to mind.
            """)

        let touched = try await engine.item("sword").hasFlag(.isTouched)
        #expect(touched)
    }

    @Test("Thinking about player")
    func testThinkAboutPlayer() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame.lit())

        try await engine.execute("think about me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > think about me
            Yes, yes, you’re very important.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(ThinkActionHandler().actionID == .think)
    }
}
