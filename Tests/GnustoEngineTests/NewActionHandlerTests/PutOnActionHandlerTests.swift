import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PutOnActionHandler Tests")
struct PutOnActionHandlerTests {
    let handler = PutOnActionHandler()
    var game: MinimalGame!
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    var book: Item!
    var table: Item!
    var remoteTable: Item!
    var box: Item!
    var plate: Item!

    @Before
    func setup() {
        book = Item(id: "book", .name("heavy book"), .in(.player))
        table = Item(id: "table", .name("sturdy table"), .isSurface, .in(.location("room")))
        remoteTable = Item(
            id: "remoteTable", .name("remote table"), .isSurface, .in(.location("otherRoom")))
        box = Item(id: "box", .name("box"), .in(.location("room")))  // Not a surface
        plate = Item(id: "plate", .name("plate"), .isSurface, .in(.item("table")))

        game = MinimalGame(
            player: Player(in: "room"),
            locations: [
                Location(id: "room", .name("Room")),
                Location(id: "otherRoom", .name("Other Room")),
            ],
            items: [book, table, remoteTable, box, plate]
        )

        (engine, mockIO) = await GameEngine.test(blueprint: game)
    }

    // MARK: - Syntax Rule Testing

    @Test("PUT <item> ON <surface> syntax works")
    func testPutOnSyntax() async throws {
        try await engine.execute("put book on table")
        let output = await mockIO.flush()
        #expect(output.contains("You put the heavy book on the sturdy table."))
    }

    @Test("PLACE <item> ON <surface> synonym works")
    func testPlaceOnSyntax() async throws {
        let placeVerb = Verb(id: .put, synonyms: ["put", "place"])
        let customVocabulary = Vocabulary(verbs: [placeVerb] + standardVerbs)
        let parser = StandardParser(vocabulary: customVocabulary)
        (engine, mockIO) = await GameEngine.test(blueprint: game, parser: parser)

        try await engine.execute("place book on table")
        let output = await mockIO.flush()
        #expect(output.contains("You put the heavy book on the sturdy table."))
    }

    // MARK: - Validation Testing

    @Test("Fails with missing direct object")
    func testValidationFailsMissingDirectObject() async throws {
        try await engine.execute("put on table")
        let output = await mockIO.flush()
        #expect(output.contains("Put what on the sturdy table?"))
    }

    @Test("Fails with missing indirect object")
    func testValidationFailsMissingIndirectObject() async throws {
        try await engine.execute("put book on")
        let output = await mockIO.flush()
        #expect(output.contains("Put the heavy book on what?"))
    }

    @Test("Fails when item not held")
    func testValidationFailsWhenNotHeld() async throws {
        try await engine.update(item: "book") { $0.parent = .location("room") }
        try await engine.execute("put book on table")
        let output = await mockIO.flush()
        #expect(output.contains("You aren’t holding the heavy book."))
    }

    @Test("Fails when surface not reachable")
    func testValidationFailsWhenNotReachable() async throws {
        try await engine.execute("put book on remote table")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t see any such thing."))
    }

    @Test("Fails when target is not a surface")
    func testValidationFailsWhenNotSurface() async throws {
        try await engine.execute("put book on box")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t put things on the box."))
    }

    @Test("Fails when putting item on itself")
    func testValidationFailsPuttingOnSelf() async throws {
        try await engine.update(item: "table") { $0.parent = .player }  // Player is holding the table now
        try await engine.execute("put table on table")
        let output = await mockIO.flush()
        #expect(output.contains("You can’t put something on itself."))
    }

    @Test("Fails with circular placement")
    func testValidationFailsCircularPlacement() async throws {
        // plate is on table, player holds table. Can't put table on plate.
        try await engine.update(item: "table") { $0.parent = .player }
        try await engine.execute("put table on plate")
        let output = await mockIO.flush()
        #expect(
            output.contains(
                "You can’t put the sturdy table on the plate, since the plate is already on the sturdy table."
            ))
    }

    // MARK: - Processing Testing

    @Test("Item is moved to surface")
    func testProcessItemMoved() async throws {
        try await engine.execute("put book on table")
        let bookState = try await engine.item("book")
        #expect(bookState.parent == .item("table"))
    }

    @Test("Putting touches both items")
    func testProcessTouchesBothItems() async throws {
        try await engine.update(item: "book") { $0.clearFlag(.isTouched) }
        try await engine.update(item: "table") { $0.clearFlag(.isTouched) }
        var bookState = try await engine.item("book")
        var tableState = try await engine.item("table")
        #expect(bookState.hasFlag(.isTouched) == false)
        #expect(tableState.hasFlag(.isTouched) == false)

        try await engine.execute("put book on table")

        bookState = try await engine.item("book")
        tableState = try await engine.item("table")
        #expect(bookState.hasFlag(.isTouched) == true)
        #expect(tableState.hasFlag(.isTouched) == true)
    }

    // MARK: - ActionID Testing

    @Test("PUT ON action resolves to PutOnActionHandler")
    func testPutOnActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("put book on table")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is PutOnActionHandler)
    }
}
