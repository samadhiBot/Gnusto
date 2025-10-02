import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("FindActionHandler Tests")
struct FindActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("FIND DIRECTOBJECT syntax works")
    func testFindDirectObjectSyntax() async throws {
        // Given
        let book = Item("book")
            .name("old book")
            .description("An old leather-bound book.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find book")

        // Then
        await mockIO.expect(
            """
            > find book
            It stands before you in all its mundane glory!
            """
        )
    }

    @Test("SEARCH FOR DIRECTOBJECT syntax works")
    func testSearchForDirectObjectSyntax() async throws {
        // Given
        let key = Item("key")
            .name("brass key")
            .description("A brass key.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("search for key")

        // Then
        await mockIO.expect(
            """
            > search for key
            It rests securely in your possession.
            """
        )
    }

    @Test("LOCATE syntax works")
    func testLocateSyntax() async throws {
        // Given
        let coin = Item("coin")
            .name("gold coin")
            .description("A shiny gold coin.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("locate coin")

        // Then
        await mockIO.expect(
            """
            > locate coin
            It stands before you in all its mundane glory!
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot find without specifying target")
    func testCannotFindWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find")

        // Then
        await mockIO.expect(
            """
            > find
            Find what?
            """
        )
    }

    @Test("Requires light to find")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")
        // Note: No .inherentlyLit property

        let gem = Item("gem")
            .name("precious gem")
            .description("A precious gem.")
            .isTakable
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find gem")

        // Then
        await mockIO.expect(
            """
            > find gem
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Find item held by player")
    func testFindItemHeldByPlayer() async throws {
        // Given
        let sword = Item("sword")
            .name("steel sword")
            .description("A steel sword.")
            .isTakable
            .in(.player)

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find sword")

        // Then
        await mockIO.expect(
            """
            > find sword
            It rests securely in your possession.
            """
        )
    }

    @Test("Find item visible in current location")
    func testFindItemVisibleInCurrentLocation() async throws {
        // Given
        let table = Item("table")
            .name("wooden table")
            .description("A wooden table.")
            .in(.startRoom)

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find table")

        // Then
        await mockIO.expect(
            """
            > find table
            It stands before you in all its mundane glory!
            """
        )
    }

    @Test("Find item in container in current location")
    func testFindItemInContainerInCurrentLocation() async throws {
        // Given
        let box = Item("box")
            .name("wooden box")
            .description("A wooden box.")
            .isContainer
            .isOpen
            .in(.startRoom)

        let ring = Item("ring")
            .name("silver ring")
            .description("A silver ring.")
            .isTakable
            .in(.item("box"))

        let game = MinimalGame(
            items: box, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find ring")

        // Then
        await mockIO.expect(
            """
            > find ring
            It stands before you in all its mundane glory!
            """
        )
    }

    @Test("Find item not in scope")
    func testFindItemNotInScope() async throws {
        // Given
        let anotherRoom = Location("anotherRoom")
            .name("Another Room")
            .inherentlyLit

        let remoteTreasure = Item("remoteTreasure")
            .name("hidden treasure")
            .description("A hidden treasure.")
            .isTakable
            .in("anotherRoom")

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTreasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find treasure")

        // Then
        await mockIO.expect(
            """
            > find treasure
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Find nonexistent item")
    func testFindNonexistentItem() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find dragon")

        // Then
        await mockIO.expect(
            """
            > find dragon
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Find item in closed container")
    func testFindItemInClosedContainer() async throws {
        // Given
        let chest = Item("chest")
            .name("treasure chest")
            .description("A treasure chest.")
            .isContainer
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)

        let jewelry = Item("jewelry")
            .name("gold jewelry")
            .description("Gold jewelry.")
            .isTakable
            .in(.item("chest"))

        let game = MinimalGame(
            items: chest, jewelry
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find jewelry")

        // Then
        await mockIO.expect(
            """
            > find jewelry
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Find multiple different items")
    func testFindMultipleDifferentItems() async throws {
        // Given
        let lamp = Item("lamp")
            .name("brass lamp")
            .description("A brass lamp.")
            .isTakable
            .in(.player)

        let statue = Item("statue")
            .name("stone statue")
            .description("A stone statue.")
            .in(.startRoom)

        let game = MinimalGame(
            items: lamp, statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Find held item
        try await engine.execute("find lamp")

        // Then
        await mockIO.expect(
            """
            > find lamp
            It rests securely in your possession.
            """
        )

        // When: Find visible item
        try await engine.execute("find statue")

        // Then
        await mockIO.expect(
            """
            > find statue
            Your powers of observation are truly remarkable -- it's right
            here!
            """
        )
    }

    @Test("Find item on surface")
    func testFindItemOnSurface() async throws {
        // Given
        let desk = Item("desk")
            .name("wooden desk")
            .description("A wooden desk.")
            .isSurface
            .in(.startRoom)

        let paper = Item("paper")
            .name("important paper")
            .description("An important paper.")
            .isTakable
            .in(.item("desk"))

        let game = MinimalGame(
            items: desk, paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find paper")

        // Then
        await mockIO.expect(
            """
            > find paper
            It stands before you in all its mundane glory!
            """
        )
    }

    @Test("Find using different verbs")
    func testFindUsingDifferentVerbs() async throws {
        // Given
        let crystal = Item("crystal")
            .name("magic crystal")
            .description("A magic crystal.")
            .isTakable
            .in(.startRoom)

        let game = MinimalGame(
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "find"
        try await engine.execute("find crystal")

        // Then
        await mockIO.expect(
            """
            > find crystal
            It stands before you in all its mundane glory!
            """
        )

        // When: Use "locate"
        try await engine.execute("locate crystal")

        // Then
        await mockIO.expect(
            """
            > locate crystal
            Your powers of observation are truly remarkable -- it's right
            here!
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = FindActionHandler()
        #expect(handler.synonyms.contains(.find))
        #expect(handler.synonyms.contains(.locate))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = FindActionHandler()
        #expect(handler.requiresLight == true)
    }
}
