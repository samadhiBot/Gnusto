import CustomDump
import Testing

@testable import GnustoEngine

@Suite("KnockActionHandler Tests")
struct KnockActionHandlerTests {
    let handler = KnockActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var closedDoor: Item!
    var openDoor: Item!
    var lockedDoor: Item!
    var box: Item!
    var rock: Item!

    @Before
    func setup() {
        closedDoor = Item(id: "closedDoor", .name("closed door"), .isDoor, .in(.location("room")))
        openDoor = Item(
            id: "openDoor", .name("open door"), .isDoor, .isOpen, .in(.location("room")))
        lockedDoor = Item(
            id: "lockedDoor", .name("locked door"), .isDoor, .isLocked, .in(.location("room")))
        box = Item(id: "box", .name("box"), .isContainer, .in(.location("room")))
        rock = Item(id: "rock", .name("rock"), .in(.location("room")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [closedDoor, openDoor, lockedDoor, box, rock]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("KNOCK ON <item> syntax works")
    func testKnockOnSyntax() async throws {
        try await engine.execute("knock on rock")
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the rock, but nothing happens."))
    }

    @Test("TAP <item> synonym works")
    func testTapSyntax() async throws {
        try await engine.execute("tap rock")
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the rock, but nothing happens."))
    }

    @Test("RAP ON <item> synonym works")
    func testRapOnSyntax() async throws {
        // Need to add 'rap' as a synonym to the vocabulary for this to pass
        let rapVerb = Verb(id: .knock, synonyms: ["knock", "rap", "tap"])
        let customVocabulary = Vocabulary(verbs: [rapVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("rap on rock")
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the rock, but nothing happens."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenDirectObjectMissing() async throws {
        try await engine.execute("knock")
        let output = await mockIO.flush()
        #expect(output.contains("Knock on what?"))
    }

    // MARK: - Processing Testing

    @Test("Knocking on a closed door")
    func testProcessKnockClosedDoor() async throws {
        try await engine.execute("knock on closed door")
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the closed door, but there's no answer."))
    }

    @Test("Knocking on an open door")
    func testProcessKnockOpenDoor() async throws {
        try await engine.execute("knock on open door")
        let output = await mockIO.flush()
        #expect(output.contains("No need to knock, the open door is already open."))
    }

    @Test("Knocking on a locked door")
    func testProcessKnockLockedDoor() async throws {
        try await engine.execute("knock on locked door")
        let output = await mockIO.flush()
        #expect(output.contains("You knock on the locked door, but nobody's home."))
    }

    @Test("Knocking on a container")
    func testProcessKnockContainer() async throws {
        try await engine.execute("knock on box")
        let output = await mockIO.flush()
        #expect(output.contains("Knocking on the box produces a hollow sound."))
    }

    @Test("Knocking touches the item")
    func testProcessKnockTouchesItem() async throws {
        var rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == false)

        try await engine.execute("knock on rock")

        rockState = try await engine.item("rock")
        #expect(rockState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("KNOCK action resolves to KnockActionHandler")
    func testKnockActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("knock on door")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is KnockActionHandler)
    }
}
