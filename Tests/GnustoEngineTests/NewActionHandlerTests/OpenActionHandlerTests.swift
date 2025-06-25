import CustomDump
import Testing

@testable import GnustoEngine

@Suite("OpenActionHandler Tests")
struct OpenActionHandlerTests {
    let handler = OpenActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var box: Item!
    var lockedBox: Item!
    var openBox: Item!
    var boxWithStuff: Item!
    var rock: Item!
    var key: Item!

    @Before
    func setup() {
        box = Item(id: "box", .name("box"), .isOpenable, .isContainer, .in(.location("room")))
        lockedBox = Item(
            id: "lockedBox", .name("locked box"), .isOpenable, .isContainer, .isLocked,
            .in(.location("room")))
        openBox = Item(
            id: "openBox", .name("open box"), .isOpenable, .isContainer, .isOpen,
            .in(.location("room")))
        boxWithStuff = Item(
            id: "boxWithStuff", .name("full box"), .isOpenable, .isContainer, .in(.location("room"))
        )
        rock = Item(id: "rock", .name("rock"), .in(.location("room")))  // Not openable
        key = Item(id: "key", .name("key"), .in(.item("boxWithStuff")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [box, lockedBox, openBox, boxWithStuff, rock, key]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("OPEN <item> syntax works")
    func testOpenSyntax() async throws {
        try await engine.execute("open box")
        let output = await mockIO.flush()
        #expect(output.contains("You open the box."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("open")
        let output = await mockIO.flush()
        #expect(output.contains("Open what?"))
    }

    @Test("Fails when item is not openable")
    func testValidationFailsWhenNotOpenable() async throws {
        try await engine.execute("open rock")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t open the rock."))
    }

    @Test("Fails when item is locked")
    func testValidationFailsWhenLocked() async throws {
        try await engine.execute("open locked box")
        let output = await mockIO.flush()
        #expect(output.contains("The locked box is locked."))
    }

    // MARK: - Processing Testing

    @Test("Fails when item is already open")
    func testProcessFailsWhenAlreadyOpen() async throws {
        try await engine.execute("open open box")
        let output = await mockIO.flush()
        #expect(output.contains("The open box is already open."))
    }

    @Test("Opening reveals contents")
    func testProcessOpeningRevealsContents() async throws {
        try await engine.execute("open full box")
        let output = await mockIO.flush()
        #expect(output.contains("Opening the full box reveals a key."))
    }

    @Test("Opening sets isOpen and isTouched flags")
    func testProcessSetsFlags() async throws {
        try await engine.update(item: "box") {
            $0.clearFlag(.isTouched)
            $0.clearFlag(.isOpen)
        }
        var boxState = try await engine.item("box")
        #expect(boxState.hasFlag(.isTouched) == false)
        #expect(boxState.hasFlag(.isOpen) == false)

        try await engine.execute("open box")

        boxState = try await engine.item("box")
        #expect(boxState.hasFlag(.isTouched) == true)
        #expect(boxState.hasFlag(.isOpen) == true)
    }

    // MARK: - ActionID Testing

    @Test("OPEN action resolves to OpenActionHandler")
    func testOpenActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("open box")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is OpenActionHandler)
    }
}
