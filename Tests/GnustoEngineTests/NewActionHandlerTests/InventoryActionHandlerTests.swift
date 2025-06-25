import Testing
import CustomDump
@testable import GnustoEngine

@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INVENTORY syntax works")
    func testInventorySyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inventory
            You are empty-handed.
            """)
    }

    @Test("I syntax works")
    func testISyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("i")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > i
            You are empty-handed.
            """)
    }

    // MARK: - Processing Testing

    @Test("Empty inventory shows appropriate message")
    func testEmptyInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inventory
            You are empty-handed.
            """)
    }

    @Test("Single item inventory")
    func testSingleItemInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("rusty sword"),
            .description("An old rusty sword."),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inventory
            You are carrying:
              - A rusty sword
            """)
    }

    @Test("Multiple items inventory")
    func testMultipleItemsInventory() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("rusty sword"),
            .description("An old rusty sword."),
            .in(.player)
        )

        let gem = Item(
            id: "gem",
            .name("sparkling gem"),
            .description("A beautiful gem."),
            .in(.player)
        )

        let lantern = Item(
            id: "lantern",
            .name("brass lantern"),
            .description("A shiny brass lantern."),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: sword, gem, lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inventory
            You are carrying:
              - A brass lantern
              - A rusty sword
              - A sparkling gem
            """)
    }

    @Test("Inventory works in dark room")
    func testInventoryInDarkRoom() async throws {
        // Given: Dark room with player carrying items
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let lantern = Item(
            id: "lantern",
            .name("brass lantern"),
            .description("A shiny brass lantern."),
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > inventory
            You are carrying:
              - A brass lantern
            """)
    }

    @Test("Inventory after taking item")
    func testInventoryAfterTaking() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take key")
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > take key
            Taken.
            > inventory
            You are carrying:
              - A brass key
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testCorrectActionIDs() async throws {
        // Given
        let handler = InventoryActionHandler()

        // When & Then
        // InventoryActionHandler doesn't specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testCorrectVerbIDs() async throws {
        // Given
        let handler = InventoryActionHandler()

        // When
        let verbIDs = handler.verbs

        // Then
        #expect(verbIDs.contains(.inventory))
        #expect(verbIDs.contains("i"))
    }

    @Test("Handler does not require light")
    func testHandlerDoesNotRequireLight() async throws {
        // Given
        let handler = InventoryActionHandler()

        // When & Then
        #expect(handler.requiresLight == false)
    }
}
