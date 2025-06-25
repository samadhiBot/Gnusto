import CustomDump
import Testing

@testable import GnustoEngine

@Suite("RaiseActionHandler Tests")
struct RaiseActionHandlerTests {
    let handler = RaiseActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rock: Item!

    @Before
    func setup() {
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rock]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("RAISE <item> syntax works")
    func testRaiseSyntax() async throws {
        try await engine.execute("raise rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't lift the heavy rock."))
    }

    @Test("LIFT <item> synonym works")
    func testLiftSyntax() async throws {
        let liftVerb = Verb(id: .raise, synonyms: ["raise", "lift"])
        let customVocabulary = Vocabulary(verbs: [liftVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("lift rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't lift the heavy rock."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("raise")
        let output = await mockIO.flush()
        #expect(output.contains("Raise what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "rock") { $0.parent = .location("otherRoom") }
        try await engine.execute("raise rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Raising an item touches it")
    func testProcessRaiseTouchesItem() async throws {
        try await engine.update(item: "rock") { $0.clearFlag(.isTouched) }
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("raise rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("RAISE action resolves to RaiseActionHandler")
    func testRaiseActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("raise rock")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is RaiseActionHandler)
    }
}
