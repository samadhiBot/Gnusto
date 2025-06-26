import Testing
import CustomDump
@testable import GnustoEngine

@Suite("ListenActionHandler Tests")
struct ListenActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LISTEN alone syntax works")
    func testListenAloneSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A quiet room for testing."),
            .inherentlyLit
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("LISTEN TO DIRECTOBJECT syntax works")
    func testListenToDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let radio = Item(
            id: "radio",
            .name("old radio"),
            .description("An antique radio."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to radio")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to radio
            You hear nothing unusual.
            """)
    }

    // MARK: - Validation Testing

    @Test("Listen works in dark room")
    func testListenWorksInDarkRoom() async throws {
        // Given: Dark room
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("Listen to object in dark room")
    func testListenToObjectInDarkRoom() async throws {
        // Given: Dark room with an object
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let clock = Item(
            id: "clock",
            .name("ticking clock"),
            .description("A mechanical clock."),
            .in(.location("darkRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: clock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to clock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to clock
            You hear nothing unusual.
            """)
    }

    // MARK: - Processing Testing

    @Test("Listen to environment")
    func testListenToEnvironment() async throws {
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
        try await engine.execute("listen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("Listen to object in room")
    func testListenToObjectInRoom() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let fountain = Item(
            id: "fountain",
            .name("stone fountain"),
            .description("A decorative stone fountain."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: fountain
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to fountain")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to fountain
            You hear nothing unusual.
            """)
    }

    @Test("Listen to held item")
    func testListenToHeldItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let watch = Item(
            id: "watch",
            .name("pocket watch"),
            .description("An ornate pocket watch."),
            .isTakable,
            .in(.player)
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: watch
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to watch")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to watch
            You hear nothing unusual.
            """)
    }

    @Test("Listen to object in open container")
    func testListenToObjectInOpenContainer() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("music box"),
            .description("An ornate music box."),
            .isContainer,
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let mechanism = Item(
            id: "mechanism",
            .name("music mechanism"),
            .description("The mechanical parts of the music box."),
            .in(.item("box"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box, mechanism
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to mechanism")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to mechanism
            You hear nothing unusual.
            """)
    }

    @Test("Listen sequence")
    func testListenSequence() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let piano = Item(
            id: "piano",
            .name("grand piano"),
            .description("A beautiful grand piano."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: piano
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen")
        try await engine.execute("listen to piano")
        try await engine.execute("listen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            > listen to piano
            You hear nothing unusual.
            > listen
            You hear nothing unusual.
            """)
    }

    @Test("Listen with different objects")
    func testListenWithDifferentObjects() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .in(.location("testRoom"))
        )

        let wind = Item(
            id: "wind",
            .name("wind chimes"),
            .description("Delicate wind chimes."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door, wind
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to door")
        try await engine.execute("listen to chimes")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen to door
            You hear nothing unusual.
            > listen to chimes
            You hear nothing unusual.
            """)
    }

    @Test("Listen multiple times")
    func testListenMultipleTimes() async throws {
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
        try await engine.execute("listen")
        try await engine.execute("listen")
        try await engine.execute("listen")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > listen
            You hear nothing unusual.
            > listen
            You hear nothing unusual.
            > listen
            You hear nothing unusual.
            """)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = ListenActionHandler()
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ListenActionHandler()
        #expect(handler.verbs.contains(.listen))
        #expect(handler.verbs.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = ListenActionHandler()
        #expect(handler.requiresLight == false)
    }
}
