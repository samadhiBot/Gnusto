import CustomDump
import Testing

@testable import GnustoEngine

@Suite
struct TakeActionHandlerTests {
    // MARK: - Syntax Rule Testing

    @Test("Syntax rule for 'take <items>'")
    func testSyntaxTake() async throws {
        let handler = TakeActionHandler()
        let syntax = try handler.syntax.primary.parse("take book")
        #expect(syntax.verb == .take)
        #expect(syntax.directObjects.count == 1)
        #expect(syntax.directObjects.first == .item(id: "book"))
    }

    @Test("Syntax rule for 'pick up <items>'")
    func testSyntaxPickUp() async throws {
        let handler = TakeActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.first == .verb(.pick) })!.parse("pick up book")
        #expect(syntax.verb == .take)
        #expect(syntax.directObjects.count == 1)
        #expect(syntax.directObjects.first == .item(id: "book"))
    }

    @Test("Syntax rule for 'take <items> from <item>'")
    func testSyntaxTakeFrom() async throws {
        let handler = TakeActionHandler()
        let syntax = try handler.syntax.first(where: { $0.pattern.contains(.preposition(.from)) })!.parse("take book from bag")
        #expect(syntax.verb == .take)
        #expect(syntax.directObjects.count == 1)
        #expect(syntax.directObjects.first == .item(id: "book"))
        #expect(syntax.indirectObject == .item(id: "bag"))
    }

    @Test("Syntax rule for synonym 'get <items>'")
    func testSyntaxGet() async throws {
        let handler = TakeActionHandler()
        let syntax = try handler.syntax.primary.parse("get book")
        #expect(syntax.verb == .take)
    }

    // MARK: - Validation Testing

    @Test("Validation fails without a direct object")
    func testValidationFailsWithoutDirectObject() async throws {
        let (engine, mockIO) = await GameEngine.test(blueprint: MinimalGame())
        try await engine.execute("take")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take
         Take what?
         """)
    }

    @Test("Validation fails for non-takable item")
    func testValidationFailsForNonTakableItem() async throws {
        let wall = Item(id: "wall", .name("a wall"), .in(.location("testRoom")))
        let game = MinimalGame.lit(items: wall)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("take wall")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take wall
         You can’t take the wall.
         """)
    }

    @Test("Validation fails when inventory is full")
    func testValidationFailsInventoryFull() async throws {
        let book = Item(id: "book", .name("a book"), .isTakable, .size(10), .in(.location("testRoom")))
        let player = Player(in: "testRoom", maxCapacity: 5)
        let game = MinimalGame.lit(player: player, items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("take book")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take book
         You’re carrying too much stuff to take that.
         """)
    }

    @Test("Validation fails for item in closed, opaque container")
    func testValidationFailsItemInClosedOpaqueContainer() async throws {
        let box = Item(id: "box", .name("a box"), .isContainer, .in(.location("testRoom")))
        let coin = Item(id: "coin", .name("a coin"), .isTakable, .in(.item("box")))
        let game = MinimalGame.lit(items: box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("take coin")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take coin
         You can’t see any coin here.
         """)
    }

    @Test("Validation succeeds for item in closed, transparent container")
    func testValidationSucceedsItemInClosedTransparentContainer() async throws {
        let box = Item(id: "box", .name("a box"), .isContainer, .isTransparent, .in(.location("testRoom")))
        let coin = Item(id: "coin", .name("a coin"), .isTakable, .in(.item("box")))
        let game = MinimalGame.lit(items: box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)
        try await engine.execute("take coin")
        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take coin
         The box is closed.
         """)
    }

    // MARK: - Processing Testing

    @Test("Taking a single item")
    async func testTakeSingleItem() async throws {
        let book = Item(id: "book", .name("a book"), .isTakable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take book")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take book
         Taken.
         """)
        let finalBook = try await engine.item("book")
        #expect(finalBook.parent == .player)
        #expect(finalBook.hasFlag(.isTouched))
    }

    @Test("Taking an already held item")
    async func testTakeHeldItem() async throws {
        let book = Item(id: "book", .name("a book"), .isTakable, .in(.player))
        let game = MinimalGame.lit(items: book)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take book")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take book
         You already have that.
         """)
    }

    @Test("Taking item from an open container")
    async func testTakeFromOpenContainer() async throws {
        let box = Item(id: "box", .name("a box"), .isContainer, .isOpen, .in(.location("testRoom")))
        let coin = Item(id: "coin", .name("a coin"), .isTakable, .in(.item("box")))
        let game = MinimalGame.lit(items: box, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take coin from box")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take coin from box
         Taken.
         """)
        let finalCoin = try await engine.item("coin")
        #expect(finalCoin.parent == .player)
    }

    @Test("Take all from location")
    async func testTakeAllFromLocation() async throws {
        let book = Item(id: "book", .name("a book"), .isTakable, .in(.location("testRoom")))
        let rock = Item(id: "rock", .name("a rock"), .in(.location("testRoom")))
        let coin = Item(id: "coin", .name("a coin"), .isTakable, .in(.location("testRoom")))
        let game = MinimalGame.lit(items: book, rock, coin)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("take all")

        let output = await mockIO.flush()
        expectNoDifference(output, """
         > take all
         You take the book and the coin.
         """)
        #expect(try await engine.item("book").parent == .player)
        #expect(try await engine.item("coin").parent == .player)
        #expect(try await engine.item("rock").parent != .player)
    }

    // MARK: - ActionID Testing

    @Test("Handler has correct action ID")
    func testActionID() {
        #expect(TakeActionHandler().actionID == .take)
    }
}
