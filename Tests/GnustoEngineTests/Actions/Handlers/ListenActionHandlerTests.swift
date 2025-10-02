import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("ListenActionHandler Tests")
struct ListenActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("LISTEN alone syntax works")
    func testListenAloneSyntax() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen")

        // Then
        await mockIO.expect(
            """
            > listen
            The world holds its breath as you listen, revealing nothing of
            import.
            """
        )
    }

    @Test("LISTEN TO DIRECTOBJECT syntax works")
    func testListenToDirectObjectSyntax() async throws {
        // Given
        let radio = Item("radio")
            .name("old radio")
            .description("An antique radio.")
            .in(.startRoom)

        let game = MinimalGame(
            items: radio
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to radio")

        // Then
        await mockIO.expect(
            """
            > listen to radio
            You listen to the old radio. You hear nothing unusual.
            """
        )
    }

    @Test("LISTEN FOR DIRECTOBJECT syntax works")
    func testListenForDirectObjectSyntax() async throws {
        // Given
        let horse = Item("horse")
            .name("white horse")
            .description("A beautiful white horse.")
            .in(.startRoom)

        let game = MinimalGame(
            items: horse
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen for the horse")

        // Then
        await mockIO.expect(
            """
            > listen for the horse
            You listen for the white horse but hear nothing.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Listen works in dark room")
    func testListenWorksInDarkRoom() async throws {
        // Given: Dark room
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen")

        // Then
        await mockIO.expect(
            """
            > listen
            The world holds its breath as you listen, revealing nothing of
            import.
            """
        )
    }

    @Test("Listen to object in dark room")
    func testListenToObjectInDarkRoom() async throws {
        // Given: Dark room with an object
        let darkRoom = Location("darkRoom")
            .name("Dark Room")
            .description("A pitch black room.")

        let clock = Item("clock")
            .name("ticking clock")
            .description("A mechanical clock.")
            .in("darkRoom")

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: clock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to the clock")

        // Then
        await mockIO.expect(
            """
            > listen to the clock
            You strain your ears in the darkness but hear nothing unusual.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Listen to object in open container")
    func testListenToObjectInOpenContainer() async throws {
        // Given
        let box = Item("box")
            .name("music box")
            .description("An ornate music box.")
            .isContainer
            .isOpenable
            .isOpen
            .in(.startRoom)

        let mechanism = Item("mechanism")
            .name("music mechanism")
            .description("The mechanical parts of the music box.")
            .in(.item("box"))

        let game = MinimalGame(
            items: box, mechanism
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("listen to mechanism")

        // Then
        await mockIO.expect(
            """
            > listen to mechanism
            You listen to the music mechanism. You hear nothing unusual.
            """
        )
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = ListenActionHandler()
        #expect(handler.synonyms.contains(.listen))
        #expect(handler.synonyms.count == 1)
    }

    @Test("Handler does not require light")
    func testDoesNotRequireLight() async throws {
        let handler = ListenActionHandler()
        #expect(handler.requiresLight == false)
    }
}
