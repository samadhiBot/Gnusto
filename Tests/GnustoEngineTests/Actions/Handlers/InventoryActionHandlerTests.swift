import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("InventoryActionHandler Tests")
struct InventoryActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("INVENTORY syntax works")
    func testInventorySyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            Your hands are as empty as your pockets.
            """
        )
    }

    @Test("I syntax works")
    func testISyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("i")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > i
            Your hands are as empty as your pockets.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Empty inventory shows appropriate message")
    func testEmptyInventory() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            Your hands are as empty as your pockets.
            """
        )
    }

    @Test("Single item inventory")
    func testSingleItemInventory() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("rusty sword"),
            .description("An old rusty sword."),
            .in(.player)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            You are carrying:
            - A rusty sword
            """
        )
    }

    @Test("Multiple items inventory")
    func testMultipleItemsInventory() async throws {
        // Given
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
            items: sword, gem, lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > inventory
            You are carrying:
            - A sparkling gem
            - A brass lantern
            - A rusty sword
            """
        )
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
        expectNoDifference(
            output,
            """
            > inventory
            You are carrying:
            - A brass lantern
            """
        )
    }

    @Test("Inventory after taking item")
    func testInventoryAfterTaking() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A small brass key."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take key")
        try await engine.execute("inventory")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > take key
            Taken.

            > inventory
            You are carrying:
            - A brass key
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testCorrectVerbs() async throws {
        // Given
        let handler = InventoryActionHandler()

        // When
        let verbIDs = handler.synonyms

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
