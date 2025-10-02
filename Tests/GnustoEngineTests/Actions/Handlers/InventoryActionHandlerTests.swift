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
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
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
        await mockIO.expectOutput(
            """
            > inventory
            Your hands are as empty as your pockets.
            """
        )
    }

    @Test("Single item inventory")
    func testSingleItemInventory() async throws {
        // Given
        let game = MinimalGame(
            items: Lab.ironSword.inPlayerInventory
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        await mockIO.expectOutput(
            """
            > inventory
            You are carrying:
            - An iron sword
            """
        )
    }

    @Test("Multiple items inventory")
    func testMultipleItemsInventory() async throws {
        // Given
        let sword = Item("sword")
            .name("rusty sword")
            .description("An old rusty sword.")
            .in(.player)

        let gem = Item("gem")
            .name("sparkling gem")
            .description("A beautiful gem.")
            .in(.player)

        let lantern = Item("lantern")
            .name("brass lantern")
            .description("A shiny brass lantern.")
            .in(.player)

        let game = MinimalGame(
            items: sword, gem, lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        await mockIO.expectOutput(
            """
            > inventory
            You are carrying:
            - A sparkling gem
            - A brass lantern
            - A rusty sword
            """
        )
    }

    @Test("Items being worn")
    func testItemsBeingWorn() async throws {
        // Given
        let tiara = Item("tiara")
            .name("lovely tiara")
            .in(.player)
            .isWorn

        let game = MinimalGame(
            items: Lab.ironSword.inPlayerInventory, tiara
        )
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute(
            """
            inventory
            remove the tiara
            inventory
            """
        )

        // Then
        await mockIO.expectOutput(
            """
            > inventory
            You are carrying:
            - An iron sword
            - A lovely tiara (worn)

            > remove the tiara
            You remove the lovely tiara.

            > inventory
            You are carrying:
            - An iron sword
            - A lovely tiara
            """
        )
    }

    @Test("Inventory works in dark room")
    func testInventoryInDarkRoom() async throws {
        // Given: Dark room with player carrying items
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let lantern = Item("lantern")
            .name("brass lantern")
            .description("A shiny brass lantern.")
            .in(.player)

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: lantern
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("inventory")

        // Then
        await mockIO.expectOutput(
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
        let key = Item("key")
            .name("brass key")
            .description("A small brass key.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("take key")
        try await engine.execute("inventory")

        // Then
        await mockIO.expectOutput(
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
