import CustomDump
import Testing

@testable import GnustoEngine

@Suite("InsertActionHandler Tests")
struct InsertActionHandlerTests {
    let handler = InsertActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var lamp: Item!
    var book: Item!
    var box: Item!
    var closedBox: Item!
    var fullBox: Item!
    var bigThing: Item!

    @Before
    func setup() {
        lamp = Item(id: "lamp", .name("brass lantern"), .in(.player), .size(10))
        book = Item(id: "book", .name("book"), .in(.player), .size(5))
        box = Item(
            id: "box",
            .name("wooden box"),
            .in(.location("room")),
            .isContainer,
            .isOpen,
            .capacity(15)
        )
        closedBox = Item(
            id: "closedBox",
            .name("closed box"),
            .in(.location("room")),
            .isContainer
            // .isOpen is missing
        )
        fullBox = Item(
            id: "fullBox",
            .name("full box"),
            .in(.location("room")),
            .isContainer,
            .isOpen,
            .capacity(8)
        )
        bigThing = Item(id: "bigThing", .name("big thing"), .in(.player), .size(20))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [Location(id: "room", .name("Room"))],
            items: [lamp, book, box, closedBox, fullBox, bigThing]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("PUT <item> IN <container> syntax works")
    func testPutInSyntax() async throws {
        try await engine.execute("put lamp in box")
        let output = await mockIO.flush()
        #expect(output.contains("You put the brass lantern in the wooden box."))
    }

    @Test("INSERT <item> INTO <container> syntax works")
    func testInsertIntoSyntax() async throws {
        try await engine.execute("insert lamp into box")
        let output = await mockIO.flush()
        #expect(output.contains("You put the brass lantern in the wooden box."))
    }

    @Test("PLACE <item> INSIDE <container> syntax works")
    func testPlaceInsideSyntax() async throws {
        try await engine.execute("place lamp inside box")
        let output = await mockIO.flush()
        #expect(output.contains("You put the brass lantern in the wooden box."))
    }

    // MARK: - Validation Testing

    @Test("Fails when item is not held")
    func testValidationFailsWhenItemNotHeld() async throws {
        let roomLamp = Item(id: "roomLamp", .name("room lamp"), .in(.location("room")))
        var blueprint = game.gameBlueprint
        blueprint.items.append(roomLamp)
        (engine, mockIO) = await GameEngine.test(blueprint: blueprint)

        try await engine.execute("put room lamp in box")
        let output = await mockIO.flush()
        #expect(output.contains("You are not holding the room lamp."))
    }

    @Test("Fails when container is closed")
    func testValidationFailsWhenContainerClosed() async throws {
        try await engine.execute("put lamp in closed box")
        let output = await mockIO.flush()
        #expect(output.contains("The closed box is closed."))
    }

    @Test("Fails when target is not a container")
    func testValidationFailsWhenNotAContainer() async throws {
        try await engine.execute("put lamp in book")
        let output = await mockIO.flush()
        #expect(output.contains("You can't put things in that."))
    }

    @Test("Fails when putting item in itself")
    func testValidationFailsPuttingItemInItself() async throws {
        // Player can't hold a box to put it in itself in this setup.
        // We'll move the box to the player to test this logic.
        try await engine.update(item: "box") { $0.parent = .player }

        try await engine.execute("put box in box")
        let output = await mockIO.flush()
        #expect(output.contains("You can't put the wooden box in itself."))
    }

    @Test("Fails on circular insertion")
    func testValidationFailsCircularInsertion() async throws {
        // Put the box in the lamp, then try to put the lamp in the box.
        try await engine.update(item: "box") { $0.parent = .item("lamp") }

        try await engine.execute("put lamp in box")
        let output = await mockIO.flush()
        #expect(
            output.contains(
                "You can't put the brass lantern inside the wooden box, because the wooden box is already inside it!"
            ))
    }

    @Test("Fails when item is too large for container")
    func testValidationFailsWhenItemTooLarge() async throws {
        try await engine.execute("put big thing in box")
        let output = await mockIO.flush()
        #expect(output.contains("The big thing won't fit in the wooden box."))
    }

    // MARK: - Processing Testing

    @Test("Successfully inserts an item")
    func testProcessInsertsItem() async throws {
        try await engine.execute("put lamp in box")
        let lampState = try await engine.item("lamp")
        #expect(lampState.parent == .item("box"))
    }

    @Test("Successfully inserts multiple items with 'all'")
    func testProcessInsertAll() async throws {
        try await engine.execute("put all in box")
        let output = await mockIO.flush()
        #expect(output.contains("You put the brass lantern and the book in the wooden box."))

        let lampState = try await engine.item("lamp")
        #expect(lampState.parent == .item("box"))

        let bookState = try await engine.item("book")
        #expect(bookState.parent == .item("box"))
    }

    @Test("'Put all' skips items that don't fit")
    func testProcessInsertAllSkipsUnfitting() async throws {
        try await engine.execute("put all in fullBox")
        let output = await mockIO.flush()
        // The book (size 5) should fit, but the lamp (size 10) should not.
        #expect(output.contains("You put the book in the full box."))

        let lampState = try await engine.item("lamp")
        #expect(lampState.parent == .player)

        let bookState = try await engine.item("book")
        #expect(bookState.parent == .item("fullBox"))
    }

    // MARK: - ActionID Testing

    @Test("INSERT action resolves to InsertActionHandler")
    func testInsertActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("put lamp in box")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is InsertActionHandler)
    }
}
