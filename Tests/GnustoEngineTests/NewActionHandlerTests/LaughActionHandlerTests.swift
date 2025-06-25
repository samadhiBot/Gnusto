import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LaughActionHandler Tests")
struct LaughActionHandlerTests {
    let handler = LaughActionHandler()
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

    @Test("LAUGH syntax works")
    func testLaughSyntax() async throws {
        try await engine.execute("laugh")
        let output = await mockIO.flush()
        #expect(!output.isEmpty)
        #expect(
            output.contains("laugh") || output.contains("chuckle") || output.contains("giggle")
                || output.contains("snicker") || output.contains("chortle"))
    }

    @Test("LAUGH AT <item> syntax works")
    func testLaughAtItemSyntax() async throws {
        try await engine.execute("laugh at rock")
        let output = await mockIO.flush()
        #expect(!output.isEmpty)
        #expect(
            output.contains("laugh") || output.contains("chuckle") || output.contains("giggle")
                || output.contains("snicker") || output.contains("chortle"))
    }

    @Test("CHUCKLE synonym works")
    func testChuckleSynonym() async throws {
        let chuckleVerb = Verb(id: .laugh, synonyms: ["laugh", "chuckle"])
        let customVocabulary = Vocabulary(verbs: [chuckleVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("chuckle")
        let output = await mockIO.flush()
        #expect(!output.isEmpty)
        #expect(
            output.contains("laugh") || output.contains("chuckle") || output.contains("giggle")
                || output.contains("snicker") || output.contains("chortle"))
    }

    // MARK: - Processing Testing

    @Test("Processing returns a random laugh response")
    func testProcessReturnsRandomResponse() async throws {
        let context = ActionContext(command: Command(verb: .laugh), engine: engine)
        let result = try await handler.process(context: context)
        #expect(result.message != nil)
        #expect(result.changes.isEmpty)
        #expect(result.effects.isEmpty)
    }

    // MARK: - ActionID Testing

    @Test("LAUGH action resolves to LaughActionHandler")
    func testLaughActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("laugh")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is LaughActionHandler)
    }
}
