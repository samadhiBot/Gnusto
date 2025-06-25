import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct SmellActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule accepts 'smell'")
    func testSyntaxRuleSmell() async throws {
        let handler = SmellActionHandler()
        let syntax = try handler.syntax.primary.parse("smell")
        #expect(syntax.verb == .smell)
        #expect(isNil(syntax.directObject))
    }

    @Test("Syntax rule accepts 'smell <item>'")
    func testSyntaxRuleSmellItem() async throws {
        let handler = SmellActionHandler()
        let syntax = try handler.syntax.primary.parse("smell rock")
        #expect(syntax.verb == .smell)
        #expect(syntax.directObject == .item(id: "rock"))
    }

    @Test("Syntax rule accepts synonym 'sniff'")
    func testSyntaxRuleSniff() async throws {
        let handler = SmellActionHandler()
        let syntax = try handler.syntax.synonyms.first!.parse("sniff")
        #expect(syntax.verb == .smell)
        #expect(isNil(syntax.directObject))
    }

    // MARK: - Validation Testing

    @Test("Validation succeeds with no direct object")
    func testValidationSucceedsWithNoDirectObject() async throws {
        let handler = SmellActionHandler()
        let (engine, _) = await GameEngine.test(blueprint: MinimalGame())
        let context = ActionContext(command: Command(verb: .smell), engine: engine)

        try await handler.validate(context: context)
    }

    @Test("Validation succeeds for reachable item")
    func testValidationSucceedsForReachableItem() async throws {
        let handler = SmellActionHandler()
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, _) = await GameEngine.test(blueprint: game)
        let command = Command(verb: .smell, directObject: .item(id: "rock"))
        let context = ActionContext(command: command, engine: engine)

        try await handler.validate(context: context)
    }

    @Test("Validation fails for unreachable item")
    func testValidationFailsForUnreachableItem() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("smell rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > smell rock
            You can’t see any rock here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Processing smell with no object")
    func testProcessSmellNoObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.execute("smell")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("Processing smell with an item")
    func testProcessSmellItem() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("smell rock")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > smell rock
            The rock smells about average.
            """)
    }

    @Test("Processing smell myself gives a response")
    func testProcessSmellMyself() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())

        try await engine.execute("smell myself")

        let output = await mockIO.flush()
        #expect(!output.isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(SmellActionHandler().actionID == .smell)
    }
}
