import CustomDump
import GnustoEngine
import GnustoTestSupport
import Testing

@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLOSE DIRECTOBJECT syntax works")
    func testCloseDirectObjectSyntax() async throws {
        // Given
        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close chest
            Firmly closed.
            """
        )

        let finalState = try await engine.item("chest")
        #expect(await finalState.hasFlag(.isOpen) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("SHUT syntax works")
    func testShutSyntax() async throws {
        // Given
        let door = Item(
            id: "door",
            .name("wooden door"),
            .description("A heavy wooden door."),
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shut door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > shut door
            Firmly closed.
            """
        )
    }

    // MARK: - Validation Testing

    @Test("Cannot close without specifying target")
    func testCannotCloseWithoutTarget() async throws {
        // Given
        let game = MinimalGame()
        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close
            Close what?
            """
        )
    }

    @Test("Cannot close target not in scope")
    func testCannotCloseTargetNotInScope() async throws {
        // Given
        let anotherRoom = Location(
            id: "anotherRoom",
            .name("Another Room"),
            .inherentlyLit
        )

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("remote door"),
            .description("A door in another room."),
            .isOpenable,
            .isOpen,
            .in("anotherRoom")
        )

        let game = MinimalGame(
            locations: anotherRoom,
            items: remoteDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close door
            Any such thing lurks beyond your reach.
            """
        )
    }

    @Test("Cannot close non-openable item")
    func testCannotCloseNonOpenableItem() async throws {
        // Given
        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close rock
            The large rock stubbornly resists your attempts to close it.
            """
        )
    }

    @Test("Requires light to close")
    func testRequiresLight() async throws {
        // Given: Dark room with openable item
        let darkRoom = Location(
            id: "darkRoom",
            .name("Dark Room"),
            .description("A pitch black room.")
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isOpenable,
            .isOpen,
            .in("darkRoom")
        )

        let game = MinimalGame(
            player: Player(in: "darkRoom"),
            locations: darkRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close chest
            The darkness here is absolute, consuming all light and hope of
            sight.
            """
        )
    }

    // MARK: - Processing Testing

    @Test("Close open item succeeds")
    func testCloseOpenItem() async throws {
        // Given
        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close box
            Firmly closed.
            """
        )

        let finalState = try await engine.item("box")
        #expect(await finalState.hasFlag(.isOpen) == false)
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    @Test("Close already closed item gives appropriate message")
    func testCloseAlreadyClosedItem() async throws {
        // Given
        let closedChest = Item(
            id: "closedChest",
            .name("closed chest"),
            .description("A chest that is already closed."),
            .isOpenable,
            // Note: No .isOpen flag - defaults to closed
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: closedChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(
            output,
            """
            > close chest
            The closed chest is already closed.
            """
        )

        let finalState = try await engine.item("closedChest")
        #expect(await finalState.hasFlag(.isOpen) == false)
    }

    @Test("Closing sets isTouched flag")
    func testClosingSetsTouchedFlag() async throws {
        // Given
        let container = Item(
            id: "container",
            .name("metal container"),
            .description("A metal storage container."),
            .isOpenable,
            .isOpen,
            .in(.startRoom)
        )

        let game = MinimalGame(
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close container")

        // Then
        let finalState = try await engine.item("container")
        #expect(await finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = CloseActionHandler()
        #expect(handler.synonyms.contains(.close))
        #expect(handler.synonyms.contains(.shut))
        #expect(handler.synonyms.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CloseActionHandler()
        #expect(handler.requiresLight == true)
    }
}
