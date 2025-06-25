import Testing
import CustomDump
@testable import GnustoEngine

@Suite("SmellActionHandler Tests")
struct SmellActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("SMELL alone syntax works")
    func testSmellAloneSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("SMELL DIRECTOBJECT syntax works")
    func testSmellDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let flower = Item(
            id: "flower",
            .name("red flower"),
            .description("A fragrant red flower."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: flower
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell flower")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell flower
            The red flower smells about average.
            """)
    }

    @Test("SNIFF syntax works")
    func testSniffSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let book = Item(
            id: "book",
            .name("old book"),
            .description("A musty old book."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: book
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sniff book")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sniff book
            The old book smells about average.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot smell target not in scope")
    func testCannotSmellTargetNotInScope() async throws {
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

        let remoteRose = Item(
            id: "remoteRose",
            .name("remote rose"),
            .description("A rose in another room."),
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteRose
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell rose")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell rose
            You can’t see any such thing.
            """)
    }

    @Test("Smell works in dark room")
    func testSmellWorksInDarkRoom() async throws {
        // Given: Dark room with an object to smell
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let candle = Item(
            id: "candle",
            .name("wax candle"),
            .description("A waxy candle."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: candle
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - smell the environment in dark
        try await engine.execute("smell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("Smell specific object in dark room fails")
    func testSmellSpecificObjectInDarkRoomFails() async throws {
        // Given: Dark room with an object to smell
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let spice = Item(
            id: "spice",
            .name("aromatic spice"),
            .description("A fragrant spice."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: spice
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When - smell specific object in dark
        try await engine.execute("smell spice")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell spice
            You can’t see any such thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Smell environment")
    func testSmellEnvironment() async throws {
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
        try await engine.execute("smell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("Smell object in room")
    func testSmellObjectInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let cheese = Item(
            id: "cheese",
            .name("aged cheese"),
            .description("A wheel of aged cheese."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: cheese
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell cheese")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell cheese
            The aged cheese smells about average.
            """)
    }

    @Test("Smell held item")
    func testSmellHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let perfume = Item(
            id: "perfume",
            .name("bottle of perfume"),
            .description("An elegant bottle of perfume."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: perfume
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell perfume")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell perfume
            The bottle of perfume smells about average.
            """)
    }

    @Test("Smell object in open container")
    func testSmellObjectInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("wooden box"),
            .description("A wooden box with aromatic contents."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let tea = Item(
            id: "tea",
            .name("herbal tea"),
            .description("Dried herbal tea leaves."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, tea
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("sniff tea")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > sniff tea
            The herbal tea smells about average.
            """)
    }

    @Test("Smell sequence of different objects")
    func testSmellSequenceOfDifferentObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let soap = Item(
            id: "soap",
            .name("lavender soap"),
            .description("A bar of lavender soap."),
            .in(.location("testRoom"))
        )

        let bread = Item(
            id: "bread",
            .name("fresh bread"),
            .description("A loaf of fresh bread."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: soap, bread
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell soap")
        try await engine.execute("sniff bread")
        try await engine.execute("smell")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell soap
            The lavender soap smells about average.
            > sniff bread
            The fresh bread smells about average.
            > smell
            You smell nothing unusual.
            """)
    }

    @Test("Different smell syntax variations")
    func testDifferentSmellSyntaxVariations() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let apple = Item(
            id: "apple",
            .name("green apple"),
            .description("A crisp green apple."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: apple
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("smell apple")
        try await engine.execute("sniff apple")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > smell apple
            The green apple smells about average.
            > sniff apple
            The green apple smells about average.
            """)
    }

    // MARK: - ActionID Testing

    @Test("Handler exposes correct ActionIDs")
    func testActionIDs() async throws {
        let handler = SmellActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct VerbIDs")
    func testVerbIDs() async throws {
        let handler = SmellActionHandler()
        #expect(handler.verbs.contains(.smell))
        #expect(handler.verbs.contains(.sniff))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = SmellActionHandler()
        #expect(handler.requiresLight == false)
    }
}
