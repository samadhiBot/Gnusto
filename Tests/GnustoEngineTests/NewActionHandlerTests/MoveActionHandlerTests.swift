import CustomDump
import Testing

@testable import GnustoEngine

@Suite("MoveActionHandler Tests")
struct MoveActionHandlerTests {
    let handler = MoveActionHandler()
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

    @Test("MOVE <item> syntax works")
    func testMoveSyntax() async throws {
        try await engine.execute("move rock")
        let output = await mockIO.flush()
        #expect(output.contains("Moving the heavy rock doesn't accomplish anything."))
    }

    @Test("SLIDE <item> synonym works")
    func testSlideSyntax() async throws {
        let slideVerb = Verb(id: .move, synonyms: ["move", "slide"])
        let customVocabulary = Vocabulary(verbs: [slideVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("slide rock")
        let output = await mockIO.flush()
        #expect(output.contains("Moving the heavy rock doesn't accomplish anything."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("move")
        let output = await mockIO.flush()
        #expect(output.contains("Move what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "rock") { $0.parent = .location("otherRoom") }
        try await engine.execute("move rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can't see any such thing."))
    }

    // MARK: - Processing Testing

    @Test("Moving an item touches it")
    func testProcessMoveTouchesItem() async throws {
        try await engine.update(item: "rock") { $0.clearFlag(.isTouched) }
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("move rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    @Test("MOVE ALL gives a summary message")
    func testProcessMoveAll() async throws {
        try await engine.execute("move all")
        let output = await mockIO.flush()
        #expect(output.contains("You move the heavy rock and the sturdy table."))
    }

    // MARK: - ActionID Testing

    @Test("MOVE action resolves to MoveActionHandler")
    func testMoveActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("move rock")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is MoveActionHandler)
    }
}
