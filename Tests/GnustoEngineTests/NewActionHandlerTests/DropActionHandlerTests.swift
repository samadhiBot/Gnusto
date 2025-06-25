import Testing
import CustomDump
@testable import GnustoEngine

@Suite("DropActionHandler Tests")
struct DropActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DROP syntax works")
    func testDropSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let sword = Item(id: "sword", .name("long sword"), .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop sword
            Dropped.
            """)

        let finalState = try await engine.item("sword")
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("PUT DOWN syntax works")
    func testPutDownSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let shield = Item(id: "shield", .name("heavy shield"), .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: shield
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("put down shield")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > put down shield
            Dropped.
            """)
        let finalState = try await engine.item("shield")
        #expect(finalState.parent == .location("testRoom"))
    }

    @Test("THROW an item (not at a target) is a synonym for drop")
    func testThrowAsDropSyntax() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let rock = Item(id: "rock", .name("a rock"), .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("throw rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > throw rock
            Dropped.
            """)
        let finalState = try await engine.item("rock")
        #expect(finalState.parent == .location("testRoom"))
    }


    // MARK: - Validation Testing

    @Test("Cannot drop without specifying target")
    func testCannotDropWithoutTarget() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop
            What do you want to drop?
            """)
    }

    @Test("Cannot drop item not held")
    func testCannotDropItemNotHeld() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let book = Item(id: "book", .name("heavy book"), .in(.location("testRoom")))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop book
            You're not holding that.
            """)
    }

    @Test("Cannot drop a worn item")
    func testCannotDropWornItem() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let cloak = Item(id: "cloak", .name("dark cloak"), .isWearable, .isWorn, .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cloak
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop cloak")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop cloak
            You are wearing the dark cloak. You'll have to take it off first.
            """)
        let finalState = try await engine.item("cloak")
        #expect(finalState.parent == .player)
        #expect(finalState.hasFlag(.isWorn))
    }

    // MARK: - Processing Testing

    @Test("Drop all items")
    func testDropAll() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let sword = Item(id: "sword", .name("long sword"), .in(.player))
        let shield = Item(id: "shield", .name("heavy shield"), .in(.player))
        let key = Item(id: "key", .name("small key"), .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, shield, key
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop all
            long sword: Dropped.
            heavy shield: Dropped.
            small key: Dropped.
            """)
        #expect((try await engine.item("sword")).parent == .location("testRoom"))
        #expect((try await engine.item("shield")).parent == .location("testRoom"))
        #expect((try await engine.item("key")).parent == .location("testRoom"))
    }

    @Test("Drop all with some worn items")
    func testDropAllWithWornItems() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let sword = Item(id: "sword", .name("long sword"), .in(.player))
        let cloak = Item(id: "cloak", .name("dark cloak"), .isWearable, .isWorn, .in(.player))

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, cloak
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop all
            long sword: Dropped.
            dark cloak: You are wearing the dark cloak. You'll have to take it off first.
            """)

        #expect((try await engine.item("sword")).parent == .location("testRoom"))
        #expect((try await engine.item("cloak")).parent == .player)
        #expect((try await engine.item("cloak")).hasFlag(.isWorn))
    }

    @Test("Drop all when holding nothing")
    func testDropAllWhenEmptyHanded() async throws {
        // Given
        let testRoom = Location(id: "testRoom", .name("Test Room"), .inherentlyLit)
        let game = MinimalGame(player: Player(in: "testRoom"), locations: testRoom)
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drop all")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drop all
            You are empty-handed.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DropActionHandler()
        #expect(handler.verbs.contains(.drop))
        #expect(handler.verbs.contains(.putDown))
        #expect(handler.verbs.contains(.throw))
        #expect(handler.verbs.count == 3)
    }

    @Test("Handler does not require light")
    func testRequiresLightProperty() async throws {
        let handler = DropActionHandler()
        #expect(handler.requiresLight == false)
    }
}
