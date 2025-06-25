import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookInsideActionHandler Tests")
struct LookInsideActionHandlerTests {
    let handler = LookInsideActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var openBox: Item!
    var closedBox: Item!
    var emptyBox: Item!
    var rock: Item!
    var key: Item!

    @Before
    func setup() {
        openBox = Item(
            id: "openBox", .name("open box"), .isContainer, .isOpen, .in(.location("room")))
        closedBox = Item(id: "closedBox", .name("closed box"), .isContainer, .in(.location("room")))
        emptyBox = Item(
            id: "emptyBox", .name("empty box"), .isContainer, .isOpen, .in(.location("room")))
        rock = Item(id: "rock", .name("rock"), .description("Just a rock."), .in(.location("room")))
        key = Item(id: "key", .name("key"), .in(.item("openBox")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [openBox, closedBox, emptyBox, rock, key]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("LOOK IN <item> syntax works")
    func testLookInSyntax() async throws {
        try await engine.execute("look in open box")
        let output = await mockIO.flush()
        #expect(output.contains("In the open box you see a key."))
    }

    @Test("PEEK IN <item> synonym works")
    func testPeekInSyntax() async throws {
        let peekVerb = Verb(id: .look, synonyms: ["look", "peek"])
        let customVocabulary = Vocabulary(verbs: [peekVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("peek in open box")
        let output = await mockIO.flush()
        #expect(output.contains("In the open box you see a key."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("look in")
        let output = await mockIO.flush()
        #expect(output.contains("Look in what?"))
    }

    // MARK: - Processing Testing

    @Test("Looking in an open, empty container")
    func testProcessLookInEmptyContainer() async throws {
        try await engine.execute("look in empty box")
        let output = await mockIO.flush()
        #expect(output.contains("The empty box is empty."))
    }

    @Test("Looking in a closed container")
    func testProcessLookInClosedContainer() async throws {
        try await engine.execute("look in closed box")
        let output = await mockIO.flush()
        #expect(output.contains("The closed box is closed."))
    }

    @Test("Looking in a non-container")
    func testProcessLookInNonContainer() async throws {
        try await engine.execute("look in rock")
        let output = await mockIO.flush()
        #expect(output.contains("Just a rock."))
    }

    @Test("Looking in an item touches it")
    func testProcessLookInTouchesItem() async throws {
        try await engine.update(item: "openBox") { $0.clearFlag(.isTouched) }
        var boxState = try await engine.item("openBox")
        #expect(boxState.hasFlag(.isTouched) == false)

        try await engine.execute("look in open box")

        boxState = try await engine.item("openBox")
        #expect(boxState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("LOOK IN action resolves to LookInsideActionHandler")
    func testLookInActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("look in box")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is LookInsideActionHandler)
    }
}
