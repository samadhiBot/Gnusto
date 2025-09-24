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
        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather-bound book."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find book
            Behold! It's right here!
            """
        )
    }

    @Test("SEARCH FOR DIRECTOBJECT syntax works")
    func testSearchForDirectObjectSyntax() async throws {
        // Given
        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: key
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("search for key")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > search for key
            You have it already.
            """
        )
    }

    @Test("LOCATE syntax works")
    func testLocateSyntax() async throws {
        // Given
        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: coin
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("locate coin")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > locate coin
            Behold! It's right here!
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find
            Find what?
            """
        )
    }

    @Test("Requires light to find")
    func testRequiresLight() async throws {
        // Given: Dark room with item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
            // Note: No .inherentlyLit property
        )

        let gem = Item(
            id: "gem",
            .name("precious gem"),
            .description("A precious gem."),
            .isTakable,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: gem
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find gem")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find gem
            You stand in a depthless black where even your thoughts seem to
            whisper, careful not to make a sound.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Find item held by player")
    func testFindItemHeldByPlayer() async throws {
        // Given
        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A steel sword."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            items: sword
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find sword")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find sword
            You have it already.
            """
        )
    }

    @Test("Find item visible in current location")
    func testFindItemVisibleInCurrentLocation() async throws {
        // Given
        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: table
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find table")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find table
            Behold! It's right here!
            """
        )
    }

    @Test("Find item in container in current location")
    func testFindItemInContainerInCurrentLocation() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.startRoom)
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            items: box, ring
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find ring")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find ring
            Behold! It's right here!
            """
        )
    }

    @Test("Find item not in scope")
    func testFindItemNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteTreasure = Item(
            id: "remoteTreasure",
            .name("hidden treasure"),
            .description("A hidden treasure."),
            .isTakable,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteTreasure
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find treasure")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find treasure
            Any such thing remains frustratingly inaccessible.
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
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find dragon
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Find item in closed container")
    func testFindItemInClosedContainer() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.startRoom)
        )

        let jewelry = Item(
            id: "jewelry",
            .name("gold jewelry"),
            .description("Gold jewelry."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            items: chest, jewelry
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find jewelry")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find jewelry
            Any such thing remains frustratingly inaccessible.
            """
        )
    }

    @Test("Find multiple different items")
    func testFindMultipleDifferentItems() async throws {
        // Given
        let lamp = Item(
            id: "lamp",
            .name("brass lamp"),
            .description("A brass lamp."),
            .isTakable,
            .in(.player)
        )

        let statue = Item(
            id: "statue",
            .name("stone statue"),
            .description("A stone statue."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: lamp, statue
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Find held item
        try await engine.execute("find lamp")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > find lamp
            You have it already.
            """
        )

        // When: Find visible item
        try await engine.execute("find statue")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > find statue
            It stands before you in all its mundane glory!
            """
        )
    }

    @Test("Find item on surface")
    func testFindItemOnSurface() async throws {
        // Given
        let desk = Item(
            id: "desk",
            .name("wooden desk"),
            .description("A wooden desk."),
            .isSurface,
            .in(.startRoom)
        )

        let paper = Item(
            id: "paper",
            .name("important paper"),
            .description("An important paper."),
            .isTakable,
            .in(.item("desk"))
        )

        let game = MinimalGame(
            items: desk, paper
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("find paper")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find paper
            Behold! It's right here!
            """
        )
    }

    @Test("Find using different verbs")
    func testFindUsingDifferentVerbs() async throws {
        // Given
        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A magic crystal."),
            .isTakable,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: crystal
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When: Use "find"
        try await engine.execute("find crystal")

        // Then
        let output1 = await mockIO.flush()
        expectNoDifference(
            output1,
            """
            > find crystal
            Behold! It's right here!
            """
        )

        // When: Use "locate"
        try await engine.execute("locate crystal")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > locate crystal
            It stands before you in all its mundane glory!
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
