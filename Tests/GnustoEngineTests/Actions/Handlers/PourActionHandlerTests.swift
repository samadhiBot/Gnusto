import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("PourActionHandler Tests")
struct PourActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("POUR syntax works")
    func testPourSyntax() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: bottle, plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour bottle on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour bottle on plant
            You pour the water bottle on the small plant.
            """
        )

        let finalBottle = await engine.item("bottle")
        let finalPlant = await engine.item("plant")
        #expect(await finalBottle.hasFlag(.isTouched) == true)
        #expect(await finalPlant.hasFlag(.isTouched) == true)
    }

    @Test("POUR DIRECTOBJECT syntax works")
    func testPourDirectObjectSyntax() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water")

        // Then
        await mockIO.expectOutput(
            """
            > pour water
            Pour the glass of water on what?
            """
        )
    }

    @Test("SPILL syntax works")
    func testSpillSyntax() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: milk, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("spill milk on table")

        // Then
        await mockIO.expectOutput(
            """
            > spill milk on table
            You pour the glass of milk on the wooden table.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot pour without specifying what")
    func testCannotPourWithoutWhat() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour")

        // Then
        await mockIO.expectOutput(
            """
            > pour
            Pour what?
            """
        )
    }

    @Test("Cannot pour without specifying on what")
    func testCannotPourWithoutOnWhat() async throws {
        // Given
        let juice = Item(
            id: "juice",
            .name("orange juice"),
            .description("A glass of orange juice."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: juice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour juice")

        // Then
        await mockIO.expectOutput(
            """
            > pour juice
            Pour the orange juice on what?
            """
        )
    }

    @Test("Cannot pour non-existent item")
    func testCannotPourNonExistentItem() async throws {
        // Given
        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour nonexistent on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour nonexistent on plant
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour on non-existent target")
    func testCannotPourOnNonExistentTarget() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on nonexistent")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on nonexistent
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour item not in scope")
    func testCannotPourItemNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteWater, plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on plant
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour on target not in scope")
    func testCannotPourOnTargetNotInScope() async throws {
        // Given
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
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: water, remotePlant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on plant
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour location")
    func testCannotPourLocation() async throws {
        // Given
        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour testRoom on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour testRoom on plant
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour on location")
    func testCannotPourOnLocation() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on testRoom")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on testRoom
            You cannot reach any such thing from here.
            """
        )
    }

    @Test("Cannot pour player")
    func testCannotPourPlayer() async throws {
        // Given
        let plant = Item(
            id: "plant",
            .name("small plant"),
            .description("A small potted plant."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: plant
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour me on plant")

        // Then
        await mockIO.expectOutput(
            """
            > pour me on plant
            That lacks the necessary fluidity for pouring.
            """
        )
    }

    @Test("Cannot pour on player")
    func testCannotPourOnPlayer() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on me")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on me
            You pour the glass of water on yourself. How refreshing.
            """
        )
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
            .in("darkRoom")
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
        await mockIO.expectOutput(
            """
            > pour water on plant
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Pour item on another item sets touched flags")
    func testPourItemSetsTouchedFlags() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: oil, lamp
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // Verify initial state
        let initialOil = await engine.item("oil")
        let initialLamp = await engine.item("lamp")
        #expect(await initialOil.hasFlag(.isTouched) == false)
        #expect(await initialLamp.hasFlag(.isTouched) == false)

        // When
        try await engine.execute("pour oil on lamp")

        // Then
        let finalOil = await engine.item("oil")
        let finalLamp = await engine.item("lamp")
        #expect(await finalOil.hasFlag(.isTouched) == true)
        #expect(await finalLamp.hasFlag(.isTouched) == true)

        await mockIO.expectOutput(
            """
            > pour oil on lamp
            You pour the bottle of oil on the oil lamp.
            """
        )
    }

    @Test("Pour item updates pronouns")
    func testPourItemUpdatesPronouns() async throws {
        // Given
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
            .in(.startRoom)
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather book."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: water, flower, book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // First examine the book to set pronouns
        try await engine.execute(
            "examine book",
            "pour water on flower",
            "examine it"
        )

        // The "it" should refer to either the water or the flower
        await mockIO.expectOutput(
            """
            > examine book
            An old leather book.

            > pour water on flower
            You pour the glass of water on the wilted flower.

            > examine it
            A glass filled with water.
            """
        )
    }

    @Test("Cannot pour item on itself")
    func testCannotPourItemOnItself() async throws {
        // Given
        let water = Item(
            id: "water",
            .name("glass of water"),
            .description("A glass filled with water."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: water
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("pour water on water")

        // Then
        await mockIO.expectOutput(
            """
            > pour water on water
            You cannot pour something onto itself without breaking reality.
            """
        )
    }

    @Test("Pour different liquid types")
    func testPourDifferentLiquidTypes() async throws {
        // Given
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
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: wine, coffee, table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Pour wine
        try await engine.execute(
            "pour wine on table",
            "pour coffee on table"
        )

        await mockIO.expectOutput(
            """
            > pour wine on table
            You pour the bottle of wine on the marble table.

            > pour coffee on table
            You pour the cup of coffee on the marble table.
            """
        )
    }

    @Test("Pour on different surface types")
    func testPourOnDifferentSurfaceTypes() async throws {
        // Given
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
            .in(.startRoom)
        )

        let carpet = Item(
            id: "carpet",
            .name("persian carpet"),
            .description("An expensive persian carpet."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: water, floor, carpet
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - Pour on floor
        try await engine.execute(
            "pour water on floor",
            "pour water on carpet"
        )

        await mockIO.expectOutput(
            """
            > pour water on floor
            You pour the glass of water on the wooden floor.

            > pour water on carpet
            You pour the glass of water on the persian carpet.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = PourActionHandler()
        #expect(handler.synonyms.contains(.pour))
        #expect(handler.synonyms.contains(.spill))
        #expect(handler.synonyms.count == 2)
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
