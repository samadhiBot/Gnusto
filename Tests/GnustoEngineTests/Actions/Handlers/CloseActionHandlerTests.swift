import Testing
import CustomDump
@testable import GnustoEngine

@Suite("CloseActionHandler Tests")
struct CloseActionHandlerTests {

    // MARK: - Syntax Rule Testing

    @Test("CLOSE DIRECTOBJECT syntax works")
    func testCloseDirectObjectSyntax() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .description("A room for testing."),
            .inherentlyLit
        )

        let chest = Item(
            id: "chest",
            .name("wooden chest"),
            .description("A large wooden chest."),
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: chest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close chest
            Closed.
            """)

        let finalState = try await engine.item("chest")
        #expect(finalState.hasFlag(.isOpen) == false)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("SHUT syntax works")
    func testShutSyntax() async throws {
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
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: door
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("shut door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > shut door
            Closed.
            """)
    }

    // MARK: - Validation Testing

    @Test("Cannot close without specifying target")
    func testCannotCloseWithoutTarget() async throws {
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
        try await engine.execute("close")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close
            Close what?
            """)
    }

    @Test("Cannot close target not in scope")
    func testCannotCloseTargetNotInScope() async throws {
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

        let remoteDoor = Item(
            id: "remoteDoor",
            .name("remote door"),
            .description("A door in another room."),
            .isOpenable,
            .isOpen,
            .in(.location("anotherRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom, anotherRoom,
            items: remoteDoor
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close door")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close door
            You can’t see any such thing.
            """)
    }

    @Test("Cannot close non-openable item")
    func testCannotCloseNonOpenableItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let rock = Item(
            id: "rock",
            .name("large rock"),
            .description("A large boulder."),
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: rock
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close rock")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close rock
            You can’t close the large rock.
            """)
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
            .in(.location("darkRoom"))
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
        expectNoDifference(output, """
            > close chest
            It is pitch black. You can’t see a thing.
            """)
    }

    // MARK: - Processing Testing

    @Test("Close open item succeeds")
    func testCloseOpenItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let box = Item(
            id: "box",
            .name("cardboard box"),
            .description("A simple cardboard box."),
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: box
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close box")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close box
            Closed.
            """)

        let finalState = try await engine.item("box")
        #expect(finalState.hasFlag(.isOpen) == false)
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    @Test("Close already closed item gives appropriate message")
    func testCloseAlreadyClosedItem() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let closedChest = Item(
            id: "closedChest",
            .name("closed chest"),
            .description("A chest that is already closed."),
            .isOpenable,
            // Note: No .isOpen flag - defaults to closed
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: closedChest
        )

        let (engine, mockIO) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close chest")

        // Then
        let output = await mockIO.flush()
        expectNoDifference(output, """
            > close chest
            The closed chest is already closed.
            """)

        let finalState = try await engine.item("closedChest")
        #expect(finalState.hasFlag(.isOpen) == false)
    }

    @Test("Closing sets isTouched flag")
    func testClosingSetsTouchedFlag() async throws {
        // Given
        let testRoom = Location(
            id: "testRoom",
            .name("Test Room"),
            .inherentlyLit
        )

        let container = Item(
            id: "container",
            .name("metal container"),
            .description("A metal storage container."),
            .isOpenable,
            .isOpen,
            .in(.location("testRoom"))
        )

        let game = MinimalGame(
            player: Player(in: "testRoom"),
            locations: testRoom,
            items: container
        )

        let (engine, _) = await GameEngine.test(blueprint: game)

        // When
        try await engine.execute("close container")

        // Then
        let finalState = try await engine.item("container")
        #expect(finalState.hasFlag(.isTouched) == true)
    }

    // MARK: - Intent Testing

    @Test("Handler exposes correct Intents")
    func testIntents() async throws {
        let handler = CloseActionHandler()
        // CloseActionHandler doesn’t specify actions, so it should be empty
        #expect(handler.actions.isEmpty)
    }

    @Test("Handler exposes correct Verbs")
    func testVerbs() async throws {
        let handler = CloseActionHandler()
        #expect(handler.verbs.contains(.close))
        #expect(handler.verbs.contains(.shut))
        #expect(handler.verbs.count == 2)
    }

    @Test("Handler requires light")
    func testRequiresLightProperty() async throws {
        let handler = CloseActionHandler()
        #expect(handler.requiresLight == true)
    }
}
