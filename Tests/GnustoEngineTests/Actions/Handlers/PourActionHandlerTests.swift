import CustomDump
import Testing

@testable import GnustoEngine

@Suite("PourActionHandler Tests")
struct PourActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("POUR syntax works")
    func testPourSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let bottle = Item(
            id: "bottle",
            .name("water bottle"),
            .description("A bottle filled with water."),
            .isTakable,
            .in(.player)
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .isPlant,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: bottle, plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour bottle on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour bottle on plant
            You pour the water bottle on the small plant.
            """)

        let finalBottle = try await engine.item("bottle")
        let finalPlant = try await engine.item("plant")
        #expect(finalBottle.hasFlag(.isTouched) == true)
        #expect(finalPlant.hasFlag(.isTouched) == true)
    }

    @Test("POUR DIRECTOBJECT syntax works")
    func testPourDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water
            Pour the glass of water on what?
            """)
    }

    @Test("SPILL syntax works")
    func testSpillSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let milk = Item(
            id: "milk",
            .name("glass of milk"),
            .description("A glass of fresh milk."),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A sturdy wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: milk, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("spill milk on table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > spill milk on table
            You pour the glass of milk on the wooden table.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot pour without specifying what")
    func testCannotPourWithoutWhat() async throws {
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
        try await engine.execute("pour")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour
            Pour what?
            """)
    }

    @Test("Cannot pour without specifying on what")
    func testCannotPourWithoutOnWhat() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let juice = Item(
            id: "juice",
            .name("orange juice"),
            .description("A glass of orange juice."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: juice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour juice")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour juice
            Pour the orange juice on what?
            """)
    }

    @Test("Cannot pour non-existent item")
    func testCannotPourNonExistentItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour nonexistent on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour nonexistent on plant
            You can’t see any such thing.
            """)
    }

    @Test("Cannot pour on non-existent target")
    func testCannotPourOnNonExistentTarget() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on nonexistent")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on nonexistent
            You can’t see any such thing.
            """)
    }

    @Test("Cannot pour item not in scope")
    func testCannotPourItemNotInScope() async throws {
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

        let remoteWater = Item(
            id: "remoteWater",
            .name("remote water"),
            .description("Water in another room."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteWater, plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on plant
            You can’t see any such thing.
            """)
    }

    @Test("Cannot pour on target not in scope")
    func testCannotPourOnTargetNotInScope() async throws {
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

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let remotePlant = Item(
            id: "remotePlant",
            .name("remote plant"),
            .description("A plant in another room."),
            .isPlant,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: water, remotePlant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on plant
            You can’t see any such thing.
            """)
    }

    @Test("Cannot pour location")
    func testCannotPourLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour testRoom on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour testRoom on plant
            You can’t pour that.
            """)
    }

    @Test("Cannot pour on location")
    func testCannotPourOnLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on testRoom")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on testRoom
            You can’t pour the glass of water on that.
            """)
    }

    @Test("Cannot pour player")
    func testCannotPourPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour me on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour me on plant
            You can’t pour that.
            """)
    }

    @Test("Cannot pour on player")
    func testCannotPourOnPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on me")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on me
            You can’t pour the glass of water on that.
            """)
    }

    @Test("Requires light to pour")
    func testRequiresLight() async throws {
        // Given: Dark room with items
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: water, plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on plant")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on plant
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Pour item on another item sets touched flags")
    func testPourItemSetsTouchedFlags() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let oil = Item(
            id: "oil",
            .name("bottle of oil"),
            .description("A bottle filled with oil."),
            .isTakable,
            .in(.player)
        )

        let lamp = Item(
            id: "lamp",
            .name("oil lamp"),
            .description("An antique oil lamp."),
            .isLightSource,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: oil, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialOil = try await engine.item("oil")
        let initialLamp = try await engine.item("lamp")
        #expect(initialOil.hasFlag(.isTouched) == false)
        #expect(initialLamp.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("pour oil on lamp")

        // Then
        let finalOil = try await engine.item("oil")
        let finalLamp = try await engine.item("lamp")
        #expect(finalOil.hasFlag(.isTouched) == true)
        #expect(finalLamp.hasFlag(.isTouched) == true)

        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour oil on lamp
            You pour the bottle of oil on the oil lamp.
            """)
    }

    @Test("Pour item updates pronouns")
    func testPourItemUpdatesPronouns() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let flower = Item(
            id: "flower",
            .name("wilted flower"),
            .description("A wilted flower that needs water."),
            .in(.location("testRoom"))
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water, flower, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute("examine book")
        _ = await mockIO.flush()

        // When - Pour water should update pronouns
        try await engine.execute("pour water on flower")
        _ = await mockIO.flush()

        // Then - "examine it" should refer to one of the poured items
        try await engine.execute("examine it")

        let output = await mockIO.flush()
        // The "it" should refer to either the water or the flower
        #expect(
            output.contains("glass filled with water")
                || output.contains("wilted flower that needs water")
        )
    }

    @Test("Cannot pour item on itself")
    func testCannotPourItemOnItself() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on water")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > pour water on water
            You can’t pour the glass of water on itself.
            """)
    }

    @Test("Pour different liquid types")
    func testPourDifferentLiquidTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let wine = Item(
            id: "wine",
            .name("bottle of wine"),
            .description("A bottle of red wine."),
            .isTakable,
            .in(.player)
        )

        let coffee = Item(
            id: "coffee",
            .name("cup of coffee"),
            .description("A steaming cup of coffee."),
            .isTakable,
            .in(.player)
        )

        let table = Item(
            id: "table",
            .name("marble table"),
            .description("An elegant marble table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: wine, coffee, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Pour wine
        try await engine.execute("pour wine on table")

        let wineOutput = await mockIO.flush()
        expectNoDifference(
            wineOutput,
            """
            > pour wine on table
            You pour the bottle of wine on the marble table.
            """)

        // When - Pour coffee
        try await engine.execute("pour coffee on table")

        let coffeeOutput = await mockIO.flush()
        expectNoDifference(
            coffeeOutput,
            """
            > pour coffee on table
            You pour the cup of coffee on the marble table.
            """)
    }

    @Test("Pour on different surface types")
    func testPourOnDifferentSurfaceTypes() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let floor = Item(
            id: "floor",
            .name("wooden floor"),
            .description("Polished wooden flooring."),
            .in(.location("testRoom"))
        )

        let carpet = Item(
            id: "carpet",
            .name("persian carpet"),
            .description("An expensive persian carpet."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: water, floor, carpet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Pour on floor
        try await engine.execute("pour water on floor")

        let floorOutput = await mockIO.flush()
        expectNoDifference(
            floorOutput,
            """
            > pour water on floor
            You pour the glass of water on the wooden floor.
            """)

        // Refill water for next test (simulate)
        try await engine.execute("pour water on carpet")

        let carpetOutput = await mockIO.flush()
        expectNoDifference(
            carpetOutput,
            """
            > pour water on carpet
            You pour the glass of water on the persian carpet.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = PourActionHandler()
        // PourActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = PourActionHandler()
        #expect(handler.verbs.contains(.pour))
        #expect(handler.verbs.contains(.spill))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = PourActionHandler()
        #expect(handler.requiresLight == true)
    }

    @Test("Handler uses correct syntax")
    func testSyntaxRules() async throws {
        let handler = PourActionHandler()
        #expect(handler.syntax.count == 3)

        // Should have three syntax rules:
        // .match(.verb)
        // .match(.verb, .directObject)
        // .match(.verb, .directObject, .on, .indirectObject)
    }
}
