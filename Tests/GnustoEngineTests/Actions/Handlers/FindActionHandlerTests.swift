import CustomDump
import Testing

@testable import GnustoEngine

@Suite("FindActionHandler Tests")
struct FindActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("FIND DIRECTOBJECT syntax works")
    func testFindDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("An old leather-bound book."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)
    }

    @Test("SEARCH FOR DIRECTOBJECT syntax works")
    func testSearchForDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let key = Item(
            id: "key",
            .name("brass key"),
            .description("A brass key."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You have it.
            """)
    }

    @Test("LOCATE syntax works")
    func testLocateSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let coin = Item(
            id: "coin",
            .name("gold coin"),
            .description("A shiny gold coin."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot find without specifying target")
    func testCannotFindWithoutTarget() async throws {
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
        try await engine.execute("find")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find
            Find what?
            """)
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
            .in(.location("darkRoom"))
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
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Find item held by player")
    func testFindItemHeldByPlayer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let sword = Item(
            id: "sword",
            .name("steel sword"),
            .description("A steel sword."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You have it.
            """)
    }

    @Test("Find item visible in current location")
    func testFindItemVisibleInCurrentLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let table = Item(
            id: "table",
            .name("wooden table"),
            .description("A wooden table."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)
    }

    @Test("Find item in container in current location")
    func testFindItemInContainerInCurrentLocation() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box."),
            .isContainer,
            .isOpen,
            .in(.location("testRoom"))
        )

        let ring = Item(
            id: "ring",
            .name("silver ring"),
            .description("A silver ring."),
            .isTakable,
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)
    }

    @Test("Find item not in scope")
    func testFindItemNotInScope() async throws {
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

        let remoteTreasure = Item(
            id: "remoteTreasure",
            .name("hidden treasure"),
            .description("A hidden treasure."),
            .isTakable,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
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
            You can’t see any such thing.
            """)
    }

    @Test("Find nonexistent item")
    func testFindNonexistentItem() async throws {
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
        try await engine.execute("find dragon")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > find dragon
            You can’t see any such thing.
            """)
    }

    @Test("Find item in closed container")
    func testFindItemInClosedContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("treasure chest"),
            .description("A treasure chest."),
            .isContainer,
            // Note: No .isOpen flag - container is closed
            .in(.location("testRoom"))
        )

        let jewelry = Item(
            id: "jewelry",
            .name("gold jewelry"),
            .description("Gold jewelry."),
            .isTakable,
            .in(.item("chest"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You can’t see any such thing.
            """)
    }

    @Test("Find multiple different items")
    func testFindMultipleDifferentItems() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

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
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            You have it.
            """)

        // When: Find visible item
        try await engine.execute("find statue")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > find statue
            It’s right here!
            """)
    }

    @Test("Find item on surface")
    func testFindItemOnSurface() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let desk = Item(
            id: "desk",
            .name("wooden desk"),
            .description("A wooden desk."),
            .isSurface,
            .in(.location("testRoom"))
        )

        let paper = Item(
            id: "paper",
            .name("important paper"),
            .description("An important paper."),
            .isTakable,
            .in(.item("desk"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)
    }

    @Test("Find using different verbs")
    func testFindUsingDifferentVerbs() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let crystal = Item(
            id: "crystal",
            .name("magic crystal"),
            .description("A magic crystal."),
            .isTakable,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
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
            It’s right here!
            """)

        // When: Use "locate"
        try await engine.execute("locate crystal")

        // Then
        let output2 = await mockIO.flush()
        expectNoDifference(
            output2,
            """
            > locate crystal
            It’s right here!
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = FindActionHandler()
        // FindActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = FindActionHandler()
        #expect(handler.verbs.contains(.find))
        #expect(handler.verbs.contains(.locate))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = FindActionHandler()
        #expect(handler.requiresLight == true)
    }
}
