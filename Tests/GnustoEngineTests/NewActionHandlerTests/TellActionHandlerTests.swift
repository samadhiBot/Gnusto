import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TellActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax for 'tell <character> about <topic>'")
    func testSyntaxTellAbout() async throws {
        let handler = TellActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.about)) })!
            .parse("tell wizard about sword")
        #expect(syntax.verb == .tell)
        #expect(syntax.directObject == .item(id: "wizard"))
        #expect(syntax.indirectObject == .item(id: "sword"))
    }

    @Test("Syntax for 'inform <character> about <topic>'")
    func testSyntaxInformAbout() async throws {
        let handler = TellActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.about)) })!
            .parse("inform wizard about sword")
        #expect(syntax.verb == .tell)
        #expect(syntax.directObject == .item(id: "wizard"))
        #expect(syntax.indirectObject == .item(id: "sword"))
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("tell")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell
            Tell whom?
            """)
    }

    @Test("Validation fails without an indirect object")
    func testValidationFailsWithoutIndirectObject() async throws {
        let wizard = Item(id: "wizard", .name("a wizard"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("tell wizard")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard
            Tell the wizard about what?
            """)
    }

    @Test("Validation fails if direct object is not a character")
    func testValidationFailsIfNotCharacter() async throws {
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: rock)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("tell rock about something")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell rock about something
            You can’t tell the rock about anything.
            """)
    }

    @Test("Validation fails if character is not reachable")
    func testValidationFailsIfCharacterUnreachable() async throws {
        let wizard = Item(
            id: "wizard", .name("a wizard"), .isCharacter, .in(.location("anotherRoom")))
        let game = MinimalGame.lit(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("tell wizard about something")
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about something
            You can’t see any wizard here.
            """)
    }

    // MARK: - Processing Testing

    @Test("Telling character about an item")
    func testTellAboutItem() async throws {
        let wizard = Item(
            id: "wizard", .name("the wizard"), .isCharacter, .in(.location("testRoom")))
        let sword = Item(id: "sword", .name("a sword"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wizard, sword)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tell wizard about sword")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about sword
            The wizard listens politely to what you say about the sword.
            """)
    }

    @Test("Telling character about player")
    func testTellAboutPlayer() async throws {
        let wizard = Item(
            id: "wizard", .name("the wizard"), .isCharacter, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wizard)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("tell wizard about me")

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > tell wizard about me
            The wizard listens politely to what you say about yourself.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TellActionHandler().actionID == .tell)
    }
}
