import CustomDump
import Testing

@testable import GnustoEngine

@Suite("ReadActionHandler Tests")
struct ReadActionHandlerTests {
    let handler = ReadActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var book: Item!
    var heldBook: Item!
    var unreadableBook: Item!
    var blankBook: Item!
    var darkRoom: Location!

    @Before
    func setup() {
        book = Item(id: "book", .name("book"), .isReadable, .isTakable, .readText("It's a book."), .in(.location("room")))
        heldBook = Item(id: "heldBook", .name("held book"), .isReadable, .readText("It's a held book."), .in(.player))
        unreadableBook = Item(id: "unreadableBook", .name("unreadable book"), .in(.location("room")))
        blankBook = Item(id: "blankBook", .name("blank book"), .isReadable, .in(.location("room")))
        darkRoom = Location(id: "darkRoom", .name("Dark Room"), .description("It is pitch black."))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [
                Location(id: "room", .name("Room"), .inherentlyLit),
                darkRoom
            ],
            items: [book, heldBook, unreadableBook, blankBook]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("READ <item> syntax works")
    func testReadSyntax() async throws {
        try await engine.execute("read heldBook")
        let output = await mockIO.flush()
        #expect(output.contains("It’s a held book."))
    }

    // MARK: - Validation Testing

    @Test("Fails when direct object is missing")
    func testValidationFailsWhenObjectMissing() async throws {
        try await engine.execute("read")
        let output = await mockIO.flush()
        #expect(output.contains("Read what?"))
    }

    @Test("Fails when item is not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.update(item: "book") { $0.parent = .location("otherRoom") }
        try await engine.execute("read book")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t see any such thing."))
    }

    @Test("Fails when room is dark")
    func testValidationFailsWhenDark() async throws {
        try await engine.teleport(to: "darkRoom")
        let bookInDark = Item(id: "darkBook", .name("dark book"), .isReadable, .readText("darkness"), .in(.location("darkRoom")))
        var blueprint = game.gameBlueprint
        blueprint.items.append(bookInDark)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)
        try await engine.teleport(to: "darkRoom")

        try await engine.execute("read darkBook")
        let output = await mockIO.flush()
        #expect(output.contains("It is pitch dark, and you can’t see a thing."))
    }

    @Test("Fails when item is not readable")
    func testValidationFailsWhenNotReadable() async throws {
        try await engine.execute("read unreadableBook")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t read the unreadable book."))
    }

    // MARK: - Processing Testing

    @Test("Reading a takable item takes it first")
    func testProcessAutoTake() async throws {
        try await engine.execute("read book")
        let output = await mockIO.flush()
        #expect(output.contains("(Taken)"))
        #expect(output.contains("It’s a book."))
        let bookState = try await engine.item("book")
        #expect(bookState.parent == .player)
    }

    @Test("Reading an item with no text gives default message")
    func testProcessNoText() async throws {
        try await engine.execute("read blankBook")
        let output = await mockIO.flush()
        #expect(output.contains("There’s nothing written on the blank book."))
    }

    @Test("Reading an item touches it")
    func testProcessReadTouchesItem() async throws {
        try await engine.update(item: "book") { $0.clearFlag(.isTouched) }
        var bookState = try await engine.item("book")
        #expect(bookState.hasFlag(.isTouched) == false)

        try await engine.execute("read book")

        bookState = try await engine.item("book")
        #expect(bookState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("READ action resolves to ReadActionHandler")
    func testReadActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("read book")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is ReadActionHandler)
    }
}
