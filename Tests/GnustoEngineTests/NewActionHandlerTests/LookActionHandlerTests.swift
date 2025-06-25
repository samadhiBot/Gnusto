import CustomDump
import Testing

@testable import GnustoEngine

@Suite("LookActionHandler Tests")
struct LookActionHandlerTests {
    let handler = LookActionHandler()
    var engine: GameEngine!
    var mockIO: MockIOHandler!

    // MARK: - Basic Look (No Items)

    @Test("LOOK in a lit room")
    func testLookInLitRoom() async throws {
        let room = Location(id: "room", .name("Test Room"), .description("A plain room."))
        let game = MinimalGame(player: Player(in: "room"), locations: [room])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("Test Room"))
        #expect(output.contains("A plain room."))
    }

    @Test("LOOK in a dark room")
    func testLookInDarkRoom() async throws {
        let room = Location(id: "darkRoom", .name("Dark Room"), .description("It's dark."))
        let game = MinimalGame(player: Player(in: "darkRoom"), locations: [room])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("It is pitch black. You can't see a thing."))
    }

    // MARK: - Look with Items

    @Test("LOOK with one item")
    func testLookWithOneItem() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let rock = Item(id: "rock", .name("rock"), .in(.location("room")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [rock])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("There is a rock here."))
    }

    @Test("LOOK with multiple items")
    func testLookWithMultipleItems() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let rock = Item(id: "rock", .name("rock"), .in(.location("room")))
        let gem = Item(id: "gem", .name("gem"), .in(.location("room")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [rock, gem])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("There are a gem and a rock here."))
    }

    @Test("LOOK respects firstDescription for untouched items")
    func testLookRespectsFirstDescription() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let rock = Item(
            id: "rock", .name("rock"), .firstDescription("A peculiar rock is sitting here."),
            .in(.location("room")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [rock])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("A peculiar rock is sitting here."))
    }

    @Test("LOOK ignores firstDescription for touched items")
    func testLookIgnoresFirstDescriptionAfterTouch() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let rock = Item(
            id: "rock", .name("rock"), .firstDescription("..."), .isTouched, .in(.location("room")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [rock])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("There is a rock here."))
    }

    // MARK: - Look with Containers and Surfaces

    @Test("LOOK lists items on a surface")
    func testLookListsItemsOnSurface() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let table = Item(id: "table", .name("table"), .isSurface, .in(.location("room")))
        let book = Item(id: "book", .name("book"), .in(.item("table")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [table, book])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("On the table is a book."))
    }

    @Test("LOOK lists items in an open container")
    func testLookListsItemsInOpenContainer() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let box = Item(id: "box", .name("box"), .isContainer, .isOpen, .in(.location("room")))
        let key = Item(id: "key", .name("key"), .in(.item("box")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [box, key])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("The box contains a key."))
    }

    @Test("LOOK does not list items in a closed container")
    func testLookHidesItemsInClosedContainer() async throws {
        let room = Location(id: "room", .name("Room"), .description("A room."))
        let box = Item(id: "box", .name("box"), .isContainer, .in(.location("room")))  // Closed by default
        let key = Item(id: "key", .name("key"), .in(.item("box")))
        let game = MinimalGame(player: Player(in: "room"), locations: [room], items: [box, key])
        (engine, mockIO) = await GameEngine.test(blueprint: game)

        try await engine.execute("look")
        let output = await mockIO.flush()
        #expect(output.contains("There is a box here."))
        #expect(!output.contains("key"))
    }

    // MARK: - ActionID Testing

    @Test("LOOK action resolves to LookActionHandler")
    func testLookActionID() async throws {
        let parser = StandardParser()
        let command = try parser.parse("look")
        let resolvedAction = await engine.resolveAction(for: command)
        #expect(isNotNil(resolvedAction))
        #expect(resolvedAction?.handler is LookActionHandler)
    }
}
