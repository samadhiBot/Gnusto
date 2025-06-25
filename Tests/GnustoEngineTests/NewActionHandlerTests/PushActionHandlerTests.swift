import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PushActionHandler Tests")
struct PushActionHandlerTests {
    let handler = PushActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var rock: Item!
    var table: Item!

    @Before
    func setup() {
        rock = Item(id: "rock", .name("heavy rock"), .in(.location("room")))
        table = Item(id: "table", .name("sturdy table"), .in(.location("room")))
        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [rock, table]
        )
        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("PUSH <item> syntax works")
    func testPushSyntax() async throws {
        try await engine.execute("push rock")
        let output = await mockIO.flush()
        #expect(output.contains("You push the heavy rock."))
    }

    @Test("SHOVE <item> synonym works")
    func testShoveSyntax() async throws {
        let shoveVerb = Verb(id: .push, synonyms: ["push", "shove"])
        let customVocabulary = Vocabulary(verbs: [shoveVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("shove rock")
        let output = await mockIO.flush()
        #expect(output.contains("You push the heavy rock."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("push")
        let output = await mockIO.flush()
        #expect(output.contains("Push what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "rock") { $0.parent = .location("otherRoom") }
        try await engine.execute("push rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Pushing multiple items works")
    func testProcessPushMultipleItems() async throws {
        try await engine.execute("push rock and table")
        let output = await mockIO.flush()
        #expect(output.contains("You push the heavy rock and the sturdy table."))
    }

    @Test("Pushing an item touches it")
    func testProcessPushTouchesItem() async throws {
        try await engine.update(item: "rock") { $0.clearFlag(.isTouched) }
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("push rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    @Test("PUSH ALL works")
    func testPushAll() async throws {
        try await engine.execute("push all")
        let output = await mockIO.flush()
        #expect(output.contains("You push the heavy rock and the sturdy table."))
    }

    // MARK: - ActionID Testing

    @Test("PUSH action resolves to PushActionHandler")
    func testPushActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("push rock")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is PushActionHandler)
    }
}
