import Testing
import CustomDump
@testable import GnustoEngine

@Suite("DrinkActionHandler Tests")
struct DrinkActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("DRINK syntax works")
    func testDrinkSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let potion = Item(
            id: "potion",
            .name("bubbling potion"),
            .description("A strange, bubbling potion."),
            .isDrinkable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: potion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink potion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink potion
            You drink the bubbling potion.
            """)

        let finalState = await engine.gameState.items[potion.id]
        #expect(finalState == nil) // The potion should be consumed
    }

    // MARK: - Validation Testing

    @Test("Cannot drink without specifying target")
    func testCannotDrinkWithoutTarget() async throws {
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
        try await engine.execute("drink")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink
            What do you want to drink?
            """)
    }

    @Test("Cannot drink item not in scope")
    func testCannotDrinkItemNotInScope() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remotePotion = Item(
            id: "remotePotion",
            .name("remote potion"),
            .isDrinkable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remotePotion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink potion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink potion
            You can't see any such thing.
            """)
    }

    @Test("Requires light to drink items")
    func testRequiresLight() async throws {
        // Given
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room")
        )

        let potion = Item(
            id: "potion",
            .name("bubbling potion"),
            .isDrinkable,
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: potion
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink potion")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink potion
            It is pitch black. You can't see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Cannot drink a non-drinkable item")
    func testCannotDrinkNonDrinkableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("heavy rock"),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink rock
            You can't drink that.
            """)
    }

    @Test("Drinking water gives a special message")
    func testDrinkingWater() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("quantity of water"),
            .isWater, // Special flag
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("drink water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > drink water
            Drinking the water has no apparent effect.
            """)

        let finalState = await engine.gameState.items[water.id]
        #expect(finalState != nil) // Water is not consumed
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.verbs.contains(.drink))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = DrinkActionHandler()
        #expect(handler.requiresLight == true)
    }
}
